#!/bin/bash
cd "$(dirname "$0")"
swift build --configuration release
echo "Starting ClaudeZ..."
.build/release/ClaudeZ