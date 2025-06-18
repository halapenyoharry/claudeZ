#!/bin/bash

# Convert SVG to macOS icon formats

echo "Creating ClaudeZ icons..."

# Create PNG versions at different sizes
for size in 16 32 64 128 256 512 1024; do
    echo "Creating ${size}x${size} PNG..."
    sips -s format png Resources/icon.svg --resampleHeightWidth ${size} ${size} --out Resources/icon_${size}.png 2>/dev/null || \
    convert -background none -resize ${size}x${size} Resources/icon.svg Resources/icon_${size}.png 2>/dev/null || \
    echo "Warning: Could not create ${size}x${size} PNG (install ImageMagick or use sips)"
done

# Create .icns file if iconutil is available
if command -v iconutil &> /dev/null; then
    echo "Creating .icns file..."
    
    # Create iconset directory
    mkdir -p ClaudeZ.iconset
    
    # Copy PNGs with correct names for iconutil
    cp Resources/icon_16.png ClaudeZ.iconset/icon_16x16.png 2>/dev/null
    cp Resources/icon_32.png ClaudeZ.iconset/icon_16x16@2x.png 2>/dev/null
    cp Resources/icon_32.png ClaudeZ.iconset/icon_32x32.png 2>/dev/null
    cp Resources/icon_64.png ClaudeZ.iconset/icon_32x32@2x.png 2>/dev/null
    cp Resources/icon_128.png ClaudeZ.iconset/icon_128x128.png 2>/dev/null
    cp Resources/icon_256.png ClaudeZ.iconset/icon_128x128@2x.png 2>/dev/null
    cp Resources/icon_256.png ClaudeZ.iconset/icon_256x256.png 2>/dev/null
    cp Resources/icon_512.png ClaudeZ.iconset/icon_256x256@2x.png 2>/dev/null
    cp Resources/icon_512.png ClaudeZ.iconset/icon_512x512.png 2>/dev/null
    cp Resources/icon_1024.png ClaudeZ.iconset/icon_512x512@2x.png 2>/dev/null
    
    # Generate .icns
    iconutil -c icns ClaudeZ.iconset -o Resources/AppIcon.icns
    
    # Clean up
    rm -rf ClaudeZ.iconset
    rm -f Resources/icon_*.png
    
    echo "✅ Created AppIcon.icns"
else
    echo "Warning: iconutil not found. Cannot create .icns file."
fi

# For menu bar, we need a PDF template image
echo "Creating menu bar icon..."
if command -v rsvg-convert &> /dev/null; then
    rsvg-convert -f pdf -o Resources/MenuBarIcon.pdf Resources/icon.svg
elif command -v convert &> /dev/null; then
    convert Resources/icon.svg Resources/MenuBarIcon.pdf
else
    echo "Warning: Cannot convert to PDF. Install librsvg or ImageMagick."
fi

echo "✅ Icon creation complete!"