# Operação, observabilidade básica e ciclo de vida

## Identificação da revisão em execução

A versão semântica em `/version` identifica o contrato da API, mas não muda a
cada commit. A revisão implantada deve ser obtida pela imagem do contêiner:

```bash
docker inspect --format '{{.Config.Image}}' cloud-tasks-api
docker logs --tail 100 cloud-tasks-api
```

A tag esperada é `ghcr.io/bingxyi/cloud-pipeline-aws:<SHA>`. Sua comparação com o
workflow de CD permite verificar a correspondência entre revisão e execução.
Os registros coletados anteriormente encontram-se em [VALIDACAO.md](VALIDACAO.md).

## Diagnóstico

| Sintoma | Verificação inicial |
|---|---|
| Imagem indisponível | Confirmar SHA, publicação no GHCR e acesso público ao pacote |
| Falha de SSH | Conferir IP atual, origem /32, usuário, chave e known_hosts |
| Credencial AWS expirada | Renovar os secrets temporários usados para acesso de runner |
| HTTP sem resposta | Conferir processo, porta 80, encaminhamento Docker e Security Group |
| Health 503 | Inspecionar erro SQLite e permissões do diretório do banco |
| Regra SSH residual | Identificar a regra temporária e sua execução antes da revogação |

Logs podem conter detalhes do ambiente; sua publicação exige revisão prévia.
`/health` representa uma sondagem simples de aplicação/banco, não monitoramento
contínuo ou medição de disponibilidade.

## Persistência e recuperação

O banco `/data/tasks.db` reside no volume remoto `cloud-tasks-data`. A troca do
contêiner conserva o volume; sua exclusão remove a persistência. O volume reside
no EBS do host, de modo que o encerramento da instância com exclusão do disco
elimina também os dados.

Não há rotina de backup ou restauração automatizada. Uma política de recuperação
exigiria definir retenção, consistência do backup, armazenamento externo e teste
de restauração. A conservação observada após recriação não comprova recuperação
após perda do host.

## Custos e inventário

A coleta de 16/11/2026 registrou uma EC2 t3.micro, EBS gp3 criptografado de 8 GiB
e Security Group dedicado. Não foram retornados Elastic IPs alocados na conta.
O IP público automático pode mudar após parada e reinicialização.

O Cost Explorer retornou US$ 0,0408888848 em 15/11 e US$ 0,047590091 em 16/11,
totalizando US$ 0,0884789758 estimados. São valores UnblendedCost da conta inteira,
sujeitos a atraso de consolidação, sem atribuição exclusiva ao projeto. A fonte
está em [aws.json](evidencias/aws.json); não se infere custo mensal a partir dessa
amostra parcial.

## Desativação controlada

O ambiente permanece ativo para observação do serviço. A desativação requer
preservar os dados necessários, confirmar conta/região e identificar os recursos
exclusivos da aplicação. O disco observado está configurado com
`DeleteOnTermination=true`; parar a instância não equivale a excluir o disco.

Após o encerramento, é necessário confirmar o estado terminal da instância e
inspecionar discos, endereços, regras e pares de chaves remanescentes. A VPC,
as sub-redes e o Security Group padrão podem ser compartilhados e não devem ser
tratados como recursos exclusivos da aplicação. O encerramento e a atualização
dos custos precisam ser registrados apenas depois de efetivamente verificados.
