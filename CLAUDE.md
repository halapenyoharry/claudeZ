# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

### Build & Run
```bash
# Build the application
swift build                      # Debug build
swift build --configuration release  # Release build

# Run the application
./run.sh                        # Build and run release version
./run-debug.sh                  # Build and run with console output

# Test diagnostics feature
./test-diagnostic.sh            # Build and show diagnostic testing instructions
```

### Development
```bash
# Clean build artifacts
swift package clean

# Update dependencies (if any are added)
swift package update

# Generate Xcode project (optional)
swift package generate-xcodeproj
```

## Architecture Overview

ClaudeZ is a lightweight macOS menu bar application for managing multiple Claude Desktop instances. It's built with Swift and AppKit, using a simple architecture focused on clarity and native macOS integration.

### Core Components

**AppDelegate (main.swift)**
- Entry point and main application controller
- Manages the menu bar status item and menu
- Coordinates between ClaudeManager, MCPManager, and VoiceTypingManager
- Handles periodic instance refresh and MCP menu updates (every 5 seconds)

**ClaudeManager**
- Central class for detecting and managing Claude Desktop instances
- Uses NSWorkspace APIs to launch new instances with `createsNewApplicationInstance`
- Enforces configurable instance limit (default: 5, max: 10)
- Monitors running applications for Claude instances
- Handles focus switching between instances

**MCPManager**
- Manages Claude Desktop MCP server configuration
- Loads/saves claude_desktop_config.json
- Toggles servers on/off by adding/removing underscore prefix
- Opens config in TextEdit for manual editing

**VoiceTypingManager**
- Integrates macOS Speech framework for voice dictation
- Shows floating transcription window during recording
- Sends transcribed text to active Claude window via AppleScript

**PreferencesWindow**
- Simplified preferences with launch at login option
- Removed complex panes/instances settings that weren't working properly

### Key Design Patterns

1. **Multiple Instances**: Each Claude instance runs as a separate process for true isolation
2. **Instance Detection**: Searches for multiple possible Claude bundle identifiers to handle naming variations
3. **Menu Bar App**: Uses `.accessory` activation policy (no dock icon)
4. **Keyboard Shortcuts**: ⌘1-9 for quick instance switching, ⌘N for new instance
5. **Periodic Refresh**: Timer-based instance detection to catch externally launched instances
6. **MCP Server Toggle**: Uses underscore prefix convention to disable servers without deleting config

### Platform Requirements
- macOS 13.0+ (Ventura or later)
- Swift 5.9+
- Claude Desktop app installed

### Permissions Required
- Accessibility API access (for window management and focus switching)
- Optional: Screen Recording (for future window preview features)