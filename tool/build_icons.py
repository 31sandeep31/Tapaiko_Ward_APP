"""Generates the launcher icons, splash icon and Play Store graphics.

Usage (from the repo root):  python tool/build_icons.py
Requires: Pillow.
"""

from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parent.parent
RES = ROOT / 'android' / 'app' / 'src' / 'main' / 'res'
STORE = ROOT / 'store'

BLUE_TOP = (31, 87, 195)
BLUE = (0, 56, 147)
CRIMSON = (220, 20, 60)
WHITE = (255, 255, 255)
SS = 4  # supersampling factor

DENSITIES = {'mdpi': 1, 'hdpi': 1.5, 'xhdpi': 2, 'xxhdpi': 3, 'xxxhdpi': 4}


def gradient(size: int) -> Image.Image:
    img = Image.new('RGB', (size, size))
    px = img.load()
    for y in range(size):
        for x in range(size):
            t = (x + y) / (2 * (size - 1))
            px[x, y] = tuple(round(a + (b - a) * t) for a, b in zip(BLUE_TOP, BLUE))
    return img


def draw_pin(size: int, scale: float, color=WHITE, dot=CRIMSON,
             shadow=True) -> Image.Image:
    """Map pin centred in a transparent square canvas.

    `scale` is the pin height as a fraction of the canvas.
    """
    s = size * SS
    layer = Image.new('RGBA', (s, s), (0, 0, 0, 0))
    h = s * scale
    r = h * 0.36                      # head radius
    cx = s / 2
    cy = s / 2 - h / 2 + r            # head centre
    tip = (cx, s / 2 + h / 2)

    def pin_shape(d: ImageDraw.ImageDraw, fill, dx=0.0, dy=0.0):
        d.ellipse([cx - r + dx, cy - r + dy, cx + r + dx, cy + r + dy], fill=fill)
        # Tangent lines from tip to the head circle.
        dist = tip[1] - cy
        ang = math.asin(r / dist)
        a1 = math.pi / 2 + ang
        a2 = math.pi / 2 - ang
        p1 = (cx + r * math.cos(a1 + math.pi) * -1, 0)
        # tangent points
        t = math.acos(r / dist)
        left = (cx - r * math.sin(t) + dx, cy + r * math.cos(t) + dy)
        right = (cx + r * math.sin(t) + dx, cy + r * math.cos(t) + dy)
        d.polygon([left, right, (tip[0] + dx, tip[1] + dy)], fill=fill)
        del p1, a1, a2

    if shadow:
        sh = Image.new('RGBA', (s, s), (0, 0, 0, 0))
        pin_shape(ImageDraw.Draw(sh), (0, 0, 0, 70), dy=s * 0.012)
        sh = sh.filter(ImageFilter.GaussianBlur(s * 0.015))
        layer.alpha_composite(sh)
    d = ImageDraw.Draw(layer)
    pin_shape(d, color)
    if dot is not None:
        dr = r * 0.42
        d.ellipse([cx - dr, cy - dr, cx + dr, cy + dr], fill=dot)
    return layer.resize((size, size), Image.LANCZOS)


def rounded_mask(size: int, radius_frac: float) -> Image.Image:
    m = Image.new('L', (size * SS, size * SS), 0)
    ImageDraw.Draw(m).rounded_rectangle(
        [0, 0, size * SS - 1, size * SS - 1], radius=size * SS * radius_frac, fill=255)
    return m.resize((size, size), Image.LANCZOS)


def circle_mask(size: int) -> Image.Image:
    m = Image.new('L', (size * SS, size * SS), 0)
    ImageDraw.Draw(m).ellipse([0, 0, size * SS - 1, size * SS - 1], fill=255)
    return m.resize((size, size), Image.LANCZOS)


def full_icon(size: int, shape: str = 'square') -> Image.Image:
    bg = gradient(size).convert('RGBA')
    bg.alpha_composite(draw_pin(size, 0.62))
    mask = circle_mask(size) if shape == 'circle' else rounded_mask(size, 0.22)
    out = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    out.paste(bg, (0, 0), mask)
    return out


def save(img: Image.Image, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    img.save(path, optimize=True)
    print('wrote', path.relative_to(ROOT))


def main() -> None:
    for name, d in DENSITIES.items():
        legacy = round(48 * d)
        save(full_icon(legacy), RES / f'mipmap-{name}' / 'ic_launcher.png')
        save(full_icon(legacy, 'circle'), RES / f'mipmap-{name}' / 'ic_launcher_round.png')
        adaptive = round(108 * d)
        # Foreground lives inside the 66dp safe zone of the 108dp canvas.
        save(draw_pin(adaptive, 0.42), RES / f'mipmap-{name}' / 'ic_launcher_foreground.png')
        save(draw_pin(adaptive, 0.42, color=WHITE, dot=(0, 0, 0, 0), shadow=False),
             RES / f'mipmap-{name}' / 'ic_launcher_monochrome.png')
        # Android 12+ splash icon: 288dp canvas, icon within the 192dp circle.
        splash = round(288 * d)
        save(draw_pin(splash, 0.40), RES / f'drawable-{name}' / 'splash_icon.png')
        # Pre-12 splash: centred logo bitmap.
        save(full_icon(round(120 * d)), RES / f'drawable-{name}' / 'launch_logo.png')

    # Play Store assets.
    save(full_icon(512).convert('RGBA'), STORE / 'icon-512.png')
    feature = gradient(1024).resize((1024, 500)).convert('RGBA')
    grid = Image.new('RGBA', feature.size, (0, 0, 0, 0))
    g = ImageDraw.Draw(grid)
    # Subtle map grid.
    for x in range(0, 1024, 64):
        g.line([(x, 0), (x, 500)], fill=(255, 255, 255, 22), width=1)
    for y in range(0, 500, 64):
        g.line([(0, y), (1024, y)], fill=(255, 255, 255, 22), width=1)
    feature.alpha_composite(grid)
    feature.alpha_composite(draw_pin(340, 0.8), (60, 80))
    d = ImageDraw.Draw(feature)
    try:
        title = ImageFont.truetype('segoeuib.ttf', 76)
        sub = ImageFont.truetype('segoeui.ttf', 32)
        nep = ImageFont.truetype('Nirmala.ttc', 42)
    except OSError:
        title = sub = nep = ImageFont.load_default()
    d.text((420, 140), 'Tapaiko Ward', font=title, fill=WHITE)
    d.text((424, 248), 'Find your ward anywhere in Nepal', font=sub, fill=(220, 230, 255))
    d.text((424, 300), 'तपाईंको वडा', font=nep, fill=WHITE)
    save(feature.convert('RGB'), STORE / 'feature-graphic-1024x500.png')


if __name__ == '__main__':
    main()
