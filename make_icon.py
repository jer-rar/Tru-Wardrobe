from PIL import Image, ImageDraw

CANVAS = 1024
ACCENT = (193, 122, 91, 255)  # kAccentColor terracotta
BG = (18, 18, 20, 255)  # near-black, matches app's dark theme


RAW_POINTS = [
    (-0.16, 0.00),   # neck left
    (0.00, 0.16),    # neck dip (center) — concave, do not round
    (0.16, 0.00),    # neck right
    (0.34, 0.10),    # right shoulder — convex, round
    (0.95, 0.34),    # right sleeve outer tip — convex, round
    (0.52, 0.58),    # right underarm notch — concave, do not round
    (0.48, 1.30),    # right hem — convex, round
    (-0.48, 1.30),   # left hem — convex, round
    (-0.52, 0.58),   # left underarm notch — concave, do not round
    (-0.95, 0.34),   # left sleeve outer tip — convex, round
    (-0.34, 0.10),   # left shoulder — convex, round
]
# Indices of the convex (outward-pointing) corners — safe to fillet with a
# filled circle. Concave corners (neckline dip, underarm notches) are left
# sharp since rounding those would incorrectly fill in the intended notch.
ROUND_INDICES = [3, 4, 6, 7, 9, 10]


def shirt_polygon(cx, cy, scale):
    # Classic folded t-shirt silhouette: crew neckline, short sleeves,
    # straight hem. Symmetric, simple, unambiguous — reads as "clothing"
    # at a glance (unlike the hanger, which read as a volcano at small size).
    xs = [p[0] for p in RAW_POINTS]
    ys = [p[1] for p in RAW_POINTS]
    mid_x = (min(xs) + max(xs)) / 2
    mid_y = (min(ys) + max(ys)) / 2
    return [(cx + (x - mid_x) * scale, cy + (y - mid_y) * scale) for x, y in RAW_POINTS]


def draw_shirt(draw, cx, cy, scale, color):
    draw.polygon(shirt_polygon(cx, cy, scale), fill=color)


# --- Foreground layer (transparent, for adaptive icon) ---
fg = Image.new("RGBA", (CANVAS, CANVAS), (0, 0, 0, 0))
draw = ImageDraw.Draw(fg)
draw_shirt(draw, CANVAS // 2, CANVAS // 2, 340, ACCENT)
fg.save("assets/icon/icon_foreground.png", "PNG")

# --- Flat combined icon (background + foreground) for the main/legacy icon ---
flat = Image.new("RGBA", (CANVAS, CANVAS), BG)
draw2 = ImageDraw.Draw(flat)
draw_shirt(draw2, CANVAS // 2, CANVAS // 2, 280, ACCENT)
flat.save("assets/icon/icon.png", "PNG")

print("Icon assets generated.")
