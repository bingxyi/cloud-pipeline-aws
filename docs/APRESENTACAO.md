# Roteiro da apresentação — 4min30

**Projeto:** Cloud Tasks API
**Responsável:** Rafael Bitu Castro de Abreu — RA22301190 (individual)
**Demonstração:** [slides HTML](apresentacao.html) · [repositório](https://github.com/bingxyi/cloud-pipeline-aws)

O roteiro cobre os sete critérios da auditoria: Git/PR; testes e CI; Docker/GHCR; EC2 e segurança; CD e health; evolução funcional; documentação e apresentação. Duração total: **4min30**. As chamadas HTTP abaixo são somente leitura. Não excluir dados nem recriar o contêiner ao vivo; apresente os resultados já registrados.

## 0:00–0:30 — 1. Projeto e resultado

“Este é meu projeto individual de Computação em Nuvem. A API de tarefas Flask usa SQLite e é implantada em uma EC2 com Docker. O PR #1 introduziu a funcionalidade e foi mesclado no commit `fedf0295356db273686130be3bdf76c3c5d5d87e`. Depois, o PR #3 atualizou a documentação; o snapshot implantado e auditado é `57e2869681c5844205272fc67c3733817f5cd390`. Vou mostrar a API, a CI/CD, a infraestrutura e as evidências.”

Abra o [PR #1](https://github.com/bingxyi/cloud-pipeline-aws/pull/1), o [PR #3](https://github.com/bingxyi/cloud-pipeline-aws/pull/3) e o repositório.

## 0:30–1:10 — 2. API implantada

“A instância responde publicamente em HTTP. `/health` confirma disponibilidade e `/version` identifica o serviço e a versão. `/tasks` lista as tarefas atuais.”

No PowerShell, execute apenas consultas GET:

```powershell
curl.exe -i http://54.198.190.67/health
curl.exe -i http://54.198.190.67/version
curl.exe -i http://54.198.190.67/tasks
```

Resultados registrados: health `ok`; versão `cloud-tasks-api`, `1.1.0`. Mostre a rota `/tasks` como está, sem criar nem apagar tarefas durante a apresentação.

## 1:10–1:45 — 3. Funcionalidade e testes

“A API oferece criação, listagem, atualização e exclusão. O DELETE retorna 204 sem corpo ao remover uma tarefa e 404 JSON para um ID ausente. Esses dois resultados já foram verificados na instância. A suíte tem nove testes, incluindo o contrato de versão e a persistência do banco ao recriar a aplicação.”

Links: [CI do PR #1 aprovada](https://github.com/bingxyi/cloud-pipeline-aws/actions/runs/43886754600) · [CI da main para o snapshot atual](https://github.com/bingxyi/cloud-pipeline-aws/actions/runs/43889934062).

Não rode o DELETE ao vivo: os códigos 204 e 404 estão no resultado registrado em `docs/evidencia-ec2.json`.

## 1:45–2:20 — 4. Revisão e CI

“A funcionalidade foi desenvolvida em branch e integrada pelo PR #1; o merge commit é `fedf0295356db273686130be3bdf76c3c5d5d87e`. O PR #3 atualizou a documentação; o snapshot auditado atual é `57e2869681c5844205272fc67c3733817f5cd390`. A CI executa os nove testes e o build; no PR ela não publica imagem.”

Abra o [PR #1](https://github.com/bingxyi/cloud-pipeline-aws/pull/1), o [PR #3](https://github.com/bingxyi/cloud-pipeline-aws/pull/3), a [CI do PR #1](https://github.com/bingxyi/cloud-pipeline-aws/actions/runs/43886754600) e a [CI da main para o snapshot atual](https://github.com/bingxyi/cloud-pipeline-aws/actions/runs/43889934062). Mostre os SHAs correspondentes, sem editar configurações.

## 2:20–2:55 — 5. Imagem e contêiner

“A imagem é publicada no GHCR com tag vinculada ao SHA. A EC2 usa Ubuntu 24.04, tipo `t3.micro`, e Docker 29.1.3. O contêiner usa o volume nomeado `cloud-tasks-data` para manter o SQLite em `/data/tasks.db`.”

Imagem implantada: `ghcr.io/bingxyi/cloud-pipeline-aws:57e2869681c5844205272fc67c3733817f5cd390`.

## 2:55–3:35 — 6. CD e controles de rede

“Depois de CI aprovada, o CD implanta a mesma revisão na EC2 e valida a saúde. O ambiente `production` guarda os secrets e variables necessários sem colocá-los no repositório. O acesso SSH é restrito ao IP administrativo; a regra temporária para o runner foi revogada. HTTP na porta 80 permanece público para a demonstração.”

Abra a execução [CD aprovada](https://github.com/bingxyi/cloud-pipeline-aws/actions/runs/43890085299). Não abra nem copie secrets. Security Group: porta 22 de `189.6.11.151/32`; porta 80 de `0.0.0.0/0`.

## 3:35–4:10 — 7. Persistência comprovada

“Para provar persistência, registrei uma tarefa, recriei o contêiner pelo script de deploy com a mesma imagem e consultei a tarefa novamente. O ID 1 e o título `Evidencia persistencia 20261116-113828` permaneceram. Os IDs dos contêineres antes e depois são diferentes; o volume de dados foi mantido.”

Mostre [docs/evidencia-ec2.json](evidencia-ec2.json). Não execute deploy durante a demonstração.

## 4:10–4:30 — Custo e fechamento

“A medição estimada no Cost Explorer foi de US$ 0,0408888848 em 15 de novembro e US$ 0,047590091 em 16 de novembro, total de **US$ 0,0884789758 na conta**. Ela não atribui o total exclusivamente ao projeto e não é necessariamente a fatura final. A EC2 permanece ligada por solicitação para a apresentação; o momento da limpeza será decidido depois.”

Finalize com o estado real das evidências. Não marque limpeza como concluída antes de confirmar instância, volumes e IPs no console.
