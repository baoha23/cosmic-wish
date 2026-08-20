"""
Generate a stylized prayer hands icon for Cosmic Wish.
200x200 PNG, gold tint, transparent BG.

We use Pillow's ImageDraw.arc + polygon-with-many-points to render
smooth curves. Each hand is built from a single closed path with 4
fingers and a thumb curving inward.
"""
import math
from PIL import Image, ImageDraw, ImageFilter

SIZE = 400
GOLD = (255, 215, 0)
GOLD_DARK = (200, 162, 0)
GOLD_LIGHT = (255, 235, 130)
HIGHLIGHT = (255, 250, 220)
SEAM = (255, 240, 180)
SHADOW = (110, 80, 0)


def _sample_quad(p0, p1, p2, n=24):
    """Sample a quadratic Bezier curve into a list of points."""
    pts = []
    for i in range(n + 1):
        t = i / n
        x = (1 - t) ** 2 * p0[0] + 2 * (1 - t) * t * p1[0] + t ** 2 * p2[0]
        y = (1 - t) ** 2 * p0[1] + 2 * (1 - t) * t * p1[1] + t ** 2 * p2[1]
        pts.append((x, y))
    return pts


def _sample_cubic(p0, p1, p2, p3, n=24):
    pts = []
    for i in range(n + 1):
        t = i / n
        x = ((1 - t) ** 3 * p0[0] + 3 * (1 - t) ** 2 * t * p1[0]
             + 3 * (1 - t) * t ** 2 * p2[0] + t ** 3 * p3[0])
        y = ((1 - t) ** 3 * p0[1] + 3 * (1 - t) ** 2 * t * p1[1]
             + 3 * (1 - t) * t ** 2 * p2[1] + t ** 3 * p3[1])
        pts.append((x, y))
    return pts


def _arc(cx, cy, rx, ry, start_deg, end_deg, n=40):
    """Sample an elliptical arc into points."""
    pts = []
    for i in range(n + 1):
        t = start_deg + (end_deg - start_deg) * (i / n)
        rad = math.radians(t)
        pts.append((cx + rx * math.cos(rad), cy + ry * math.sin(rad)))
    return pts


def build_hand_outline(side, hand_w=32, hand_h=88):
    """
    Return a list of (x,y) points outlining one hand silhouette, with
    smooth Bezier curves. Local coords: seam at x=0, top of fingers at
    y=0, wrist at y=hand_h. side = -1 (left) or +1 (right).
    """
    pts = []

    # Start: wrist center
    pts.append((0, hand_h))

    # === Wrist bottom -> outer side ===
    pts += _sample_cubic(
        (0, hand_h),
        (side * hand_w * 0.45, hand_h),
        (side * hand_w * 0.85, hand_h - 2),
        (side * hand_w, hand_h - 10),
    )

    # === Up the outer (pinky) side ===
    pts += _sample_cubic(
        (side * hand_w, hand_h - 10),
        (side * hand_w * 1.02, 30),
        (side * hand_w * 1.02, 20),
        (side * hand_w * 0.98, 12),
    )

    # === Pinky finger (shortest) — bump out then back ===
    # base at (side*hand_w*0.98, 12), tip at (side*hand_w*0.78, 0)
    pts += _sample_cubic(
        (side * hand_w * 0.98, 12),
        (side * hand_w * 0.95, 4),
        (side * hand_w * 0.86, -2),
        (side * hand_w * 0.75, -2),
    )
    pts += _sample_cubic(
        (side * hand_w * 0.75, -2),
        (side * hand_w * 0.65, -2),
        (side * hand_w * 0.58, 8),
        (side * hand_w * 0.58, 14),
    )

    # === Ring finger (medium) ===
    pts += _sample_cubic(
        (side * hand_w * 0.58, 14),
        (side * hand_w * 0.58, 2),
        (side * hand_w * 0.50, -8),
        (side * hand_w * 0.38, -8),
    )
    pts += _sample_cubic(
        (side * hand_w * 0.38, -8),
        (side * hand_w * 0.26, -8),
        (side * hand_w * 0.20, 8),
        (side * hand_w * 0.20, 16),
    )

    # === Middle finger (longest) ===
    pts += _sample_cubic(
        (side * hand_w * 0.20, 16),
        (side * hand_w * 0.20, 0),
        (side * hand_w * 0.12, -12),
        (side * hand_w * -0.02, -12),
    )
    pts += _sample_cubic(
        (side * hand_w * -0.02, -12),
        (side * hand_w * -0.16, -12),
        (side * hand_w * -0.22, 6),
        (side * hand_w * -0.22, 18),
    )

    # === Index finger (slightly shorter than middle) ===
    pts += _sample_cubic(
        (side * hand_w * -0.22, 18),
        (side * hand_w * -0.22, 4),
        (side * hand_w * -0.30, -6),
        (side * hand_w * -0.42, -6),
    )
    pts += _sample_cubic(
        (side * hand_w * -0.42, -6),
        (side * hand_w * -0.54, -6),
        (side * hand_w * -0.58, 12),
        (side * hand_w * -0.58, 22),
    )

    # === Thumb: stubby, curving inward across the palm ===
    pts += _sample_cubic(
        (side * hand_w * -0.58, 22),
        (side * hand_w * -0.58, 32),
        (side * hand_w * -0.35, 40),
        (side * hand_w * -0.08, 38),
    )
    pts += _sample_cubic(
        (side * hand_w * -0.08, 38),
        (side * hand_w * 0.05, 36),
        (side * hand_w * 0.02, 28),
        (0, 22),
    )

    # === Down the seam ===
    pts += _sample_cubic(
        (0, 22),
        (0, hand_h * 0.5),
        (0, hand_h * 0.8),
        (0, hand_h),
    )

    return pts


def main():
    img = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
    cx, cy = SIZE / 2, SIZE / 2

    # === Outer glow ===
    glow = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    for r, alpha in [(int(SIZE*0.18), 8), (int(SIZE*0.15), 18), (int(SIZE*0.13), 35), (int(SIZE*0.11), 55), (int(SIZE*0.09), 75)]:
        gd.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(255, 215, 0, alpha))
    glow = glow.filter(ImageFilter.GaussianBlur(radius=5))
    img.alpha_composite(glow)

    draw = ImageDraw.Draw(img)

    hand_w = 100
    hand_h = 240
    wrist_y = cy + 70
    hand_top_y = wrist_y - hand_h

    # Shadows first
    for side in [-1, 1]:
        pts = build_hand_outline(side, hand_w, hand_h)
        shadow_pts = [(p[0] + cx + 1, p[1] + hand_top_y + 2) for p in pts]
        draw.polygon(shadow_pts, fill=SHADOW + (140,))

    # Main hand fills
    for side in [-1, 1]:
        pts = build_hand_outline(side, hand_w, hand_h)
        global_pts = [(p[0] + cx, p[1] + hand_top_y) for p in pts]
        color = GOLD if side == -1 else GOLD_DARK
        draw.polygon(global_pts, fill=color + (255,))

    # Outlines
    for side in [-1, 1]:
        pts = build_hand_outline(side, hand_w, hand_h)
        global_pts = [(p[0] + cx, p[1] + hand_top_y) for p in pts]
        for i in range(len(global_pts)):
            a = global_pts[i]
            b = global_pts[(i + 1) % len(global_pts)]
            draw.line([a, b], fill=GOLD_LIGHT + (180,), width=1)

    # Center seam
    seam_top_y = hand_top_y + 4
    seam_bot_y = wrist_y - 4
    draw.line([(cx, seam_top_y), (cx, seam_bot_y)], fill=SEAM + (220,), width=1)
    # Highlight streak
    for i, alpha in enumerate([180, 130, 80]):
        x = cx + (i - 1)
        draw.line(
            [(x, seam_top_y + 4), (x, seam_bot_y - 6)],
            fill=(255, 250, 220, alpha),
            width=1,
        )

    # Prayer bead
    bead_y = seam_bot_y + 1
    draw.ellipse([cx - 2.5, bead_y - 2.5, cx + 2.5, bead_y + 2.5], fill=GOLD_LIGHT + (255,))

    img.save('assets/images/praying_hands.png')
    print(f"Saved assets/images/praying_hands.png ({SIZE}x{SIZE})")


if __name__ == '__main__':
    main()
