# Verificacao da rede antes de prosseguir na EC2

## Estado a reconciliar

O inventario compartilhado no chat nao tinha instancias. Os arquivos locais
RETOMADA.md e PROXIMOS_PASSOS.md agora registram uma EC2 criada posteriormente:
`i-0c6f23086bc98c45e`, com SG `sg-09352ffbaa35709b2`.
Esses registros ainda precisam ser confrontados com consulta atual. Nao repetir
o provisionamento nem criar outra EC2 antes dessa verificacao.

## Consulta somente leitura

Executar no PowerShell do usuario, dentro de meu-cloud-pipeline:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\inspect-aws.ps1 -IncludeNetwork
```

O script confirma conta e regiao, consulta instancias e regras de entrada,
sub-redes, tabelas de rotas, Internet Gateway, AMI Ubuntu e oferta de tipos
t2.micro/t3.micro por AZ. Nao le arquivos privados nem altera recursos.
Disponibilidade de tipo na regiao nao comprova permissao do AWS Academy.
O script usa somente STS GetCallerIdentity e operacoes EC2 Describe.

## Decisoes apos receber o resultado

1. Se a EC2 registrada existir, reutiliza-la. Verificar que sua AMI e Ubuntu
   24.04 x86_64 e validar bootstrap/Docker com o procedimento SSH ja documentado.
2. Confirmar a rota efetiva da sub-rede: associacao explicita tem precedencia;
   sem ela, usar tabela principal da VPC. Para acesso publico, exigir rota ativa
   0.0.0.0/0 para Internet Gateway anexado e IPv4 publico na instancia.
3. Verificar SG: TCP 80 para demonstracao HTTP; TCP 22 somente do IP administrativo
   /32 e, durante CD, do IP do runner /32. Nunca abrir SSH globalmente.
4. Se a instancia nao existir, apresentar um plano de criacao com IDs reais,
   AMI oficial, t3.micro se permitido, disco gp3 minimo adequado, exclusao do
   disco no encerramento e chave nova fora do repositorio. Informar o plano
   antes de executar criacao. Nao recriar automaticamente com base em estado antigo.
5. O workflow CD local ja preve regra SSH temporaria por runner e revogacao
   ao final. Antes do merge, verificar permissao do Lab para autorizar/revogar
   regras e configurar secrets temporarios no GitHub pelo usuario.

## Referencias

- [Localizar imagens Ubuntu oficiais](https://ubuntu.com/aws/docs/aws-how-to/instances/find-ubuntu-images/)
- [Consultar oferta de tipos EC2](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/instance-discovery.html)

Nenhuma execucao na AWS ou teste de conectividade e alegado por este documento.
