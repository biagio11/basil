"""Generates Basil's pixel-art icons (Android + web) from the 16x16 leaf grid.

Run:  python tool/make_icons.py   (needs Pillow)
"""
import os
from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

GRID = [
    '................',
    '............ooo.',
    '.........ooolvo.',
    '......ooollgvdo.',
    '.....olvgggvdo..',
    '....olggvgvdvo..',
    '...olggggvdddo..',
    '...ovgggvdddo...',
    '...olvgvdvddo...',
    '..olggvdddvo....',
    '..oggvdddddo....',
    '..ogvdvdddo.....',
    '..ovdddvoo......',
    '..sooooo........',
    '.s..............',
    's...............',
]
PAL = {
    'o': (28, 122, 58), 'd': (22, 110, 48), 'g': (46, 170, 74),
    'l': (140, 255, 150), 'v': (18, 96, 42), 's': (46, 170, 74),
}
BG = (6, 11, 7)
GRIDLINE = (14, 34, 20)


def leaf(px):
    img = Image.new('RGBA', (16 * px, 16 * px), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    for y, row in enumerate(GRID):
        for x, c in enumerate(row):
            if c in PAL:
                d.rectangle([x * px, y * px, (x + 1) * px - 1, (y + 1) * px - 1], fill=PAL[c] + (255,))
    return img


def icon(size, fill=0.78, bg=True, round_=0.0, grid=True):
    """Leaf centred on a dark square; `fill` = fraction of the side used by the leaf."""
    px = max(1, int(size * fill) // 16)
    lf = leaf(px)
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    if bg:
        base = Image.new('RGBA', (size, size), BG + (255,))
        if grid and size >= 96:
            d = ImageDraw.Draw(base)
            step = max(4, size // 24)
            for i in range(0, size, step):
                d.line([(i, 0), (i, size)], fill=GRIDLINE + (255,))
                d.line([(0, i), (size, i)], fill=GRIDLINE + (255,))
        if round_ > 0:
            mask = Image.new('L', (size, size), 0)
            ImageDraw.Draw(mask).rounded_rectangle([0, 0, size - 1, size - 1], radius=int(size * round_), fill=255)
            img.paste(base, (0, 0), mask)
        else:
            img = base
    off = ((size - lf.width) // 2, (size - lf.height) // 2)
    img.alpha_composite(lf, off)
    return img


def save(img, *parts):
    p = os.path.join(ROOT, *parts)
    os.makedirs(os.path.dirname(p), exist_ok=True)
    img.save(p, optimize=True)
    print('wrote', os.path.relpath(p, ROOT))


# --- Web --------------------------------------------------------------------
save(icon(32, fill=1.0, grid=False, round_=0.18), 'web', 'favicon.png')
save(icon(192, round_=0.0), 'web', 'icons', 'Icon-192.png')
save(icon(512, round_=0.0), 'web', 'icons', 'Icon-512.png')
save(icon(192, fill=0.6), 'web', 'icons', 'Icon-maskable-192.png')
save(icon(512, fill=0.6), 'web', 'icons', 'Icon-maskable-512.png')
save(icon(180, fill=0.72), 'web', 'icons', 'apple-touch-icon.png')
save(icon(1200, fill=0.5), 'web', 'icons', 'og-image.png')

# --- Android legacy + adaptive -------------------------------------------------
dens = {'mdpi': 1, 'hdpi': 1.5, 'xhdpi': 2, 'xxhdpi': 3, 'xxxhdpi': 4}
for name, k in dens.items():
    s = int(48 * k)
    save(icon(s, fill=0.75, round_=0.2), 'android', 'app', 'src', 'main', 'res', f'mipmap-{name}', 'ic_launcher.png')
    fg = int(108 * k)
    save(icon(fg, fill=0.5, bg=False), 'android', 'app', 'src', 'main', 'res', f'mipmap-{name}', 'ic_launcher_foreground.png')
