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
falhar (sem conexão, timeout ou erro do servidor), a tela cai para esses
dados salvos e exibe um banner deixando claro que a informação pode estar
desatualizada, com o horário da última atualização bem-sucedida. O saldo
retornado por `GET /me` nunca é recalculado localmente a partir do extrato,
conforme o contrato da API.

### Responsividade

Um `ResponsiveContainer` (largura máxima configurável, centralizado) evita
que cards e formulários se estiquem de ponta a ponta em telas grandes.
Testado em iPhone e em iPad (simulador) — em celular não tem efeito visual,
pois a tela já é menor que o limite.

### Temas

Claro e escuro via `ColorScheme.fromSeed` (Material 3), com um botão no
Perfil que alterna manualmente entre os dois (em vez de seguir apenas a
configuração do sistema) e persiste a escolha.

## O que foi implementado

- Login (CPF/senha), persistência de sessão, logout.
- Dashboard: nome, foto (com placeholder), saldo, 5 últimas transações,
  pull-to-refresh.
- Extrato: lista paginada, filtro (todos/crédito/débito), tela de detalhe.
- Perfil: nome, escola, matrícula, alternância de tema, sair.
- Estados de carregamento, erro da API, tempo limite excedido e sem conexão
  (com fallback para cache no Dashboard e no Extrato).
- Cache local do perfil, saldo e transações recentes.
- Temas claro/escuro.

## O que ficou de fora

- **Recarga e saque** (escopo adicional/opcional do desafio): não
  implementados por priorização de tempo — o esforço foi direcionado a
  cobrir com solidez todo o escopo obrigatório (incluindo os estados de
  erro/offline, que exigem testes manuais cuidadosos) antes de expandir para
  o opcional.
- **Testes automatizados** (unitários/widget): não implementados pelo mesmo
  motivo de priorização.
- Diferenciação visual entre "erro do servidor" e "tempo limite excedido" no
  Extrato: ambos caem hoje na mesma tela de erro genérica com botão de tentar
  novamente — decisão consciente de não complicar a UI dado o tempo
  disponível, já que a experiência (mensagem clara + retry) continua
  adequada em ambos os casos.

## Dependências principais

| Pacote | Uso |
| --- | --- |
| `provider` | gerenciamento de estado |
| `http` | cliente HTTP |
| `hive` / `hive_flutter` | persistência local (sessão, cache, preferências) |
| `cached_network_image` | avatar do aluno com placeholder |
| `intl` | formatação de moeda (R$) e datas em pt-BR |
