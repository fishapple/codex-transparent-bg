$ErrorActionPreference = 'Stop'
$runtime = Join-Path $PSScriptRoot 'Set-CodexWindowOpacity.ps1'

while ($true) {
    try {
        & $runtime -WaitSeconds 0 | Out-Null
    }
    catch {
        Write-Verbose $_.Exception.Message
    }
    Start-Sleep -Seconds 5
}
