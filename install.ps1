[CmdletBinding()]
param(
    [string]$UserHome = [Environment]::GetFolderPath('UserProfile'),
    [string]$SourceRoot = $PSScriptRoot,
    [switch]$SkipCodexRegistration
)

$ErrorActionPreference = 'Stop'
$pluginName = 'codex-window-opacity'
$sourceRootPath = [System.IO.Path]::GetFullPath($SourceRoot)
$userHomePath = [System.IO.Path]::GetFullPath($UserHome)
$marketplaceRoot = Join-Path $userHomePath '.agents\plugins'
$marketplacePath = Join-Path $marketplaceRoot 'marketplace.json'
$pluginsRoot = Join-Path $marketplaceRoot 'plugins'
$destination = Join-Path $pluginsRoot $pluginName
$requiredPaths = @('.codex-plugin', 'hooks', 'scripts', 'skills')

foreach ($relativePath in $requiredPaths) {
    $sourcePath = Join-Path $sourceRootPath $relativePath
    if (-not (Test-Path -LiteralPath $sourcePath -PathType Container)) {
        throw "The plugin source is incomplete: $sourcePath is missing."
    }
}

New-Item -ItemType Directory -Path $pluginsRoot -Force | Out-Null

$pluginsRootFull = [System.IO.Path]::GetFullPath($pluginsRoot).TrimEnd('\') + '\'
$destinationFull = [System.IO.Path]::GetFullPath($destination)
if (-not $destinationFull.StartsWith($pluginsRootFull, [StringComparison]::OrdinalIgnoreCase)) {
    throw "Refusing to install outside the personal plugins directory: $destinationFull"
}

New-Item -ItemType Directory -Path $destinationFull -Force | Out-Null
foreach ($relativePath in $requiredPaths) {
    $targetPath = Join-Path $destinationFull $relativePath
    if (Test-Path -LiteralPath $targetPath) {
        Remove-Item -LiteralPath $targetPath -Recurse -Force
    }
    Copy-Item -LiteralPath (Join-Path $sourceRootPath $relativePath) -Destination $targetPath -Recurse -Force
}

if (Test-Path -LiteralPath $marketplacePath) {
    $marketplace = Get-Content -LiteralPath $marketplacePath -Raw | ConvertFrom-Json
    if ($marketplace.name -ne 'personal') {
        throw "The existing marketplace must be named 'personal'; found '$($marketplace.name)'."
    }
    if ($null -eq $marketplace.plugins) {
        $marketplace | Add-Member -NotePropertyName plugins -NotePropertyValue @()
    }
}
else {
    New-Item -ItemType Directory -Path $marketplaceRoot -Force | Out-Null
    $marketplace = [pscustomobject]@{
        name = 'personal'
        interface = [pscustomobject]@{ displayName = 'Personal' }
        plugins = @()
    }
}

$entry = [pscustomobject]@{
    name = $pluginName
    source = [pscustomobject]@{ source = 'local'; path = "./plugins/$pluginName" }
    policy = [pscustomobject]@{ installation = 'AVAILABLE'; authentication = 'ON_INSTALL' }
    category = 'Productivity'
}

$updatedPlugins = [System.Collections.Generic.List[object]]::new()
$replaced = $false
foreach ($plugin in @($marketplace.plugins)) {
    if ($plugin.name -eq $pluginName) {
        if (-not $replaced) {
            $updatedPlugins.Add($entry)
            $replaced = $true
        }
    }
    else {
        $updatedPlugins.Add($plugin)
    }
}
if (-not $replaced) { $updatedPlugins.Add($entry) }
$marketplace.plugins = @($updatedPlugins)
$marketplace | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $marketplacePath -Encoding utf8

if (-not $SkipCodexRegistration) {
    $codex = Get-Command codex -ErrorAction SilentlyContinue
    if ($null -ne $codex) {
        & $codex.Source plugin add "$pluginName@personal"
        if ($LASTEXITCODE -ne 0) { throw "Codex could not register $pluginName@personal." }
    }
    else {
        Write-Warning "Codex CLI was not found. After it is available, run: codex plugin add $pluginName@personal"
    }
}

Write-Host "Installed $pluginName to $destinationFull"
Write-Host 'Start a new Codex task so the plugin hook and skill are loaded.'
