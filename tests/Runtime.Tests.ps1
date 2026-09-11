[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:Passed = 0
$script:Failed = 0

function Invoke-Test {
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [scriptblock]$Body
    )

    try {
        & $Body
        $script:Passed++
        Write-Host "PASS $Name"
    }
    catch {
        $script:Failed++
        Write-Host "FAIL $Name`n  $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Assert-Equal {
    param($Expected, $Actual)

    if ($Expected -ne $Actual) {
        throw "Expected <$Expected> but received <$Actual>."
    }
}

function Assert-True {
    param([bool]$Condition)

    if (-not $Condition) {
        throw 'Expected condition to be true.'
    }
}

function Assert-False {
    param([bool]$Condition)

    if ($Condition) {
        throw 'Expected condition to be false.'
    }
}

function Assert-Throws {
    param([scriptblock]$Body)

    try {
        & $Body
    }
    catch {
        return
    }

    throw 'Expected the operation to throw.'
}

$repositoryRoot = Split-Path -Parent $PSScriptRoot
$modulePath = Join-Path $repositoryRoot 'scripts\CodexWindowOpacity.Settings.psm1'
if (-not (Test-Path -LiteralPath $modulePath)) {
    throw "Required runtime module does not exist: $modulePath"
}
Import-Module $modulePath -Force

Invoke-Test '35 percent maps to alpha 89' {
    Assert-Equal 89 (ConvertTo-OpacityAlpha -Opacity 35)
}

Invoke-Test '90 percent maps to alpha 230' {
    Assert-Equal 230 (ConvertTo-OpacityAlpha -Opacity 90)
}

Invoke-Test '100 percent maps to alpha 255' {
    Assert-Equal 255 (ConvertTo-OpacityAlpha -Opacity 100)
}

Invoke-Test 'opacity below 35 is rejected' {
    Assert-Throws { ConvertTo-OpacityAlpha -Opacity 34 }
}

Invoke-Test 'opacity above 100 is rejected' {
    Assert-Throws { ConvertTo-OpacityAlpha -Opacity 101 }
}

Invoke-Test 'missing settings file returns 90 percent' {
    $missingPath = Join-Path ([IO.Path]::GetTempPath()) "codex-opacity-missing-$([guid]::NewGuid()).json"
    Assert-Equal 90 (Read-CodexOpacitySetting -Path $missingPath)
}

Invoke-Test 'saved opacity round-trips through JSON' {
    $temporaryDirectory = Join-Path ([IO.Path]::GetTempPath()) "codex-opacity-$([guid]::NewGuid())"
    $settingsPath = Join-Path $temporaryDirectory 'settings.json'
    try {
        Save-CodexOpacitySetting -Path $settingsPath -Opacity 82
        Assert-Equal 82 (Read-CodexOpacitySetting -Path $settingsPath)
    }
    finally {
        if (Test-Path -LiteralPath $temporaryDirectory) {
            Remove-Item -LiteralPath $temporaryDirectory -Recurse -Force
        }
    }
}

Invoke-Test 'packaged Codex executable path is accepted' {
    $path = 'C:\Program Files\WindowsApps\OpenAI.Codex_26.903.9818.0_x64__2p2nqsd0c76g0\app\ChatGPT.exe'
    Assert-True (Test-CodexProcessImagePath -Path $path)
}

Invoke-Test 'ordinary ChatGPT executable path is rejected' {
    Assert-False (Test-CodexProcessImagePath -Path 'C:\Program Files\ChatGPT\ChatGPT.exe')
}

Invoke-Test 'wrong executable inside Codex package is rejected' {
    Assert-False (Test-CodexProcessImagePath -Path 'C:\Program Files\WindowsApps\OpenAI.Codex_1.0.0_x64__test\app\helper.exe')
}

Write-Host "Runtime tests: $script:Passed passed, $script:Failed failed"
if ($script:Failed -gt 0) {
    exit 1
}
