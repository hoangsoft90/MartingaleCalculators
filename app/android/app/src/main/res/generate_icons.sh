#!/bin/bash
# Generate PNG icons from vector drawables
# Requires: ImageMagick (apt-get install imagemagick)

set -e

RES_DIR="$(dirname "$0")"
VECTOR_FILE="$RES_DIR/drawable/ic_launcher_foreground.xml"

# Icon sizes for each density
declare -A SIZES=(
    ["mdpi"]=48
    ["hdpi"]=72
    ["xhdpi"]=96
    ["xxhdpi"]=144
    ["xxxhdpi"]=192
)

echo "Generating app icons..."

# Check if ImageMagick is available
if ! command -v convert &> /dev/null; then
    echo "ImageMagick not found. Installing..."
    apt-get update && apt-get install -y imagemagick
fi

# Generate icons for each density
for density in "${!SIZES[@]}"; do
    size=${SIZES[$density]}
    output_dir="$RES_DIR/mipmap-$density"
    output_file="$output_dir/ic_launcher.png"
    output_round="$output_dir/ic_launcher_round.png"

    echo "Generating $density ($size x $size)..."

    # Create icon with background (using integer arithmetic)
    half=$((size/2))
    quarter=$((size/4))
    three_quarter=$((size*3/4))
    
    convert -size ${size}x${size} xc:"#0D1B2A" \
        -fill "#1E3A5F" -draw "circle $half,$half $half,$quarter" \
        -fill "#4CAF50" -draw "rectangle $((size*3/10)),$((size*2/5)) $((size*2/5)),$((size*7/10))" \
        -fill "#F44336" -draw "rectangle $((size*9/20)),$((size/2)) $((size*11/20)),$((size*4/5))" \
        -fill "#4CAF50" -draw "rectangle $((size*3/5)),$((size*3/10)) $((size*7/10)),$((size*3/5))" \
        -fill "#FFD700" -stroke "#FFD700" -strokewidth 2 \
        -draw "line $((size/4)),$((size*13/20)) $((size*3/4)),$((size*3/10))" \
        "$output_file"

    # Create round version
    convert "$output_file" \
        -gravity center -extent ${size}x${size} \
        \( +clone -threshold -1 -negate -fill white -draw "circle $((size/2)),$((size/2)) $((size/2)),$((size/4))" \) \
        -alpha off -compose CopyOpacity -composite \
        "$output_round"

    echo "  Created: $output_file"
    echo "  Created: $output_round"
done

echo ""
echo "✅ Icons generated successfully!"
echo ""
echo "Icon design:"
echo "  - Background: Dark navy blue (#0D1B2A)"
echo "  - Grid pattern: Subtle lines (#1E3A5F)"
echo "  - Candlesticks: Green (#4CAF50) up, Red (#F44336) down"
echo "  - Trend line: Gold (#FFD700) upward"
echo ""
echo "For custom icons, replace the PNG files in mipmap-* folders."
