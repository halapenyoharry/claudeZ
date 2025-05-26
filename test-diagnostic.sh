#!/bin/bash
cd "$(dirname "$0")"

echo "Building diagnostic version..."
# Build just the diagnostic main file
swiftc Sources/ClaudeZ/main-diagnostic.swift -o test-diagnostic

echo "Running diagnostic app..."
echo "============================"
./test-diagnostic