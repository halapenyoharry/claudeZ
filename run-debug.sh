#!/bin/bash
cd "$(dirname "$0")"
swift build --configuration release
echo "Starting ClaudeZ with console output..."
echo "Look for debug messages here:"
echo "================================"
.build/release/ClaudeZ