param(
    [string]$Profile = 'default',
    [switch]$IncludeNetwork,
    [string]$VpcId = 'vpc-0cc72263e870653f0'
)
$ErrorActionPreference = 'Stop'
$region = 'us-east-1'
$awsCommand = Get-Command aws.exe -ErrorAction SilentlyContinue
if ($awsCommand) {
    $awsExecutable = $awsCommand.Source
} else {
    $candidates = @(
        'C:\Program Files\Amazon\AWSCLIV2\aws.exe',
        (Join-Path $env:LOCALAPPDATA 'Programs\Amazon\AWSCLIV2\aws.exe')
    )
    $awsExecutable = $candidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
}
if (-not $awsExecutable) { throw 'AWS CLI nao localizado.' }

function Read-AwsJson {
    param([string[]]$CommandArgs)
    $result = & $awsExecutable @CommandArgs --profile $Profile --region $region --output json --no-cli-pager --cli-connect-timeout 5 --cli-read-timeout 15
    if ($LASTEXITCODE -ne 0) { throw 'Consulta AWS falhou. Nenhum recurso foi alterado.' }
    return (($result -join "`n") | ConvertFrom-Json)
}

# Only read operations. Do not read, print or copy credential files.
$identity = Read-AwsJson -CommandArgs @('sts', 'get-caller-identity')
if ($identity.Account -ne '109347287884') {
    throw 'Conta diferente da configurada para o projeto; inventario interrompido.'
}
$instances = Read-AwsJson -CommandArgs @(
    'ec2', 'describe-instances',
    '--filters', 'Name=instance-state-name,Values=pending,running,stopping,stopped',
    '--query', 'Reservations[].Instances[].{Id:InstanceId,State:State.Name,Type:InstanceType,Image:ImageId,PublicIp:PublicIpAddress,KeyName:KeyName,Groups:SecurityGroups[].GroupId}'
)
$groups = Read-AwsJson -CommandArgs @(
    'ec2', 'describe-security-groups',
    '--query', 'SecurityGroups[].{Id:GroupId,Name:GroupName,Vpc:VpcId,Ingress:IpPermissions}'
)
$report = [ordered]@{
    CapturedAt = (Get-Date).ToUniversalTime().ToString('o')
    Account = $identity.Account
    Region = $region
    Instances = @($instances)
    SecurityGroups = @($groups)
}
if ($IncludeNetwork) {
    if ($VpcId -notmatch '^vpc-[0-9a-f]+$') { throw 'VpcId invalido.' }
    $vpcs = Read-AwsJson -CommandArgs @(
        'ec2', 'describe-vpcs', '--vpc-ids', $VpcId,
        '--query', 'Vpcs[].{Id:VpcId,State:State,Default:IsDefault,Cidr:CidrBlock}'
    )
    $subnets = Read-AwsJson -CommandArgs @(
        'ec2', 'describe-subnets', '--filters', "Name=vpc-id,Values=$VpcId",
        '--query', 'Subnets[].{Id:SubnetId,AZ:AvailabilityZone,State:State,FreeIps:AvailableIpAddressCount,AutoPublicIp:MapPublicIpOnLaunch}'
    )
    $routes = Read-AwsJson -CommandArgs @(
        'ec2', 'describe-route-tables', '--filters', "Name=vpc-id,Values=$VpcId",
        '--query', 'RouteTables[].{Id:RouteTableId,Associations:Associations,Routes:Routes}'
    )
    $gateways = Read-AwsJson -CommandArgs @(
        'ec2', 'describe-internet-gateways', '--filters', "Name=attachment.vpc-id,Values=$VpcId",
        '--query', 'InternetGateways[].{Id:InternetGatewayId,Attachments:Attachments}'
    )
    # Official Canonical publisher, standard Ubuntu 24.04 x86_64 (not Pro).
    $images = Read-AwsJson -CommandArgs @(
        'ec2', 'describe-images', '--owners', '099720109477', '--filters',
        'Name=name,Values=ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*',
        'Name=state,Values=available', 'Name=architecture,Values=x86_64',
        'Name=virtualization-type,Values=hvm',
        '--query', 'sort_by(Images,&CreationDate)[-1:].{Id:ImageId,Name:Name,Owner:OwnerId,Created:CreationDate,RootDevice:RootDeviceName}'
    )
    $offerings = Read-AwsJson -CommandArgs @(
        'ec2', 'describe-instance-type-offerings', '--location-type', 'availability-zone',
        '--filters', 'Name=instance-type,Values=t2.micro,t3.micro',
        '--query', 'InstanceTypeOfferings[].{Type:InstanceType,AZ:Location}'
    )
    $report.Network = [ordered]@{
        Vpcs = @($vpcs)
        Subnets = @($subnets)
        RouteTables = @($routes)
        InternetGateways = @($gateways)
    }
    $report.Ubuntu2404Candidates = @($images)
    $report.InstanceTypeOfferings = @($offerings)
    $report.Note = 'Oferta regional nao comprova permissao do Lab nem capacidade no momento do lancamento. Nenhum recurso criado.'
}
$report | ConvertTo-Json -Depth 12
