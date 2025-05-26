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
            if let image = NSImage(systemSymbolName: "rectangle.split.2x1.fill", accessibilityDescription: "ClaudeZ") {
                image.isTemplate = true
                button.image = image
                print("ClaudeZ: Status bar icon set")
            } else {
                button.title = "CZ"
                print("ClaudeZ: Using text fallback for status bar")
            }
            button.toolTip = "ClaudeZ - Manage Claude Desktop instances"
        }
        
        // Create menu
        statusItem?.menu = createMenu()
        print("ClaudeZ: Menu created")
        
        // Set up periodic refresh of instances
        Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.refreshInstances()
        }
        
        print("ClaudeZ: Setup complete")
    }
    
    func createMenu() -> NSMenu {
        let menu = NSMenu()
        
        // New instance/pane
        let newInstanceItem = NSMenuItem(title: "New Claude Instance", action: #selector(newInstance), keyEquivalent: "")
        newInstanceItem.target = self
        menu.addItem(newInstanceItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Instances submenu
        let instancesMenuItem = NSMenuItem(title: "Instances", action: nil, keyEquivalent: "")
        let instancesMenu = NSMenu()
        updateInstancesMenu(instancesMenu)
        instancesMenuItem.submenu = instancesMenu
        menu.addItem(instancesMenuItem)
        
        menu.addItem(NSMenuItem.separator())
        
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
                let title = "Instance \(index + 1)"
                let item = NSMenuItem(title: title, action: #selector(focusInstance(_:)), keyEquivalent: "\(index + 1)")
                item.tag = index
                item.target = self
                if instance.process.isActive {
                    item.state = .on
                }
                menu.addItem(item)
            }
        }
    }
    
    @objc func newInstance() {
        print("New Instance clicked")
        claudeManager?.launchNewInstance()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            if let menu = self?.statusItem?.menu?.item(withTitle: "Instances")?.submenu {
                self?.updateInstancesMenu(menu)
            }
        }
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