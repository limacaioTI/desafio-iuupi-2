# Desafio IUUPI Mobile — Carteira Digital Escolar

Este é um repositório para o desafio técnico de desenvolvimento mobile para a IUUPI.

## Objetivo

Desenvolva um aplicativo Flutter para consultar o saldo de um aluno e acompanhar
seu histórico de transações. O desafio busca avaliar competências comuns no
desenvolvimento mobile: consumo de API REST, gerenciamento de estado, navegação,
cache local, tratamento de erros, arquitetura, qualidade de código e experiência
do usuário.

O produto é organizado em Dashboard, Extrato e, como escopo adicional,
Operações com a Carteira para recarga e saque.

## Entrega

1. Faça um **fork** deste repositório para a sua conta.
2. Desenvolva e envie o projeto completo no repositório criado pelo fork.
3. Inclua no seu projeto instruções suficientes para instalar as dependências e
   executar o aplicativo.
4. Utilize **Flutter** `3.44.0` ou superior para desenvolver o app.
5. Ao concluir, envie o link do fork para parceriacom@iuupi.com.br.
6. O prazo de entrega é até **segunda-feira, 24/08/2026**.

## Escopo do aplicativo

### 1. Login

- CPF;
- senha;
- persistência da sessão;
- logout.

### 2. Dashboard

Exiba:

- nome e foto do usuário;
- saldo disponível;
- as cinco transações mais recentes;
- atualização por gesto de *pull-to-refresh*.

Exemplo:

```text
João da Silva

Saldo
R$ 58,40

Últimas movimentações
+ R$ 50,00  Recarga
- R$ 12,00  Lanche
- R$ 8,50   Refrigerante
```

### 3. Extrato

- lista paginada;
- filtros: todos, crédito e débito;
- ao tocar em uma transação, abrir a tela de detalhes.

### 4. Operações com a carteira — escopo adicional

Implemente duas operações:

- uma tela de **recarga**, que adiciona saldo;
- uma tela de **saque**, que reduz saldo.

Cada tela deve:

- receber e validar um valor monetário positivo;
- permitir confirmar ou cancelar a operação;
- apresentar loading, sucesso e erro;
- atualizar o saldo do Dashboard;
- fazer a nova movimentação aparecer no início do Extrato.

O saque deve apresentar uma mensagem adequada quando o saldo for insuficiente.

### 5. Perfil

Exiba:

- nome;
- escola;
- matrícula;
- botão para sair.

## Requisitos obrigatórios

### API

Consuma os seguintes endpoints:

- `POST /login`;
- `GET /me`;
- `GET /transactions`;
- `GET /transactions/:id`.

O contrato completo, os exemplos e a possibilidade de testar as requisições
estão disponíveis na documentação Swagger descrita abaixo.

Como extensão opcional, a API também oferece:

- `POST /transactions`.

Essa rota permite implementar as telas de recarga e saque sem alterar o escopo
obrigatório de consulta da carteira e do extrato.

### Estados e erros

A interface deve representar adequadamente:

- carregamento;
- dispositivo sem conexão;
- tempo limite excedido;
- erro retornado pela API.

### Cache local

Ao abrir novamente o aplicativo, apresente o último saldo conhecido mesmo sem
conexão e deixe claro para o usuário que esse valor pode estar desatualizado.
Você pode usar Hive, Isar, SQLite ou outra solução equivalente. Armazenar também
o perfil e as últimas transações para consulta offline é um diferencial.

### Interface

- temas claro e escuro;
- bom funcionamento em celular pequeno e tablet;
- estados vazios e mensagens de erro compreensíveis;
- placeholder adequado caso a foto remota do aluno não carregue.

## Diferenciais

Os itens abaixo não são obrigatórios, mas contam pontos extras:

- testes unitários;
- testes de widgets;
- acessibilidade;
- boa documentação das decisões técnicas.

Você pode escolher Riverpod, Bloc, Cubit, Provider ou outra abordagem. O
importante é manter uma arquitetura coerente e justificar a decisão no README da
sua entrega.

## Executando a API local

### Pré-requisitos

- Ruby 3.1 ou superior;
- Bundler;
- `curl` (opcional, para testar pelo terminal).

Instale as dependências e inicie o servidor:

```bash
bundle install
bundle exec ruby api.rb
```

A API ficará disponível em:

```text
http://localhost:3001
```

Para confirmar:

```bash
curl http://localhost:3001/
```

### Swagger

Com a API em execução, acesse:

```text
http://localhost:3001/docs
```

Essa tela permite consultar e testar interativamente os endpoints. A
especificação OpenAPI também está disponível diretamente em:

```text
http://localhost:3001/openapi.yaml
```

A interface do Swagger utiliza arquivos visuais carregados da internet. Se eles
não estiverem disponíveis, o arquivo `openapi.yaml` continuará podendo ser
consultado no repositório ou pela rota acima.

### Credenciais de teste

```text
CPF:   12345678900
Senha: 123456
```

O CPF também pode ser enviado formatado, por exemplo `123.456.789-00`.

### Autenticação

Faça o login:

```bash
curl -X POST http://localhost:3001/login \
  -H "Content-Type: application/json" \
  -d '{"cpf":"12345678900","password":"123456"}'
```

Os demais endpoints obrigatórios exigem o cabeçalho:

```text
Authorization: Bearer desafio-mobile-token
```

O token do mock é fixo e não expira. Não é necessário implementar renovação de
token. No logout, remova a sessão persistida e os dados locais considerados
sensíveis. No botão **Authorize** do Swagger, informe somente
`desafio-mobile-token`, sem escrever `Bearer`.

Exemplos:

```bash
curl http://localhost:3001/me \
  -H "Authorization: Bearer desafio-mobile-token"

curl "http://localhost:3001/transactions?page=1&per_page=10" \
  -H "Authorization: Bearer desafio-mobile-token"

curl "http://localhost:3001/transactions?type=credit" \
  -H "Authorization: Bearer desafio-mobile-token"

curl http://localhost:3001/transactions/1 \
  -H "Authorization: Bearer desafio-mobile-token"

curl -X POST http://localhost:3001/transactions \
  -H "Authorization: Bearer desafio-mobile-token" \
  -H "Content-Type: application/json" \
  -d '{"type":"credit","amount":50.00,"description":"Recarga via Pix"}'
```

Filtros aceitos em `GET /transactions`:

| Parâmetro | Descrição | Padrão |
| --- | --- | --- |
| `page` | Página, começando em 1 | `1` |
| `per_page` | Quantidade por página, entre 1 e 50 | `10` |
| `type` | `credit` ou `debit`; omita para todos | todos |

Parâmetros vazios, fora dos limites ou com formatos inválidos retornam HTTP
`400`. Uma página além do total retorna HTTP `200` com `data: []`.

As transações são retornadas da mais recente para a mais antiga. O campo
`amount` é sempre um número positivo; utilize `type` para decidir se o valor
deve ser apresentado como crédito ou débito. O saldo retornado por `GET /me` é
sempre a fonte do saldo atual e não precisa ser recalculado pelo aplicativo a
partir do extrato.

### Operações com a carteira — extensão opcional

Utilize `POST /transactions` para criar uma recarga ou um saque:

```json
{
  "type": "credit",
  "amount": 50.0,
  "description": "Recarga via Pix"
}
```

Regras:

- `credit` representa uma recarga e aumenta o saldo;
- `debit` representa um saque e reduz o saldo;
- `amount` deve ser numérico, positivo e possuir no máximo duas casas decimais;
- `description` é opcional e aceita entre 1 e 100 caracteres;
- se a descrição for omitida, a API utiliza `Recarga de saldo` ou
  `Saque de saldo`;
- saques acima do saldo retornam `422` com `insufficient_balance`;
- saldo e extrato são atualizados juntos;
- a resposta `201` contém a transação criada e o novo saldo.

Exemplo de saque:

```bash
curl -X POST http://localhost:3001/transactions \
  -H "Authorization: Bearer desafio-mobile-token" \
  -H "Content-Type: application/json" \
  -d '{"type":"debit","amount":10.00}'
```

### Testando estados de erro

Rotas auxiliares disponíveis:

- `GET /simulate/error`: retorna erro HTTP 500;
- `GET /simulate/slow`: aguarda três segundos antes de responder.

Elas podem ser usadas para validar erro da API e timeout. Também é possível
parar o servidor para simular indisponibilidade/offline. A rota lenta informa o
atraso no campo `delay_seconds`; para testar timeout, configure temporariamente
o cliente HTTP com limite inferior a três segundos.

### Endereço da API no Flutter

O endereço depende de onde o aplicativo está rodando:

| Ambiente | URL base |
| --- | --- |
| Flutter Web | `http://localhost:3001` |
| iOS Simulator | `http://localhost:3001` |
| Android Emulator | `http://10.0.2.2:3001` |
| Dispositivo físico | `http://IP-DA-SUA-MAQUINA:3001` |

O servidor escuta em `0.0.0.0`, portanto pode ser acessado por um dispositivo na
mesma rede local. Verifique o firewall da máquina e substitua
`IP-DA-SUA-MAQUINA` pelo endereço IP local do computador.

## Contrato resumido da API

O arquivo [`openapi.yaml`](openapi.yaml) é a fonte mais detalhada do contrato.
Esta seção apresenta apenas os exemplos principais.

### `POST /login`

Corpo:

```json
{
  "cpf": "12345678900",
  "password": "123456"
}
```

Resposta de sucesso (`200`):

```json
{
  "access_token": "desafio-mobile-token",
  "token_type": "Bearer",
  "user": {
    "id": 1,
    "name": "João da Silva",
    "cpf": "12345678900",
    "school": "Escola Exemplo",
    "registration": "20260001",
    "balance": 58.4,
    "avatar_url": "https://i.pravatar.cc/300?img=12"
  }
}
```

### `GET /transactions`

Resposta de sucesso (`200`):

```json
{
  "data": [
    {
      "id": 1,
      "type": "credit",
      "description": "Recarga de saldo",
      "amount": 50.0,
      "created_at": "2026-08-06T12:00:00-03:00"
    }
  ],
  "pagination": {
    "page": 1,
    "per_page": 10,
    "total": 25,
    "total_pages": 3
  }
}
```

As datas são geradas quando a API é iniciada e, por isso, podem variar.

### `POST /transactions` — extensão opcional

Resposta de uma recarga de R$ 50,00 sobre o saldo inicial:

```json
{
  "transaction": {
    "id": 26,
    "type": "credit",
    "description": "Recarga via Pix",
    "amount": 50.0,
    "created_at": "2026-08-06T12:05:00-03:00"
  },
  "balance": 108.4
}
```

### Formato dos erros

Todos os erros retornam:

```json
{
  "error": "invalid_parameter",
  "message": "O parâmetro page deve ser um número inteiro positivo"
}
```

O campo `error` é um código estável para decisões do aplicativo. A mensagem pode
ser apresentada diretamente ou adaptada para oferecer uma experiência melhor.

| Situação | HTTP | `error` |
| --- | ---: | --- |
| JSON inválido | `400` | `invalid_json` |
| Filtro ou paginação inválidos | `400` | `invalid_parameter` |
| Credenciais inválidas | `401` | `invalid_credentials` |
| Token ausente ou inválido | `401` | `unauthorized` |
| Transação ou endpoint inexistente | `404` | `not_found` |
| Dados inválidos ao criar uma transação | `422` | `validation_error` |
| Saldo insuficiente para saque | `422` | `insufficient_balance` |
| Erro simulado ou inesperado | `500` | `internal_server_error` |

## Critérios de avaliação

- atendimento ao escopo e funcionamento do fluxo completo;
- clareza da arquitetura e separação de responsabilidades;
- tratamento de estados, erros e conectividade;
- persistência de sessão e cache;
- qualidade, legibilidade e consistência do código;
- UX, responsividade e suporte aos temas;
- qualidade dos testes e da documentação.

## Observações sobre a API

Os dados são mantidos somente em memória. Reiniciar o processo restaura o estado
inicial de saldo e transações. A criação de recargas e saques é opcional e não
faz parte do escopo obrigatório de consulta. A foto do usuário é carregada de um
serviço externo e pode ficar indisponível.
