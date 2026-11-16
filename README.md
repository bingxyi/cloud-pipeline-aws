# Cloud Tasks API

## Integração e implantação contínuas de uma API em nuvem

Este projeto estuda a relação entre versionamento, testes automatizados,
conteinerização e implantação remota de uma API de tarefas. O problema central
é estabelecer uma cadeia verificável entre uma alteração no código, a imagem
publicada e o serviço executado em uma instância Amazon EC2.

A solução utiliza Flask, Gunicorn e SQLite. O GitHub Actions executa testes e
constrói a imagem nos pull requests. Após a integração na `main`, publica uma
imagem identificada pelo SHA do commit no GitHub Container Registry (GHCR).
O CD implanta essa revisão na EC2 e consulta o endpoint `/health`.

## Arquitetura

```mermaid
flowchart LR
    PR[Branch e pull request] --> CI[Testes e construção]
    CI --> MAIN[Integração na main]
    MAIN --> IMG[GHCR: imagem por SHA]
    IMG --> CD[Implantação por SSH]
    CD --> EC2[EC2: Docker e Gunicorn]
    EC2 --> API[API Flask]
    API --> DB[SQLite em volume persistente]
```

A separação entre imagem e volume permite substituir o contêiner sem substituir
o banco. Esse mecanismo foi verificado pela conservação de um registro após a
recriação do contêiner. Ele não equivale a backup ou alta disponibilidade, pois
o volume permanece no mesmo host.

## Interface HTTP

| Método | Recurso | Comportamento |
|---|---|---|
| GET | `/` | Identificação do serviço e recursos disponíveis |
| GET | `/health` | HTTP 200 com consulta SQLite bem-sucedida; HTTP 503 em erro |
| GET | `/version` | Serviço `cloud-tasks-api`, versão `1.1.0` |
| GET | `/tasks` | Lista ordenada por identificador |
| POST | `/tasks` | Criação com título válido; HTTP 201 ou 400 |
| PATCH | `/tasks/<id>` | Atualização de `done`; HTTP 200, 400 ou 404 |
| DELETE | `/tasks/<id>` | HTTP 204 sem corpo; HTTP 404 se ausente |

O título deve ser texto não vazio com até 120 caracteres. O campo `done` aceita
somente valores booleanos. As operações de escrita utilizam parâmetros SQL.

## Reprodução local

Com Python 3.12, no PowerShell:

```powershell
py -3.12 -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r requirements-dev.txt
.\.venv\Scripts\python.exe -m pytest -q
```

Com Docker Compose:

```bash
docker compose up --build -d
curl --fail http://localhost:8080/health
```

`bash validate-local.sh` reúne testes, análise de sintaxe, construção da imagem
e verificação de persistência após recriação. Requer Python com as dependências
instaladas, Bash e Docker Compose.

Na EC2, o banco está em `/data/tasks.db`, no volume `cloud-tasks-data`. No
Compose, o nome efetivo do volume recebe também o prefixo do projeto. Os volumes
dos ambientes local e remoto não são compartilhados automaticamente.

## Documentação técnica

| Documento | Conteúdo |
|---|---|
| [Relatório técnico](docs/RELATORIO.md) | Problema, decisões, método, resultados e limitações |
| [Protocolo de validação](docs/VALIDACAO.md) | Propriedades verificadas e registros experimentais |
| [Configuração](docs/CONFIGURACAO.md) | Reprodução do ambiente e parâmetros do pipeline |
| [Operação](docs/OPERACAO.md) | Diagnóstico, persistência, custos e ciclo de vida |
| [Síntese do seminário](docs/SEMINARIO.md) | Exposição dos fundamentos e resultados |
| [Slides](docs/apresentacao.html) | Síntese visual; abrir localmente no navegador |

Os [registros experimentais](docs/evidencias/) representam coletas datadas.
Execuções posteriores podem produzir outro SHA e outro contêiner. O histórico
dos workflows está disponível em [Actions](https://github.com/bingxyi/cloud-pipeline-aws/actions).

## Delimitação

Foram aprovados nove testes de API e verificadas respostas HTTP, rastreabilidade
da imagem e persistência na recriação do contêiner. Não foram medidos latência,
throughput, disponibilidade longitudinal ou capacidade sob carga.

A topologia utiliza uma instância Ubuntu 24.04 `t3.micro` em `us-east-1`, HTTP
na porta 80, SSH restrito por origem e processo `appuser` no contêiner. Não há
TLS, autenticação de usuários, replicação do banco ou recuperação automática do
host. Trata-se de um estudo de implantação de pequena escala, sem garantias de
alta disponibilidade.
