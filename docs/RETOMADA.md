# Estado para retomada

Atualizado em 2026-11-16. Este arquivo resume a sessao; nao representa uma
compactacao tecnica do historico da interface.

## Orientacoes vigentes

- Informar o plano antes de iniciar cada nova etapa.
- Seguir master-prompt.md no diretorio pai, preservando trabalho ja feito.
- Usuario autorizou commits/push/PR automatizados, sem Co-Authored-By. No Codex gh api user retorna 401; usar publicador no PowerShell autenticado.
- Usuario autorizou acoes AWS; apresentar plano especifico antes de qualquer modificacao de recursos.
- A janela original terminou em 2026-11-15 as 23:50; nao representa um prazo novo.
- Nunca incluir chaves, tokens ou arquivos PEM em evidencias ou commits.
- Credenciais e chave privada foram expostas no chat. Nao reutilizar valores do
  historico. Substituir chave SSH autorizada antes de usa-la no deploy.

## Concluido e pendente

- Projeto ativo: meu-cloud-pipeline. Starter original permanece separado.
- Responsavel: Rafael Bitu Castro de Abreu, RA22301190 (projeto individual). Repositorio: https://github.com/bingxyi/cloud-pipeline-aws; usuario confirma que o codigo ainda nao foi enviado.
- DELETE retorna 204/404, GET `/version` retorna 1.1.0; nove testes locais passaram.
- Validacao mais recente no host: pytest 9 passed em 0.73s; build da imagem Ubuntu/Python 3.12; smoke test de health/version/DELETE; persistencia comprovada apos recriar contêiner.
- Containers e rede do harness foram removidos. Volume `cloud-tasks-smoke-535_cloud-tasks-data` mantido para inspecao; preservar e nao remover em limpeza automatica.
- AWS: o inventario inicial somente leitura encontrou apenas o security group default. Depois, o host criou EC2 `i-0c6f23086bc98c45e`, IP `54.198.190.67`, SG `sg-09352ffbaa35709b2` em us-east-1.
- `scripts/provision-aws.ps1` passou parser PowerShell e validacao offline AWS CLI; testes mockados de rede nao fizeram chamadas AWS. A consulta `-Status` no host confirmou instancia/tag e gerou `known_hosts` com chave publica obtida via console AWS autenticado. Usuario confirmou via SSH: cloud-init status done e Docker cliente/servidor 29.1.3 acessivel como ubuntu. App ainda nao implantada.
- Validacao local nao cobre EC2: deploy e persistencia em instancia remota seguem pendentes. CI, GHCR e CD remotos tambem pendentes.
- O interpretador local fica em `../.tools/python/cpython-3.12.13-windows-x86_64-none/python.exe`; venv `.venv` esta no projeto. Reproduzir com `.venv/Scripts/python.exe -m pytest -q` apos instalar `requirements-dev.txt`; `.venv` e ignorado pelo Git.
- Codigo ainda nao enviado pelo usuario. Nenhuma CI remota, publicacao GHCR ou deploy foi verificado.
- Nao afirmar branch local ou remoto sem verificar o historico atual. A publicacao automatizada foi autorizada, preservando branch feature e PR.
- Nao copiar credenciais para o repositorio. Nao reutilizar chaves ou valores secretos do historico.

## Proximo passo concreto

Verificacao SSH abaixo concluida pelo usuario: cloud-init done e Docker cliente/servidor 29.1.3 acessivel como ubuntu. Proximo passo e a publicacao automatizada ao GitHub conforme PROXIMOS_PASSOS.md, com base na main e implementacao em feature/PR. Comando SSH usado:

```powershell
$s = Get-Content (Join-Path $env:USERPROFILE '.cloud-pipeline\cloud-pipeline-starter-state.json') -Raw | ConvertFrom-Json
ssh.exe -i $s.KeyPath -o "UserKnownHostsFile=$($s.KnownHostsPath)" -o StrictHostKeyChecking=yes -o IdentitiesOnly=yes -o BatchMode=yes -o ConnectTimeout=10 "ubuntu@$($s.PublicIp)" "cloud-init status; docker version"
```

Nao repetir o provisionamento: a EC2 ja existe. A tentativa SSH feita no ambiente Codex falhou por permissao local sobre o arquivo da chave e nao comprova falha da chave nem da instancia.

Para a publicacao automatizada ao GitHub, branch feature, PR e CI, seguir [PROXIMOS_PASSOS.md](PROXIMOS_PASSOS.md).

Historico de proximo passo proposto (nao executado):

No PowerShell do usuario, dentro de meu-cloud-pipeline:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\inspect-aws.ps1
```

Esse procedimento foi uma proposta historica. A autorizacao AWS atual cobre as acoes necessarias ao projeto, respeitando o plano e o escopo informado pelo usuario.
