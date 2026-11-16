# Protocolo de validação e rastreabilidade experimental

## Objetivo

O protocolo examina a consistência entre contrato HTTP, integração de código,
imagem publicada e ambiente remoto. Os arquivos em `evidencias/` representam
coletas de 16/11/2026; `evidencia-ec2.json` registra o experimento anterior de
recriação. As coletas têm escopos distintos, identificados por horário, revisão
e ID de contêiner.

## Propriedades e procedimentos

| Propriedade | Procedimento e condição esperada | Registro |
|---|---|---|
| Contrato funcional | Executar pytest com bancos temporários | [testes.txt](evidencias/testes.txt) |
| Separação entre revisão e publicação | No PR, login GHCR e publicação devem estar skipped | [github.json](evidencias/github.json) |
| Publicação após integração | Inspecionar CI de push na main e sua etapa de publicação | [github.json](evidencias/github.json) |
| Rastreabilidade | Comparar SHA da CI/CD com a tag em execução | [container.json](evidencias/container.json) |
| Acesso à imagem | Consultar manifest com configuração Docker vazia | [ghcr-manifest.json](evidencias/ghcr-manifest.json) |
| Estado HTTP | Consultar health, version e tasks | [http.json](evidencias/http.json) |
| Persistência | Comparar IDs de contêiner e o mesmo registro antes/depois | [evidencia-ec2.json](evidencia-ec2.json) |
| Infraestrutura | Consultar instância, disco, IMDSv2 e regras de entrada | [aws.json](evidencias/aws.json) |
| Rede | Inspecionar sub-rede, rotas e Internet Gateway | [rede.json](evidencias/rede.json) |

O experimento remoto de DELETE registrou 204 e, na repetição, 404. O teste de
persistência conservou a tarefa ID 1 enquanto o identificador do contêiner
mudou. A preservação foi observada no volume local, não em recuperação de host.

## Referências de execução

- [PR da evolução funcional](https://github.com/bingxyi/cloud-pipeline-aws/pull/1).
- [CI do PR](https://github.com/bingxyi/cloud-pipeline-aws/actions/runs/43886754600).
- [CI da revisão de referência](https://github.com/bingxyi/cloud-pipeline-aws/actions/runs/43889934062).
- [CD da revisão de referência](https://github.com/bingxyi/cloud-pipeline-aws/actions/runs/43890085299).

A revisão de referência da segunda coleta é
`57e2869681c5844205272fc67c3733817f5cd390`. Novas execuções devem ser consultadas
na aba [Actions](https://github.com/bingxyi/cloud-pipeline-aws/actions), sem
reinterpretar os registros antigos como estado atual.

## Limites de interpretação

Os registros são respostas selecionadas das APIs, sem valores secretos. Não
constituem coleta contínua, benchmark ou auditoria de segurança abrangente. O
Cost Explorer em `aws.json` descreve custos estimados da conta, não exclusivamente
da aplicação.

Os casos funcionais estão em [test_api.py](../tests/test_api.py). Os testes de
[test_runner_ssh_access.sh](../tests/test_runner_ssh_access.sh) simulam a AWS CLI
e a consulta de IP. Eles avaliam a lógica do script, enquanto os runs de CD e o
inventário do Security Group fornecem a observação do ambiente real.
