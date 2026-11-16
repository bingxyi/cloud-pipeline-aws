# Configuração e reprodução do ambiente

## Dependências e organização

A API utiliza Python 3.12, Flask, Gunicorn e SQLite. Os intervalos de versões
estão em `requirements.txt` e `requirements-dev.txt`; não há lockfile. A reprodução
resolve dependências dentro desses intervalos e pode obter versões diferentes
em datas distintas. O Dockerfile utiliza a tag `python:3.12-slim`, sem fixar o
digest da imagem base.

O README apresenta os comandos de instalação e teste local. Docker Compose
expõe `8080:8000` e monta um volume em `/data`. Para encerrar os contêineres locais
preservando os dados, utiliza-se `docker compose down`, sem a opção `--volumes`.

## Provisionamento da infraestrutura

`scripts/provision-aws.ps1` configura Ubuntu 24.04 x86_64 em EC2 `t3.micro`,
região `us-east-1`. Utiliza VPC/sub-rede padrão, IP público, Security Group
dedicado, disco gp3 criptografado e IMDSv2 obrigatório. O bootstrap instala
Docker e habilita seu serviço.

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\provision-aws.ps1 -Status
```

`-Status` consulta a instância registrada. Sem essa opção, a ausência de estado
permite criar recursos; por isso, o arquivo de estado deve ser preservado.
Os parâmetros disponíveis são `-Profile`, `-AdminCidr`, `-StatePath` e `-Status`.
O perfil padrão é `default`, e o script valida a conta antes de operar.

O estado fica em `%USERPROFILE%\.cloud-pipeline\cloud-pipeline-starter-state.json`.
A chave privada permanece fora do repositório. A origem SSH administrativa é
um IPv4 `/32`; quando omitida, é detectada pelo provisionador. Alterações de rede
exigem conferir essa origem. `-AdminCidr` participa da criação; não atualiza
automaticamente um Security Group já existente.

O arquivo known_hosts utiliza a chave pública obtida pelo console AWS
autenticado. Ao mudar o IP da instância, o modo de consulta pode preservar a
chave já validada e atualizar sua associação ao IP. Uma chave desconhecida não
é aceita silenciosamente. Uma falha parcial exige inspecionar os recursos e o
estado antes de repetir o provisionamento.

## Parâmetros do pipeline

| Nome | Tipo no GitHub | Uso |
|---|---|---|
| EC2_HOST | Secret | IP ou DNS do host, sem protocolo |
| EC2_SSH_KEY | Secret | Chave privada autorizada na instância |
| EC2_KNOWN_HOSTS | Secret | Entrada de host previamente autenticada |
| AWS_ACCESS_KEY_ID | Secret | Identificador de credencial temporária AWS |
| AWS_SECRET_ACCESS_KEY | Secret | Chave de acesso AWS |
| AWS_SESSION_TOKEN | Secret | Token da sessão temporária |
| EC2_USER | Variable | Usuário remoto, `ubuntu` |
| EC2_SECURITY_GROUP_ID | Variable | Grupo utilizado no acesso temporário do runner |

O CD referencia o environment `production`. As credenciais AWS Academy expiram;
a configuração deve ser renovada quando necessário. Valores secretos não são
armazenados no código, nos registros experimentais ou na documentação.

## Publicação e implantação

A CI é disparada em PRs direcionados à main e em pushes nessa branch. O job de
imagem depende do job de testes. A publicação é habilitada somente no push.
O pacote GHCR deve ser público para o pull anônimo utilizado pela EC2.

O CD depende do sucesso da CI originada por push. O checkout e a tag usam o SHA
do evento de CI. `scripts/deploy.sh` cria o volume, obtém a imagem, substitui o
contêiner e consulta `/health` até o limite de tentativas. Uma segunda consulta
HTTP é realizada pelo runner.

O script `runner-ssh-access.sh` autoriza a porta 22 somente para o IP `/32` do
runner. Registra o ID da regra criada e tenta revogá-la ao término do job. Uma
regra preexistente para essa origem não é removida por essa execução. Para
interpretação dos resultados e limites, consultar [VALIDACAO.md](VALIDACAO.md).
