[CmdletBinding()]
param(
    [string]$ArchivePath = (Join-Path (Split-Path -Parent $PSScriptRoot) 'dist\codex-window-opacity-v1.0.0.zip')
)

$ErrorActionPreference = 'Stop'
if (-not (Test-Path -LiteralPath $ArchivePath -PathType Leaf)) {
    throw "Release archive does not exist: $ArchivePath"
}

Add-Type -AssemblyName System.IO.Compression.FileSystem
$archive = [System.IO.Compression.ZipFile]::OpenRead((Resolve-Path $ArchivePath))
try {
    $entries = @($archive.Entries | ForEach-Object { $_.FullName.Replace('\', '/') })
}
finally {
    $archive.Dispose()
}

$required = @(
    '.codex-plugin/plugin.json',
    'hooks/hooks.json',
    'scripts/Set-CodexWindowOpacity.ps1',
    'scripts/Watch-CodexWindow.ps1',
    'scripts/Remove-CodexOpacitySetting.ps1',
    'scripts/CodexWindowOpacity.Settings.psm1',
    'skills/codex-window-opacity/SKILL.md',
    'install.ps1',
    'uninstall.ps1',
    'README.md',
    'README.zh-CN.md',
    'LICENSE',
    'assets/demo/codex-transparent-bg-demo.gif'
)

foreach ($path in $required) {
    if ($path -notin $entries) { throw "Release archive is missing: $path" }
}

$forbiddenPrefixes = @('.git/', '.github/', 'tests/', 'tools/', 'dist/', 'docs/')
foreach ($entry in $entries) {
    foreach ($prefix in $forbiddenPrefixes) {
        if ($entry.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) {
            throw "Release archive contains forbidden path: $entry"
        }
    }
}

Write-Host "PASS release archive contains $($entries.Count) allowlisted files and no development-only paths"
