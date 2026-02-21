#!/usr/bin/env python3
"""
Generate cartoon sprite assets for Cows in the Ditch.
Draws at 4x supersampled resolution, then downscales with LANCZOS for anti-aliased edges.
Outputs @2x and @3x PNGs into Assets.xcassets/ image sets.
"""

import os
import json
import math
from PIL import Image, ImageDraw, ImageFont, ImageFilter

ASSETS_DIR = os.path.join(os.path.dirname(__file__), "CowsInTheDitch", "Assets.xcassets")
SUPERSAMPLE = 4  # Draw at 4x, downsample for AA


def ensure_imageset(name):
    """Create an .imageset directory with Contents.json for @2x and @3x."""
    d = os.path.join(ASSETS_DIR, f"{name}.imageset")
    os.makedirs(d, exist_ok=True)
    contents = {
        "images": [
            {"filename": f"{name}@2x.png", "idiom": "universal", "scale": "2x"},
            {"filename": f"{name}@3x.png", "idiom": "universal", "scale": "3x"},
        ],
        "info": {"author": "xcode", "version": 1},
    }
    with open(os.path.join(d, "Contents.json"), "w") as f:
        json.dump(contents, f, indent=2)
    return d


def save_asset(img_at3x, name):
    """Save @3x image and create @2x by downscaling. img_at3x is at final @3x size."""
    d = ensure_imageset(name)
    img_at3x.save(os.path.join(d, f"{name}@3x.png"))
    w2 = int(img_at3x.width * 2 / 3)
    h2 = int(img_at3x.height * 2 / 3)
    img_at2x = img_at3x.resize((w2, h2), Image.LANCZOS)
    img_at2x.save(os.path.join(d, f"{name}@2x.png"))


def supersample_draw(w3x, h3x, draw_func):
    """Draw at SUPERSAMPLE*@3x resolution, then downsample to @3x."""
    sw, sh = w3x * SUPERSAMPLE, h3x * SUPERSAMPLE
    img = Image.new("RGBA", (sw, sh), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    draw_func(img, draw, sw, sh, SUPERSAMPLE)
    return img.resize((w3x, h3x), Image.LANCZOS)


def outlined_ellipse(draw, bbox, fill, outline, outline_w, s):
    """Draw an ellipse with thick outline (draw outline ellipse first, then fill)."""
    ox, oy, ox2, oy2 = bbox
    draw.ellipse([ox - outline_w * s, oy - outline_w * s,
                  ox2 + outline_w * s, oy2 + outline_w * s], fill=outline)
    draw.ellipse(bbox, fill=fill)


def outlined_rect(draw, bbox, fill, outline, outline_w, s):
    """Draw a rectangle with thick outline."""
    ox, oy, ox2, oy2 = bbox
    draw.rounded_rectangle([ox - outline_w * s, oy - outline_w * s,
                            ox2 + outline_w * s, oy2 + outline_w * s],
                           radius=2 * s, fill=outline)
    draw.rounded_rectangle(bbox, radius=2 * s, fill=fill)


def outlined_circle(draw, cx, cy, r, fill, outline, outline_w, s):
    outlined_ellipse(draw, [cx - r, cy - r, cx + r, cy + r], fill, outline, outline_w, s)


# ── COW SPRITES ──

def draw_cow(img, draw, w, h, s, variant=1):
    cx, cy = w // 2, h // 2
    # Body
    bw, bh = 48 * s, 34 * s
    outlined_ellipse(draw, [cx - bw, cy - bh + 4 * s, cx + bw, cy + bh + 4 * s],
                     fill=(255, 255, 255), outline=(40, 40, 40), outline_w=2, s=s)
    # Spots
    import random
    random.seed(variant * 42)
    for _ in range(4):
        sx = cx + random.randint(-30 * s, 30 * s)
        sy = cy + random.randint(-15 * s, 15 * s)
        sr = random.randint(6 * s, 12 * s)
        draw.ellipse([sx - sr, sy - sr // 2, sx + sr, sy + sr // 2], fill=(30, 30, 30, 200))
    # Legs
    leg_color = (60, 60, 60)
    for lx in [-28, -10, 10, 28]:
        lx_abs = cx + lx * s
        ly_top = cy + 20 * s
        ly_bot = cy + 40 * s
        draw.rounded_rectangle([lx_abs - 4 * s, ly_top, lx_abs + 4 * s, ly_bot],
                               radius=2 * s, fill=leg_color)
        # Hooves
        draw.rounded_rectangle([lx_abs - 5 * s, ly_bot - 4 * s, lx_abs + 5 * s, ly_bot + 2 * s],
                               radius=2 * s, fill=(80, 60, 40))
    # Head
    head_cy = cy - 26 * s
    outlined_circle(draw, cx, head_cy, 16 * s, fill=(255, 255, 255), outline=(40, 40, 40),
                    outline_w=2, s=s)
    # Snout
    outlined_ellipse(draw, [cx - 10 * s, head_cy + 2 * s, cx + 10 * s, head_cy + 14 * s],
                     fill=(255, 210, 180), outline=(40, 40, 40), outline_w=1, s=s)
    # Nostrils
    draw.ellipse([cx - 5 * s, head_cy + 6 * s, cx - 2 * s, head_cy + 10 * s], fill=(80, 50, 50))
    draw.ellipse([cx + 2 * s, head_cy + 6 * s, cx + 5 * s, head_cy + 10 * s], fill=(80, 50, 50))
    # Eyes
    for ex in [-7, 7]:
        ex_abs = cx + ex * s
        ey = head_cy - 4 * s
        # White
        draw.ellipse([ex_abs - 5 * s, ey - 5 * s, ex_abs + 5 * s, ey + 5 * s], fill=(255, 255, 255))
        draw.ellipse([ex_abs - 5 * s, ey - 5 * s, ex_abs + 5 * s, ey + 5 * s], outline=(40, 40, 40), width=s)
        # Pupil
        draw.ellipse([ex_abs - 2 * s, ey - 3 * s, ex_abs + 2 * s, ey + 3 * s], fill=(20, 20, 20))
        # Highlight
        draw.ellipse([ex_abs - 1 * s, ey - 3 * s, ex_abs + 1 * s, ey - 1 * s], fill=(255, 255, 255))
    # Horns
    for hx in [-10, 10]:
        hx_abs = cx + hx * s
        hy = head_cy - 14 * s
        draw.polygon([
            (hx_abs - 3 * s, head_cy - 10 * s),
            (hx_abs + (3 if hx > 0 else -3) * s, hy - 8 * s),
            (hx_abs + 3 * s, head_cy - 10 * s),
        ], fill=(220, 190, 130), outline=(40, 40, 40))
    # Ears
    for ex_sign in [-1, 1]:
        ear_cx = cx + ex_sign * 15 * s
        ear_cy = head_cy - 6 * s
        draw.ellipse([ear_cx - 5 * s, ear_cy - 3 * s, ear_cx + 5 * s, ear_cy + 3 * s],
                     fill=(255, 220, 200), outline=(40, 40, 40), width=s)
    # Tail
    tx = cx + 46 * s
    ty = cy - 5 * s
    points = []
    for i in range(20):
        t = i / 19.0
        px = tx + int(t * 12 * s)
        py = ty + int(math.sin(t * math.pi * 2) * 8 * s) - int(t * 15 * s)
        points.append((px, py))
    if len(points) > 1:
        draw.line(points, fill=(60, 60, 60), width=2 * s)
        # Tuft
        tp = points[-1]
        draw.ellipse([tp[0] - 4 * s, tp[1] - 4 * s, tp[0] + 4 * s, tp[1] + 4 * s], fill=(30, 30, 30))


def generate_cow_walk():
    for variant in [1, 2]:
        img = supersample_draw(156, 132, lambda i, d, w, h, s: draw_cow(i, d, w, h, s, variant))
        save_asset(img, f"cow_walk_{variant}")


def generate_cow_drowning():
    def draw_fn(img, draw, w, h, s):
        cx, cy = w // 2, h // 2 - 8 * s
        # Water surface
        water_y = h // 2 + 10 * s
        draw.rectangle([0, water_y, w, h], fill=(50, 90, 160, 180))
        # Wave line
        for wx in range(0, w, 8 * s):
            wy = water_y + int(math.sin(wx / (12 * s)) * 3 * s)
            draw.ellipse([wx, wy - 2 * s, wx + 6 * s, wy + 2 * s], fill=(80, 140, 220, 200))
        # Upper body visible
        bw, bh = 42 * s, 24 * s
        outlined_ellipse(draw, [cx - bw, cy - bh, cx + bw, cy + bh],
                         fill=(255, 255, 255), outline=(40, 40, 40), outline_w=2, s=s)
        # Spots
        import random
        random.seed(99)
        for _ in range(3):
            sx = cx + random.randint(-25 * s, 25 * s)
            sy = cy + random.randint(-10 * s, 5 * s)
            sr = random.randint(5 * s, 10 * s)
            draw.ellipse([sx - sr, sy - sr // 2, sx + sr, sy + sr // 2], fill=(30, 30, 30, 180))
        # Head (worried)
        head_cy = cy - 20 * s
        outlined_circle(draw, cx, head_cy, 14 * s, fill=(255, 255, 255), outline=(40, 40, 40),
                        outline_w=2, s=s)
        # Worried eyes (wide)
        for ex in [-6, 6]:
            ex_abs = cx + ex * s
            ey = head_cy - 2 * s
            draw.ellipse([ex_abs - 5 * s, ey - 6 * s, ex_abs + 5 * s, ey + 6 * s], fill=(255, 255, 255))
            draw.ellipse([ex_abs - 5 * s, ey - 6 * s, ex_abs + 5 * s, ey + 6 * s],
                         outline=(40, 40, 40), width=s)
            draw.ellipse([ex_abs - 2 * s, ey - 2 * s, ex_abs + 2 * s, ey + 4 * s], fill=(20, 20, 20))
            draw.ellipse([ex_abs - 1 * s, ey - 3 * s, ex_abs + 1 * s, ey - 1 * s], fill=(255, 255, 255))
        # Worried mouth
        draw.arc([cx - 8 * s, head_cy + 4 * s, cx + 8 * s, head_cy + 14 * s],
                 start=0, end=180, fill=(40, 40, 40), width=2 * s)
        # Horns
        for hx in [-9, 9]:
            hx_abs = cx + hx * s
            hy = head_cy - 12 * s
            draw.polygon([
                (hx_abs - 3 * s, head_cy - 8 * s),
                (hx_abs + (3 if hx > 0 else -3) * s, hy - 6 * s),
                (hx_abs + 3 * s, head_cy - 8 * s),
            ], fill=(220, 190, 130), outline=(40, 40, 40))

    img = supersample_draw(156, 108, draw_fn)
    save_asset(img, "cow_drowning")


# ── FARMER ──

def generate_farmer():
    def draw_fn(img, draw, w, h, s):
        cx, cy = w // 2, h // 2
        # Legs
        for lx in [-12, 12]:
            lx_abs = cx + lx * s
            draw.rounded_rectangle([lx_abs - 6 * s, cy + 36 * s, lx_abs + 6 * s, cy + 65 * s],
                                   radius=3 * s, fill=(50, 80, 140))
            # Boots
            draw.rounded_rectangle([lx_abs - 7 * s, cy + 58 * s, lx_abs + 8 * s, cy + 68 * s],
                                   radius=2 * s, fill=(100, 60, 30), outline=(60, 40, 20))
        # Body / Overalls
        outlined_ellipse(draw, [cx - 24 * s, cy - 10 * s, cx + 24 * s, cy + 42 * s],
                         fill=(50, 100, 180), outline=(30, 60, 120), outline_w=2, s=s)
        # Overall straps
        draw.line([(cx - 16 * s, cy - 6 * s), (cx - 8 * s, cy + 10 * s)], fill=(40, 80, 150), width=3 * s)
        draw.line([(cx + 16 * s, cy - 6 * s), (cx + 8 * s, cy + 10 * s)], fill=(40, 80, 150), width=3 * s)
        # Overall pocket
        draw.rounded_rectangle([cx - 8 * s, cy + 16 * s, cx + 8 * s, cy + 28 * s],
                               radius=2 * s, fill=(40, 80, 150), outline=(30, 60, 120), width=s)
        # Arms
        for ax_sign in [-1, 1]:
            ax = cx + ax_sign * 28 * s
            draw.rounded_rectangle([ax - 6 * s, cy, ax + 6 * s, cy + 30 * s],
                                   radius=3 * s, fill=(210, 160, 110), outline=(160, 110, 60))
            # Hands
            draw.ellipse([ax - 7 * s, cy + 26 * s, ax + 7 * s, cy + 36 * s], fill=(220, 170, 120))
        # Head
        head_cy = cy - 28 * s
        outlined_circle(draw, cx, head_cy, 22 * s, fill=(220, 170, 120), outline=(180, 130, 80),
                        outline_w=2, s=s)
        # Eyes
        for ex in [-9, 9]:
            ex_abs = cx + ex * s
            ey = head_cy - 2 * s
            draw.ellipse([ex_abs - 5 * s, ey - 6 * s, ex_abs + 5 * s, ey + 6 * s], fill=(255, 255, 255))
            draw.ellipse([ex_abs - 5 * s, ey - 6 * s, ex_abs + 5 * s, ey + 6 * s],
                         outline=(40, 40, 40), width=s)
            draw.ellipse([ex_abs - 2 * s, ey - 2 * s, ex_abs + 2 * s, ey + 3 * s], fill=(50, 100, 50))
            draw.ellipse([ex_abs - 1 * s, ey - 3 * s, ex_abs + 1 * s, ey - 1 * s], fill=(255, 255, 255))
        # Smile
        draw.arc([cx - 10 * s, head_cy + 4 * s, cx + 10 * s, head_cy + 16 * s],
                 start=10, end=170, fill=(40, 40, 40), width=2 * s)
        # Nose
        draw.ellipse([cx - 3 * s, head_cy + 1 * s, cx + 3 * s, head_cy + 6 * s],
                     fill=(200, 150, 100))
        # Cowboy hat
        hat_cy = head_cy - 24 * s
        # Brim
        draw.ellipse([cx - 32 * s, hat_cy - 2 * s, cx + 32 * s, hat_cy + 10 * s],
                     fill=(140, 90, 40), outline=(90, 60, 20), width=s)
        # Crown
        draw.rounded_rectangle([cx - 18 * s, hat_cy - 20 * s, cx + 18 * s, hat_cy + 4 * s],
                               radius=4 * s, fill=(160, 100, 40), outline=(100, 65, 25), width=s)
        # Hat band
        draw.rectangle([cx - 18 * s, hat_cy - 4 * s, cx + 18 * s, hat_cy + 1 * s],
                       fill=(180, 40, 40))

    img = supersample_draw(180, 216, draw_fn)
    save_asset(img, "farmer")


# ── BACKGROUNDS ──

def generate_background_grass():
    def draw_fn(img, draw, w, h, s):
        import random
        random.seed(7)
        # Green gradient
        for y in range(h):
            t = y / h
            r = int(60 + t * 30)
            g = int(140 + t * 40)
            b = int(30 + t * 20)
            draw.line([(0, y), (w, y)], fill=(r, g, b))
        # Grass blades
        for _ in range(200):
            gx = random.randint(0, w)
            gy = random.randint(0, h)
            gh = random.randint(6 * s, 14 * s)
            lean = random.randint(-3 * s, 3 * s)
            green_var = random.randint(-20, 20)
            color = (60 + green_var, 160 + green_var, 30 + green_var, 120)
            draw.line([(gx, gy), (gx + lean, gy - gh)], fill=color, width=max(1, s))

    img = supersample_draw(512, 512, draw_fn)
    save_asset(img, "background_grass")


def generate_safe_pasture():
    def draw_fn(img, draw, w, h, s):
        import random
        random.seed(13)
        # Darker green gradient
        for y in range(h):
            t = y / h
            r = int(40 + t * 25)
            g = int(120 + t * 30)
            b = int(20 + t * 15)
            draw.line([(0, y), (w, y)], fill=(r, g, b))
        # Grass blades
        for _ in range(150):
            gx = random.randint(0, w)
            gy = random.randint(0, h)
            gh = random.randint(4 * s, 10 * s)
            lean = random.randint(-2 * s, 2 * s)
            draw.line([(gx, gy), (gx + lean, gy - gh)], fill=(50, 140, 25, 100), width=max(1, s))
        # Flowers
        for _ in range(30):
            fx = random.randint(0, w)
            fy = random.randint(0, h)
            petal_colors = [(255, 200, 50), (255, 100, 100), (200, 100, 255), (255, 255, 255)]
            pc = random.choice(petal_colors)
            fr = random.randint(3 * s, 5 * s)
            for angle in range(0, 360, 72):
                px = fx + int(math.cos(math.radians(angle)) * fr)
                py = fy + int(math.sin(math.radians(angle)) * fr)
                draw.ellipse([px - 2 * s, py - 2 * s, px + 2 * s, py + 2 * s], fill=pc)
            draw.ellipse([fx - 2 * s, fy - 2 * s, fx + 2 * s, fy + 2 * s], fill=(255, 220, 50))

    img = supersample_draw(512, 512, draw_fn)
    save_asset(img, "safe_pasture")


# ── DITCH WATER ──

def generate_ditch_water():
    for frame in range(1, 4):
        def draw_fn(img, draw, w, h, s, _frame=frame):
            import random
            random.seed(_frame * 100)
            # Blue gradient
            for y in range(h):
                t = y / h
                r = int(30 + t * 20)
                g = int(60 + t * 40)
                b = int(140 + t * 40)
                draw.line([(0, y), (w, y)], fill=(r, g, b))
            # Wave patterns
            phase = _frame * 2.1
            for wy_base in range(0, h, 12 * s):
                points = []
                for wx in range(0, w, 4 * s):
                    wy = wy_base + int(math.sin(wx / (30 * s) + phase) * 4 * s)
                    points.append((wx, wy))
                if len(points) > 1:
                    draw.line(points, fill=(80, 140, 220, 100), width=2 * s)
            # Shimmer highlights
            for _ in range(20):
                sx = random.randint(0, w)
                sy = random.randint(0, h)
                sw = random.randint(8 * s, 20 * s)
                draw.ellipse([sx, sy, sx + sw, sy + 2 * s], fill=(150, 200, 255, 60))

        img = supersample_draw(512, 160, draw_fn)
        save_asset(img, f"ditch_water_{frame}")


def generate_ditch_edge():
    def draw_fn(img, draw, w, h, s):
        import random
        random.seed(55)
        # Brown dirt
        draw.rectangle([0, 0, w, h], fill=(120, 80, 40))
        # Texture
        for _ in range(80):
            x = random.randint(0, w)
            y = random.randint(0, h)
            r = random.randint(1 * s, 3 * s)
            shade = random.randint(-20, 20)
            draw.ellipse([x - r, y - r, x + r, y + r], fill=(100 + shade, 60 + shade, 30 + shade))
        # Grass on top
        for x in range(0, w, 3 * s):
            gh = random.randint(2 * s, 6 * s)
            lean = random.randint(-1 * s, 1 * s)
            draw.line([(x, 0), (x + lean, -gh)], fill=(70, 150, 30, 180), width=max(1, s))

    img = supersample_draw(512, 24, draw_fn)
    save_asset(img, "ditch_edge")


# ── FENCE ──

def generate_fence_post():
    def draw_fn(img, draw, w, h, s):
        # Wooden post with grain
        draw.rounded_rectangle([2 * s, 0, w - 2 * s, h], radius=3 * s,
                               fill=(140, 90, 45), outline=(90, 55, 25), width=2 * s)
        # Grain lines
        import random
        random.seed(22)
        for _ in range(8):
            gx = random.randint(4 * s, w - 4 * s)
            draw.line([(gx, random.randint(0, h // 4)),
                       (gx + random.randint(-2 * s, 2 * s), random.randint(h * 3 // 4, h))],
                      fill=(120, 75, 35, 80), width=max(1, s))
        # Nail at top
        draw.ellipse([w // 2 - 2 * s, 6 * s, w // 2 + 2 * s, 10 * s], fill=(80, 80, 80))

    img = supersample_draw(24, 120, draw_fn)
    save_asset(img, "fence_post")


def generate_fence_rail():
    def draw_fn(img, draw, w, h, s):
        draw.rounded_rectangle([0, 2 * s, w, h - 2 * s], radius=2 * s,
                               fill=(160, 105, 55), outline=(100, 65, 30), width=s)
        # Grain
        import random
        random.seed(33)
        for _ in range(15):
            gy = random.randint(3 * s, h - 3 * s)
            gx1 = random.randint(0, w // 3)
            gx2 = random.randint(w * 2 // 3, w)
            draw.line([(gx1, gy), (gx2, gy)], fill=(140, 85, 40, 60), width=max(1, s))

    img = supersample_draw(512, 18, draw_fn)
    save_asset(img, "fence_rail")


# ── GATE ──

def generate_gate_door():
    def draw_fn(img, draw, w, h, s):
        # Wooden planks
        plank_w = w // 4
        for i in range(4):
            px = i * plank_w
            shade = [0, 10, -5, 8][i]
            color = (150 + shade, 95 + shade, 45 + shade)
            draw.rectangle([px + s, 2 * s, px + plank_w - s, h - 2 * s], fill=color)
            draw.rectangle([px + s, 2 * s, px + plank_w - s, h - 2 * s],
                           outline=(100, 60, 25), width=s)
        # Cross-brace
        draw.line([(4 * s, 4 * s), (w - 4 * s, h - 4 * s)], fill=(120, 70, 30), width=3 * s)
        draw.line([(4 * s, h - 4 * s), (w - 4 * s, 4 * s)], fill=(120, 70, 30), width=3 * s)
        # Iron hinges
        for hy_ratio in [0.2, 0.8]:
            hy = int(h * hy_ratio)
            draw.rounded_rectangle([0, hy - 3 * s, 12 * s, hy + 3 * s],
                                   radius=s, fill=(60, 60, 60))
            draw.ellipse([8 * s, hy - 2 * s, 12 * s, hy + 2 * s], fill=(50, 50, 50))

    img = supersample_draw(240, 108, draw_fn)
    save_asset(img, "gate_door")


def generate_gate_post():
    def draw_fn(img, draw, w, h, s):
        # Thicker wooden post
        draw.rounded_rectangle([3 * s, 8 * s, w - 3 * s, h], radius=3 * s,
                               fill=(120, 75, 35), outline=(80, 50, 20), width=2 * s)
        # Grain
        import random
        random.seed(44)
        for _ in range(6):
            gx = random.randint(5 * s, w - 5 * s)
            draw.line([(gx, 10 * s), (gx + random.randint(-s, s), h - 5 * s)],
                      fill=(100, 60, 25, 70), width=max(1, s))
        # Iron cap
        draw.rounded_rectangle([2 * s, 0, w - 2 * s, 12 * s],
                               radius=2 * s, fill=(70, 70, 70), outline=(40, 40, 40), width=s)
        # Cap highlight
        draw.line([(5 * s, 3 * s), (w - 5 * s, 3 * s)], fill=(100, 100, 100, 150), width=s)

    img = supersample_draw(36, 144, draw_fn)
    save_asset(img, "gate_post")


# ── CLOUDS ──

def generate_clouds():
    for variant in range(1, 4):
        def draw_fn(img, draw, w, h, s, _v=variant):
            cx, cy = w // 2, h // 2 + 10 * s
            import random
            random.seed(_v * 77)
            # Cloud puffs
            puffs = [
                (0, 0, 35), (-30, 5, 28), (25, 3, 30), (-15, -10, 25),
                (18, -8, 22), (35, 8, 20), (-38, 10, 18),
            ]
            # Slight variation per cloud
            for i, (px, py, pr) in enumerate(puffs):
                px += random.randint(-5, 5)
                py += random.randint(-3, 3)
                pr += random.randint(-3, 3) + (_v - 2) * 2
                pr = max(12, pr)
                x = cx + px * s
                y = cy + py * s
                r = pr * s
                # Soft shadow
                draw.ellipse([x - r, y - r + 4 * s, x + r, y + r + 4 * s],
                             fill=(200, 200, 210, 40))
                # White puff
                draw.ellipse([x - r, y - r, x + r, y + r], fill=(255, 255, 255, 230))
            # Highlight puffs
            for px, py, pr in [(-5, -12, 20), (10, -10, 18)]:
                x = cx + px * s
                y = cy + py * s
                r = (pr + (_v - 2)) * s
                draw.ellipse([x - r, y - r, x + r, y + r], fill=(255, 255, 255, 250))

        img = supersample_draw(240, 120, draw_fn)
        save_asset(img, f"cloud_{variant}")


# ── UI ELEMENTS ──

def draw_text_outlined(draw, pos, text, font_size, fill, outline_color, outline_w, s):
    """Draw text with outline by drawing it offset in all directions."""
    x, y = pos
    # Use default font scaled
    try:
        font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", font_size)
    except (OSError, IOError):
        try:
            font = ImageFont.truetype("/System/Library/Fonts/SFNSDisplay.ttf", font_size)
        except (OSError, IOError):
            font = ImageFont.load_default()
    # Outline
    ow = outline_w
    for dx in range(-ow, ow + 1):
        for dy in range(-ow, ow + 1):
            if dx * dx + dy * dy <= ow * ow + 1:
                draw.text((x + dx, y + dy), text, font=font, fill=outline_color, anchor="mm")
    # Fill
    draw.text((x, y), text, font=font, fill=fill, anchor="mm")
    return font


def generate_title_logo():
    def draw_fn(img, draw, w, h, s):
        cx, cy = w // 2, h // 2
        # Background banner shape
        draw.rounded_rectangle([20 * s, 20 * s, w - 20 * s, h - 20 * s],
                               radius=20 * s, fill=(60, 130, 40, 200),
                               outline=(40, 90, 25), width=3 * s)
        # Title text
        draw_text_outlined(draw, (cx, cy - 12 * s), "COWS IN", 42 * s,
                           fill=(255, 255, 255), outline_color=(40, 40, 40),
                           outline_w=3 * s, s=s)
        draw_text_outlined(draw, (cx, cy + 30 * s), "THE DITCH", 48 * s,
                           fill=(255, 230, 80), outline_color=(40, 40, 40),
                           outline_w=3 * s, s=s)

    img = supersample_draw(900, 240, draw_fn)
    save_asset(img, "title_logo")


def generate_button(name, text, color):
    def draw_fn(img, draw, w, h, s, _text=text, _color=color):
        cx, cy = w // 2, h // 2
        r, g, b = _color
        # Shadow
        draw.rounded_rectangle([8 * s, 12 * s, w - 8 * s, h - 4 * s],
                               radius=20 * s, fill=(0, 0, 0, 80))
        # Button body
        draw.rounded_rectangle([8 * s, 8 * s, w - 8 * s, h - 12 * s],
                               radius=20 * s, fill=(r, g, b),
                               outline=(max(0, r - 40), max(0, g - 40), max(0, b - 40)),
                               width=3 * s)
        # Highlight
        draw.rounded_rectangle([16 * s, 12 * s, w - 16 * s, cy - 4 * s],
                               radius=14 * s,
                               fill=(min(255, r + 40), min(255, g + 40), min(255, b + 40), 100))
        # Text
        draw_text_outlined(draw, (cx, cy - 4 * s), _text, 40 * s,
                           fill=(255, 255, 255), outline_color=(0, 0, 0, 180),
                           outline_w=3 * s, s=s)

    img = supersample_draw(600, 180, draw_fn)
    save_asset(img, name)


def generate_heart(name, color, alpha=255):
    def draw_fn(img, draw, w, h, s, _color=color, _alpha=alpha):
        cx, cy = w // 2, h // 2
        r, g, b = _color
        # Heart shape via two circles + triangle
        hr = 14 * s
        # Left bump
        draw.ellipse([cx - hr * 2, cy - hr - 4 * s, cx, cy + hr // 2 - 4 * s],
                     fill=(r, g, b, _alpha))
        # Right bump
        draw.ellipse([cx, cy - hr - 4 * s, cx + hr * 2, cy + hr // 2 - 4 * s],
                     fill=(r, g, b, _alpha))
        # Bottom triangle
        draw.polygon([
            (cx - hr * 2 + 2 * s, cy - 2 * s),
            (cx + hr * 2 - 2 * s, cy - 2 * s),
            (cx, cy + hr + 10 * s),
        ], fill=(r, g, b, _alpha))
        # Outline
        outline_col = (max(0, r - 60), max(0, g - 60), max(0, b - 60), _alpha)
        draw.ellipse([cx - hr * 2, cy - hr - 4 * s, cx, cy + hr // 2 - 4 * s],
                     outline=outline_col, width=2 * s)
        draw.ellipse([cx, cy - hr - 4 * s, cx + hr * 2, cy + hr // 2 - 4 * s],
                     outline=outline_col, width=2 * s)
        # Highlight
        hl_r = 6 * s
        draw.ellipse([cx - 8 * s, cy - 10 * s, cx - 8 * s + hl_r * 2, cy - 10 * s + hl_r],
                     fill=(255, 255, 255, min(255, _alpha // 2)))

    img = supersample_draw(84, 78, draw_fn)
    save_asset(img, name)


def generate_score_badge():
    def draw_fn(img, draw, w, h, s):
        # Rounded badge
        draw.rounded_rectangle([4 * s, 4 * s, w - 4 * s, h - 4 * s],
                               radius=16 * s, fill=(40, 40, 60, 200),
                               outline=(80, 80, 120, 200), width=2 * s)
        # Inner glow
        draw.rounded_rectangle([8 * s, 8 * s, w - 8 * s, h - 8 * s],
                               radius=14 * s, fill=(50, 50, 70, 100))

    img = supersample_draw(480, 120, draw_fn)
    save_asset(img, "score_badge")


def generate_game_over_banner():
    def draw_fn(img, draw, w, h, s):
        cx, cy = w // 2, h // 2
        # Dark banner
        draw.rounded_rectangle([10 * s, 20 * s, w - 10 * s, h - 20 * s],
                               radius=16 * s, fill=(40, 15, 15, 230),
                               outline=(180, 40, 40), width=3 * s)
        # Text
        draw_text_outlined(draw, (cx, cy), "GAME OVER", 56 * s,
                           fill=(255, 60, 60), outline_color=(40, 10, 10),
                           outline_w=4 * s, s=s)

    img = supersample_draw(900, 240, draw_fn)
    save_asset(img, "game_over_banner")


def generate_gate_indicators():
    for state, color in [("open", (40, 200, 40)), ("closed", (200, 40, 40))]:
        def draw_fn(img, draw, w, h, s, _color=color):
            cx, cy = w // 2, h // 2
            r, g, b = _color
            # Outer ring
            draw.ellipse([2 * s, 2 * s, w - 2 * s, h - 2 * s],
                         fill=(40, 40, 40), outline=(80, 80, 80), width=2 * s)
            # Inner glow
            draw.ellipse([6 * s, 6 * s, w - 6 * s, h - 6 * s], fill=(r, g, b))
            # Highlight
            draw.ellipse([10 * s, 8 * s, w // 2, h // 2 - 2 * s],
                         fill=(min(255, r + 80), min(255, g + 80), min(255, b + 80), 140))

        img = supersample_draw(48, 48, draw_fn)
        save_asset(img, f"gate_indicator_{state}")


# ── PARTICLES ──

def generate_particle(name, size_px, draw_func):
    def wrapper(img, draw, w, h, s):
        draw_func(draw, w, h, s)
    img = supersample_draw(size_px, size_px, wrapper)
    save_asset(img, name)


def generate_particles():
    # Splash droplet
    def splash(draw, w, h, s):
        cx, cy = w // 2, h // 2
        draw.ellipse([cx - 5 * s, cy - 3 * s, cx + 5 * s, cy + 5 * s],
                     fill=(100, 160, 240, 200))
        draw.polygon([(cx, cy - 6 * s), (cx - 3 * s, cy - 1 * s), (cx + 3 * s, cy - 1 * s)],
                     fill=(100, 160, 240, 200))
        draw.ellipse([cx - 2 * s, cy - 1 * s, cx + 1 * s, cy + 1 * s],
                     fill=(180, 220, 255, 180))
    generate_particle("particle_splash", 16, splash)

    # Dust puff
    def dust(draw, w, h, s):
        cx, cy = w // 2, h // 2
        draw.ellipse([cx - 4 * s, cy - 4 * s, cx + 4 * s, cy + 4 * s],
                     fill=(160, 130, 80, 150))
        draw.ellipse([cx - 2 * s, cy - 2 * s, cx + 2 * s, cy + 2 * s],
                     fill=(180, 150, 100, 100))
    generate_particle("particle_dust", 12, dust)

    # Grass blade
    def grass_blade(draw, w, h, s):
        cx = w // 2
        draw.polygon([
            (cx - 2 * s, h - s),
            (cx + 2 * s, h - s),
            (cx + s, s),
            (cx - s, s),
        ], fill=(60, 160, 30, 180))
    generate_particle("particle_grass", 8, grass_blade)

    # Star
    def star(draw, w, h, s):
        cx, cy = w // 2, h // 2
        r_outer = 6 * s
        r_inner = 3 * s
        points = []
        for i in range(10):
            angle = math.radians(i * 36 - 90)
            r = r_outer if i % 2 == 0 else r_inner
            points.append((cx + int(math.cos(angle) * r), cy + int(math.sin(angle) * r)))
        draw.polygon(points, fill=(255, 220, 50, 230))
        draw.polygon(points, outline=(200, 170, 20), width=max(1, s))
    generate_particle("particle_star", 16, star)

    # Sparkle
    def sparkle(draw, w, h, s):
        cx, cy = w // 2, h // 2
        r = 3 * s
        draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(255, 255, 255, 200))
        draw.ellipse([cx - r // 2, cy - r // 2, cx + r // 2, cy + r // 2],
                     fill=(255, 255, 255, 250))
    generate_particle("particle_sparkle", 8, sparkle)


# ── MAIN ──

def main():
    print("Generating sprites into", ASSETS_DIR)
    print()

    generators = [
        ("Cow walk sprites", generate_cow_walk),
        ("Cow drowning sprite", generate_cow_drowning),
        ("Farmer sprite", generate_farmer),
        ("Background grass", generate_background_grass),
        ("Safe pasture", generate_safe_pasture),
        ("Ditch water (3 frames)", generate_ditch_water),
        ("Ditch edge", generate_ditch_edge),
        ("Fence post", generate_fence_post),
        ("Fence rail", generate_fence_rail),
        ("Gate door", generate_gate_door),
        ("Gate post", generate_gate_post),
        ("Clouds (3 variants)", generate_clouds),
        ("Title logo", generate_title_logo),
        ("Play button", lambda: generate_button("button_play", "PLAY", (60, 180, 60))),
        ("Replay button", lambda: generate_button("button_replay", "PLAY AGAIN", (60, 160, 60))),
        ("Heart full", lambda: generate_heart("heart_full", (220, 40, 40))),
        ("Heart empty", lambda: generate_heart("heart_empty", (120, 120, 120), alpha=100)),
        ("Score badge", generate_score_badge),
        ("Game over banner", generate_game_over_banner),
        ("Gate indicators", generate_gate_indicators),
        ("Particle effects", generate_particles),
    ]

    for name, gen in generators:
        print(f"  Generating {name}...")
        gen()

    print()
    print("Done! All assets generated.")


if __name__ == "__main__":
    main()
