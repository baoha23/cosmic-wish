"""
Tạo adaptive icon (foreground + background) cho Android.
"""
import math
from PIL import Image, ImageDraw, ImageFilter

COSMIC_BLACK = (13, 0, 20)
DEEP_PURPLE = (45, 0, 80)
GOLD = (255, 215, 0)
WHISPER_GOLD = (255, 233, 125)
SOFT_WHITE = (232, 217, 240)

def hex_to_rgb(h):
    h = h.lstrip('#')
    return tuple(int(h[i:i+2], 16) for i in (0, 2, 4))

def gradient_bg(size, filename):
    img = Image.new('RGBA', (size, size), COSMIC_BLACK + (255,))
    draw = ImageDraw.Draw(img)
    for y in range(size):
        t = y / size
        r = int(COSMIC_BLACK[0] + (DEEP_PURPLE[0] - COSMIC_BLACK[0]) * t)
        g = int(COSMIC_BLACK[1] + (DEEP_PURPLE[1] - COSMIC_BLACK[1]) * t)
        b = int(COSMIC_BLACK[2] + (DEEP_PURPLE[2] - COSMIC_BLACK[2]) * t)
        draw.line([(0, y), (size, y)], fill=(r, g, b, 255))
    img.save(filename, 'PNG')
    print(f"Created {filename}")

def create_foreground(size, filename):
    # Transparent background, 66% safe zone in center
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    cx, cy = size / 2, size / 2
    outer = size * 0.22  # smaller to fit in safe zone
    inner = size * 0.09

    # Glow
    glow = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    gd.ellipse([cx - outer * 1.6, cy - outer * 1.6, cx + outer * 1.6, cy + outer * 1.6],
               fill=(*GOLD, 80))
    glow = glow.filter(ImageFilter.GaussianBlur(size // 10))
    img = Image.alpha_composite(img, glow)
    draw = ImageDraw.Draw(img)

    # Ring
    draw.ellipse([cx - outer * 1.25, cy - outer * 1.25, cx + outer * 1.25, cy + outer * 1.25],
                 outline=(*GOLD, 220), width=max(2, size // 64))

    # Hexagram
    points_up = []
    for i in range(3):
        a = -math.pi / 2 + i * 2 * math.pi / 3
        points_up.append((cx + outer * math.cos(a), cy + outer * math.sin(a)))
    points_down = []
    for i in range(3):
        a = math.pi / 2 + i * 2 * math.pi / 3
        points_down.append((cx + outer * math.cos(a), cy + outer * math.sin(a)))

    draw.polygon(points_up, outline=(*GOLD, 255), width=max(2, size // 56))
    draw.polygon(points_down, outline=(*GOLD, 255), width=max(2, size // 56))

    # Center dot
    cr = max(2, size // 40)
    draw.ellipse([cx - cr, cy - cr, cx + cr, cy + cr], fill=(*WHISPER_GOLD, 255))

    img.save(filename, 'PNG')
    print(f"Created {filename}")

if __name__ == '__main__':
    gradient_bg(512, 'assets/icons/adaptive_background.png')
    create_foreground(512, 'assets/icons/adaptive_foreground.png')
