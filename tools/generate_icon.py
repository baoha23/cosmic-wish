"""
Tạo icon PNG cho Cosmic Wish.
Chạy: python tools/generate_icon.py
Yêu cầu: pip install Pillow
"""
import math
from PIL import Image, ImageDraw, ImageFilter

COSMIC_BLACK = (13, 0, 20)
COSMIC_PURPLE = (26, 0, 51)
DEEP_PURPLE = (45, 0, 80)
GOLD = (255, 215, 0)
WHISPER_GOLD = (255, 233, 125)
SOFT_WHITE = (232, 217, 240)

def hex_to_rgb(h):
    h = h.lstrip('#')
    return tuple(int(h[i:i+2], 16) for i in (0, 2, 4))

def create_icon(size, filename):
    # Background gradient
    img = Image.new('RGBA', (size, size), COSMIC_BLACK + (255,))
    draw = ImageDraw.Draw(img)

    # Vertical gradient from cosmic_black → deep_purple
    for y in range(size):
        t = y / size
        r = int(COSMIC_BLACK[0] + (DEEP_PURPLE[0] - COSMIC_BLACK[0]) * t)
        g = int(COSMIC_BLACK[1] + (DEEP_PURPLE[1] - COSMIC_BLACK[1]) * t)
        b = int(COSMIC_BLACK[2] + (DEEP_PURPLE[2] - COSMIC_BLACK[2]) * t)
        draw.line([(0, y), (size, y)], fill=(r, g, b, 255))

    # Random stars
    import random
    random.seed(42)
    for _ in range(size * 2):
        x = random.randint(0, size)
        y = random.randint(0, size)
        r = random.choice([0, 0, 0, 1, 1, 2])
        a = random.randint(80, 200)
        draw.ellipse([x-r, y-r, x+r, y+r], fill=(*SOFT_WHITE, a))

    # Center hexagram / star (6-pointed) - cosmic symbol
    cx, cy = size / 2, size / 2
    outer = size * 0.30
    inner = size * 0.12

    # Two overlapping triangles (Star of David variant)
    points_up = []
    for i in range(3):
        a = -math.pi / 2 + i * 2 * math.pi / 3
        points_up.append((cx + outer * math.cos(a), cy + outer * math.sin(a)))
    points_down = []
    for i in range(3):
        a = math.pi / 2 + i * 2 * math.pi / 3
        points_down.append((cx + outer * math.cos(a), cy + outer * math.sin(a)))

    # Gold outer ring
    draw.ellipse([cx - outer * 1.2, cy - outer * 1.2, cx + outer * 1.2, cy + outer * 1.2],
                 outline=(*GOLD, 200), width=max(2, size // 64))

    # Glow
    glow_layer = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    glow_draw = ImageDraw.Draw(glow_layer)
    glow_draw.ellipse([cx - outer * 1.5, cy - outer * 1.5, cx + outer * 1.5, cy + outer * 1.5],
                      fill=(*GOLD, 60))
    glow_layer = glow_layer.filter(ImageFilter.GaussianBlur(size // 8))
    img = Image.alpha_composite(img, glow_layer)
    draw = ImageDraw.Draw(img)

    # Triangles
    draw.polygon(points_up, outline=(*GOLD, 240), width=max(2, size // 48))
    draw.polygon(points_down, outline=(*GOLD, 240), width=max(2, size // 48))

    # Center dot
    cr = max(2, size // 32)
    draw.ellipse([cx - cr, cy - cr, cx + cr, cy + cr], fill=(*WHISPER_GOLD, 255))

    # Outer thin circle
    draw.ellipse([cx - outer * 1.4, cy - outer * 1.4, cx + outer * 1.4, cy + outer * 1.4],
                 outline=(*GOLD, 80), width=1)

    img.save(filename, 'PNG')
    print(f"Created {filename} ({size}x{size})")

if __name__ == '__main__':
    create_icon(192, 'assets/icons/icon-192.png')
    create_icon(512, 'assets/icons/icon-512.png')
    create_icon(1024, 'assets/icons/icon-1024.png')
    create_icon(48, 'assets/icons/icon-48.png')
    create_icon(72, 'assets/icons/icon-72.png')
    create_icon(96, 'assets/icons/icon-96.png')
    create_icon(144, 'assets/icons/icon-144.png')
    create_icon(256, 'assets/icons/icon-256.png')
    print("Done!")
