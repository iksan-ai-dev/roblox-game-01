#!/usr/bin/env python3
"""Render Starfall Rush's three screenshots with Pillow.

There is no Roblox Studio on this Linux machine, so the screens are drawn
from the same numbers the Luau code uses: the same layout, palette, panel
sizes and text from src/shared/Config.luau and src/client/Interface.luau.
Each picture is 1280x720, the first by name is the cover, and each is saved
as a JPEG under 256 KiB.

Usage: python3 render_screenshots.py
"""

import math
import os

from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "screenshots")

W, H = 1280, 720
ARENA_X, ARENA_Y, ARENA_W, ARENA_H = 320, 120, 640, 480
BG_TOP = (11, 16, 38)
BG_BOTTOM = (30, 27, 75)
ARENA = (22, 33, 62)
ARENA_BORDER = (61, 90, 153)
STAR = (255, 209, 102)
METEOR = (239, 68, 68)
METEOR_DARK = (153, 27, 27)
HEART = (244, 114, 182)
SHIP = (34, 211, 238)
TEXT = (240, 244, 255)
MUTED = (148, 163, 184)
BUTTON = (34, 197, 94)
PANEL = (15, 23, 42)
GOLD = (250, 204, 21)
RED = (248, 113, 113)
WHITE = (255, 255, 255)
DARK_BAR = (30, 41, 59)

# The fixed starfield, copied from Config.luau's STARFIELD table.
STARFIELD = [
    (0.04, 0.07, 2), (0.11, 0.18, 1), (0.17, 0.05, 2), (0.24, 0.13, 1),
    (0.31, 0.06, 2), (0.38, 0.16, 1), (0.45, 0.04, 2), (0.53, 0.11, 1),
    (0.60, 0.06, 2), (0.67, 0.15, 1), (0.74, 0.05, 2), (0.81, 0.12, 1),
    (0.88, 0.06, 2), (0.95, 0.16, 1), (0.07, 0.32, 1), (0.14, 0.42, 2),
    (0.21, 0.30, 1), (0.28, 0.44, 2), (0.35, 0.31, 1), (0.42, 0.45, 2),
    (0.58, 0.30, 1), (0.65, 0.44, 2), (0.72, 0.31, 1), (0.79, 0.45, 2),
    (0.86, 0.32, 1), (0.93, 0.43, 2), (0.05, 0.62, 2), (0.12, 0.74, 1),
    (0.19, 0.88, 2), (0.27, 0.68, 1), (0.34, 0.82, 2), (0.41, 0.93, 1),
    (0.59, 0.66, 2), (0.66, 0.80, 1), (0.73, 0.92, 2), (0.80, 0.68, 1),
    (0.87, 0.83, 2), (0.94, 0.94, 1), (0.50, 0.90, 2), (0.97, 0.55, 1),
]

FONT_DIR = "/usr/share/fonts/truetype/dejavu"


def font(size, bold=True):
    name = "DejaVuSans-Bold.ttf" if bold else "DejaVuSans.ttf"
    return ImageFont.truetype(os.path.join(FONT_DIR, name), size)


def base():
    """Night-sky gradient with the fixed starfield, like the client draws."""
    img = Image.new("RGB", (W, H))
    px = img.load()
    for y in range(H):
        t = y / (H - 1)
        c = tuple(round(BG_TOP[i] + (BG_BOTTOM[i] - BG_TOP[i]) * t) for i in range(3))
        for x in range(W):
            px[x, y] = c
    d = ImageDraw.Draw(img, "RGBA")
    for sx, sy, r in STARFIELD:
        x, y = sx * W, sy * H
        d.ellipse([x - r, y - r, x + r, y + r], fill=(255, 255, 255, 165))
    return img, d


def arena_box(d):
    d.rectangle([ARENA_X, ARENA_Y, ARENA_X + ARENA_W, ARENA_Y + ARENA_H],
                fill=ARENA, outline=ARENA_BORDER, width=2)


def hud(d, score, lives, level, seconds_left):
    """Score, lives, level and time above the arena, plus the gold bar."""
    f26 = font(26)
    y = 48 + (56 - 26) // 2
    d.text((ARENA_X, y), f"SCORE {score}", font=f26, fill=TEXT)
    hearts = "♥" * lives if lives > 0 else "—"
    lw = d.textlength(hearts, font=f26)
    d.text((ARENA_X + 240 - lw / 2, y), hearts, font=f26, fill=HEART)
    lv = f"LEVEL {level}"
    lw = d.textlength(lv, font=f26)
    d.text((ARENA_X + 400 - lw / 2, y), lv, font=f26, fill=TEXT)
    t = f"{seconds_left // 60}:{seconds_left % 60:02d}"
    tw = d.textlength(t, font=f26)
    d.text((ARENA_X + ARENA_W - tw, y), t, font=f26, fill=TEXT)
    d.rectangle([ARENA_X, 108, ARENA_X + ARENA_W, 114], fill=DARK_BAR)
    fill_w = round(ARENA_W * min(score, 500) / 500)
    if fill_w:
        d.rectangle([ARENA_X, 108, ARENA_X + fill_w, 114], fill=GOLD)


def ship(d, left_x):
    top = ARENA_Y + ARENA_H - 36 - 28
    d.rounded_rectangle([left_x, top, left_x + 64, top + 28], radius=10, fill=SHIP)
    d.rounded_rectangle([left_x + 21, top, left_x + 43, top + 12], radius=6, fill=WHITE)


def star_glyph(d, cx, cy, size=28):
    f = font(size)
    d.text((cx, cy), "★", font=f, fill=STAR, anchor="mm")


def meteor(d, cx, cy, r=16):
    d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=METEOR)
    d.ellipse([cx - r * 0.65, cy - r * 0.65, cx - r * 0.05, cy - r * 0.05],
              fill=METEOR_DARK)


def heart_glyph(d, cx, cy, size=28):
    f = font(size)
    d.text((cx, cy), "♥", font=f, fill=HEART, anchor="mm")


def panel(d, x, y, w, h, border=GOLD):
    d.rounded_rectangle([x, y, x + w, y + h], radius=16, fill=PANEL,
                        outline=border, width=2)


def centred_text(d, cx, y, text, size, color, bold=True):
    f = font(size, bold)
    d.text((cx, y), text, font=f, fill=color, anchor="ma")


def green_button(d, cx, y, w, h, text, size=28):
    d.rounded_rectangle([cx - w / 2, y, cx + w / 2, y + h], radius=12, fill=BUTTON)
    f = font(size)
    d.text((cx, y + h / 2), text, font=f, fill=WHITE, anchor="mm")


def start_screen():
    img, d = base()
    hud(d, 0, 3, 1, 90)
    arena_box(d)
    ship(d, 608)
    px, py, pw, ph = 360, 150, 560, 420
    panel(d, px, py, pw, ph)
    centred_text(d, 640, py + 28, "STARFALL RUSH", 52, GOLD)
    centred_text(d, 640, py + 100, "Catch the stars. Dodge the meteors.", 22, TEXT, bold=False)
    lines = ["◀ ▶  or  A / D  to steer your ship",
             "★  Gold star  =  +10 points  —  500 wins",
             "☄  Red meteor  =  −1 life  —  3 lives, 90 seconds"]
    f20 = font(20, bold=False)
    for i, line in enumerate(lines):
        d.text((640, py + 150 + i * 30), line, font=f20, fill=MUTED, anchor="ma")
    green_button(d, 640, py + 268, 240, 64, "▶  PLAY")
    centred_text(d, 640, py + 348, "Best: 0", 20, MUTED, bold=False)
    return img


def play_screen():
    img, d = base()
    hud(d, 120, 3, 2, 42)
    arena_box(d)
    star_glyph(d, 430, 230)
    star_glyph(d, 700, 200)
    star_glyph(d, 860, 330)
    star_glyph(d, 640, 500)
    meteor(d, 520, 330)
    meteor(d, 790, 450)
    heart_glyph(d, 900, 210)
    ship(d, 608)
    f24 = font(24)
    d.text((640, 460), "+10", font=f24, fill=GOLD, anchor="mm")
    return img


def end_screen():
    img, d = base()
    # Won by score with 17 seconds still on the clock, one life left.
    hud(d, 520, 1, 5, 17)
    arena_box(d)
    # The round is over, so the falling items are cleared; only the ship
    # stays, where the player left it at the bottom-left of the arena.
    ship(d, 340)
    px, py, pw, ph = 400, 180, 480, 360
    panel(d, px, py, pw, ph)
    centred_text(d, 640, py + 36, "YOU WIN!", 48, GOLD)
    centred_text(d, 640, py + 116, "Score: 520", 28, TEXT)
    centred_text(d, 640, py + 164, "Best: 520", 22, MUTED, bold=False)
    green_button(d, 640, py + 224, 240, 56, "↻  PLAY AGAIN", size=24)
    return img


def main():
    os.makedirs(OUT, exist_ok=True)
    for name, fn in [("1-start.jpg", start_screen),
                     ("2-play.jpg", play_screen),
                     ("3-end.jpg", end_screen)]:
        img = fn()
        path = os.path.join(OUT, name)
        img.save(path, "JPEG", quality=85, optimize=True)
        size = os.path.getsize(path)
        print(f"{name}: {img.size[0]}x{img.size[1]}, {size} bytes")
        assert size <= 262144, f"{name} over 256 KiB"


if __name__ == "__main__":
    main()
