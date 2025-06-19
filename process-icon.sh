#!/bin/bash

# Process icon image to create all necessary formats for macOS app

set -e

SOURCE_IMAGE="$1"

if [ -z "$SOURCE_IMAGE" ]; then
    echo "Usage: ./process-icon.sh <source-image-file>"
    echo "Example: ./process-icon.sh claudez-icon.png"
    exit 1
fi

if [ ! -f "$SOURCE_IMAGE" ]; then
    echo "Error: Source image file not found: $SOURCE_IMAGE"
    exit 1
fi

echo "Processing icon from: $SOURCE_IMAGE"

# Create Resources directory if it doesn't exist
mkdir -p Resources

# Extract just one frame if it's a grid (we'll use the top-left icon)
# Using ImageMagick to crop to just the first icon
if command -v convert &> /dev/null; then
    echo "Extracting single icon from grid..."
    # Assuming it's a 2x2 grid, extract top-left quadrant
    convert "$SOURCE_IMAGE" -crop 50%x50%+0+0 +repage Resources/icon-single.png
    WORKING_IMAGE="Resources/icon-single.png"
else
    WORKING_IMAGE="$SOURCE_IMAGE"
fi

# Create iconset directory
mkdir -p ClaudeZ.iconset

# Generate all required sizes for .icns
echo "Generating icon sizes..."
for size in 16 32 128 256 512; do
    # 1x version
    sips -z $size $size "$WORKING_IMAGE" --out "ClaudeZ.iconset/icon_${size}x${size}.png" &>/dev/null
    
    # 2x version (for Retina)
    size2x=$((size * 2))
    if [ $size2x -le 1024 ]; then
        sips -z $size2x $size2x "$WORKING_IMAGE" --out "ClaudeZ.iconset/icon_${size}x${size}@2x.png" &>/dev/null
    fi
done

# Special case for 512@2x (1024x1024)
sips -z 1024 1024 "$WORKING_IMAGE" --out "ClaudeZ.iconset/icon_512x512@2x.png" &>/dev/null

# Create the .icns file
echo "Creating .icns file..."
iconutil -c icns ClaudeZ.iconset -o Resources/AppIcon.icns

# Create menu bar icon (needs to be a template image)
echo "Creating menu bar icon..."
# Menu bar icons should be 22x22 points (44x44 pixels for @2x)
sips -z 22 22 "$WORKING_IMAGE" --out "Resources/MenuBarIcon.png" &>/dev/null
sips -z 44 44 "$WORKING_IMAGE" --out "Resources/MenuBarIcon@2x.png" &>/dev/null

# Convert to PDF for better template image support
if command -v convert &> /dev/null; then
    convert "Resources/MenuBarIcon.png" -negate -colorspace Gray "Resources/MenuBarIcon.pdf"
    echo "Created template PDF for menu bar"
fi

# Clean up
rm -rf ClaudeZ.iconset
rm -f Resources/icon-single.png

echo "✅ Icon processing complete!"
echo ""
echo "Created:"
echo "  - Resources/AppIcon.icns (app icon)"
echo "  - Resources/MenuBarIcon.png (menu bar icon)"
echo "  - Resources/MenuBarIcon@2x.png (menu bar icon @2x)"
if [ -f "Resources/MenuBarIcon.pdf" ]; then
    echo "  - Resources/MenuBarIcon.pdf (template image)"
fi