param(
    [string]$Profile = 'default'
)

$originalPath = $env:PATH
$originalDbPath = $env:DB_PATH
$originalPytestTemp = $env:PYTEST_DEBUG_TEMPROOT
$originalPytestOpts = $env:PYTEST_ADDOPTS
$originalLocation = Get-Location
$failed = $false

try {
    $repo = Split-Path -Parent $PSScriptRoot
    $dockerDir = Join-Path $env:LOCALAPPDATA 'Programs\DockerDesktop\resources\bin'
    $venvDir = Join-Path $repo '.venv\Scripts'
    $env:PATH = "$venvDir;$dockerDir;$originalPath"
    $env:DB_PATH = Join-Path $repo '.venv\host-validation.db'
    Set-Location -LiteralPath $repo

    try {
        $pytestTemp = Join-Path ([IO.Path]::GetTempPath()) ('cloud-tasks-pytest-' + [guid]::NewGuid().ToString('N'))
        [IO.Directory]::CreateDirectory($pytestTemp) | Out-Null
        $env:PYTEST_DEBUG_TEMPROOT = $pytestTemp
        $env:PYTEST_ADDOPTS = "$originalPytestOpts -p no:cacheprovider".Trim()
        $docker = Join-Path $dockerDir 'docker.exe'
        $bashCandidates = @(
            (Join-Path $env:ProgramFiles 'Git\bin\bash.exe'),
            (Join-Path ${env:ProgramFiles(x86)} 'Git\bin\bash.exe'),
            (Join-Path $env:LOCALAPPDATA 'Programs\Git\bin\bash.exe')
        )
        $bash = $bashCandidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
        if (-not (Test-Path -LiteralPath $docker)) { throw 'Docker CLI nao localizado.' }
        if (-not (Test-Path -LiteralPath (Join-Path $venvDir 'python.exe'))) { throw 'Python do ambiente .venv nao localizado.' }
        if (-not $bash) { throw 'Git Bash nao localizado.' }
        & $docker version
        if ($LASTEXITCODE -ne 0) { throw 'docker version falhou.' }
        & $bash 'validate-local.sh'
        if ($LASTEXITCODE -ne 0) { throw 'A validacao local falhou.' }
    } catch {
        Write-Warning "Validacao local falhou: $_"
        $failed = $true
    }

    try {
        & (Join-Path $PSScriptRoot 'inspect-aws.ps1') -Profile $Profile
        if (-not $?) { throw 'Inventario AWS falhou.' }
    } catch {
        Write-Warning "Inventario AWS falhou: $_"
        $failed = $true
    }
} finally {
    $env:PATH = $originalPath
    $env:DB_PATH = $originalDbPath
    $env:PYTEST_DEBUG_TEMPROOT = $originalPytestTemp
    $env:PYTEST_ADDOPTS = $originalPytestOpts
    Set-Location -LiteralPath $originalLocation.Path
}

if ($failed) { exit 1 }
exit 0
