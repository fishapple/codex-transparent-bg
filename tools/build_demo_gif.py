#!/usr/bin/env python3
"""Build a deterministic, privacy-safe animation for the project README."""

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


WIDTH, HEIGHT = 1200, 675
PANEL = (42, 38, 844, 637)


def load_font(size: int, *, bold: bool = False) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    candidates = (
        Path("C:/Windows/Fonts/seguisb.ttf") if bold else Path("C:/Windows/Fonts/segoeui.ttf"),
        Path("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf")
        if bold
        else Path("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"),
    )
    for candidate in candidates:
        if candidate.exists():
            return ImageFont.truetype(str(candidate), size)
    return ImageFont.load_default()


def cover(image: Image.Image) -> Image.Image:
    image = image.convert("RGB")
    scale = max(WIDTH / image.width, HEIGHT / image.height)
    resized = image.resize(
        (round(image.width * scale), round(image.height * scale)), Image.Resampling.LANCZOS
    )
    left = (resized.width - WIDTH) // 2
    top = (resized.height - HEIGHT) // 2
    return resized.crop((left, top, left + WIDTH, top + HEIGHT))


def draw_mock_window(background: Image.Image, opacity: int, frame_index: int) -> Image.Image:
    frame = background.convert("RGBA")
    overlay = Image.new("RGBA", frame.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)

    # A fabricated Codex-like shell: intentionally generic and disconnected from real user data.
    draw.rounded_rectangle(PANEL, radius=22, fill=(13, 18, 29, opacity), outline=(255, 255, 255, 35), width=1)
    draw.rounded_rectangle((42, 38, 844, 91), radius=22, fill=(24, 31, 46, min(255, opacity + 12)))
    draw.rectangle((42, 69, 844, 91), fill=(24, 31, 46, min(255, opacity + 12)))
    draw.ellipse((66, 57, 78, 69), fill=(255, 120, 132, 225))
    draw.ellipse((87, 57, 99, 69), fill=(255, 202, 112, 225))
    draw.ellipse((108, 57, 120, 69), fill=(115, 220, 160, 225))
    draw.line((246, 91, 246, 637), fill=(255, 255, 255, 30), width=1)

    title_font = load_font(26, bold=True)
    heading_font = load_font(22, bold=True)
    body_font = load_font(18)
    small_font = load_font(15)
    draw.text((143, 52), "Codex", font=body_font, fill=(242, 246, 255, 235))

    draw.text((67, 121), "Tasks", font=small_font, fill=(196, 207, 226, 210))
    draw.rounded_rectangle((61, 151, 226, 195), radius=10, fill=(105, 150, 255, 45))
    draw.text((76, 163), "Transparent demo", font=small_font, fill=(238, 243, 255, 235))
    draw.text((76, 215), "New task", font=small_font, fill=(196, 207, 226, 190))

    draw.text((284, 126), "Transparent background", font=title_font, fill=(247, 249, 255, 245))
    draw.text((284, 177), "Show your wallpaper while you work.", font=body_font, fill=(205, 214, 232, 220))

    draw.rounded_rectangle((284, 244, 790, 319), radius=14, fill=(77, 99, 142, 90))
    draw.text((307, 267), "Set opacity to 67%", font=heading_font, fill=(248, 250, 255, 245))

    draw.rounded_rectangle((284, 346, 790, 461), radius=14, fill=(10, 15, 25, 105), outline=(255, 255, 255, 28))
    draw.ellipse((307, 372, 329, 394), fill=(110, 170, 255, 245))
    draw.text((346, 370), "Done", font=heading_font, fill=(239, 245, 255, 245))
    draw.text((307, 414), "The wallpaper is now visible through Codex.", font=small_font, fill=(201, 213, 233, 225))

    track = (284, 505, 790, 513)
    draw.rounded_rectangle(track, radius=4, fill=(255, 255, 255, 50))
    progress = (255 - opacity) / (255 - 170)
    knob_x = round(310 + progress * 440)
    draw.rounded_rectangle((284, 505, knob_x, 513), radius=4, fill=(113, 165, 255, 230))
    draw.ellipse((knob_x - 10, 496, knob_x + 10, 522), fill=(244, 248, 255, 255))
    percentage = round(opacity / 255 * 100)
    draw.text((284, 535), f"Window opacity  {percentage}%", font=small_font, fill=(221, 229, 243, 225))

    # A tiny final-frame cursor blink keeps the animation endpoints distinct after restoring opacity.
    if frame_index % 2:
        draw.rounded_rectangle((801, 602, 813, 620), radius=3, fill=(125, 174, 255, 210))

    return Image.alpha_composite(frame, overlay).convert("RGB")


def build_demo(wallpaper_path: Path, output_path: Path) -> None:
    with Image.open(wallpaper_path) as source:
        background = cover(source)

    alpha_sequence = [255, 245, 232, 218, 204, 190, 180, 170] + [170] * 8 + [180, 190, 204, 218, 232, 245, 255, 255]
    frames = [draw_mock_window(background, alpha, index) for index, alpha in enumerate(alpha_sequence)]

    output_path.parent.mkdir(parents=True, exist_ok=True)
    frames[0].save(
        output_path,
        format="GIF",
        save_all=True,
        append_images=frames[1:],
        duration=[260] + [95] * (len(frames) - 2) + [700],
        loop=0,
        optimize=False,
        disposal=2,
        comment=b"Privacy-safe synthetic demo",
    )


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--wallpaper", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    return parser.parse_args()


if __name__ == "__main__":
    arguments = parse_args()
    build_demo(arguments.wallpaper, arguments.output)
