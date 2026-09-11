[CmdletBinding()]
param(
    [string]$UserHome = [Environment]::GetFolderPath('UserProfile'),
    [switch]$SkipCodexRegistration,
    [switch]$KeepSettings
)

$ErrorActionPreference = 'Stop'
$pluginName = 'codex-window-opacity'
$userHomePath = [System.IO.Path]::GetFullPath($UserHome)
$marketplaceRoot = Join-Path $userHomePath '.agents\plugins'
$marketplacePath = Join-Path $marketplaceRoot 'marketplace.json'
$pluginsRoot = Join-Path $marketplaceRoot 'plugins'
$destination = Join-Path $pluginsRoot $pluginName
$runtimeScript = Join-Path $destination 'scripts\Set-CodexWindowOpacity.ps1'

if (Test-Path -LiteralPath $runtimeScript) {
    try {
        & $runtimeScript -Restore -WaitSeconds 0 | Out-Null
    }
    catch {
        Write-Verbose "The Codex window could not be restored before removal: $($_.Exception.Message)"
    }
}

if (-not $SkipCodexRegistration) {
    $codex = Get-Command codex -ErrorAction SilentlyContinue
    if ($null -ne $codex) {
        & $codex.Source plugin remove "$pluginName@personal"
        if ($LASTEXITCODE -ne 0) {
            Write-Warning 'Codex CLI did not remove the registration; local cleanup will continue.'
        }
    }
}

if (Test-Path -LiteralPath $marketplacePath) {
    $marketplace = Get-Content -LiteralPath $marketplacePath -Raw | ConvertFrom-Json
    $marketplace.plugins = @($marketplace.plugins | Where-Object { $_.name -ne $pluginName })
    $marketplace | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $marketplacePath -Encoding utf8
}

$pluginsRootFull = [System.IO.Path]::GetFullPath($pluginsRoot).TrimEnd('\') + '\'
$destinationFull = [System.IO.Path]::GetFullPath($destination)
if (-not $destinationFull.StartsWith($pluginsRootFull, [StringComparison]::OrdinalIgnoreCase)) {
    throw "Refusing to remove a path outside the personal plugins directory: $destinationFull"
}
if (Test-Path -LiteralPath $destinationFull) {
    Remove-Item -LiteralPath $destinationFull -Recurse -Force
}

if (-not $KeepSettings) {
    $settingsDirectory = Join-Path $userHomePath 'AppData\Local\CodexWindowOpacity'
    $expectedSettingsParent = [System.IO.Path]::GetFullPath((Join-Path $userHomePath 'AppData\Local')).TrimEnd('\') + '\'
    $settingsFull = [System.IO.Path]::GetFullPath($settingsDirectory)
    if (-not $settingsFull.StartsWith($expectedSettingsParent, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing to remove a settings path outside the user profile: $settingsFull"
    }
    if (Test-Path -LiteralPath $settingsFull) {
        Remove-Item -LiteralPath $settingsFull -Recurse -Force
    }
}

Write-Host "Removed $pluginName."
