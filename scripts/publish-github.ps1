Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Set-Location (Split-Path -Parent $PSScriptRoot)

# Trust this exact project for this process and its gh/git children only.
# The working copy may have been created by another Windows account.
# Preserve inherited Git settings; never trust every repository or change globals.
$configCount = 0
if ($env:GIT_CONFIG_COUNT) {
    if (-not [int]::TryParse($env:GIT_CONFIG_COUNT, [ref]$configCount) -or $configCount -lt 0) {
        throw 'Invalid inherited GIT_CONFIG_COUNT.'
    }
}
$projectPath = (Get-Location).Path.Replace('\', '/')
Set-Item -Path "Env:GIT_CONFIG_KEY_$configCount" -Value 'safe.directory'
Set-Item -Path "Env:GIT_CONFIG_VALUE_$configCount" -Value $projectPath
$env:GIT_CONFIG_COUNT = [string]($configCount + 1)

function Invoke-Checked {
    param([string]$Program, [string[]]$Arguments)
    & $Program @Arguments
    if ($LASTEXITCODE -ne 0) { throw "$Program failed (exit $LASTEXITCODE)." }
}

$originUrl = git remote get-url origin
if ($LASTEXITCODE -ne 0) { throw 'Git could not read origin; see the Git error above.' }
if ($originUrl -cne 'https://github.com/bingxyi/cloud-pipeline-aws.git') {
    throw 'Unexpected origin URL.'
}
$identity = gh api user --jq .login
if ($LASTEXITCODE -ne 0 -or -not $identity) { throw 'GitHub authentication failed.' }
$status = git status --porcelain
if ($LASTEXITCODE -ne 0 -or $status) { throw 'Working tree must be clean.' }
Invoke-Checked git @('rev-parse', '--verify', 'main^{commit}') | Out-Null
Invoke-Checked git @('rev-parse', '--verify', 'feature/delete-endpoint^{commit}') | Out-Null
Invoke-Checked git @('merge-base', '--is-ancestor', 'main', 'feature/delete-endpoint')

# Fetch any existing branches first; ordinary pushes enforce fast-forward updates.
$remoteRefs = git ls-remote --heads origin
if ($LASTEXITCODE -ne 0) { throw 'Unable to inspect origin.' }
foreach ($branch in @('main', 'feature/delete-endpoint')) {
    if ($remoteRefs -match "refs/heads/$([regex]::Escape($branch))$") {
        Invoke-Checked git @('fetch', '--no-tags', 'origin', "+refs/heads/$branch`:refs/remotes/origin/$branch")
        Invoke-Checked git @('merge-base', '--is-ancestor', "refs/remotes/origin/$branch", "refs/heads/$branch")
    }
}
# Use the authenticated gh helper directly; do not prompt through Windows GCM.
Invoke-Checked git @('-c', 'credential.helper=', '-c', 'credential.helper=!gh auth git-credential', 'push', 'origin', 'refs/heads/main:refs/heads/main')
Invoke-Checked git @('-c', 'credential.helper=', '-c', 'credential.helper=!gh auth git-credential', 'push', 'origin', 'refs/heads/feature/delete-endpoint:refs/heads/feature/delete-endpoint')

$prs = gh pr list --repo bingxyi/cloud-pipeline-aws --base main --head feature/delete-endpoint --state open --json url --jq '.[].url'
if ($LASTEXITCODE -ne 0) { throw 'Unable to list pull requests.' }
if (@($prs).Count -gt 1) { throw 'Multiple matching pull requests found.' }
if (-not $prs) {
    $prBodyFile = [System.IO.Path]::GetTempFileName()
    try {
        $prBody = @'
Implement DELETE /tasks/<id> with empty 204 or JSON 404, and GET /version.
Add API tests and a local validation script that checks container recreation persistence.
Prepare EC2 provisioning/status inspection and CD access limited to the runner's temporary SSH /32 rule, with cleanup.

Validation: nine API tests passed locally. PR CI must pass before merge.
Remote deployment requires production secrets, temporary AWS credentials and a public GHCR package; EC2 deployment and remote persistence remain to be demonstrated.
'@
        [System.IO.File]::WriteAllText($prBodyFile, $prBody)
        $prs = gh pr create --repo bingxyi/cloud-pipeline-aws --base main --head feature/delete-endpoint --title 'Implement task endpoints and EC2 delivery pipeline' --body-file $prBodyFile
        if ($LASTEXITCODE -ne 0 -or -not $prs) { throw 'Unable to create pull request.' }
    } finally {
        Remove-Item -LiteralPath $prBodyFile -Force -ErrorAction SilentlyContinue
    }
}
$pr = [string]$prs

# CI can take a moment to register after a new pull request.
$checksReady = $false
for ($attempt = 0; $attempt -lt 12; $attempt++) {
    $checks = gh pr checks $pr --repo bingxyi/cloud-pipeline-aws --json name 2>$null
    if ($LASTEXITCODE -in @(0, 8) -and $checks -and @(ConvertFrom-Json $checks).Count -gt 0) {
        $checksReady = $true
        break
    }
    Start-Sleep -Seconds 5
}
if (-not $checksReady) { throw "CI checks did not appear for $pr." }
Invoke-Checked gh @('pr', 'checks', $pr, '--repo', 'bingxyi/cloud-pipeline-aws', '--watch', '--fail-fast')
$bodyFile = [System.IO.Path]::GetTempFileName()
try {
    [System.IO.File]::WriteAllText($bodyFile, 'Self-review: checked the task deletion and version changes; CI checks passed.')
    Invoke-Checked gh @('pr', 'comment', $pr, '--repo', 'bingxyi/cloud-pipeline-aws', '--body-file', $bodyFile)
} finally {
    Remove-Item -LiteralPath $bodyFile -Force -ErrorAction SilentlyContinue
}
Write-Output "Pull request: $pr"
