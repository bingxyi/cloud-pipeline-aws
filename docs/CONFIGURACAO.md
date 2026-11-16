# Guia de configuração do laboratório (AWS Ubuntu + GitHub Actions)

## 1. Repositório
1. Use o repositório [bingxyi/cloud-pipeline-aws](https://github.com/bingxyi/cloud-pipeline-aws); o usuário fará o upload manual, separando a base em `main` da implementação em `feature/delete-endpoint` e PR.
2. Ative Actions e mantenha `main` protegida quando o plano da conta permitir.
3. Crie branch `feature/...`, envie PR e só integre após CI passar.

## 2. AWS EC2

O provisionador cria Ubuntu Server 24.04 LTS x86_64 `t3.micro` em `us-east-1`, security group dedicado (HTTP TCP/80 público; SSH TCP/22 restrito a um IPv4 `/32`), chave SSH RSA 4096 protegida sob `%USERPROFILE%\.ssh\cloud-pipeline\...`, Docker via user-data e estado fora do repositório em `%USERPROFILE%\.cloud-pipeline\cloud-pipeline-starter-state.json`. Ele exige que o perfil autenticado corresponda à conta AWS esperada; se a checagem falhar, interrompe sem criar recursos.

Antes de executar, confirme perfil e IP administrativo. Sem `-AdminCidr`, o script detecta o IP público atual e usa `/32`; se a rede mudar, informe `-AdminCidr IPv4/32`. O parâmetro `-StatePath` permite escolher outro arquivo de estado, que também deve ficar fora do repositório e ser preservado. Não há estimativa de custo neste guia; consulte preços, créditos e limites da conta antes de lançar.

Na pasta do projeto, no PowerShell:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\provision-aws.ps1
```

O perfil padrão é `default`; também aceita `-Profile nome`. Se o estado já existir, repetir a mesma invocação consulta a instância registrada em vez de criar outra. Use `-Status` explicitamente para consultar progresso e obter `known_hosts` quando o bootstrap publicar sua chave pelo console AWS. O conhecido do host é derivado da chave pública observada no console autenticado; não use `ssh-keyscan` como raiz de confiança.

Se o provisionamento falhar depois de criar recursos e o estado ficar sem `InstanceId`, o script recusa uma nova criação. Preserve o estado e os IDs parciais e faça recuperação manual antes de tentar de novo; ele não remove recursos automaticamente em falha parcial. A aplicação ainda não fica implantada pelo provisionador: aguarde a inicialização Docker, valide SSH/HTTP e siga os passos de deploy.

O script ainda não foi executado; nenhuma EC2 foi criada. Para detalhes sobre regras e fontes de Security Group, consulte [AWS Security group rules](https://docs.aws.amazon.com/vpc/latest/userguide/security-group-rules.html). Para seleção e validação de imagens oficiais Ubuntu, consulte [Find Ubuntu images on AWS](https://ubuntu.com/aws/docs/aws-how-to/instances/find-ubuntu-images/).

## 3. GitHub
Em Settings > Secrets and variables > Actions configure:
- Secret `EC2_HOST`: IPv4 público ou DNS público da EC2, sem protocolo.
- Secret `EC2_SSH_KEY`: conteúdo integral da **chave privada SSH** autorizada na instância; nunca versionar.
- Secret `EC2_KNOWN_HOSTS`: conteúdo do arquivo conhecido gerado pelo provisionador após obter a chave pública via console AWS autenticado. Use `-Status` após o bootstrap; não confiar cegamente em `ssh-keyscan`.
- Variable `EC2_USER`: `ubuntu` para a AMI Ubuntu sugerida.
- Variable `EC2_SECURITY_GROUP_ID`: grupo dedicado da instância; quando definida, ativa regra SSH temporária para o runner do GitHub.
- Secrets `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY` e `AWS_SESSION_TOKEN`: credenciais temporárias do laboratório usadas somente para abrir e revogar o acesso de runner. Renovar manualmente quando expirarem; nunca registrar seus valores.
Crie environment `production` para aprovações (se disponível).

## 4. Registry GHCR
A CI publica imagem `ghcr.io/OWNER/REPO:COMMIT_SHA` após `push` na main. Para simplificar o laboratório, nas configurações do pacote GitHub mude a visibilidade da imagem para **Public**, de modo que EC2 execute `docker pull` sem credenciais persistentes. Não publique dados sensíveis na imagem.

## 5. Validação
- Crie PR: apenas testes/build; sem publicação ou deploy.
- Merge para `main`: CI publica imagem; evento `workflow_run` inicia CD.
- Acesse `http://IP_PUBLICO/health`, `http://IP_PUBLICO/tasks`.
- Faça nova mudança pela branch e PR e comprove novo deploy automático.
- Faça screenshot dos runs e registre URL/commit no relatório.

## 6. Diagnóstico
- Actions falhou em `docker push`: verifique `packages: write`, permissões de Actions e configuração GHCR.
- `docker pull` falhou na EC2: confira se pacote está público e se tag SHA existe.
- Falha SSH: reveja Security Group, conectividade do runner, chave, usuário e known_hosts. Após cada job, confirme que a regra temporária foi removida; cancelamento forçado ou credenciais expiradas podem deixar regra residual.
- Falha HTTP: verifique SG porta 80, endereço, `docker ps` e `docker logs cloud-tasks-api`.
- **Atenção:** runner público do GitHub não possui IP fixo. O workflow abre SSH temporário restrito ao IP /32 do runner e tenta revogar a regra exata no encerramento. Não abra SSH para `0.0.0.0/0`; verifique manualmente o grupo após cada execução. Uma alternativa é runner auto-hospedado em rede permitida ou SSM, conforme orientação docente.

## 7. Custos e encerramento
Custos estimados da conta e inventario do projeto registrados em [AUDITORIA_FINAL.md](AUDITORIA_FINAL.md), com data, escopo e limitacoes. Desligar nem sempre elimina custo de EBS e IP; após a apresentação, exclua instância, volumes e recursos alocados conforme orientação docente. Preserve a chave e o arquivo de estado até terminar de conferir os recursos criados; mantenha ambos fora do repositório.
