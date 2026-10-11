#!/usr/bin/env python3
"""Draws the launcher icon sources: foreground, monochrome and legacy.

    python3 tool/make-icon.py [--out tool/icon] [--size 1080] [--font PATH]

The layout is designed on the 108 dp adaptive icon and sits inside its 66 dp
safe zone. Needs Pillow and a bold monospace font (DejaVu Sans Mono Bold by
default, found by name on the usual font paths or given with --font).
"""

import argparse
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

DP = 108

# flutter_launcher_icons wraps each adaptive layer in a 16% inset, so the
# layer image covers only the middle of the 108 dp icon; it is drawn on that
# smaller canvas for the layout to come out at its designed size.
INSET = 0.16
CANVAS_DP = DP * (1 - 2 * INSET)

# The layout's bounding box is 58 x 39 dp, whose diagonal is wider than the
# 66 dp circle a launcher may mask to; it is drawn at this fraction of that.
LAYOUT_SCALE = 0.84
CENTER_X, CENTER_Y = 54, 56.5
ORANGE = (255, 102, 0)
WHITE = (255, 255, 255)
SOFT = (255, 190, 150)
PEACH = (255, 214, 186)
FONT_NAME = "DejaVuSansMono-Bold.ttf"
SUPERSAMPLE = 2
LEGACY_SCALE = 1.35

HACKER_WIDTH = 58
HACKER_X, HACKER_BASELINE = 25, 50
NEWS_X, NEWS_BASELINE = 42, 75
CURSOR_GAP, CURSOR_WIDTH = 1.5, 6
CURSOR_TOP, CURSOR_BOTTOM = 62, 76
ELBOW_X, ELBOW_TOP, ELBOW_BOTTOM, ELBOW_END, ELBOW_WIDTH = 29, 54, 70, 40, 3.4


def load_font(path, px):
    return ImageFont.truetype(path or FONT_NAME, px)


def fitted_font(path, text, width_px):
    size = 10
    while load_font(path, size + 2).getlength(text) <= width_px:
        size += 2
    return load_font(path, size)


def draw_glyphs(size, font_path, colors):
    """The text, elbow and cursor on a transparent square of [size] px."""
    unit = size * SUPERSAMPLE / CANVAS_DP * LAYOUT_SCALE
    side = round(size * SUPERSAMPLE)
    img = Image.new("RGBA", (side, side), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    middle = side / 2

    def at(x, y):
        return (middle + (x - CENTER_X) * unit, middle + (y - CENTER_Y) * unit)

    def box(x0, y0, x1, y1):
        return [*at(x0, y0), *at(x1, y1)]

    font = fitted_font(font_path, "Hacker", HACKER_WIDTH * unit)
    hacker, elbow, news, cursor = colors
    d.text(at(HACKER_X, HACKER_BASELINE), "Hacker", font=font, fill=hacker, anchor="ls")
    half = ELBOW_WIDTH / 2
    d.rounded_rectangle(
        box(ELBOW_X - half, ELBOW_TOP, ELBOW_X + half, ELBOW_BOTTOM),
        radius=half * unit,
        fill=elbow,
    )
    d.rounded_rectangle(
        box(ELBOW_X - half, ELBOW_BOTTOM - ELBOW_WIDTH, ELBOW_END, ELBOW_BOTTOM),
        radius=half * unit,
        fill=elbow,
    )
    d.text(at(NEWS_X, NEWS_BASELINE), "News", font=font, fill=news, anchor="ls")
    cursor_x = NEWS_X + font.getlength("News") / unit + CURSOR_GAP
    d.rectangle(box(cursor_x, CURSOR_TOP, cursor_x + CURSOR_WIDTH, CURSOR_BOTTOM), fill=cursor)
    return img


def finish(img, size):
    return img.resize((size, size), Image.LANCZOS)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--out", default="tool/icon", type=Path)
    parser.add_argument("--size", default=1080, type=int)
    parser.add_argument("--font")
    args = parser.parse_args()
    args.out.mkdir(parents=True, exist_ok=True)

    foreground = draw_glyphs(args.size, args.font, (WHITE, SOFT, PEACH, WHITE))
    finish(foreground, args.size).save(args.out / "foreground.png")

    mono = draw_glyphs(args.size, args.font, (WHITE,) * 4)
    finish(mono, args.size).save(args.out / "monochrome.png")

    full = finish(foreground, round(args.size * CANVAS_DP / DP * LEGACY_SCALE))
    legacy = Image.new("RGBA", (args.size, args.size), ORANGE + (255,))
    corner = (args.size - full.width) // 2
    legacy.alpha_composite(full, (corner, corner))
    legacy.convert("RGB").save(args.out / "legacy.png")


if __name__ == "__main__":
    main()
