$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$wallpaper = Join-Path $repoRoot 'assets\demo\hoshino-wallpaper.png'
$demoGif = Join-Path $repoRoot 'assets\demo\codex-transparent-bg-demo.gif'

if (-not (Test-Path -LiteralPath $wallpaper)) { throw "Missing wallpaper: $wallpaper" }
if (-not (Test-Path -LiteralPath $demoGif)) { throw "Missing demo GIF: $demoGif" }

$pythonCheck = @'
from hashlib import sha256
from pathlib import Path
from PIL import Image
import re
import sys

wallpaper_path, gif_path, username = sys.argv[1:4]
prohibited = [
    username,
    "C:" + chr(92) + "Users" + chr(92),
    "Bearer" + " ",
    "PRIVATE" + " KEY",
]

for path in (wallpaper_path, gif_path):
    with Image.open(path) as image:
        metadata = " ".join(f"{key}={value}" for key, value in image.info.items())
        for token in prohibited:
            if token and token.lower() in metadata.lower():
                raise AssertionError(f"private metadata found in {Path(path).name}")

with Image.open(gif_path) as image:
    assert image.format == "GIF", image.format
    assert image.size == (1200, 675), image.size
    assert getattr(image, "n_frames", 1) >= 12, getattr(image, "n_frames", 1)
    image.seek(0)
    first = sha256(image.convert("RGBA").tobytes()).hexdigest()
    image.seek(image.n_frames - 1)
    last = sha256(image.convert("RGBA").tobytes()).hexdigest()
    assert first != last, "first and last demo frames are identical"

print("PASS demo is an animated 1200x675 GIF with distinct endpoints")
print("PASS image metadata contains no private markers")
'@

& python -c $pythonCheck $wallpaper $demoGif $env:USERNAME
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$textExtensions = @('.md', '.ps1', '.psm1', '.py', '.json', '.yml', '.yaml', '.txt')
$trackedFiles = @(& git -C $repoRoot ls-files --cached --others --exclude-standard) | Select-Object -Unique
$privatePatterns = @(
    [regex]::Escape($env:USERNAME),
    [regex]::Escape(('C:' + [char]92 + 'Users' + [char]92)),
    '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}',
    'Bearer\s+[A-Za-z0-9._~-]{16,}',
    'BEGIN\s+(RSA\s+|OPENSSH\s+)?PRIVATE\s+KEY'
)

foreach ($relativePath in $trackedFiles) {
    $path = Join-Path $repoRoot $relativePath
    if ((Test-Path -LiteralPath $path -PathType Leaf) -and ([IO.Path]::GetExtension($path) -in $textExtensions)) {
        $content = Get-Content -LiteralPath $path -Raw
        foreach ($pattern in $privatePatterns) {
            if ($pattern -and $content -match $pattern) {
                throw "Privacy scan failed for $relativePath"
            }
        }
    }
}

Write-Host 'PASS tracked text contains no username, home path, email, token, or private-key marker'
