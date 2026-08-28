#!/usr/bin/env python3
"""Generate App Icon (512x512) and Feature Graphic (1024x500) for Grid Survival Simulator."""

from PIL import Image, ImageDraw, ImageFont
import math

# ─── Colors ───────────────────────────────────────────────────
DARK_NAVY = (13, 27, 42)       # #0D1B2A
PRIMARY_NAVY = (30, 58, 95)    # #1E3A5F
WHITE = (255, 255, 255)
GREEN = (76, 175, 80)          # #4CAF50
RED = (244, 67, 54)            # #F44336
GOLD = (255, 215, 0)           # #FFD700
GOLD_DARK = (218, 165, 32)     # Darker gold for gradient
LIGHT_BLUE = (30, 64, 100)     # Lighter navy for accents

def draw_grid_background(draw, w, h, cell_size=30, color=(30, 58, 95), alpha=80):
    """Draw subtle grid lines."""
    for x in range(0, w, cell_size):
        draw.line([(x, 0), (x, h)], fill=color, width=1)
    for y in range(0, h, cell_size):
        draw.line([(0, y), (w, y)], fill=color, width=1)

def draw_candlestick(draw, x, body_w, body_h, wick_ext, is_green, scale=1.0):
    """Draw a candlestick at position x."""
    bw = int(body_w * scale)
    bh = int(body_h * scale)
    we = int(wick_ext * scale)
    color = GREEN if is_green else RED
    cy = 200  # center y for candles in icon

    # Body
    draw.rectangle([x - bw//2, cy - bh//2, x + bw//2, cy + bh//2], fill=color)
    # Wicks
    draw.line([(x, cy - bh//2 - we), (x, cy - bh//2)], fill=color, width=max(1, int(2*scale)))
    draw.line([(x, cy + bh//2), (x, cy + bh//2 + we)], fill=color, width=max(1, int(2*scale)))

def draw_trend_line(draw, points, color=GOLD, width=3):
    """Draw a smooth trend line through points."""
    for i in range(len(points) - 1):
        draw.line([points[i], points[i+1]], fill=color, width=width)

def draw_arrow_head(draw, tip, size=12, color=GOLD, angle=-45):
    """Draw an arrowhead at the tip."""
    rad = math.radians(angle)
    x, y = tip
    p1 = (x + size * math.cos(rad + math.pi), y + size * math.sin(rad + math.pi))
    p2 = (x + size * math.cos(rad + math.pi/2), y + size * math.sin(rad + math.pi/2))
    p3 = (x + size * math.cos(rad - math.pi/2), y + size * math.sin(rad - math.pi/2))
    draw.polygon([tip, p1, p2], fill=color)

def create_icon(size=512):
    """Create App Icon at given size."""
    img = Image.new('RGBA', (size, size), DARK_NAVY)
    draw = ImageDraw.Draw(img)

    # Background gradient effect (vertical)
    for y in range(size):
        ratio = y / size
        r = int(DARK_NAVY[0] * (1 - ratio * 0.3) + PRIMARY_NAVY[0] * ratio * 0.3)
        g = int(DARK_NAVY[1] * (1 - ratio * 0.3) + PRIMARY_NAVY[1] * ratio * 0.3)
        b = int(DARK_NAVY[2] * (1 - ratio * 0.3) + PRIMARY_NAVY[2] * ratio * 0.3)
        draw.line([(0, y), (size, y)], fill=(r, g, b))

    # Grid pattern
    cell = size // 14
    for x in range(0, size, cell):
        draw.line([(x, 0), (x, size)], fill=(30, 58, 95, 60), width=1)
    for y in range(0, size, cell):
        draw.line([(0, y), (size, y)], fill=(30, 58, 95, 60), width=1)

    # Candlesticks
    cx = size // 2
    cy = size // 2
    bw = int(size * 0.07)  # body width
    gap = int(size * 0.14)

    candles = [
        (-2, True),   # green
        (-1, False),  # red
        (0, True),    # green
        (1, True),    # green
        (2, True),    # green
    ]

    for offset, is_green in candles:
        x = cx + offset * gap
        bh = int(size * (0.12 if is_green else 0.14))
        we = int(size * 0.06)
        color = GREEN if is_green else RED

        # Body
        draw.rectangle([x - bw, cy + int(size*0.05) - bh, x + bw, cy + int(size*0.05)], fill=color)
        # Wicks
        draw.line([(x, cy + int(size*0.05) - bh - we), (x, cy + int(size*0.05) - bh)], fill=color, width=max(2, size//200))
        draw.line([(x, cy + int(size*0.05)), (x, cy + int(size*0.05) + we)], fill=color, width=max(2, size//200))

    # Trend line (upward gold)
    points = [
        (cx - 2*gap, cy + int(size*0.12)),
        (cx - gap, cy + int(size*0.06)),
        (cx, cy),
        (cx + gap, cy - int(size*0.06)),
        (cx + 2*gap, cy - int(size*0.12)),
    ]
    draw_trend_line(draw, points, GOLD, width=max(3, size//120))

    # Arrow head at top-right
    tip = (cx + 2*gap, cy - int(size*0.12))
    arrow_size = int(size * 0.04)
    draw.polygon([
        tip,
        (tip[0] - arrow_size, tip[1] + arrow_size//2),
        (tip[0] - arrow_size, tip[1] - arrow_size//2),
    ], fill=GOLD)

    # Shield icon (bottom-right corner)
    sx, sy = int(size * 0.78), int(size * 0.78)
    ss = int(size * 0.1)
    draw.polygon([
        (sx, sy - ss),
        (sx + ss, sy - ss//2),
        (sx + ss//2, sy + ss),
        (sx - ss//2, sy + ss),
        (sx - ss, sy - ss//2),
    ], fill=(30, 100, 180, 200))
    # Checkmark in shield
    draw.line([(sx - ss//3, sy), (sx - ss//8, sy + ss//3), (sx + ss//3, sy - ss//3)], fill=WHITE, width=max(2, size//200))

    return img

def create_feature_graphic(w=1024, h=500):
    """Create Feature Graphic."""
    img = Image.new('RGBA', (w, h), DARK_NAVY)
    draw = ImageDraw.Draw(img)

    # Gradient background
    for y in range(h):
        ratio = y / h
        r = int(13 + (30-13) * ratio)
        g = int(27 + (58-27) * ratio)
        b = int(42 + (95-42) * ratio)
        draw.line([(0, y), (w, y)], fill=(r, g, b))

    # Grid pattern
    cell = 40
    for x in range(0, w, cell):
        draw.line([(x, 0), (x, h)], fill=(30, 58, 95), width=1)
    for y in range(0, h, cell):
        draw.line([(0, y), (w, y)], fill=(30, 58, 95), width=1)

    # ─── Left side: Large candlestick chart ───
    chart_x = 60
    chart_y = 80
    chart_w = 420
    chart_h = 340

    # Chart border
    draw.rectangle([chart_x, chart_y, chart_x + chart_w, chart_y + chart_h],
                   outline=(30, 58, 95), width=2)

    # Grid lines in chart
    for i in range(1, 5):
        y = chart_y + i * chart_h // 5
        draw.line([(chart_x, y), (chart_x + chart_w, y)], fill=(30, 58, 95), width=1)
    for i in range(1, 7):
        x = chart_x + i * chart_w // 7
        draw.line([(x, chart_y), (x, chart_y + chart_h)], fill=(30, 58, 95), width=1)

    # Candlesticks in chart
    candle_data = [
        # (x_offset, open_y, close_y, wick_top, wick_bottom, is_green)
        (30, 280, 220, 200, 300, True),
        (80, 240, 290, 220, 310, False),
        (130, 270, 200, 180, 290, True),
        (180, 210, 160, 140, 230, True),
        (230, 170, 210, 150, 230, False),
        (280, 200, 140, 120, 220, True),
        (330, 150, 110, 90, 170, True),
        (380, 120, 80, 60, 140, True),
    ]

    for dx, open_y, close_y, wt, wb, is_green in candle_data:
        x = chart_x + dx
        color = GREEN if is_green else RED
        top = min(open_y, close_y)
        bot = max(open_y, close_y)
        # Body
        draw.rectangle([x-8, top, x+8, bot], fill=color)
        # Wicks
        draw.line([(x, wt), (x, top)], fill=color, width=2)
        draw.line([(x, bot), (x, wb)], fill=color, width=2)

    # Trend line
    trend_points = [
        (chart_x + 30, chart_y + 280),
        (chart_x + 130, chart_y + 230),
        (chart_x + 230, chart_y + 260),
        (chart_x + 330, chart_y + 180),
        (chart_x + 400, chart_y + 120),
    ]
    draw_trend_line(draw, trend_points, GOLD, width=3)

    # Arrow
    tip = trend_points[-1]
    draw.polygon([
        tip,
        (tip[0] + 15, tip[1] + 5),
        (tip[0] + 5, tip[1] + 15),
    ], fill=GOLD)

    # Grid level markers (blue dots on left side)
    for i in range(6):
        y = chart_y + 80 + i * 50
        x = chart_x + 50 + i * 60
        draw.ellipse([x-5, y-5, x+5, y+5], fill=(100, 160, 255))

    # Average entry line (green dashed)
    for x in range(chart_x + 20, chart_x + chart_w - 20, 12):
        draw.line([(x, chart_y + 200), (x + 6, chart_y + 200)], fill=GREEN, width=2)

    # Breakeven line (orange dashed)
    for x in range(chart_x + 20, chart_x + chart_w - 20, 12):
        draw.line([(x, chart_y + 250), (x + 6, chart_y + 250)], fill=(255, 152, 0), width=2)

    # ─── Right side: Text content ───
    text_x = 540

    # Title
    try:
        title_font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 42)
        subtitle_font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 22)
        body_font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 16)
        small_font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 13)
    except:
        title_font = ImageFont.load_default()
        subtitle_font = ImageFont.load_default()
        body_font = ImageFont.load_default()
        small_font = ImageFont.load_default()

    # "GRID SURVIVAL" title
    draw.text((text_x, 70), "GRID", fill=WHITE, font=title_font)
    draw.text((text_x, 118), "SURVIVAL", fill=GOLD, font=title_font)

    # "SIMULATOR" subtitle
    draw.text((text_x, 175), "SIMULATOR", fill=(148, 163, 184), font=subtitle_font)

    # Divider line
    draw.line([(text_x, 210), (text_x + 300, 210)], fill=GOLD, width=2)

    # Tagline
    draw.text((text_x, 230), "Stress-test your Grid strategy", fill=WHITE, font=body_font)
    draw.text((text_x, 255), "before the market does.", fill=WHITE, font=body_font)

    # Feature bullets
    features = [
        "📊  Survivable Levels & Max Drawdown",
        "📈  Interactive Price Ladder Chart",
        "🎚️  What-If Scenario Slider",
        "🔄  Reverse Mode — Find Max Lot",
    ]
    for i, feat in enumerate(features):
        draw.text((text_x, 295 + i * 28), feat, fill=(200, 210, 220), font=small_font)

    # Bottom: Phone mockup silhouette (simplified)
    phone_x = text_x + 280
    phone_y = 280
    phone_w = 80
    phone_h = 160
    draw.rounded_rectangle(
        [phone_x, phone_y, phone_x + phone_w, phone_y + phone_h],
        radius=12, outline=(60, 80, 110), width=2
    )
    # Screen content (mini chart)
    mini_cx = phone_x + phone_w // 2
    mini_cy = phone_y + phone_h // 2
    for i in range(5):
        bx = phone_x + 15 + i * 12
        bh = 15 + (i * 5 if i < 3 else 25 - i * 3)
        color = GREEN if i != 1 else RED
        draw.rectangle([bx, mini_cy - bh, bx + 8, mini_cy], fill=color)

    # Disclaimer at bottom
    draw.text((text_x, h - 40), "Not financial advice · 100% Offline", fill=(100, 116, 139), font=small_font)

    return img

# ─── Generate ───
if __name__ == '__main__':
    # App Icon
    icon = create_icon(512)
    icon.save('/home/hoangweb24/htdocs_apps/MartingaleCalculators/.draft/icon.png')
    print("✅ icon.png created (512x512)")

    # Feature Graphic
    fg = create_feature_graphic(1024, 500)
    fg.save('/home/hoangweb24/htdocs_apps/MartingaleCalculators/.draft/feature-graphic.png')
    print("✅ feature-graphic.png created (1024x500)")
