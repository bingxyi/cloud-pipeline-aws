# Relatorio de entrega - Cloud Tasks API

## Identificacao e arquitetura

Responsavel: Rafael Bitu Castro de Abreu, RA22301190. Projeto individual.
Repositorio: [bingxyi/cloud-pipeline-aws](https://github.com/bingxyi/cloud-pipeline-aws) (codigo ainda nao enviado pelo usuario).
Responsabilidades individuais: implementacao da API e testes, container e validacao local, preparacao do pipeline e da infraestrutura, relatorio e entrega. A preparacao local nao significa que CI remota, publicacao, provisionamento ou deploy tenham ocorrido.

```mermaid
flowchart LR
    PR[Branch feature e PR] --> CI[pytest e build Docker]
    CI --> Main[Merge na main]
    Main --> GHCR[Imagem GHCR por SHA]
    GHCR --> CD[CD apos CI aprovada]
    CD --> EC2[EC2 Ubuntu e Docker]
    EC2 --> DB[SQLite em cloud-tasks-data]
```

## Implementacao

- DELETE `/tasks/<id>` retorna 204 sem corpo ou 404 JSON.
- GET `/version` retorna service `cloud-tasks-api` e version `1.1.0`.
- Nove testes cobrem a API e persistencia apos recriar a aplicacao no mesmo banco.
- Configuracao da CI define pytest, teste simulado de acesso SSH e build em PR; publicacao GHCR por SHA em push na main. Execucao remota pendente.
- Configuracao do CD espera CI aprovada, usa o mesmo SHA e verifica `/health`; execucao remota pendente.
- Usuario autorizou commits e publicacao automatizados. Base preparada em main e implementacao em feature/delete-endpoint, sem Co-Authored-By. Publicacao remota ainda pendente.
- Host confirma que `scripts/provision-aws.ps1` criou Ubuntu 24.04 `t3.micro`: instancia `i-0c6f23086bc98c45e`, IP `54.198.190.67`, SG `sg-09352ffbaa35709b2`. `-Status` validou instancia/tag e gerou `known_hosts` com chave publica obtida pelo console AWS autenticado. Chave privada e estado ficam fora do repositorio.
- Comando documentado: `powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\provision-aws.ps1`. Perfil default; aceita `-Profile`, `-AdminCidr`, `-StatePath` e `-Status`. Estado existente direciona consultas e impede criacao duplicada; falha parcial sem `InstanceId` exige recuperacao manual.
- O workflow de CD pode usar acesso temporario SSH /32 ao runner via `EC2_SECURITY_GROUP_ID` e credenciais curtas `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_SESSION_TOKEN`. A revogacao exata e tentada no encerramento; validar o Security Group apos cada job, pois cancelamento forcado ou credenciais expiradas podem deixar regra residual.

## Infraestrutura prevista

Regiao: us-east-1; Ubuntu 24.04 x86_64. O inventario inicial somente leitura nao
encontrou instancias nos estados consultados; depois, o host criou a instancia
`i-0c6f23086bc98c45e`, IP `54.198.190.67`, security group `sg-09352ffbaa35709b2`.
Porta HTTP 80 para validacao; SSH 22 apenas
de origem confiavel. O runner precisa de acesso autorizado, conforme guia docente.
O deploy usa volume nomeado `cloud-tasks-data` e banco `/data/tasks.db`.
EC2_USER e uma variable do Actions; os demais EC2_* sao secrets, conforme README.

## Verificacoes e limitacoes observadas

- Harness no host: pytest 9 passed em 0.73s.
- Dependencias instaladas: `uv pip check --python .venv/Scripts/python.exe`: 15 pacotes compativeis.
- Os YAML de Compose e dos dois workflows foram analisados sintaticamente; isso nao equivale a validacao por Docker Compose ou execucao no GitHub Actions. O TOML de `.codex/config.toml` foi analisado.
- Sintaxe dos tres scripts shell validada separadamente com Git Bash; `scripts/inspect-aws.ps1` passou analise do parser PowerShell.
- Testes mockados de `scripts/runner-ssh-access.sh` passaram pelo harness; AWS CLI e consulta de IP foram simulados, sem chamadas AWS. O teste foi incluido no harness e na CI.
- `scripts/provision-aws.ps1` passou analise de parser PowerShell; AWS CLI `--generate-cli-skeleton` aceitou argumentos representativos de `run-instances` (validacao offline).
- `-Status` executado pelo usuario validou instancia/tag e obteve a chave publica de host do console AWS autenticado, gerando `known_hosts` fora do repositorio.
- Build da imagem Ubuntu/Python 3.12 e smoke test local aprovados: health, version, DELETE e persistencia apos recriar container.
- Containers e rede do harness foram removidos; volume `cloud-tasks-smoke-535_cloud-tasks-data` mantido para inspecao. Preservar esse volume; nao remove-lo durante limpeza automatica.
- Persistencia local aprovada. Usuario confirmou via SSH cloud-init done e Docker cliente/servidor 29.1.3 (linux/amd64), acessivel como ubuntu. Aplicacao e persistencia em EC2 seguem pendentes.
- Codigo ainda nao foi enviado ao GitHub. Workflows remotos, CI, GHCR e deploy nao foram verificados.
- Inventario atualizado fornecido pelo usuario em 2026-11-16: EC2 running em us-east-1, Ubuntu 24.04 oficial, rota ativa via Internet Gateway, HTTP 80 publico e SSH 22 restrito ao IP administrativo /32. Custos nao verificados.

## Evidencias externas pendentes

| Evidencia | Estado |
|---|---|
| URL do repositorio | Informada; codigo ainda nao enviado |
| Integrante e matricula | Rafael Bitu Castro de Abreu, RA22301190 |
| PR com revisao e CI aprovada | Pendente |
| Imagem GHCR publica com SHA | Pendente |
| CD aprovado e HTTP /health | Pendente |
| GET /tasks antes/depois de recriar container | Pendente |
| Inventario AWS, custos e encerramento | Pendente |
| Harness local: pytest, build, API e persistencia do container | Aprovado |

O host informa a criacao da EC2 acima; esta atualizacao documental nao fez alteracoes AWS. Custos nao foram verificados. Apos a demonstracao, registrar IDs dos recursos,
encerrar a instancia e verificar volumes/IPs remanescentes no console, guardando
evidencias sem credenciais. Nao registrar encerramento sem verificacao real.
