# Cloud Tasks API — projeto de Computação em Nuvem

**Integrante:** Rafael Bitu Castro de Abreu (RA22301190), projeto individual.
**Repositório:** [bingxyi/cloud-pipeline-aws](https://github.com/bingxyi/cloud-pipeline-aws)
**Estado em 2026-11-16:** implementação, CI, CD e demonstração de persistência remota concluídos para o commit `fedf0295356db273686130be3bdf76c3c5d5d87e`.

## Evidências verificadas

- [PR #1 mesclado](https://github.com/bingxyi/cloud-pipeline-aws/pull/1), commit `fedf0295356db273686130be3bdf76c3c5d5d87e`.
- [CI do PR aprovada](https://github.com/bingxyi/cloud-pipeline-aws/actions/runs/43886754600) e [CI da main aprovada](https://github.com/bingxyi/cloud-pipeline-aws/actions/runs/43887501389).
- [CD aprovado](https://github.com/bingxyi/cloud-pipeline-aws/actions/runs/43887665966) para o mesmo SHA. O runner baixou a imagem GHCR; antes, o manifest da imagem base também foi verificado com configuração Docker vazia na EC2, confirmando acesso anônimo.
- Imagem implantada: `ghcr.io/bingxyi/cloud-pipeline-aws:fedf0295356db273686130be3bdf76c3c5d5d87e`, digest `sha256:ffc8f538af5aded1bafa37990154782112803de8faf162a8a3e0615d1fb6af7e`.
- API em `http://54.198.190.67`: `/health` retornou `{"status":"ok"}` e `/version` retornou serviço `cloud-tasks-api`, versão `1.1.0`.
- DELETE remoto respondeu 204 na primeira exclusão e 404 na repetição.
- Persistência remota comprovada: a tarefa ID 1 sobreviveu à recriação do contêiner pelo `scripts/deploy.sh`, mantendo o volume e a imagem do commit. Evidência detalhada em [docs/evidencia-ec2.json](docs/evidencia-ec2.json).
- EC2 `i-0c6f23086bc98c45e`, região `us-east-1`, IP `54.198.190.67`; Docker 29.1.3. Regras verificadas ao final: SSH 22 somente de `189.6.11.151/32` e HTTP 80 de `0.0.0.0/0`; a regra temporária do runner foi removida.
- Ambiente GitHub `production`, secrets e variables necessários ao deploy foram configurados sem incluir valores neste repositório.

Custos consultados: US$ 0,08848 estimados na conta em 15–16/11, sem atribuicao exclusiva ao projeto. A instancia permanece ligada para apresentacao por solicitacao do responsavel. Veja a [auditoria dos sete criterios](docs/AUDITORIA_FINAL.md).

## API e testes

A API Flask usa SQLite. Suporta GET `/`, `/health`, `/version`, `/tasks`; POST `/tasks`; PATCH e DELETE `/tasks/<id>`. DELETE retorna 204 sem corpo ao excluir e 404 JSON para ID inexistente. `/version` retorna `{"service":"cloud-tasks-api","version":"1.1.0"}`. O contêiner armazena o banco em `/data/tasks.db`, montado no volume persistente `cloud-tasks-data`.

Os nove testes de `tests/test_api.py` cobrem saúde, criação/listagem, validação, PATCH, DELETE 204/404, versão e persistência ao recriar a aplicação com o mesmo banco. Foram aprovados localmente e na CI. A validacao local também aprovou build, smoke test e persistência ao recriar contêiner.

Para executar localmente com Python 3.12:

```powershell
py -3.12 -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r requirements-dev.txt
.\.venv\Scripts\python.exe -m pytest -q
```

Ou use Docker Compose:

```bash
docker compose up --build -d
curl --fail http://localhost:8080/health
```

## Entrega restante

- [x] Custos estimados consultados e documentados na auditoria final.
- [x] Evidencias coletadas e roteiro/slides preparados; apresentacao pelo responsavel ainda futura.
- [ ] Após a apresentação, encerrar a EC2 e revisar volumes e IPs remanescentes; documentar a verificação.

Mais contexto e registro de execução: [relatório](docs/RELATORIO.md) e [próximos passos](docs/PROXIMOS_PASSOS.md). Procedimentos AWS/GitHub: [docs/CONFIGURACAO.md](docs/CONFIGURACAO.md).

## Pacote final de apresentacao

- [Matriz dos sete criterios e evidencias](docs/AUDITORIA_FINAL.md).
- [Roteiro de demonstracao de ate cinco minutos](docs/APRESENTACAO.md).
- [Slides HTML](docs/apresentacao.html): baixar/abrir no navegador local; usar as setas para navegar e Ctrl+P para imprimir ou salvar PDF.
- [Respostas coletadas de AWS, GitHub, GHCR, HTTP e testes](docs/evidencias/), com data de coleta e sem credenciais.

As evidencias documentam instantes especificos da execucao. Consultar a aba Actions
para o ultimo commit publicado. A apresentacao e o envio ao Moodle sao realizados
pelo responsavel; a API permanece ligada para essa demonstracao.
