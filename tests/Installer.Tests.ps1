$ErrorActionPreference = 'Stop'

$script:Passed = 0
$script:Failed = 0

function Assert-True {
    param([bool]$Condition, [string]$Name)
    if ($Condition) {
        $script:Passed++
        Write-Host "PASS $Name"
    }
    else {
        $script:Failed++
        Write-Host "FAIL $Name" -ForegroundColor Red
    }
}

$repoRoot = Split-Path -Parent $PSScriptRoot
$installScript = Join-Path $repoRoot 'install.ps1'
$uninstallScript = Join-Path $repoRoot 'uninstall.ps1'
$fixture = Join-Path ([System.IO.Path]::GetTempPath()) ("codex-opacity-installer-{0}" -f [guid]::NewGuid().ToString('N'))
$marketplacePath = Join-Path $fixture '.agents\plugins\marketplace.json'
$pluginPath = Join-Path $fixture '.agents\plugins\plugins\codex-window-opacity'

try {
    $marketplaceDirectory = Split-Path -Parent $marketplacePath
    New-Item -ItemType Directory -Path $marketplaceDirectory -Force | Out-Null
    @{
        name = 'personal'
        interface = @{ displayName = 'My private marketplace label' }
        plugins = @(
            @{
                name = 'keep-me'
                source = @{ source = 'local'; path = './plugins/keep-me' }
                policy = @{ installation = 'AVAILABLE'; authentication = 'ON_INSTALL' }
                category = 'Developer Tools'
            }
        )
    } | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $marketplacePath -Encoding utf8

    & $installScript -UserHome $fixture -SourceRoot $repoRoot -SkipCodexRegistration
    & $installScript -UserHome $fixture -SourceRoot $repoRoot -SkipCodexRegistration

    $marketplace = Get-Content -LiteralPath $marketplacePath -Raw | ConvertFrom-Json
    Assert-True ($marketplace.name -eq 'personal') 'marketplace name remains personal'
    Assert-True ($marketplace.interface.displayName -eq 'My private marketplace label') 'marketplace interface metadata is preserved'
    Assert-True (@($marketplace.plugins | Where-Object name -eq 'keep-me').Count -eq 1) 'unrelated plugin remains unchanged'
    Assert-True (@($marketplace.plugins | Where-Object name -eq 'codex-window-opacity').Count -eq 1) 'target marketplace entry is idempotent'
    Assert-True (Test-Path -LiteralPath (Join-Path $pluginPath '.codex-plugin\plugin.json')) 'plugin manifest is installed'
    Assert-True (Test-Path -LiteralPath (Join-Path $pluginPath 'scripts\Set-CodexWindowOpacity.ps1')) 'runtime script is installed'
    Assert-True (Test-Path -LiteralPath (Join-Path $pluginPath 'scripts\Watch-CodexWindow.ps1')) 'window watcher is installed'
    Assert-True (Test-Path -LiteralPath (Join-Path $pluginPath 'scripts\Remove-CodexOpacitySetting.ps1')) 'host settings cleanup is installed'

    & $uninstallScript -UserHome $fixture -SkipCodexRegistration -KeepSettings

    $marketplaceAfter = Get-Content -LiteralPath $marketplacePath -Raw | ConvertFrom-Json
    Assert-True (@($marketplaceAfter.plugins | Where-Object name -eq 'keep-me').Count -eq 1) 'uninstaller preserves unrelated plugin'
    Assert-True (@($marketplaceAfter.plugins | Where-Object name -eq 'codex-window-opacity').Count -eq 0) 'uninstaller removes only target entry'
    Assert-True (-not (Test-Path -LiteralPath $pluginPath)) 'uninstaller removes target plugin directory'
}
finally {
    if (Test-Path -LiteralPath $fixture) {
        Remove-Item -LiteralPath $fixture -Recurse -Force
    }
}

Write-Host "Installer tests: $script:Passed passed, $script:Failed failed"
if ($script:Failed -gt 0) { exit 1 }
