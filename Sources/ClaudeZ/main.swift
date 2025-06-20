import Cocoa

@objc class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var claudeManager: ClaudeManager?
    var preferencesWindow: PreferencesWindow?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        print("ClaudeZ: Application launching...")
        
        // Initialize Claude manager
        claudeManager = ClaudeManager()
        print("ClaudeZ: Claude manager initialized")
        
        // Create status bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            // Try to load custom icon first
            if let iconURL = Bundle.main.url(forResource: "MenuBarIcon", withExtension: "png"),
               let customIcon = NSImage(contentsOf: iconURL) {
                customIcon.isTemplate = true
                customIcon.size = NSSize(width: 18, height: 18)
                button.image = customIcon
                print("ClaudeZ: Custom menu bar icon set")
            } else if let customIcon = NSImage(named: "MenuBarIcon") {
                customIcon.isTemplate = true
                customIcon.size = NSSize(width: 18, height: 18)
                button.image = customIcon
                print("ClaudeZ: Custom menu bar icon set (named)")
            } else if let image = NSImage(systemSymbolName: "asterisk", accessibilityDescription: "ClaudeZ") {
                image.isTemplate = true
                button.image = image
                print("ClaudeZ: Using asterisk symbol")
            } else {
                button.title = "CZ"
                print("ClaudeZ: Using text fallback for status bar")
            }
            button.toolTip = "ClaudeZ - Manage Claude Desktop instances"
        }
        
        // Create menu
        statusItem?.menu = createMenu()
        print("ClaudeZ: Menu created")
        
        // Set up periodic refresh
        Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.refreshInstances()
            // Also refresh MCP menu periodically
            if let menu = self?.statusItem?.menu?.item(withTitle: "MCP Servers")?.submenu {
                self?.updateMCPMenu(menu)
            }
        }
        
        print("ClaudeZ: Setup complete")
    }
    
    func createMenu() -> NSMenu {
        let menu = NSMenu()
        
        // New instance
        let newInstanceItem = NSMenuItem(title: "New Claude Instance", action: #selector(newInstance), keyEquivalent: "n")
        newInstanceItem.target = self
        menu.addItem(newInstanceItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Instances submenu
        let instancesMenuItem = NSMenuItem(title: "Instances", action: nil, keyEquivalent: "")
        let instancesMenu = NSMenu()
        updateInstancesMenu(instancesMenu)
        instancesMenuItem.submenu = instancesMenu
        menu.addItem(instancesMenuItem)
        
        // Force refresh instances
        let refreshItem = NSMenuItem(title: "Force Refresh Instances", action: #selector(forceRefreshInstances), keyEquivalent: "r")
        refreshItem.target = self
        menu.addItem(refreshItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // MCP Servers submenu
        let mcpMenuItem = NSMenuItem(title: "MCP Servers", action: nil, keyEquivalent: "")
        let mcpMenu = NSMenu()
        updateMCPMenu(mcpMenu)
        mcpMenuItem.submenu = mcpMenu
        menu.addItem(mcpMenuItem)
        
        // Open MCP Config
        let openConfigItem = NSMenuItem(title: "Edit MCP Config...", action: #selector(openMCPConfig), keyEquivalent: "")
        openConfigItem.target = self
        menu.addItem(openConfigItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Voice Typing
        let voiceItem = NSMenuItem(title: "Voice Typing...", action: #selector(toggleVoiceTyping), keyEquivalent: "v")
        voiceItem.target = self
        menu.addItem(voiceItem)
        
        // Preferences
        let prefsItem = NSMenuItem(title: "Preferences...", action: #selector(showPreferences), keyEquivalent: ",")
        prefsItem.target = self
        menu.addItem(prefsItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Quit
        menu.addItem(NSMenuItem(title: "Quit ClaudeZ", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        
        return menu
    }
    
    func updateInstancesMenu(_ menu: NSMenu) {
        menu.removeAllItems()
        
        guard let manager = claudeManager else { return }
        
        if manager.instances.isEmpty {
            menu.addItem(NSMenuItem(title: "No instances running", action: nil, keyEquivalent: ""))
        } else {
            for (index, instance) in manager.instances.enumerated() {
                let appName = instance.process.localizedName ?? "Unknown"
                let pid = instance.process.processIdentifier
                let title = "Instance \(index + 1): \(appName) (PID: \(pid))"
                let item = NSMenuItem(title: title, action: #selector(focusInstance(_:)), keyEquivalent: "\(index + 1)")
                item.tag = index
                item.target = self
                if instance.process.isActive {
                    item.state = .on
                }
                // Add tooltip with more info
                if let bundleId = instance.process.bundleIdentifier {
                    item.toolTip = "Bundle: \(bundleId)\nTerminated: \(instance.process.isTerminated)"
                }
                menu.addItem(item)
            }
        }
    }
    
    @objc func newInstance() {
        print("New Instance clicked")
        claudeManager?.launchNewInstance()
        
        // Refresh instances after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.refreshInstances()
        }
    }
    
    func updateMCPMenu(_ menu: NSMenu) {
        menu.removeAllItems()
        
        guard let config = MCPManager.shared.loadConfig() else {
            menu.addItem(NSMenuItem(title: "No MCP config found", action: nil, keyEquivalent: ""))
            return
        }
        
        let sortedServers = config.mcpServers.sorted { $0.key < $1.key }
        
        for (serverName, server) in sortedServers {
            let displayName = serverName.hasPrefix("_") ? String(serverName.dropFirst()) : serverName
            let isEnabled = MCPManager.shared.isServerEnabled(serverName)
            
            let item = NSMenuItem(title: displayName, action: #selector(toggleMCPServer(_:)), keyEquivalent: "")
            item.target = self
            item.state = isEnabled ? .on : .off
            item.representedObject = serverName
            
            if let description = server.description {
                item.toolTip = description
            }
            
            menu.addItem(item)
        }
    }
    
    @objc func toggleMCPServer(_ sender: NSMenuItem) {
        guard let serverName = sender.representedObject as? String else { return }
        
        let isCurrentlyEnabled = MCPManager.shared.isServerEnabled(serverName)
        if MCPManager.shared.toggleServer(named: serverName, enabled: !isCurrentlyEnabled) {
            sender.state = !isCurrentlyEnabled ? .on : .off
            
            // Update the menu to reflect the change
            if let menu = sender.menu {
                updateMCPMenu(menu)
            }
            
            showMCPRestartAlert()
        }
    }
    
    @objc func openMCPConfig() {
        MCPManager.shared.openInTextEdit()
    }
    
    func showMCPRestartAlert() {
        let alert = NSAlert()
        alert.messageText = "MCP Configuration Changed"
        alert.informativeText = "You'll need to restart Claude Desktop for MCP server changes to take effect."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    
    @objc func focusInstance(_ sender: NSMenuItem) {
        claudeManager?.focusInstance(at: sender.tag)
        if let menu = sender.menu {
            updateInstancesMenu(menu)
        }
    }
    
    @objc func showPreferences() {
        if preferencesWindow == nil {
            preferencesWindow = PreferencesWindow()
        }
        preferencesWindow?.showWindow(nil)
        preferencesWindow?.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    
    func refreshInstances() {
        claudeManager?.detectExistingInstances()
        if let menu = statusItem?.menu?.item(withTitle: "Instances")?.submenu {
            updateInstancesMenu(menu)
        }
    }
    
    @objc func forceRefreshInstances() {
        print("\n🔄 FORCE REFRESH REQUESTED")
        // Clear all instances first
        claudeManager?.clearAllInstances()
        
        // Then detect fresh
        claudeManager?.detectExistingInstances()
        if let menu = statusItem?.menu?.item(withTitle: "Instances")?.submenu {
            updateInstancesMenu(menu)
        }
    }
    
    @objc func toggleVoiceTyping() {
        VoiceTypingManager.shared.showVoiceTyping()
    }
}

// Create app
print("ClaudeZ: Starting application...")
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate

// Set activation policy - accessory means app appears in menu bar but not in dock
app.setActivationPolicy(.accessory)

// Ensure app is properly initialized
app.finishLaunching()

print("ClaudeZ: Running main loop...")
app.run()