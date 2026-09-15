$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot

function Invoke-CheckedScript {
    param([string]$Path, [string[]]$Arguments = @())
    & pwsh -NoProfile -File $Path @Arguments
    if ($LASTEXITCODE -ne 0) { throw "Test script failed: $Path" }
}

Invoke-CheckedScript (Join-Path $PSScriptRoot 'Runtime.Tests.ps1')
Invoke-CheckedScript (Join-Path $PSScriptRoot 'Installer.Tests.ps1')
Invoke-CheckedScript (Join-Path $PSScriptRoot 'Demo.Tests.ps1')

foreach ($jsonPath in @('.codex-plugin\plugin.json', 'hooks\hooks.json')) {
    Get-Content -LiteralPath (Join-Path $repoRoot $jsonPath) -Raw | ConvertFrom-Json | Out-Null
    Write-Host "PASS valid JSON: $jsonPath"
}

$manifest = Get-Content -LiteralPath (Join-Path $repoRoot '.codex-plugin\plugin.json') -Raw | ConvertFrom-Json
if ($manifest.name -ne 'codex-window-opacity' -or $manifest.version -ne '1.0.1') {
    throw 'Plugin manifest name or version is incorrect.'
}
Write-Host 'PASS plugin manifest identifies v1.0.1'

$archivePath = Join-Path $repoRoot "dist\codex-window-opacity-v$($manifest.version).zip"
& (Join-Path $repoRoot 'tools\package-release.ps1') -Version $manifest.version -OutputDirectory (Join-Path $repoRoot 'dist')
Invoke-CheckedScript (Join-Path $PSScriptRoot 'Release.Tests.ps1') @('-ArchivePath', $archivePath)

Write-Host 'All release checks passed.' -ForegroundColor Green
