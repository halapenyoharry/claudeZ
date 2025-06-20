#!/bin/bash

# Build script for creating ClaudeZ.app bundle

set -e

echo "Building ClaudeZ.app..."

# Clean previous builds
rm -rf ClaudeZ.app
rm -rf .build/release/ClaudeZ.app

# Build release version
swift build --configuration release

# Create app bundle structure
mkdir -p ClaudeZ.app/Contents/MacOS
mkdir -p ClaudeZ.app/Contents/Resources

# Copy executable
cp .build/release/ClaudeZ ClaudeZ.app/Contents/MacOS/

# Copy Info.plist
cp Resources/Info.plist ClaudeZ.app/Contents/

# Copy icons
echo "Copying icons..."
cp Resources/AppIcon.icns ClaudeZ.app/Contents/Resources/ 2>/dev/null || echo "Warning: AppIcon.icns not found"
cp Resources/MenuBarIcon*.png ClaudeZ.app/Contents/Resources/ 2>/dev/null || echo "Warning: MenuBarIcon not found"

# Set executable permissions
chmod +x ClaudeZ.app/Contents/MacOS/ClaudeZ

# Sign the app (ad-hoc signing for local use)
echo "Signing app..."
codesign --force --deep --sign - ClaudeZ.app

echo "✅ ClaudeZ.app created successfully!"
echo ""
echo "You can now:"
echo "1. Double-click ClaudeZ.app to run it"
echo "2. Drag it to /Applications to install"
echo "3. Share the app with others"