# ClaudeZ 🚀

A lightweight macOS menu bar app for managing multiple Claude Desktop instances. Perfect for power users who need multiple Claude conversations running simultaneously.

![License](https://img.shields.io/badge/license-CC%20BY--NC--SA%204.0-blue.svg)
![Platform](https://img.shields.io/badge/platform-macOS-lightgrey.svg)
![Swift](https://img.shields.io/badge/swift-5.0+-orange.svg)

## ✨ Features

- **🎯 Launch Multiple Instances**: Create separate Claude Desktop instances for different workflows
- **📊 Instance Management**: See all running Claude instances at a glance
- **⚡ Quick Focus**: Switch between instances with keyboard shortcuts (⌘1, ⌘2, etc.)
- **🎨 Clean Menu Bar UI**: Minimal, native macOS design
- **🔄 Automatic Detection**: Discovers existing Claude instances on startup

## 🚀 Installation

### Option 1: Build from Source

1. Clone the repository:
```bash
git clone https://github.com/yourusername/claudeZ.git
cd claudeZ
```

2. Build the app:
```bash
swift build --configuration release
```

3. Run the app:
```bash
.build/release/ClaudeZ
```

### Option 2: Download Pre-built Binary

Coming soon! Check the [Releases](https://github.com/yourusername/claudeZ/releases) page.

## 📸 Screenshots

<details>
<summary>Click to see screenshots</summary>

### Menu Bar Icon
The app lives in your menu bar with a subtle icon.

### Instance Menu
Easily see and switch between all your Claude instances.

</details>

## 🎮 Usage

1. **Launch ClaudeZ** - The app will appear in your menu bar
2. **Create New Instance** - Click "New Claude Instance" or press ⌘N
3. **Switch Between Instances** - Use the Instances menu or press ⌘1, ⌘2, etc.
4. **Manage Preferences** - Access settings via Preferences menu

## ⚙️ System Requirements

- macOS 11.0 (Big Sur) or later
- Claude Desktop app installed
- Swift 5.0+ (for building from source)

## 🔐 Permissions

ClaudeZ requires the following permissions:
- **Accessibility**: To send keyboard shortcuts to Claude Desktop (for instance switching)

To grant permissions:
1. Open System Settings > Privacy & Security > Accessibility
2. Add ClaudeZ to the allowed apps

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request. Remember that this project uses a non-commercial license.

## 📝 License

This project is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License - see the [LICENSE](LICENSE) file for details.

**TL;DR**: You can use and share this freely, but not for commercial purposes. Any modifications must use the same license.

## 🙏 Acknowledgments

- Built with ❤️ for the Claude community
- Thanks to Anthropic for creating Claude Desktop
- Inspired by the need for better multi-instance management

## 🐛 Known Issues

- Instance detection may take a few seconds after Claude Desktop launches
- Maximum number of instances limited by system resources

## 📮 Feedback

Found a bug or have a feature request? Please open an issue on GitHub!

---

**Note**: This is an unofficial tool and is not affiliated with Anthropic.