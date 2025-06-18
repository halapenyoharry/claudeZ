#!/bin/bash

# Create a DMG installer for ClaudeZ

set -e

APP_NAME="ClaudeZ"
DMG_NAME="ClaudeZ-Installer"
DMG_DIR="dmg-contents"

echo "Creating DMG installer..."

# Clean up any existing DMG
rm -rf "$DMG_DIR"
rm -f "$DMG_NAME.dmg"

# Create DMG contents directory
mkdir -p "$DMG_DIR"

# Copy app
cp -R "$APP_NAME.app" "$DMG_DIR/"

# Create Applications symlink
ln -s /Applications "$DMG_DIR/Applications"

# Create a simple background or instructions file
cat > "$DMG_DIR/README.txt" << EOF
ClaudeZ Installation
===================

To install ClaudeZ:
1. Drag ClaudeZ.app to the Applications folder
2. Launch ClaudeZ from Applications or Spotlight
3. Grant necessary permissions when prompted

First time setup:
- Quit all Claude Desktop instances
- Launch ClaudeZ and create one instance
- Authenticate with your Anthropic account
- Create additional instances as needed

Enjoy managing multiple Claude conversations!
EOF

# Create DMG
echo "Building DMG..."
hdiutil create -volname "$APP_NAME" -srcfolder "$DMG_DIR" -ov -format UDZO "$DMG_NAME.dmg"

# Clean up
rm -rf "$DMG_DIR"

echo "✅ $DMG_NAME.dmg created successfully!"
echo "This file can be distributed to other macOS users."