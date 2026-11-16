# Próximos passos

## Publicacao automatizada no GitHub

O usuario autorizou commits e publicacao automatizados em [bingxyi/cloud-pipeline-aws](https://github.com/bingxyi/cloud-pipeline-aws), sem trailers Co-Authored-By. Essa autorizacao substitui a orientacao anterior de upload manual. O Codex preparou a base em main e a implementacao em feature/delete-endpoint; a publicacao depende do login gh no ambiente que executar o script.

No PowerShell autenticado, dentro de meu-cloud-pipeline:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\publish-github.ps1
```

O script exige arvore limpa e branches compativeis, publica sem force push, abre
ou reutiliza PR, aguarda a CI e registra a revisao propria apos aprovacao.
Nao faz merge: configurar secrets, GHCR e CD antes dessa etapa. O push inicial
na main pode iniciar o pipeline da base, cujo CD pode falhar enquanto os secrets
e a visibilidade GHCR nao estiverem configurados. A CI do PR nao faz deploy.

Fluxo que a automacao preserva:

1. Envie somente os arquivos da base em `../cloud-pipeline-starter/cloud-pipeline-starter` para `main` como commit inicial, sem misturar a implementação.
2. Crie `feature/delete-endpoint` a partir de `main` e envie os arquivos finais atuais de `meu-cloud-pipeline` como commit separado.
3. Abra um PR da feature para `main`. Aguarde e revise a CI de PR, que deve executar testes e build sem publicar imagem ou iniciar deploy.
4. Antes do merge, configure secrets, variables, environment `production` e acesso de rede conforme [CONFIGURACAO.md](CONFIGURACAO.md). Sem isso, não espere que o CD inicial passe.
5. Após revisão e CI aprovadas, faça o merge. Confira a publicação GHCR por SHA; torne o pacote Public conforme o guia e reexecute o CD se o primeiro deploy falhar por visibilidade ou configuração.
6. Registre os links e resultados reais de PR, CI, publicação e deploy. Não marque etapas como aprovadas antes de confirmar no GitHub.

Nao envie `.venv`, caches, arquivos de estado AWS, chaves privadas nem logs brutos (incluindo `logps1script.txt`). O .gitignore deve permanecer aplicado. Criar commits e publicar alteracoes esta autorizado pelo usuario para este repositorio; nao adicionar Co-Authored-By.

## AWS

Inventário inicial somente leitura não encontrou instâncias. Depois, o host criou EC2 Ubuntu 24.04 `t3.micro`: `i-0c6f23086bc98c45e`, IP `54.198.190.67`, SG `sg-09352ffbaa35709b2`. O comando `-Status` confirmou instância/tag e gerou `known_hosts` a partir da chave pública obtida pelo console AWS autenticado. A chave privada e o estado ficam fora do repositório. Não execute novamente o provisionador.

Validacao SSH concluida pelo usuario: `cloud-init status` retornou `done`; Docker cliente e servidor 29.1.3, linux/amd64, acessiveis como `ubuntu`. O IP atual e `54.198.190.67`. A chave de host anteriormente autenticada foi preservada ao atualizar o IP. A aplicacao ainda nao foi implantada. Comando usado para essa validacao:

```powershell
$s = Get-Content (Join-Path $env:USERPROFILE '.cloud-pipeline\cloud-pipeline-starter-state.json') -Raw | ConvertFrom-Json
ssh.exe -i $s.KeyPath -o "UserKnownHostsFile=$($s.KnownHostsPath)" -o StrictHostKeyChecking=yes -o IdentitiesOnly=yes -o BatchMode=yes -o ConnectTimeout=10 "ubuntu@$($s.PublicIp)" "cloud-init status; docker version"
```

Depois do upload e da verificação da instância, configure no GitHub `EC2_HOST`, `EC2_SSH_KEY` e `EC2_KNOWN_HOSTS` como secrets; `EC2_USER=ubuntu` e `EC2_SECURITY_GROUP_ID` como variables. Para acesso temporário do runner, configure também `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY` e `AWS_SESSION_TOKEN` como secrets do laboratório e renove manualmente ao expirar. Confira a revogação da regra SSH temporária após cada run. O código ainda não foi enviado; CI, GHCR, deploy e persistência em EC2 seguem pendentes.

Para detalhes oficiais, consulte [regras de Security Group da AWS](https://docs.aws.amazon.com/vpc/latest/userguide/security-group-rules.html) e [localização de imagens Ubuntu na AWS](https://ubuntu.com/aws/docs/aws-how-to/instances/find-ubuntu-images/).

O harness local passou, incluindo build, smoke test e persistência após recriar o contêiner. Isso não comprova deploy nem persistência em EC2. O volume `cloud-tasks-smoke-535_cloud-tasks-data` foi mantido para inspeção; preserve-o durante qualquer limpeza.
