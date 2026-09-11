Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Assert-CodexOpacity {
    param([int]$Opacity)

    if ($Opacity -lt 35 -or $Opacity -gt 100) {
        throw 'Opacity must be between 35 and 100 percent.'
    }
}

function ConvertTo-OpacityAlpha {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [int]$Opacity
    )

    Assert-CodexOpacity -Opacity $Opacity
    return [byte][Math]::Round(255 * ($Opacity / 100.0))
}

function Read-CodexOpacitySetting {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        return 90
    }

    $settings = Get-Content -Raw -LiteralPath $Path | ConvertFrom-Json
    if ($null -eq $settings.opacity) {
        throw "Settings file does not contain an opacity value: $Path"
    }

    $opacity = [int]$settings.opacity
    Assert-CodexOpacity -Opacity $opacity
    return $opacity
}

function Save-CodexOpacitySetting {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [int]$Opacity
    )

    Assert-CodexOpacity -Opacity $Opacity
    $directory = Split-Path -Parent $Path
    if (-not [string]::IsNullOrWhiteSpace($directory)) {
        [void](New-Item -ItemType Directory -Path $directory -Force)
    }

    @{ opacity = $Opacity } |
        ConvertTo-Json |
        Set-Content -LiteralPath $Path -Encoding UTF8
}

function Test-CodexProcessImagePath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    return $Path -match '(?i)[\\/]WindowsApps[\\/]OpenAI\.Codex_[^\\/]+[\\/]app[\\/]ChatGPT\.exe$'
}

Export-ModuleMember -Function @(
    'ConvertTo-OpacityAlpha',
    'Read-CodexOpacitySetting',
    'Save-CodexOpacitySetting',
    'Test-CodexProcessImagePath'
)
