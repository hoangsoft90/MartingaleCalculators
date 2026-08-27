"""
Create icon.png (512x512) that exactly matches the app's adaptive icon
from ic_launcher_foreground.xml + ic_launcher_background.xml
"""
from PIL import Image, ImageDraw, ImageFont
import math

SIZE = 512
VIEWPORT = 108  # Android adaptive icon viewport

def vp_to_px(vx, vy):
    """Convert viewport (0-108) coordinates to pixel (0-512) coordinates"""
    # Adaptive icon safe zone: 66dp centered in 108dp = offset 21dp, scale = 512/66
    # But for full icon we use the full 108dp viewport mapped to 512px
    scale = SIZE / VIEWPORT
    return (vx * scale, vy * scale)

def vp_length(l):
    return l * SIZE / VIEWPORT

def create_icon():
    img = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # === BACKGROUND (ic_launcher_background.xml) ===
    # Solid dark navy background
    draw.rectangle([0, 0, SIZE, SIZE], fill=(13, 27, 42, 255))  # #0D1B2A
    
    # Subtle grid pattern (#1E3A5F, stroke 0.3dp)
    grid_color = (30, 58, 95, 80)  # semi-transparent
    grid_w = max(1, int(vp_length(0.3)))
    for y_dp in [18, 36, 54, 72, 90]:
        py = vp_to_px(0, y_dp)[1]
        draw.line([(0, py), (SIZE, py)], fill=grid_color, width=grid_w)
    for x_dp in [18, 36, 54, 72, 90]:
        px = vp_to_px(x_dp, 0)[0]
        draw.line([(px, 0), (px, SIZE)], fill=grid_color, width=grid_w)
    
    # === FOREGROUND (ic_launcher_foreground.xml) ===
    
    # 1. Background circle (#1E3A5F)
    cx, cy = vp_to_px(54, 54)
    r = vp_length(40)
    draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(30, 58, 95, 255))
    
    # 2. Grid lines inside circle (white, 0.5dp)
    grid_in = (255, 255, 255, 120)
    gw = max(1, int(vp_length(0.5)))
    # Vertical
    for x_dp in [30, 42, 54, 66, 78]:
        px = vp_to_px(x_dp, 0)[0]
        draw.line([(px, vp_to_px(0, 30)[1]), (px, vp_to_px(0, 78)[1])], fill=grid_in, width=gw)
    # Horizontal
    for y_dp in [42, 54, 66]:
        py = vp_to_px(0, y_dp)[1]
        draw.line([(vp_to_px(30, 0)[0], py), (vp_to_px(78, 0)[0], py)], fill=grid_in, width=gw)
    
    # 3. Candlesticks
    def draw_candle(body_x1, body_y1, body_x2, body_y2, wick_top, wick_bottom, color):
        """Draw a candlestick with body and wicks"""
        bx1, by1 = vp_to_px(body_x1, body_y1)
        bx2, by2 = vp_to_px(body_x2, body_y2)
        wick_w = max(2, int(vp_length(1)))
        # Body
        draw.rectangle([bx1, by1, bx2, by2], fill=color)
        # Upper wick
        mid_x = (bx1 + bx2) / 2
        wt = vp_to_px(0, wick_top)[1]
        draw.line([(mid_x, wt), (mid_x, by1)], fill=color, width=wick_w)
        # Lower wick
        wb = vp_to_px(0, wick_bottom)[1]
        draw.line([(mid_x, by2), (mid_x, wb)], fill=color, width=wick_w)
    
    green = (76, 175, 80, 255)   # #4CAF50
    red = (244, 67, 54, 255)     # #F44336
    
    # Candle 1: green (34,45)-(38,55), wick 40-60
    draw_candle(34, 45, 38, 55, 40, 60, green)
    # Candle 2: red (46,50)-(50,60), wick 45-65
    draw_candle(46, 50, 50, 60, 45, 65, red)
    # Candle 3: green (58,42)-(62,52), wick 37-57
    draw_candle(58, 42, 62, 52, 37, 57, green)
    # Candle 4: green (70,38)-(74,48), wick 33-53
    draw_candle(70, 38, 74, 48, 33, 53, green)
    
    # 4. Trend line (gold #FFD700, 1.5dp)
    gold = (255, 215, 0, 255)
    trend_w = max(2, int(vp_length(1.5)))
    points = [
        vp_to_px(32, 58),
        vp_to_px(44, 52),
        vp_to_px(56, 48),
        vp_to_px(68, 40),
        vp_to_px(76, 36),
    ]
    for i in range(len(points) - 1):
        draw.line([points[i], points[i + 1]], fill=gold, width=trend_w)
    
    # 5. Arrow head (gold triangle)
    arrow = [
        vp_to_px(74, 33),
        vp_to_px(80, 36),
        vp_to_px(74, 39),
    ]
    draw.polygon(arrow, fill=gold)
    
    # Save
    img.save('/home/hoangweb24/htdocs_apps/MartingaleCalculators/.draft/icon.png', 'PNG')
    print(f"Icon saved: {img.size}, mode={img.mode}")
    
    # Also create a copy for Firebase hosting
    img.save('/home/hoangweb24/htdocs_apps/MartingaleCalculators/.firebase-hosting/icon.png', 'PNG')
    print("Also saved to .firebase-hosting/icon.png")

if __name__ == '__main__':
    create_icon()
