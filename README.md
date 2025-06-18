# ClaudeZ 🚀

A lightweight macOS menu bar app for managing multiple Claude Desktop instances. Perfect for power users who need multiple Claude conversations running simultaneously.

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Platform](https://img.shields.io/badge/platform-macOS-lightgrey.svg)
![Swift](https://img.shields.io/badge/swift-5.0+-orange.svg)

## ✨ Features

- **🎯 Multiple Instances**: Launch separate Claude Desktop instances for independent conversations
- **📊 Instance Management**: See all running Claude instances at a glance
- **⚡ Quick Focus**: Switch between instances with keyboard shortcuts (⌘1, ⌘2, etc.)
- **🔧 MCP Server Control**: Toggle MCP servers on/off directly from the menu bar
- **📝 MCP Config Editor**: Quick access to edit your Claude Desktop configuration
- **🎤 Voice Typing**: Dictate text directly into Claude with real-time transcription
- **🎨 Clean Menu Bar UI**: Minimal, native macOS design
- **🔄 Automatic Detection**: Discovers existing Claude instances on startup

## 🚀 Installation

### Option 1: Download the App (Recommended)

1. Download the latest `ClaudeZ-Installer.dmg` from the [Releases](https://github.com/halapenyoharry/claudeZ/releases) page
2. Open the DMG and drag ClaudeZ.app to your Applications folder
3. Launch ClaudeZ from Applications or Spotlight

### Option 2: Build from Source

1. Clone the repository:
```bash
git clone https://github.com/halapenyoharry/claudeZ.git
cd claudeZ
```

2. Build the app:
```bash
./build-app.sh
```

3. The app will be created as `ClaudeZ.app` in the current directory
4. Drag it to /Applications or run it directly

## 📸 Screenshots

<details>
<summary>Click to see screenshots</summary>

### Menu Bar Icon
The app lives in your menu bar with a subtle icon.

### Instance Menu
Easily see and switch between all your Claude instances.

</details>

## 🎮 Usage

### First Time Setup (Important!)
For the best experience with multiple instances:
1. **Quit all Claude Desktop instances** first
2. **Launch ClaudeZ** from your menu bar
3. **Create one instance** and authenticate with your Anthropic account
4. **Wait for authentication to complete** (you'll see the Claude interface)
5. **Now create additional instances** - they'll share the authentication

### Daily Usage
1. **Launch ClaudeZ** - The app will appear in your menu bar
2. **Create New Instance** - Click "New Claude Instance" or press ⌘N
3. **Switch Between Instances** - Use the Instances menu or press ⌘1, ⌘2, etc.
4. **Toggle MCP Servers** - Use the MCP Servers menu to enable/disable servers
5. **Voice Typing** - Press ⌘V to start dictating text into Claude
6. **Edit MCP Config** - Click "Edit MCP Config" to open in TextEdit

## ⚙️ System Requirements

- macOS 11.0 (Big Sur) or later
- Claude Desktop app installed
- Swift 5.0+ (for building from source)

## 🔐 Permissions

ClaudeZ requires the following permissions:
- **Accessibility**: To send keyboard shortcuts to Claude Desktop
- **Speech Recognition**: For voice typing functionality
- **Microphone**: For voice typing functionality

To grant permissions:
1. Open System Settings > Privacy & Security
2. Add ClaudeZ to Accessibility, Speech Recognition, and Microphone

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

**TL;DR**: You can use, modify, and distribute this software for any purpose, including commercial use.

## 🙏 Acknowledgments

- Built with ❤️ for the Claude community
- Thanks to Anthropic for creating Claude Desktop
- Inspired by the need for better multi-instance management

## 🐛 Known Issues

- Instance detection may take a few seconds after Claude Desktop launches
- Voice typing requires macOS speech recognition permissions
- MCP server changes require Claude Desktop restart

## 📮 Feedback

Found a bug or have a feature request? Please open an issue on GitHub!

---

**Note**: This is an unofficial tool and is not affiliated with Anthropic.