#!/bin/bash

# Create a .pkg installer for ClaudeZ

set -e

APP_NAME="ClaudeZ"
VERSION="1.0.0"
IDENTIFIER="com.halapenyoharry.claudez"
INSTALL_LOCATION="/Applications"

echo "Creating .pkg installer for ClaudeZ..."

# Ensure we have a built app
if [ ! -d "$APP_NAME.app" ]; then
    echo "Building app first..."
    ./build-app.sh
fi

# Create a temporary directory for the package
PKG_ROOT="pkg-root"
rm -rf "$PKG_ROOT"
mkdir -p "$PKG_ROOT/Applications"

# Copy the app
cp -R "$APP_NAME.app" "$PKG_ROOT/Applications/"

# Create the component package
pkgbuild \
    --root "$PKG_ROOT" \
    --identifier "$IDENTIFIER" \
    --version "$VERSION" \
    --install-location "/" \
    "ClaudeZ-component.pkg"

# Create a distribution XML
cat > "distribution.xml" << EOF
<?xml version="1.0" encoding="utf-8"?>
<installer-gui-script minSpecVersion="2">
    <title>ClaudeZ</title>
    <welcome file="welcome.txt"/>
    <readme file="readme.txt"/>
    <license file="LICENSE"/>
    <pkg-ref id="$IDENTIFIER"/>
    <options customize="never" require-scripts="false" hostArchitectures="arm64,x86_64"/>
    <domains enable_localSystem="true"/>
    <choices-outline>
        <line choice="default">
            <line choice="$IDENTIFIER"/>
        </line>
    </choices-outline>
    <choice id="default"/>
    <choice id="$IDENTIFIER" visible="false">
        <pkg-ref id="$IDENTIFIER"/>
    </choice>
    <pkg-ref id="$IDENTIFIER" version="$VERSION" onConclusion="none">ClaudeZ-component.pkg</pkg-ref>
</installer-gui-script>
EOF

# Create welcome message
cat > "welcome.txt" << EOF
Welcome to ClaudeZ Installer

ClaudeZ is a macOS menu bar app for managing multiple Claude Desktop instances.

This installer will place ClaudeZ in your Applications folder.

After installation:
1. Launch ClaudeZ from Applications or Spotlight
2. Look for the ClaudeZ icon in your menu bar
3. Grant necessary permissions when prompted
EOF

# Create readme
cat > "readme.txt" << EOF
ClaudeZ - Multiple Claude Desktop Instance Manager

FIRST TIME SETUP:
1. Quit all Claude Desktop instances
2. Launch ClaudeZ from your menu bar
3. Create one instance and authenticate
4. Create additional instances as needed

FEATURES:
- Launch multiple Claude instances
- Quick switching with ⌘1, ⌘2, etc.
- MCP server management
- Voice typing support

For more information, visit:
https://github.com/halapenyoharry/claudeZ
EOF

# Build the final installer package
productbuild \
    --distribution distribution.xml \
    --package-path . \
    --resources . \
    "ClaudeZ-$VERSION.pkg"

# Clean up temporary files
rm -rf "$PKG_ROOT"
rm -f "ClaudeZ-component.pkg"
rm -f "distribution.xml"
rm -f "welcome.txt"
rm -f "readme.txt"

# Sign the package if developer ID is available
if security find-identity -p basic -v | grep -q "Developer ID Installer"; then
    echo "Signing package..."
    productsign --sign "Developer ID Installer" "ClaudeZ-$VERSION.pkg" "ClaudeZ-$VERSION-signed.pkg"
    mv "ClaudeZ-$VERSION-signed.pkg" "ClaudeZ-$VERSION.pkg"
fi

echo "✅ ClaudeZ-$VERSION.pkg created successfully!"
echo ""
echo "The installer will:"
echo "- Install ClaudeZ.app to /Applications"
echo "- Show welcome and readme information"
echo "- Handle permissions properly"