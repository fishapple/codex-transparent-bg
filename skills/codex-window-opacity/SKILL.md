---
name: codex-window-opacity
description: Use when a Windows user asks to make the Codex desktop window transparent, translucent, more or less opaque, show a wallpaper through it, save an opacity level, or restore full opacity.
---

# Codex Window Opacity

## Overview

Use the bundled PowerShell script to adjust the packaged Codex desktop window. The effect applies to the whole native window, including its text and controls.

## Commands

Resolve the plugin root as two directories above this file, then run:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File <plugin-root>\scripts\Set-CodexWindowOpacity.ps1 -Opacity 90 -Save
```

Choose a whole-number opacity from 35 through 100. Use 90 when the user does not specify a value.

Restore the normal window with:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File <plugin-root>\scripts\Set-CodexWindowOpacity.ps1 -Restore -Save
```

## Safety and troubleshooting

- Run the script in the interactive Windows desktop session. GUI access may require approval for this exact bundled script.
- Do not target unrelated processes or change system-wide transparency settings.
- If no visible window is found, keep Codex open and retry with `-WaitSeconds 12`.
- A new or changed `SessionStart` hook is skipped until the user reviews and trusts it.
- Report the applied percentage and whether a visible Codex window was found.
