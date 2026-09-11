# Codex 透明背景

![Codex 窗口透明度动画演示](assets/demo/codex-transparent-bg-demo.gif)

这是一个小巧的 Windows 专用 Codex 插件。它通过调整整个 Codex 桌面窗口的透明度，让你在工作时仍能看到桌面壁纸。

> [!IMPORTANT]
> 本插件调整的是**整个窗口的透明度**，文字和控件也会一起变淡。它不会修改 Codex 文件、注入 CSS，也不提供只透明背景的亚克力效果。

## 环境要求

- Windows 10 或 Windows 11
- 打包版 Codex 桌面应用（路径形如 `OpenAI.Codex_*\app\ChatGPT.exe`）
- 推荐 PowerShell 7（`pwsh`）；运行脚本也兼容 Windows PowerShell 5.1
- 若要自动注册插件，需要 `PATH` 中能找到 Codex CLI

## 从 v1.0.0 Release 一键安装

把下面一整行粘贴到 PowerShell：

```powershell
$d=Join-Path ([IO.Path]::GetTempPath()) ('codex-opacity-'+[guid]::NewGuid());$z="$d.zip";iwr 'https://github.com/fishapple/codex-transparent-bg/releases/download/v1.0.0/codex-window-opacity-v1.0.0.zip' -OutFile $z;Expand-Archive $z -DestinationPath $d;pwsh -ExecutionPolicy Bypass -File "$d/install.ps1";Remove-Item $z -Force;Remove-Item $d -Recurse -Force
```

安装后请新建一个 Codex 任务。Codex 可能会要求你信任随插件提供的 `SessionStart` hook；建议先查看 [`hooks/hooks.json`](hooks/hooks.json) 和 [`scripts/Set-CodexWindowOpacity.ps1`](scripts/Set-CodexWindowOpacity.ps1) 再确认。

## 从源码安装

```powershell
git clone https://github.com/fishapple/codex-transparent-bg.git
cd codex-transparent-bg
pwsh -ExecutionPolicy Bypass -File .\install.ps1
```

安装器只会把插件所需目录复制到个人 marketplace，保留其他插件和 marketplace 元数据；如果 Codex CLI 可用，还会自动注册 `codex-window-opacity@personal`。

## 使用方法

可以直接对 Codex 说：

```text
把 Codex 窗口设置为 75% 透明度并保存。
让 Codex 再透明一点。
把 Codex 窗口恢复为完全不透明。
```

也可以直接运行脚本：

```powershell
$script="$HOME\.agents\plugins\plugins\codex-window-opacity\scripts\Set-CodexWindowOpacity.ps1"
pwsh -File $script -Opacity 75 -Save
pwsh -File $script -Restore -Save
pwsh -File $script -Diagnostic
```

支持的透明度范围是 `35` 到 `100`，默认值为 `90`。保存后的数值会在新的 Codex 会话启动时自动重新应用。

## 卸载

在源码目录或解压后的 Release 目录中运行：

```powershell
pwsh -ExecutionPolicy Bypass -File .\uninstall.ps1
```

卸载器会先尝试恢复完全不透明，然后仅移除本插件及其 marketplace 条目。若想保留透明度设置，请添加 `-KeepSettings`。

## 安全与隐私

- 运行时只枚举可见的顶层窗口，并严格匹配 `OpenAI.Codex_` 打包应用路径中的 `ChatGPT.exe`。
- 只使用 User32 的窗口样式和分层窗口 API，不修改 Codex 安装文件。
- 设置文件只保存透明度数值，位于 `%LOCALAPPDATA%\CodexWindowOpacity\settings.json`。
- 演示采用生成的壁纸和完全合成的界面，不包含真实截图、账户信息、本地路径或用户内容。

## 限制与排查

- 目前仅支持 Windows。
- 透明度作用于整个窗口，较低数值也会让文字和控件变淡；为保证可用性，低于 `35` 的值会被拒绝。
- 如果找不到 Codex 窗口，请确认使用的是打包版 Codex 桌面应用，并加 `-Diagnostic` 查看诊断信息。
- 如果安装时没有 Codex CLI，之后可以运行 `codex plugin add codex-window-opacity@personal`。
- 如果保存值没有自动应用，请新建 Codex 任务以触发 `SessionStart` hook。

## 图片声明

演示壁纸是为本项目生成的原创同人图。小鸟游星野与《蔚蓝档案》的相关权利归各自权利方所有。本项目是非官方、非商业项目，与相关权利方及 OpenAI 均无隶属或背书关系。

项目代码使用 [MIT License](LICENSE)；该许可证不授予任何第三方角色名称或设计权利。

English documentation: [README.md](README.md).
