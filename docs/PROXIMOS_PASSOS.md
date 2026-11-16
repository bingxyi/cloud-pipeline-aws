# Próximos passos

## Concluído

O código está em [bingxyi/cloud-pipeline-aws](https://github.com/bingxyi/cloud-pipeline-aws). [PR #1](https://github.com/bingxyi/cloud-pipeline-aws/pull/1) foi mesclado no commit `fedf0295356db273686130be3bdf76c3c5d5d87e`. CI do PR, CI da main e [CD](https://github.com/bingxyi/cloud-pipeline-aws/actions/runs/43887665966) passaram. O ambiente `production` e os secrets/variables necessários foram configurados.

A EC2 `i-0c6f23086bc98c45e` (`us-east-1`, `54.198.190.67`) serve a aplicação. `/health`, `/version` e DELETE foram verificados remotamente. Persistência foi comprovada antes/depois de recriar o contêiner com a mesma imagem e volume; veja [evidencia-ec2.json](evidencia-ec2.json). As regras temporárias de SSH do runner foram revogadas; SG final mantém SSH 22 restrito a `189.6.11.151/32` e HTTP 80 público.

## Ações restantes

1. Custos consultados e registrados: US$ 0,08848 estimados para a conta em 15–16/11, sem atribuicao exclusiva ao projeto. Fontes e limitacoes em [AUDITORIA_FINAL.md](AUDITORIA_FINAL.md).
2. Usar o [roteiro](APRESENTACAO.md), os [slides](apresentacao.html) e as evidencias em `evidencias/` na apresentacao. O pacote esta preparado; a apresentacao pelo responsavel ainda sera realizada.
3. Depois da demonstração, encerrar a EC2. Verificar no console se há volumes ou IPs remanescentes e documentar o resultado antes de marcar a limpeza como concluída.

A instancia permanece ligada por solicitacao expressa do responsavel. Nao declarar a limpeza concluida antes de executar e verificar o encerramento.
