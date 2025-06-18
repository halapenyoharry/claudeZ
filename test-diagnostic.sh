#!/bin/bash

# Test script for ClaudeZ diagnostic feature

echo "Testing ClaudeZ diagnostic feature..."
echo "Note: This script will run ClaudeZ in the background"
echo ""

# Build the app
echo "Building ClaudeZ..."
swift build

if [ $? -ne 0 ]; then
    echo "Build failed!"
    exit 1
fi

echo "Build successful!"
echo ""
echo "To test the diagnostic feature:"
echo "1. Run: ./run.sh or ./run-debug.sh"
echo "2. Click the ClaudeZ icon in the menu bar"
echo "3. Select 'Run Diagnostics...' (or press ⌘D)"
echo ""
echo "The diagnostics will check:"
echo "✓ Claude Desktop installation"
echo "✓ System permissions (Accessibility, Screen Recording)"
echo "✓ macOS version compatibility"
echo "✓ System memory"
echo "✓ Running Claude instances"
echo "✓ ClaudeZ preferences"