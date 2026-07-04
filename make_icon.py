from PIL import Image, ImageDraw

CANVAS = 1024
ACCENT = (193, 122, 91, 255)  # kAccentColor terracotta
BG = (18, 18, 20, 255)  # near-black, matches app's dark theme


def hanger_path(draw, cx, cy, scale, color, width):
    r = width // 2

    # Hook: a clean closed ring centered above the vertex — classic, symmetric.
    hook_r = int(70 * scale)
    hook_cy = cy - int(230 * scale)
    bbox = [cx - hook_r, hook_cy - hook_r, cx + hook_r, hook_cy + hook_r]
    draw.ellipse(bbox, outline=color, width=width)

    # Neck: straight vertical line from the bottom of the hook to the vertex.
    neck_top = (cx, hook_cy + hook_r)
    vertex = (cx, cy - int(90 * scale))
    draw.line([neck_top, vertex], fill=color, width=width)

    # Body: symmetric wide V that clothes rest on.
    left = (cx - int(300 * scale), cy + int(130 * scale))
    right = (cx + int(300 * scale), cy + int(130 * scale))
    draw.line([vertex, left], fill=color, width=width)
    draw.line([vertex, right], fill=color, width=width)

    # Round every joint so strokes read as one continuous, deliberate shape.
    for pt in [neck_top, vertex, left, right]:
        draw.ellipse([pt[0] - r, pt[1] - r, pt[0] + r, pt[1] + r], fill=color)


# --- Foreground layer (transparent, for adaptive icon) ---
fg = Image.new("RGBA", (CANVAS, CANVAS), (0, 0, 0, 0))
draw = ImageDraw.Draw(fg)
hanger_path(draw, CANVAS // 2, CANVAS // 2 + 10, 0.9, ACCENT, 42)
fg.save("assets/icon/icon_foreground.png", "PNG")

# --- Flat combined icon (background + foreground) for the main/legacy icon ---
flat = Image.new("RGBA", (CANVAS, CANVAS), BG)
draw2 = ImageDraw.Draw(flat)
hanger_path(draw2, CANVAS // 2, CANVAS // 2 + 10, 0.75, ACCENT, 36)
flat.save("assets/icon/icon.png", "PNG")

print("Icon assets generated.")
