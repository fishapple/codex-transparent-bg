# Codex Transparent Background — Public Release Design

Date: 2026-09-11

## Goal

Publish a Windows-only Codex plugin that lets users set and persist whole-window opacity, with a privacy-safe animated demonstration and a straightforward installation path from GitHub.

## Repository contents

The repository will be self-contained and include:

- the Codex plugin manifest, bundled skill, startup hook, and PowerShell opacity script;
- `install.ps1` and `uninstall.ps1` scripts for personal Codex installations;
- English and Chinese usage documentation;
- an MIT license for the source code;
- a generated demonstration wallpaper and an animated GIF;
- automated validation for JSON, PowerShell syntax, plugin structure, and privacy-sensitive metadata;
- a downloadable ZIP attached to the `v1.0.0` GitHub release.

## Runtime design

`scripts/Set-CodexWindowOpacity.ps1` enumerates visible Windows desktop windows and selects only the packaged Codex application process (`OpenAI.Codex_*\\app\\ChatGPT.exe`). It applies `WS_EX_LAYERED` and an alpha value with the Windows User32 API. The supported range is 35–100 percent, with 90 percent as the default.

The chosen opacity is stored at `%LOCALAPPDATA%\\CodexWindowOpacity\\settings.json`. A trusted `SessionStart` hook reads and reapplies the saved value on startup or resume. Restoring 100 percent opacity is supported without modifying Codex application files.

Because Windows alpha blending applies to the entire native window, text and controls fade together with the background. Background-only CSS injection is explicitly out of scope because Codex plugins do not have a supported host-UI stylesheet injection surface.

## Installation and removal

`install.ps1` will:

1. copy the plugin into `%USERPROFILE%\\plugins\\codex-window-opacity`;
2. create or update `%USERPROFILE%\\.agents\\plugins\\marketplace.json` while preserving unrelated entries;
3. run `codex plugin add codex-window-opacity@personal` when the Codex CLI is available;
4. print an exact manual fallback when the CLI is unavailable.

The installer will support installation directly from a cloned repository. The README will also provide a one-line PowerShell command that downloads the tagged release archive to a temporary directory, inspects the expected archive layout, runs the installer, and removes only that temporary directory.

`uninstall.ps1` will remove the Codex registration, the plugin's personal marketplace entry, its installed source directory, and its opacity settings. It will restore the visible Codex window to 100 percent before removal when possible.

## Demonstration asset

The demo will use an original AI-generated fan-art wallpaper featuring a cute interpretation of Takanashi Hoshino. No game screenshots, extracted artwork, user files, usernames, repository paths, account details, desktop icons, notifications, or real conversations will appear.

The GIF will be built from a synthetic desktop scene. A mock Codex window with generic text will animate from opaque to translucent over the wallpaper so the feature is immediately understandable. The repository will include the final GIF and a reproducible local script that assembles its frames from repository assets.

The README will identify the character demo as unofficial fan art, state that the project is not affiliated with or endorsed by Nexon Games, Yostar, or OpenAI, and clarify that the MIT license covers the project source code rather than third-party character rights.

## Testing and validation

Local tests will cover:

- opacity validation and settings persistence;
- safe process-selection behavior;
- installer behavior against a temporary user profile and marketplace fixture;
- uninstall cleanup against a temporary fixture;
- valid plugin and hook JSON;
- PowerShell abstract-syntax-tree parsing;
- absence of known local usernames, absolute private paths, email addresses, and likely credential strings in tracked text and demo metadata;
- GIF format, dimensions, frame count, and animation.

GitHub Actions will run the portable tests on `windows-latest`. The Windows GUI effect itself will be documented as an interactive test because hosted runners do not provide the Codex desktop window.

## Release workflow

The first public release will use tag `v1.0.0`. The release archive will contain the plugin and root installation scripts without development-only files. The GitHub repository description and topics will identify it as a Windows Codex transparency plugin.

The main branch will receive the reviewed implementation commit, followed by the annotated tag, push, and GitHub release creation through authenticated Git operations or the GitHub API available on the machine.

## Error handling and safety

- Installer mutations are limited to the named personal plugin directory and its exact marketplace entry.
- Existing unrelated marketplace entries and display metadata are preserved.
- The opacity script fails clearly when no visible Codex window is found.
- Installation never patches the packaged Codex application or disables sandbox protections.
- Download instructions use the immutable `v1.0.0` release rather than executing the repository's moving default branch.
- Release checks must pass before pushing the tag or publishing the release.

## Acceptance criteria

1. A new Windows user can install the plugin from the `v1.0.0` release with one documented PowerShell command or from a clone with `install.ps1`.
2. The plugin can set, save, reapply, and restore Codex whole-window opacity.
3. The README displays an animated GIF that visibly reveals the Takanashi Hoshino wallpaper behind a synthetic Codex window.
4. The GIF and repository contain no personal information from the developer's machine.
5. Automated checks pass locally and in the committed GitHub Actions workflow.
6. The public GitHub repository contains the source, documentation, license, tag, and downloadable release archive.
