param(
    [string]$Profile = 'default',
    [string]$AdminCidr,
    [string]$StatePath,
    [switch]$Status
)

$ErrorActionPreference = 'Stop'
$region = 'us-east-1'
$account = '109347287884'
$aws = 'C:\Program Files\Amazon\AWSCLIV2\aws.exe'
if (-not (Test-Path -LiteralPath $aws)) {
    $command = Get-Command aws.exe -ErrorAction SilentlyContinue
    if (-not $command) { throw 'AWS CLI nao localizado.' }
    $aws = $command.Source
}
function Invoke-Aws([string[]]$Arguments) {
    $originalAwsEncoding = $env:AWS_CLI_OUTPUT_ENCODING
    $originalConsoleEncoding = [Console]::OutputEncoding
    try {
        $env:AWS_CLI_OUTPUT_ENCODING = 'utf-8'
        [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false)
        $output = & $aws @Arguments --profile $Profile --region $region --output json --no-cli-pager --cli-connect-timeout 5 --cli-read-timeout 30
        if ($LASTEXITCODE -ne 0) { throw "AWS CLI falhou: $($Arguments[0]) $($Arguments[1])." }
        if ($output) { return (($output -join "`n") | ConvertFrom-Json) }
    } finally {
        $env:AWS_CLI_OUTPUT_ENCODING = $originalAwsEncoding
        [Console]::OutputEncoding = $originalConsoleEncoding
    }
}
function Save-State { $state | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $StatePath -Encoding UTF8 }
function Write-JsonFile($value, [string]$path) {
    [IO.File]::WriteAllText($path, (ConvertTo-Json -InputObject $value -Depth 12 -Compress), (New-Object Text.UTF8Encoding($false)))
}

if ((Invoke-Aws @('sts','get-caller-identity')).Account -ne $account) { throw 'Conta AWS incorreta; nenhuma alteracao realizada.' }
$runId = 'cloud-pipeline-' + (Get-Date -Format 'yyyyMMddHHmmss') + '-' + [guid]::NewGuid().ToString('N').Substring(0,8)
if (-not $StatePath) { $StatePath = Join-Path $env:USERPROFILE '.cloud-pipeline\cloud-pipeline-starter-state.json' }
$StatePath = [IO.Path]::GetFullPath($StatePath)
if (Test-Path -LiteralPath $StatePath) {
    $state = Get-Content -LiteralPath $StatePath -Raw | ConvertFrom-Json
    if ($state.Account -ne $account -or $state.Region -ne $region) { throw 'Conta ou regiao do estado nao confere.' }
    if (-not $state.InstanceId) { throw "Estado parcial em $StatePath; inspecione os IDs antes de qualquer nova criacao." }
    $result = Invoke-Aws @('ec2','describe-instances','--instance-ids',$state.InstanceId)
    $instance = @($result.Reservations[0].Instances)[0]
    if ($instance.InstanceId -ne $state.InstanceId -or -not @($instance.Tags | Where-Object { $_.Key -eq 'Name' -and $_.Value -eq $state.RunId }).Count) { throw 'Instancia nao corresponde ao estado.' }
    $previousPublicIp = [string]$state.PublicIp
    $publicIp = $instance.PublicIpAddress
    Write-Output "Instancia: $($state.InstanceId); IP: $publicIp; usuario: ubuntu; grupo: $($state.SecurityGroupId); chave privada: $($state.KeyPath); estado: $StatePath"
    if ($publicIp) {
        $console = Invoke-Aws @('ec2','get-console-output','--instance-id',$state.InstanceId,'--latest')
        $output = [string]$console.Output
        if ($output -notmatch 'CLOUD_PIPELINE_SSH_HOST_ED25519') {
            try { $output = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($output)) } catch { $output = '' }
        }
        $markers = [regex]::Matches($output, '(?m)^CLOUD_PIPELINE_SSH_HOST_ED25519\s+(ssh-ed25519\s+[A-Za-z0-9+/=]+)(?:\s|$)')
        if ($markers.Count -eq 1) {
            $knownHosts = Join-Path (Split-Path -Parent $StatePath) ($state.RunId + '-known_hosts')
            [IO.File]::WriteAllText($knownHosts, "$publicIp $($markers[0].Groups[1].Value)`n", (New-Object Text.UTF8Encoding($false)))
            $state | Add-Member -NotePropertyName PublicIp -NotePropertyValue $publicIp -Force
            $state | Add-Member -NotePropertyName KnownHostsPath -NotePropertyValue $knownHosts -Force
            Save-State
            Write-Output "known_hosts autenticado: $knownHosts"
        } elseif ($markers.Count -gt 1) { throw 'Multiplas chaves de host no console; verificacao interrompida.' }
        else {
            # Console output can lose the first-boot marker after a stop/start.
            # Reuse only the previously authenticated key for this saved instance.
            $savedHosts = [string]$state.KnownHostsPath
            if ($previousPublicIp -and $savedHosts -and (Test-Path -LiteralPath $savedHosts)) {
                $savedEntry = ([IO.File]::ReadAllText($savedHosts)).Trim()
                $pattern = '^' + [regex]::Escape($previousPublicIp) + ' (ssh-ed25519 [A-Za-z0-9+/=]+)$'
                $savedMatch = [regex]::Match($savedEntry, $pattern)
                if (-not $savedMatch.Success) {
                    throw 'known_hosts salvo nao corresponde ao IP anterior; nenhuma chave nova aceita.'
                }
                [IO.File]::WriteAllText($savedHosts, "$publicIp $($savedMatch.Groups[1].Value)`n", (New-Object Text.UTF8Encoding($false)))
                $state | Add-Member -NotePropertyName PublicIp -NotePropertyValue $publicIp -Force
                Save-State
                Write-Output "IP atualizado; chave de host autenticada anteriormente preservada: $savedHosts"
            } else {
                Write-Output 'Marcador ausente e nenhuma chave autenticada salva disponivel. Verifique a chave pelo console EC2 antes de conectar; nao desative StrictHostKeyChecking.'
            }
        }
    } else { Write-Output 'IP publico ainda nao disponivel; execute novamente com -Status.' }
    exit 0
}
if ($Status) { throw "Estado nao encontrado: $StatePath" }
if (-not $AdminCidr) {
    $ipText = (Invoke-WebRequest 'https://checkip.amazonaws.com' -UseBasicParsing -TimeoutSec 15).Content.Trim()
    $AdminCidr = "$ipText/32"
}
$match = [regex]::Match($AdminCidr, '^([0-9]{1,3}(?:\.[0-9]{1,3}){3})/32$')
$ip = $null
if (-not $match.Success -or -not [Net.IPAddress]::TryParse($match.Groups[1].Value, [ref]$ip) -or $ip.AddressFamily -ne [Net.Sockets.AddressFamily]::InterNetwork -or $ip.ToString() -ne $match.Groups[1].Value -or $ip.ToString() -eq '0.0.0.0') { throw 'AdminCidr deve ser IPv4 valido no formato x.x.x.x/32.' }

$stateDir = Split-Path -Parent $StatePath
New-Item -ItemType Directory -Path $stateDir -Force | Out-Null
$state = [ordered]@{ RunId=$runId; Account=$account; Region=$region; AdminCidr=$AdminCidr; ClientToken=[guid]::NewGuid().ToString(); Status='starting' }
Save-State
try {
    # AWS CLI reference: https://docs.aws.amazon.com/cli/latest/reference/ec2/run-instances.html
    # Ubuntu image discovery: https://documentation.ubuntu.com/aws/en/latest/aws-how-to/instances/find-ubuntu-images/
    $vpcs = @(Invoke-Aws @('ec2','describe-vpcs','--filters','Name=isDefault,Values=true','--query','Vpcs[].VpcId'))
    if ($vpcs.Count -ne 1) { throw 'VPC padrao unica nao encontrada.' }
    $vpc = $vpcs[0]
    $subnets = @(Invoke-Aws @('ec2','describe-subnets','--filters',"Name=vpc-id,Values=$vpc",'Name=default-for-az,Values=true','--query','Subnets[?State==`available`].SubnetId'))
    if (-not $subnets.Count) { throw 'Subnet padrao disponivel nao encontrada.' }
    $state.VpcId=$vpc; $state.SubnetId=$subnets[0]; Save-State

    $parameter = '/aws/service/canonical/ubuntu/server/24.04/stable/current/amd64/hvm/ebs-gp3/ami-id'
    $previousPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    $raw = & $aws ssm get-parameter --name $parameter --profile $Profile --region $region --output json --no-cli-pager --cli-connect-timeout 5 --cli-read-timeout 30 2>&1
    $ssmExit = $LASTEXITCODE
    $ErrorActionPreference = $previousPreference
    if ($ssmExit -eq 0) { $amiId = (($raw -join "`n") | ConvertFrom-Json).Parameter.Value }
    elseif (($raw -join ' ') -match 'AccessDenied') {
        $images = @(Invoke-Aws @('ec2','describe-images','--owners','099720109477','--filters','Name=name,Values=ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*','Name=architecture,Values=x86_64','Name=virtualization-type,Values=hvm','Name=state,Values=available','--query','sort_by(Images,&CreationDate)[-1:]'))
        if ($images.Count -ne 1) { throw 'AMI Ubuntu nao encontrada.' }
        $amiId = $images[0].ImageId
    } else { throw 'Consulta SSM falhou; fallback reservado para AccessDenied.' }
    $images = @(Invoke-Aws @('ec2','describe-images','--image-ids',$amiId))
    $image = @($images[0].Images)[0]
    $root = @($image.BlockDeviceMappings | Where-Object { $_.DeviceName -eq $image.RootDeviceName })[0]
    if ($image.OwnerId -ne '099720109477' -or $image.Architecture -ne 'x86_64' -or $image.VirtualizationType -ne 'hvm' -or $image.State -ne 'available' -or $image.RootDeviceType -ne 'ebs' -or $image.Name -notlike 'ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*' -or $root.Ebs.VolumeType -ne 'gp3') { throw 'Metadados da AMI nao correspondem ao Ubuntu esperado.' }
    $state.ImageId=$amiId; Save-State

    $keyDir = Join-Path $env:USERPROFILE ".ssh\cloud-pipeline\$runId"
    New-Item -ItemType Directory -Path $keyDir | Out-Null
    $sid = [Security.Principal.WindowsIdentity]::GetCurrent().User.Value
    & icacls.exe $keyDir /inheritance:r /grant:r "*${sid}:(OI)(CI)F" '*S-1-5-18:(OI)(CI)F' | Out-Null
    if ($LASTEXITCODE -ne 0) { throw 'Nao foi possivel proteger o diretorio da chave.' }
    $keyPath = Join-Path $keyDir 'id_rsa'
    $state.KeyPath=$keyPath; $state.KeyName=$runId; Save-State
    $sshKeygen = (Get-Command ssh-keygen.exe -ErrorAction Stop).Source
    $process = Start-Process -FilePath $sshKeygen -ArgumentList @('-q','-t','rsa','-b','4096','-m','PEM','-N','""','-f',('"' + $keyPath + '"')) -Wait -PassThru -WindowStyle Hidden
    if ($process.ExitCode -ne 0 -or -not (Test-Path -LiteralPath "$keyPath.pub")) { throw 'Geracao da chave SSH falhou.' }
    $null = Invoke-Aws @('ec2','import-key-pair','--key-name',$runId,'--public-key-material',"fileb://$keyPath.pub")
    $state.KeyImported=$true; Save-State

    $group = Invoke-Aws @('ec2','create-security-group','--group-name',$runId,'--description','Cloud pipeline HTTP and restricted SSH','--vpc-id',$vpc)
    $state.SecurityGroupId=$group.GroupId; Save-State
    $null = Invoke-Aws @('ec2','create-tags','--resources',$group.GroupId,'--tags',"Key=Name,Value=$runId")
    $null = Invoke-Aws @('ec2','authorize-security-group-ingress','--group-id',$group.GroupId,'--protocol','tcp','--port','22','--cidr',$AdminCidr)
    $null = Invoke-Aws @('ec2','authorize-security-group-ingress','--group-id',$group.GroupId,'--protocol','tcp','--port','80','--cidr','0.0.0.0/0')

    $userData = @'
#!/bin/bash
set -eux
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y docker.io curl
systemctl enable --now docker
usermod -aG docker ubuntu
echo "CLOUD_PIPELINE_SSH_HOST_ED25519 $(cat /etc/ssh/ssh_host_ed25519_key.pub)" > /dev/console
'@
    $userDataPath=Join-Path $stateDir 'user-data.sh'
    [IO.File]::WriteAllText($userDataPath, ($userData -replace "`r`n", "`n"), (New-Object Text.UTF8Encoding($false)))
    $mappingPath=Join-Path $stateDir 'block-device.json'
    $rootSize = [Math]::Max(8, [int]$root.Ebs.VolumeSize)
    Write-JsonFile @(@{DeviceName=$image.RootDeviceName; Ebs=@{VolumeSize=$rootSize;VolumeType='gp3';Encrypted=$true;DeleteOnTermination=$true}}) $mappingPath
    $tagsPath=Join-Path $stateDir 'tags.json'
    Write-JsonFile @(@{ResourceType='instance';Tags=@(@{Key='Name';Value=$runId})},@{ResourceType='volume';Tags=@(@{Key='Name';Value=$runId})}) $tagsPath
    $state.Status='launching'; Save-State
    $launch = Invoke-Aws @('ec2','run-instances','--image-id',$amiId,'--instance-type','t3.micro','--key-name',$runId,'--subnet-id',$subnets[0],'--security-group-ids',$group.GroupId,'--associate-public-ip-address','--metadata-options','HttpTokens=required,HttpEndpoint=enabled','--block-device-mappings',"file://$mappingPath",'--tag-specifications',"file://$tagsPath",'--user-data',"fileb://$userDataPath",'--client-token',$state.ClientToken,'--count','1')
    $state.InstanceId=$launch.Instances[0].InstanceId; $state.Status='launched'; Save-State
    $instance = Invoke-Aws @('ec2','describe-instances','--instance-ids',$state.InstanceId)
    $publicIp = $instance.Reservations[0].Instances[0].PublicIpAddress
    $state.PublicIp=$publicIp; Save-State
    Write-Output "Instancia: $($state.InstanceId); IP: $publicIp; usuario: ubuntu; grupo: $($group.GroupId); estado: $StatePath"
    Write-Output 'A inicializacao ainda pode estar em andamento. Execute este script com -Status para obter a chave publica de host pelo console AWS; a aplicacao ainda nao foi implantada.'
} catch {
    Write-Warning "Provisionamento interrompido; recursos nao foram removidos. Consulte $StatePath antes de repetir. $_"
    throw
}
