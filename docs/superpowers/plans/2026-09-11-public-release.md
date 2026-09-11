# Codex Transparent Background Public Release Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Publish a tested Windows Codex opacity plugin, privacy-safe animated demo, easy installer, and `v1.0.0` GitHub release.

**Architecture:** Keep the distributable plugin at the repository root so Codex can discover `.codex-plugin`, `skills`, `hooks`, and `scripts` directly. Isolate pure settings logic in a PowerShell module, keep User32 window manipulation in one script, and parameterize installation paths so tests can exercise marketplace mutations in temporary directories. Generate the demo from an AI-created wallpaper plus a deterministic synthetic UI compositor.

**Tech Stack:** PowerShell 7/Windows PowerShell 5.1, Win32 User32 interop, JSON, Python 3 with Pillow for GIF generation, GitHub Actions, GitHub Releases.

**Spec:** `docs/superpowers/specs/2026-09-11-public-release-design.md`

## Global Constraints

- Target Windows and the packaged Codex process path `OpenAI.Codex_*\\app\\ChatGPT.exe`.
- Support opacity values from 35 through 100 percent; default to 90 percent.
- Store the saved value at `%LOCALAPPDATA%\\CodexWindowOpacity\\settings.json`.
- Never patch Codex application files or inject CSS into the host UI.
- Preserve unrelated personal marketplace entries and metadata.
- Use only synthetic UI text and generated artwork in the demonstration.
- Publish version `v1.0.0` only after every local release check passes.

---

### Task 1: Plugin runtime and persisted settings

**Files:**
- Create: `.codex-plugin/plugin.json`
- Create: `hooks/hooks.json`
- Create: `skills/codex-window-opacity/SKILL.md`
- Create: `scripts/CodexWindowOpacity.Settings.psm1`
- Create: `scripts/Set-CodexWindowOpacity.ps1`
- Create: `tests/Runtime.Tests.ps1`

**Interfaces:**
- Produces: `ConvertTo-OpacityAlpha([int]$Opacity) -> byte`
- Produces: `Read-CodexOpacitySetting([string]$Path) -> int`
- Produces: `Save-CodexOpacitySetting([string]$Path, [int]$Opacity) -> void`
- Produces: CLI parameters `-Opacity <35..100>`, `-Save`, `-Restore`, `-WaitSeconds <0..60>`, and `-Diagnostic`

- [ ] **Step 1: Write failing runtime tests**

  Create `tests/Runtime.Tests.ps1` with assertions that `35` maps to alpha `89`, `90` maps to `230`, `100` maps to `255`, invalid values throw, a missing settings file returns `90`, and save/read round-trips `82` in a temporary path.

- [ ] **Step 2: Run tests and verify the red state**

  Run: `pwsh -NoProfile -File tests/Runtime.Tests.ps1`

  Expected: non-zero exit because `scripts/CodexWindowOpacity.Settings.psm1` does not exist.

- [ ] **Step 3: Implement the settings module and window script**

  Implement strict range checks in the pure module. In the executable script, load User32 functions with `Add-Type`, enumerate visible top-level windows, resolve each process image, require both `ChatGPT.exe` and the `OpenAI.Codex_` package path when the path is available, set `WS_EX_LAYERED`, and call `SetLayeredWindowAttributes`. Use the saved/default opacity when `-Opacity` is omitted; use `100` for `-Restore`.

- [ ] **Step 4: Add plugin metadata, skill instructions, and startup hook**

  Set manifest name `codex-window-opacity`, version `1.0.0`, and truthful Windows-only descriptions. Configure `SessionStart` for `startup|resume`, invoking the bundled PowerShell script asynchronously through `$env:PLUGIN_ROOT`. Explain whole-window fading, hook trust, and restoration in the skill.

- [ ] **Step 5: Run runtime and syntax tests**

  Run:

  ```powershell
  pwsh -NoProfile -File tests/Runtime.Tests.ps1
  pwsh -NoProfile -Command '$e=$null;$t=$null;[void][System.Management.Automation.Language.Parser]::ParseFile("scripts/Set-CodexWindowOpacity.ps1",[ref]$t,[ref]$e);if($e){$e;exit 1}'
  ```

  Expected: both commands exit `0`.

- [ ] **Step 6: Commit the runtime**

  ```powershell
  git add .codex-plugin hooks skills scripts tests/Runtime.Tests.ps1
  git commit -m "feat: add Codex window opacity plugin"
  ```

### Task 2: Safe one-command installation and removal

**Files:**
- Create: `install.ps1`
- Create: `uninstall.ps1`
- Create: `tests/Installer.Tests.ps1`

**Interfaces:**
- Produces: `install.ps1 -UserHome <path> -SourceRoot <path> -SkipCodexRegistration`
- Produces: `uninstall.ps1 -UserHome <path> -SkipCodexRegistration -KeepSettings`

- [ ] **Step 1: Write failing installer tests**

  In a new temporary user home, seed `marketplace.json` with a separate `keep-me` plugin and `interface.displayName`. Execute the installer with `-SkipCodexRegistration`, then assert that source files exist, `keep-me` remains unchanged, `codex-window-opacity` appears exactly once, and the marketplace name remains `personal`. Run the installer a second time to assert idempotency. Execute the uninstaller and assert only the target entry and directory are removed.

- [ ] **Step 2: Run tests and verify the red state**

  Run: `pwsh -NoProfile -File tests/Installer.Tests.ps1`

  Expected: non-zero exit because the root installation scripts do not exist.

- [ ] **Step 3: Implement `install.ps1`**

  Resolve explicit absolute paths, copy only `.codex-plugin`, `hooks`, `scripts`, and `skills`, create a valid personal marketplace when absent, replace or append only the exact target entry, write UTF-8 JSON, then call:

  ```powershell
  codex plugin add codex-window-opacity@personal
  ```

  Skip the CLI call only when `-SkipCodexRegistration` is present or `codex` is unavailable; print a concrete fallback in the latter case.

- [ ] **Step 4: Implement `uninstall.ps1`**

  Attempt restoration with the installed opacity script, call `codex plugin remove codex-window-opacity@personal` when available, remove only the exact marketplace entry and exact plugin directory, and remove `%LOCALAPPDATA%\\CodexWindowOpacity` unless `-KeepSettings` is set.

- [ ] **Step 5: Run installer tests twice**

  Run:

  ```powershell
  pwsh -NoProfile -File tests/Installer.Tests.ps1
  pwsh -NoProfile -File tests/Installer.Tests.ps1
  ```

  Expected: both runs exit `0` and leave no test fixture behind.

- [ ] **Step 6: Commit installation support**

  ```powershell
  git add install.ps1 uninstall.ps1 tests/Installer.Tests.ps1
  git commit -m "feat: add safe plugin installer"
  ```

### Task 3: Privacy-safe animated demonstration

**Files:**
- Create: `assets/demo/hoshino-wallpaper.png`
- Create: `assets/demo/codex-transparent-bg-demo.gif`
- Create: `tools/build_demo_gif.py`
- Create: `tests/Demo.Tests.ps1`

**Interfaces:**
- Consumes: generated PNG wallpaper at `assets/demo/hoshino-wallpaper.png`
- Produces: `tools/build_demo_gif.py --wallpaper <png> --output <gif>`
- Produces: animated GIF at 1200×675 with at least 12 frames and more than one distinct frame

- [ ] **Step 1: Write failing demo artifact tests**

  Create tests that open the GIF through Pillow, assert `GIF` format, dimensions `1200x675`, `n_frames >= 12`, and differing hashes for the first and last rendered frames. Scan PNG/GIF metadata and tracked text for the local username, home-directory paths, email addresses, bearer tokens, and private-key headers.

- [ ] **Step 2: Run tests and verify the red state**

  Run: `pwsh -NoProfile -File tests/Demo.Tests.ps1`

  Expected: non-zero exit because the wallpaper and GIF do not exist.

- [ ] **Step 3: Generate the wallpaper with the built-in image generator**

  Generate one landscape wallpaper with a cute fan-art interpretation of Takanashi Hoshino, a calm blue-and-pink night palette, open negative space for a translucent window, no text, no logos, no watermark, and no UI or personal content. Inspect it visually, then save the accepted image as `assets/demo/hoshino-wallpaper.png`.

- [ ] **Step 4: Implement deterministic GIF composition**

  In Pillow, render only generic mock interface strings (`Codex`, `Transparent background`, `Set opacity to 75%`, `Done`). Animate a rounded dark panel from alpha `255` to `170`, hold the translucent state, then return to `255`. Strip source metadata when saving the final GIF.

- [ ] **Step 5: Build and test the demo**

  Run:

  ```powershell
  python tools/build_demo_gif.py --wallpaper assets/demo/hoshino-wallpaper.png --output assets/demo/codex-transparent-bg-demo.gif
  pwsh -NoProfile -File tests/Demo.Tests.ps1
  ```

  Expected: the GIF tests and privacy scan pass.

- [ ] **Step 6: Commit demonstration assets**

  ```powershell
  git add assets tools/build_demo_gif.py tests/Demo.Tests.ps1
  git commit -m "docs: add privacy-safe animated demo"
  ```

### Task 4: Documentation, CI, and release packaging

**Files:**
- Create: `README.md`
- Create: `README.zh-CN.md`
- Create: `LICENSE`
- Create: `.gitignore`
- Create: `.github/workflows/test.yml`
- Create: `tests/Run-All.ps1`
- Create: `tools/package-release.ps1`
- Create: `tests/Release.Tests.ps1`

**Interfaces:**
- Produces: `tests/Run-All.ps1` as the single CI entry point
- Produces: `tools/package-release.ps1 -Version 1.0.0 -OutputDirectory dist`
- Produces: `dist/codex-window-opacity-v1.0.0.zip`

- [ ] **Step 1: Write failing release-package tests**

  Assert the archive contains `.codex-plugin/plugin.json`, `hooks/hooks.json`, `scripts/Set-CodexWindowOpacity.ps1`, `skills/codex-window-opacity/SKILL.md`, `install.ps1`, `uninstall.ps1`, `README.md`, `README.zh-CN.md`, and `LICENSE`, and excludes `.git`, `tests`, `tools`, `dist`, and the design documents.

- [ ] **Step 2: Run the package test and verify the red state**

  Run: `pwsh -NoProfile -File tests/Release.Tests.ps1`

  Expected: non-zero exit because no archive exists.

- [ ] **Step 3: Write documentation and licensing**

  Lead both READMEs with the GIF. Document requirements, one-line tagged-release installation, clone installation, opacity examples, hook trust, uninstall, limitations, troubleshooting, security behavior, and the unofficial fan-art/non-affiliation notice. License project code under MIT while excluding third-party character rights from that grant.

- [ ] **Step 4: Add CI and aggregate validation**

  Configure `windows-latest` to install Pillow and run `pwsh -NoProfile -File tests/Run-All.ps1`. The aggregate script runs runtime, installer, demo, JSON, manifest, privacy, and release checks and returns the first failing exit code.

- [ ] **Step 5: Implement release packaging**

  Stage an explicit allowlist of distributable paths in a newly created temporary directory, compress it to the requested versioned ZIP, and remove only that verified temporary directory. Never package test fixtures, Git metadata, or local settings.

- [ ] **Step 6: Build the archive and run all checks**

  Run:

  ```powershell
  pwsh -NoProfile -File tools/package-release.ps1 -Version 1.0.0 -OutputDirectory dist
  pwsh -NoProfile -File tests/Run-All.ps1
  git diff --check
  ```

  Expected: all commands exit `0`.

- [ ] **Step 7: Commit release preparation**

  ```powershell
  git add README.md README.zh-CN.md LICENSE .gitignore .github tests/Run-All.ps1 tests/Release.Tests.ps1 tools/package-release.ps1
  git commit -m "chore: prepare v1.0.0 release"
  ```

### Task 5: Independent review and GitHub publication

**Files:**
- Modify only files identified by review findings.
- Use: `dist/codex-window-opacity-v1.0.0.zip`

**Interfaces:**
- Consumes: clean `main` branch with passing `tests/Run-All.ps1`
- Produces: pushed `main`, annotated tag `v1.0.0`, and public GitHub release with ZIP asset

- [ ] **Step 1: Review the complete change set**

  Compare `HEAD` against the design commit `9b8499f`. Check requirement coverage, installer safety, process targeting, public-path hygiene, documentation accuracy, and whether the demo visibly communicates transparency.

- [ ] **Step 2: Fix actionable findings and rerun focused tests**

  Apply only release-blocking corrections, rerun each affected test file, and commit with:

  ```powershell
  git add -A
  git commit -m "fix: address release review"
  ```

  Skip this commit when review finds no actionable issue.

- [ ] **Step 3: Run the final verification from a clean state**

  Run:

  ```powershell
  pwsh -NoProfile -File tests/Run-All.ps1
  git diff --check
  git status --short
  ```

  Expected: tests pass, diff check is empty, and the only untracked path permitted is `dist/` when excluded by `.gitignore`.

- [ ] **Step 4: Push main without force**

  Run: `git push -u origin main`

  Expected: GitHub accepts the new branch tip. If rejected, fetch and inspect rather than force-pushing.

- [ ] **Step 5: Create and push the release tag**

  Run:

  ```powershell
  git tag -a v1.0.0 -m "Codex Transparent Background v1.0.0"
  git push origin v1.0.0
  ```

  Expected: both local and remote tag resolve to the verified release commit.

- [ ] **Step 6: Publish the GitHub release**

  Use authenticated GitHub CLI or API access to create release `v1.0.0`, title it `Codex Transparent Background v1.0.0`, summarize Windows-only installation and whole-window opacity behavior, and upload `dist/codex-window-opacity-v1.0.0.zip`.

- [ ] **Step 7: Verify the public result**

  Open the repository and release URLs, confirm the README GIF renders, the release asset is downloadable, the tag points to the expected commit, and no private metadata is visible.
