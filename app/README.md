# Carteira Digital Escolar

App Flutter desenvolvido para o desafio técnico mobile da IUUPI: consulta de
saldo, extrato de transações e perfil do aluno, consumindo a API mock
descrita na raiz do repositório.

## Como rodar

Pré-requisitos: Flutter `3.44.0` ou superior, e a API mock rodando (ver
`README.md` na raiz do repositório).

```bash
# na raiz do repositório, em um terminal
bundle install
bundle exec ruby api.rb
```

```bash
# neste diretório (app/), em outro terminal
flutter pub get
flutter run
```

A URL da API é resolvida automaticamente por plataforma (ver
`lib/core/api_client.dart`): `localhost:3001` no iOS/web, `10.0.2.2:3001` no
emulador Android. Para dispositivo físico, troque manualmente pelo IP da
máquina na mesma rede.

**Credenciais de teste:**
```
CPF:   12345678900
Senha: 123456
```

## Arquitetura

```
lib/
  core/        # infraestrutura: HTTP, exceções, armazenamento local
  models/      # entidades de dados (User, Transaction...)
  providers/   # estado de cada funcionalidade (Provider/ChangeNotifier)
  screens/     # telas, organizadas por feature
  widgets/     # componentes de UI reutilizáveis entre telas
```

### Por que Provider

Optei por **Provider** em vez de Bloc/Riverpod pela simplicidade: é a
abordagem oficialmente recomendada pelo time do Flutter, tem a menor curva de
aprendizado e, para o tamanho deste app (5 telas, 3 fontes de estado), não
exige o boilerplate adicional que Bloc traria nem a complexidade de code
generation do Riverpod. Cada `ChangeNotifier` expõe um enum de status
(`loading` / `success` / `error` / variações específicas como
`offlineWithCache`) que a tela usa para decidir o que renderizar — sem lógica
de apresentação escondida dentro do provider.

- `AuthProvider`: sessão (login, logout, restauração automática ao abrir o
  app).
- `WalletProvider`: dados do Dashboard (perfil + saldo + 5 últimas
  transações).
- `TransactionsProvider`: extrato paginado, com filtro por tipo.
- `ThemeProvider`: preferência de aparência (claro/escuro), persistida.
- `WalletOperationProvider`: orquestra uma recarga ou saque (ver seção
  própria abaixo). É criado com escopo local à tela de operação, não no
  app inteiro, já que só existe enquanto o formulário está aberto.

### Camada `core`

- `ApiClient`: wrapper fino sobre `http`, centraliza base URL por plataforma,
  header de autenticação, timeout (8s) e conversão de respostas de erro em
  exceções tipadas.
- `ApiException` / `NetworkException`: diferenciam erro retornado pela API
  (com `error` code e `message`) de falha de rede (sem conexão vs. timeout).
- `StorageService`: wrapper sobre Hive com três boxes — `session` (token),
  `cache` (último perfil e transações conhecidos, para uso offline) e
  `settings` (preferência de tema, sobrevive ao logout por não ser dado de
  sessão).

### Cache local e modo offline

Ao carregar o Dashboard ou o Extrato com sucesso, o último `user` e as
transações mais recentes são salvos no Hive. Se uma chamada subsequente
falhar, a tela cai para esses dados salvos e exibe um banner (com
`Semantics(liveRegion: true)`, para leitores de tela anunciarem
automaticamente) deixando claro que a informação pode estar desatualizada,
com o horário da última atualização bem-sucedida. O saldo retornado por
`GET /me` nunca é recalculado localmente a partir do extrato, conforme o
contrato da API.

Tanto `WalletProvider` quanto `TransactionsProvider` diferenciam a origem da
falha (`ApiException` vs. `NetworkException`, e dentro desta, timeout vs.
sem conexão) para escolher a mensagem de fallback mostrada — não é um texto
genérico único.

No Extrato, uma falha ao carregar mais páginas (scroll infinito) não
descarta os itens já exibidos: mantém a lista atual e mostra um botão de
tentar novamente só para aquela página (`TransactionsStatus.loadMoreError`).

### `GET /transactions/:id`

A tela de detalhe recebe a transação já carregada da lista (evita um loading
desnecessário, já que o dado em mãos é suficiente) e, em paralelo, chama
`GET /transactions/:id` para exercitar o endpoint obrigatório e atualizar a
tela com o dado mais recente. Uma falha nessa chamada em segundo plano é
ignorada silenciosamente — o dado vindo da lista já é confiável.

### Acessibilidade

Além do que os widgets padrão do Material já oferecem (contraste do tema,
área de toque, leitura de texto por padrão), adicionei `Semantics`/`tooltip`
explícitos nos pontos onde a informação visual não teria um rótulo textual
correspondente: o avatar do aluno, o saldo no `BalanceCard`, o ícone de
crédito/débito na lista de transações, o botão de acesso ao Perfil e o
banner de offline (marcado como `liveRegion`, para leitores de tela
anunciarem a mudança de estado automaticamente).

### Responsividade

Um `ResponsiveContainer` (largura máxima configurável, centralizado) evita
que cards e formulários se estiquem de ponta a ponta em telas grandes.
Testado em iPhone e em iPad (simulador) — em celular não tem efeito visual,
pois a tela já é menor que o limite.

### Temas

Claro e escuro via `ColorScheme.fromSeed` (Material 3), com um botão no
Perfil que alterna manualmente entre os dois (em vez de seguir apenas a
configuração do sistema) e persiste a escolha.

### Recarga e saque

Implementados como uma única tela parametrizada
(`WalletOperationScreen(type: TransactionType.credit | debit)`), já que
recarga e saque têm exatamente o mesmo formato de tela — valor, descrição
opcional, confirmar/cancelar, loading/sucesso/erro — mudando só o texto,
ícone e o `type` enviado à API.

O fluxo é orquestrado pelo `WalletOperationProvider`, criado com escopo
local à tela (não fica registrado no app inteiro, só existe enquanto a tela
de operação está aberta). Ao confirmar:

1. Valida o valor localmente (positivo, no máximo duas casas decimais) antes
   de chamar a API.
2. Chama `POST /transactions`.
3. Em caso de sucesso, propaga o resultado para os providers que já
   existiam — `WalletProvider.applyBalanceUpdate()` atualiza o saldo do
   Dashboard, e `TransactionsProvider.prependTransaction()` insere a nova
   transação no início do Extrato — sem precisar refazer nenhum `GET`.
4. Em caso de saldo insuficiente (`422 insufficient_balance`), mostra essa
   mensagem específica; outros erros (rede, servidor) usam a mensagem
   vinda da própria API ou uma mensagem de rede genérica.

O formulário permanece editável após um erro, permitindo corrigir o valor e
tentar de novo sem perder o que já foi digitado.

## Testes automatizados

52 testes (unitários e de widget), rodando com `flutter test`:

```bash
flutter test
```

| Camada | Arquivos | O que cobre |
| --- | --- | --- |
| Models | `test/models/*_test.dart` | `fromJson`/`toJson`, conversão de tipos, casos de borda (paginação vazia, `hasNextPage`) |
| Core | `test/core/api_client_test.dart` | Sucesso, erro 4xx/5xx, saldo insuficiente, sem conexão e timeout — usando `MockClient` do pacote `http`, sem depender de rede real |
| Providers | `test/providers/*_test.dart` | Ciclo de tema (claro↔escuro) e persistência; `WalletOperationProvider` — recarga/saque com sucesso, saldo insuficiente e falha de rede, verificando que o saldo e o extrato só mudam quando a operação realmente é bem-sucedida |
| Widgets | `test/widgets/*_test.dart` | `state_views` (loading/erro/vazio/offline) e `TransactionTile` (cores, sinal, callback de toque) |
| Screens | `test/screens/*_test.dart` | Login (validação de formulário); Dashboard (dados carregados, vazio, offline, erro); Extrato (lista, filtro, vazio, erro, offline, retry de paginação); Perfil (dados do aluno, alternância de tema) |

**Como os testes de tela evitam depender de rede/Hive real**: em vez de
deixar `DashboardScreen`/`StatementScreen` disparar `load()` de verdade ao
montar (o que exigiria mockar a API e esperar I/O real do Hive dentro do
clock falso do `testWidgets`), os testes usam um provider "fake" que
sobrescreve `load()`/`loadMore()` como no-op e define o estado
(`status`, `user`, `items`...) diretamente — a mesma ideia dos testes de
provider que já faziam `..user = _initialUser`. Isso mantém os testes de
tela rápidos e determinísticos, testando exatamente o que a tela renderiza
para cada estado possível.

**Decisões de teste:**

- **`MockClient` em vez de mocks gerados**: o pacote `http` já vem com
  `package:http/testing.dart`, então dava pra testar o `ApiClient` de ponta a
  ponta (parsing, headers, exceções) sem adicionar `mockito`/`mocktail` como
  dependência extra.
- **`ApiClient` e `StorageService` ganharam pontos de injeção de
  dependência** (`timeout` configurável e `boxSuffix`/`useFlutterInit` no
  Hive) especificamente para permitir testes rápidos e isolados — por
  exemplo, o teste de timeout usa 50ms em vez de esperar os 8s reais.
- **`tester.runAsync()` nos testes de widget que tocam o Hive**: o binding
  de teste do Flutter (`testWidgets`) roda num clock controlado, e I/O real
  (como abrir um arquivo do Hive em disco) trava indefinidamente se não for
  explicitamente executado dentro de `runAsync`. Foi o único ponto que exigiu
  investigação mais a fundo durante o desenvolvimento — os testes travavam
  em 10 minutos cada até isolar a causa.
- **Providers que dependem de rede/disco não são testados via singletons
  globais**: cada teste cria sua própria instância de `StorageService` (Hive
  isolado por sufixo único) e `ApiClient` (com `MockClient` próprio), então
  os testes podem rodar em paralelo sem interferir uns nos outros.

## O que foi implementado

- Login (CPF/senha), persistência de sessão, logout.
- Dashboard: nome, foto (com placeholder), saldo, 5 últimas transações,
  pull-to-refresh.
- Extrato: lista paginada, filtro (todos/crédito/débito), tela de detalhe.
- Perfil: nome, escola, matrícula, alternância de tema, sair.
- Recarga e saque (escopo adicional do desafio): validação de valor,
  confirmar/cancelar, loading/sucesso/erro, saldo insuficiente tratado
  especificamente, saldo e extrato atualizados sem novo `GET`.
- Estados de carregamento, erro da API, tempo limite excedido e sem conexão
  (com fallback para cache no Dashboard e no Extrato).
- Cache local do perfil, saldo e transações recentes.
- Temas claro/escuro.
- Labels de acessibilidade (`Semantics`) no avatar, saldo, ícones de
  crédito/débito e banner offline (este último com `liveRegion: true`).
- `GET /transactions/:id` consumido pela tela de detalhe da transação.
- 52 testes automatizados (unitários e de widget) — ver seção própria acima.

## O que ficou de fora

- Testes automatizados de acessibilidade (ex.: `flutter_test`'s
  `SemanticsHandle`/`meetsGuideline`) e validação com um leitor de tela
  real: os labels (`Semantics`) foram adicionados nos pontos mais óbvios
  (avatar, saldo, ícone de crédito/débito, banner offline), mas não há uma
  auditoria formal de contraste ou navegação por leitor de tela.
- Tratamento de token expirado durante o uso do app (ex.: um `401` em
  `GET /me`/`GET /transactions` depois de um login válido): hoje isso cai no
  fluxo de erro/cache genérico em vez de deslogar o usuário automaticamente.
  Não é exigido pelo desafio, já que o token do mock não expira, mas seria a
  próxima lacuna de robustez a fechar.

## Dependências principais

| Pacote | Uso |
| --- | --- |
| `provider` | gerenciamento de estado |
| `http` | cliente HTTP |
| `hive` / `hive_flutter` | persistência local (sessão, cache, preferências) |
| `cached_network_image` | avatar do aluno com placeholder |
| `intl` | formatação de moeda (R$) e datas em pt-BR |
