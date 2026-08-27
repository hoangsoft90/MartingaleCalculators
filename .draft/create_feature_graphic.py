"""
Create Feature Graphic (1024x500) for Google Play Store
Design: Dark navy gradient + candlestick chart + grid lines + text
"""
from PIL import Image, ImageDraw, ImageFont
import math

W, H = 1024, 500

def create_feature_graphic():
    img = Image.new('RGB', (W, H))
    draw = ImageDraw.Draw(img)
    
    # === BACKGROUND: Dark navy gradient ===
    for y in range(H):
        r = int(13 + (30 - 13) * y / H)
        g = int(27 + (58 - 27) * y / H)
        b = int(42 + (95 - 42) * y / H)
        draw.line([(0, y), (W, y)], fill=(r, g, b))
    
    # === GRID PATTERN (subtle) ===
    grid_color = (30, 58, 95, 60)
    for x in range(0, W, 60):
        draw.line([(x, 0), (x, H)], fill=(30, 58, 95), width=1)
    for y in range(0, H, 60):
        draw.line([(0, y), (W, y)], fill=(30, 58, 95), width=1)
    
    # === CANDLESTICK CHART (left side) ===
    chart_x_start = 60
    chart_x_end = 520
    chart_y_start = 80
    chart_y_end = 400
    
    # Chart background (slightly lighter)
    draw.rectangle([chart_x_start - 10, chart_y_start - 10, chart_x_end + 10, chart_y_end + 10],
                   fill=(15, 30, 50), outline=(30, 58, 95), width=2)
    
    # Grid lines in chart
    for i in range(5):
        gy = chart_y_start + (chart_y_end - chart_y_start) * i / 4
        draw.line([(chart_x_start, gy), (chart_x_end, gy)], fill=(30, 58, 95), width=1)
    for i in range(7):
        gx = chart_x_start + (chart_x_end - chart_x_start) * i / 6
        draw.line([(gx, chart_y_start), (gx, chart_y_end)], fill=(30, 58, 95), width=1)
    
    # Candlestick data (ascending trend with some red)
    candles = [
        # (x_center, open, close, high, low, is_green)
        (90, 320, 280, 260, 340, False),   # red
        (140, 280, 240, 220, 300, True),    # green
        (190, 240, 260, 220, 280, False),   # red
        (240, 260, 200, 180, 280, True),    # green
        (290, 200, 180, 160, 220, True),    # green
        (340, 180, 210, 160, 230, False),   # red
        (390, 210, 160, 140, 230, True),    # green
        (440, 160, 120, 100, 180, True),    # green
        (490, 120, 100, 80, 140, True),     # green
    ]
    
    green = (76, 175, 80)
    red = (244, 67, 54)
    
    for cx, op, cl, hi, lo, is_green in candles:
        color = green if is_green else red
        body_top = min(op, cl)
        body_bot = max(op, cl)
        body_w = 24
        # Body
        draw.rectangle([cx - body_w//2, body_top, cx + body_w//2, body_bot], fill=color)
        # Wicks
        draw.line([(cx, hi), (cx, body_top)], fill=color, width=2)
        draw.line([(cx, body_bot), (cx, lo)], fill=color, width=2)
    
    # Grid level markers (blue dots)
    blue = (66, 165, 245)
    for gy in [200, 240, 280, 320]:
        draw.ellipse([chart_x_end - 8, gy - 4, chart_x_end + 8, gy + 4], fill=blue)
    
    # Average entry line (green dashed)
    avg_y = 240
    for x in range(chart_x_start, chart_x_end, 12):
        draw.line([(x, avg_y), (min(x + 6, chart_x_end), avg_y)], fill=green, width=2)
    
    # Breakeven line (orange dashed)
    be_y = 300
    for x in range(chart_x_start, chart_x_end, 12):
        draw.line([(x, be_y), (min(x + 6, chart_x_end), be_y)], fill=(255, 152, 0), width=2)
    
    # Trend line (gold)
    gold = (255, 215, 0)
    trend_points = [(80, 340), (160, 280), (240, 260), (320, 200), (400, 160), (490, 100)]
    for i in range(len(trend_points) - 1):
        draw.line([trend_points[i], trend_points[i+1]], fill=gold, width=3)
    # Arrow
    draw.polygon([(480, 90), (500, 100), (480, 110)], fill=gold)
    
    # === TEXT (right side) ===
    # Try to load a nice font, fallback to default
    try:
        font_title = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 48)
        font_subtitle = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 24)
        font_bullet = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 20)
        font_small = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 16)
    except:
        font_title = ImageFont.load_default()
        font_subtitle = font_title
        font_bullet = font_title
        font_small = font_title
    
    text_x = 560
    
    # Title
    draw.text((text_x, 80), "GRID", fill=(255, 255, 255), font=font_title)
    draw.text((text_x, 135), "SURVIVAL", fill=(255, 215, 0), font=font_title)
    draw.text((text_x, 190), "SIMULATOR", fill=(255, 255, 255), font=font_title)
    
    # Subtitle
    draw.text((text_x, 260), "Know Your Risk Before You Trade", fill=(200, 200, 200), font=font_subtitle)
    
    # Feature bullets
    bullets = [
        "📊  Survivable Levels Calculator",
        "📈  Interactive Price Ladder Chart",
        "🎚️  What-If Stress Testing",
        "🔄  Reverse Lot Size Finder",
    ]
    y = 310
    for bullet in bullets:
        draw.text((text_x, y), bullet, fill=(180, 200, 220), font=font_bullet)
        y += 32
    
    # Bottom tagline
    draw.text((text_x, 440), "100% Offline · No Login · Free", fill=(120, 140, 160), font=font_small)
    
    # Disclaimer
    draw.text((60, 460), "Not financial advice · For educational purposes only", 
              fill=(80, 100, 120), font=font_small)
    
    # Save
    img.save('/home/hoangweb24/htdocs_apps/MartingaleCalculators/.draft/feature-graphic.png', 'PNG')
    print(f"Feature graphic saved: {img.size}")
    
    # Also save to firebase hosting
    img.save('/home/hoangweb24/htdocs_apps/MartingaleCalculators/.firebase-hosting/feature-graphic.png', 'PNG')
    print("Also saved to .firebase-hosting/feature-graphic.png")

if __name__ == '__main__':
    create_feature_graphic()
