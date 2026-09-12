@echo off
set "PLUGIN_ROOT=%~dp0"
pwsh -NoProfile -ExecutionPolicy Bypass -File "%PLUGIN_ROOT%\Set-CodexWindowOpacity.ps1" -Save
