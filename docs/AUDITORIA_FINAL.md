# Auditoria dos sete criterios

Coleta em 16/11/2026. Os arquivos JSON sao respostas selecionadas das APIs e do
runtime, sem credenciais. Eles representam o instante da coleta; novos commits
de documentacao podem gerar novas imagens e novos runs. Nao sao prints simulados.

| Criterio | Resultado e evidencia |
|---|---|
| 1. Git, branches, PR e organizacao | PR #1 de `feature/delete-endpoint` revisado e mesclado; comentarios, SHA e estado em [github.json](evidencias/github.json). PRs posteriores preservam as evidencias e a organizacao. |
| 2. Testes e CI nos PRs | Nove testes aprovados em [testes.txt](evidencias/testes.txt). Run de PR em [github.json](evidencias/github.json): build aprovado; login GHCR e publicacao explicitamente `skipped`. O CD exige evento `push` de CI aprovada na main. |
| 3. Docker e GHCR versionado | Imagem por SHA coincide com o SHA dos runs CI/CD auditados. Manifest publico obtido sem credenciais em [ghcr-manifest.json](evidencias/ghcr-manifest.json); imagem implantada em [container.json](evidencias/container.json). |
| 4. EC2, rede e seguranca | Ubuntu 24.04, t3.micro, disco gp3 de 8 GiB criptografado e IMDSv2 requerido; HTTP 80 publico e SSH 22 administrativo /32 em [aws.json](evidencias/aws.json). Processo `appuser` sem root e volume montado em [container.json](evidencias/container.json). |
| 5. CD e saude | SHA de CI e CD coincide com a imagem em execucao. Etapas de HTTP e remocao da regra SSH do runner aprovadas em [github.json](evidencias/github.json). HTTP 200 e status ok em [http.json](evidencias/http.json). |
| 6. Evolucao funcional | DELETE 204 sem corpo e 404 JSON, GET /version 1.1.0 e respectivos testes em [test_api.py](../tests/test_api.py). Persistencia apos recriar o container comprovada em [evidencia-ec2.json](evidencia-ec2.json); tarefa ID 1 tambem presente na nova coleta HTTP. |
| 7. Documentacao e apresentacao | README, [relatorio](RELATORIO.md), diagrama, custos, fontes de evidencia, [roteiro cronometrado](APRESENTACAO.md) e [slides](apresentacao.html). Apresentacao preparada para ate cinco minutos. |

## Custos e recursos

[aws.json](evidencias/aws.json) registra consulta ao Cost Explorer: US$ 0,0408888848
em 15/11 e US$ 0,047590091 em 16/11, total US$ 0,0884789758 estimados. Valores
`UnblendedCost` da conta inteira, com `Estimated=true`, sujeitos a atraso de
consolidacao. Nao representam custo final nem atribuicao exclusiva ao projeto.

Recursos observados: uma EC2 t3.micro, volume EBS gp3 de 8 GiB, SG dedicado e
IPv4 publico automatico; nenhum Elastic IP alocado foi retornado pela consulta.
O volume esta configurado com DeleteOnTermination=true. O banco persistente
sobrevive a recriacao do container, mas nao ao encerramento com exclusao do disco.

## Encerramento apos a apresentacao

Por instrucao expressa do responsavel, a API permanece online para apresentacao.
Encerramento nao foi executado e nao e declarado concluido. Apos apresentar:

1. Guardar evidencias e exportar o banco se precisar dos dados.
2. Confirmar conta, regiao e ID `i-0c6f23086bc98c45e` antes de encerrar essa EC2.
3. Aguardar `terminated` e confirmar a exclusao do volume `vol-0c55e3de57a1447b7`.
4. Conferir IPs, discos, SG e par de chaves exclusivos do projeto; remover apenas
   o que nao estiver em uso. Nao remover VPC, sub-redes ou SG default do laboratorio.
5. Registrar estado terminal e inventario remanescente; atualizar custos quando
   consolidados. Parar a instancia, por si so, nao comprova eliminacao de custos.

## Entrega

Usar os links da matriz, abrir os slides e seguir o roteiro. O envio ao Moodle
e a apresentacao pelo responsavel sao atos externos a implantacao. Se o docente
preferir prints, capturar as paginas dos runs e a API reais listadas no roteiro,
sem mostrar abas de secrets, chaves, tokens ou arquivos privados.
