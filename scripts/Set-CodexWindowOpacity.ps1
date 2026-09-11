[CmdletBinding()]
param(
    [Nullable[int]]$Opacity,

    [ValidateRange(0, 60)]
    [int]$WaitSeconds = 12,

    [switch]$Diagnostic,
    [switch]$Save,
    [switch]$Restore
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$modulePath = Join-Path $PSScriptRoot 'CodexWindowOpacity.Settings.psm1'
Import-Module $modulePath -Force

$settingsDirectory = Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'CodexWindowOpacity'
$settingsPath = Join-Path $settingsDirectory 'settings.json'

if ($Restore) {
    $Opacity = 100
}
elseif (-not $PSBoundParameters.ContainsKey('Opacity')) {
    $Opacity = Read-CodexOpacitySetting -Path $settingsPath
}

$alpha = ConvertTo-OpacityAlpha -Opacity $Opacity
if ($Save) {
    Save-CodexOpacitySetting -Path $settingsPath -Opacity $Opacity
}

if (-not ('CodexWindowOpacity.NativeMethods' -as [type])) {
    Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;

namespace CodexWindowOpacity
{
    public static class NativeMethods
    {
        public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);

        [DllImport("user32.dll")]
        [return: MarshalAs(UnmanagedType.Bool)]
        public static extern bool EnumWindows(EnumWindowsProc callback, IntPtr lParam);

        [DllImport("user32.dll")]
        [return: MarshalAs(UnmanagedType.Bool)]
        public static extern bool IsWindowVisible(IntPtr hWnd);

        [DllImport("user32.dll")]
        public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint processId);

        [DllImport("user32.dll", SetLastError = true)]
        public static extern int GetWindowLong(IntPtr hWnd, int index);

        [DllImport("user32.dll", SetLastError = true)]
        public static extern int SetWindowLong(IntPtr hWnd, int index, int value);

        [DllImport("user32.dll", SetLastError = true)]
        [return: MarshalAs(UnmanagedType.Bool)]
        public static extern bool SetLayeredWindowAttributes(IntPtr hWnd, uint colorKey, byte alpha, uint flags);
    }
}
'@
}

$gwlExStyle = -20
$wsExLayered = 0x00080000
$lwaAlpha = 0x00000002
$deadline = [DateTime]::UtcNow.AddSeconds($WaitSeconds)
$changed = [Collections.Generic.HashSet[string]]::new()
$diagnostics = [Collections.Generic.List[object]]::new()

do {
    $callback = [CodexWindowOpacity.NativeMethods+EnumWindowsProc]{
        param([IntPtr]$windowHandle, [IntPtr]$callbackState)

        if (-not [CodexWindowOpacity.NativeMethods]::IsWindowVisible($windowHandle)) {
            return $true
        }

        [uint32]$processId = 0
        [void][CodexWindowOpacity.NativeMethods]::GetWindowThreadProcessId($windowHandle, [ref]$processId)
        $process = Get-Process -Id $processId -ErrorAction SilentlyContinue
        if ($null -eq $process) {
            return $true
        }

        $processPath = $null
        try {
            $processPath = $process.Path
        }
        catch {
            $processPath = $null
        }

        $isCodex = -not [string]::IsNullOrWhiteSpace($processPath) -and
            (Test-CodexProcessImagePath -Path $processPath)

        if ($Diagnostic -and $process.ProcessName -ieq 'ChatGPT') {
            $diagnostics.Add([pscustomobject]@{
                Handle = $windowHandle
                ProcessId = $processId
                Path = $processPath
                IsCodex = $isCodex
            })
        }

        if (-not $isCodex) {
            return $true
        }

        $style = [CodexWindowOpacity.NativeMethods]::GetWindowLong($windowHandle, $gwlExStyle)
        if (($style -band $wsExLayered) -eq 0) {
            [void][CodexWindowOpacity.NativeMethods]::SetWindowLong(
                $windowHandle,
                $gwlExStyle,
                ($style -bor $wsExLayered)
            )
        }

        if (-not [CodexWindowOpacity.NativeMethods]::SetLayeredWindowAttributes(
            $windowHandle,
            0,
            $alpha,
            $lwaAlpha
        )) {
            throw "Failed to set opacity for Codex window handle $windowHandle."
        }

        [void]$changed.Add($windowHandle.ToString())
        return $true
    }

    [void][CodexWindowOpacity.NativeMethods]::EnumWindows($callback, [IntPtr]::Zero)
    if ($Diagnostic) {
        $diagnostics | Format-Table -AutoSize
        return
    }

    if ($changed.Count -eq 0 -and [DateTime]::UtcNow -lt $deadline) {
        Start-Sleep -Milliseconds 250
    }
} while ($changed.Count -eq 0 -and [DateTime]::UtcNow -lt $deadline)

if ($changed.Count -eq 0) {
    throw 'No visible Codex desktop window was found. Keep Codex open and run the command again.'
}

Write-Output "Set $($changed.Count) Codex window(s) to $Opacity% opacity."
