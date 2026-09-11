[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidatePattern('^\d+\.\d+\.\d+$')]
    [string]$Version,

    [string]$OutputDirectory = 'dist'
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$outputRoot = if ([IO.Path]::IsPathRooted($OutputDirectory)) {
    [IO.Path]::GetFullPath($OutputDirectory)
}
else {
    [IO.Path]::GetFullPath((Join-Path $repoRoot $OutputDirectory))
}
$archivePath = Join-Path $outputRoot "codex-window-opacity-v$Version.zip"
$temporaryRoot = [IO.Path]::GetFullPath((Join-Path ([IO.Path]::GetTempPath()) ("codex-opacity-package-{0}" -f [guid]::NewGuid().ToString('N'))))
$systemTempRoot = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\') + '\'

if (-not $temporaryRoot.StartsWith($systemTempRoot, [StringComparison]::OrdinalIgnoreCase)) {
    throw "Refusing to stage outside the system temporary directory: $temporaryRoot"
}

$directories = @('.codex-plugin', 'hooks', 'scripts', 'skills', 'assets')
$files = @('install.ps1', 'uninstall.ps1', 'README.md', 'README.zh-CN.md', 'LICENSE')

try {
    New-Item -ItemType Directory -Path $temporaryRoot -Force | Out-Null
    foreach ($directory in $directories) {
        $source = Join-Path $repoRoot $directory
        if (-not (Test-Path -LiteralPath $source -PathType Container)) { throw "Missing release directory: $directory" }
        Copy-Item -LiteralPath $source -Destination (Join-Path $temporaryRoot $directory) -Recurse -Force
    }
    foreach ($file in $files) {
        $source = Join-Path $repoRoot $file
        if (-not (Test-Path -LiteralPath $source -PathType Leaf)) { throw "Missing release file: $file" }
        Copy-Item -LiteralPath $source -Destination (Join-Path $temporaryRoot $file) -Force
    }

    New-Item -ItemType Directory -Path $outputRoot -Force | Out-Null
    if (Test-Path -LiteralPath $archivePath) { Remove-Item -LiteralPath $archivePath -Force }
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::CreateFromDirectory(
        $temporaryRoot,
        $archivePath,
        [System.IO.Compression.CompressionLevel]::Optimal,
        $false
    )
}
finally {
    if (Test-Path -LiteralPath $temporaryRoot) {
        Remove-Item -LiteralPath $temporaryRoot -Recurse -Force
    }
}

Write-Host "Created $archivePath"
