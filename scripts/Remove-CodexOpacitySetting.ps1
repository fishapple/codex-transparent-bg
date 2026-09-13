$directory = Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'CodexWindowOpacity'
if (Test-Path -LiteralPath $directory) {
    Remove-Item -LiteralPath $directory -Recurse -Force
}
