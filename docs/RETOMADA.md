# Estado para retomada

Atualizado em 2026-11-16. Projeto: `meu-cloud-pipeline`. Repositório [bingxyi/cloud-pipeline-aws](https://github.com/bingxyi/cloud-pipeline-aws). Responsável: Rafael Bitu Castro de Abreu, RA22301190, trabalho individual.

## Estado confirmado

- Informar o plano antes de iniciar cada nova etapa; publicacao automatica autorizada.
- Nenhum commit pode conter Co-Authored-By (nem variacoes de grafia).
- Nao reutilizar credenciais/chaves expostas no historico; usar apenas configuracao local atual.
- O prazo original de 23:50 de 2026-11-15 ja passou; nao representa prazo novo.

- PR [#1](https://github.com/bingxyi/cloud-pipeline-aws/pull/1) mesclado no SHA `fedf0295356db273686130be3bdf76c3c5d5d87e`.
- [CI do PR](https://github.com/bingxyi/cloud-pipeline-aws/actions/runs/43886754600), [CI da main](https://github.com/bingxyi/cloud-pipeline-aws/actions/runs/43887501389) e [CD](https://github.com/bingxyi/cloud-pipeline-aws/actions/runs/43887665966) aprovados para a implementação.
- API em `http://54.198.190.67`: health `ok`; versão `cloud-tasks-api` 1.1.0; DELETE verificado com respostas 204 e 404.
- Persistência EC2 verificada ao recriar o contêiner via `scripts/deploy.sh` usando a mesma imagem e o volume. A tarefa ID 1 sobreviveu. Evidência: [evidencia-ec2.json](evidencia-ec2.json).
- AWS `109347287884`, `us-east-1`; EC2 `i-0c6f23086bc98c45e`, IP `54.198.190.67`, SG `sg-09352ffbaa35709b2`; Docker 29.1.3.
- Regras finais verificadas no SG: SSH 22 de `189.6.11.151/32`, HTTP 80 público. Regra SSH temporária do runner removida.
- Ambiente GitHub `production` e secrets/variables estão configurados. Não copiar valores secretos para arquivos ou mensagens.

## Trabalho restante

A EC2 está ligada para a demonstração. Inspecionar custos, concluir apresentação e então encerrar a instância e revisar volumes/IPs remanescentes. Registrar o resultado da limpeza. Ver [PROXIMOS_PASSOS.md](PROXIMOS_PASSOS.md) e [RELATORIO.md](RELATORIO.md).

Histórico: a primeira tentativa de SSH pelo Codex não teve acesso local à chave; a conexão posterior foi confirmada pelo usuário via SSH. Essa tentativa antiga não indica falha atual.
