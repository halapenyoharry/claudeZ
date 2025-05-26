import Cocoa

@objc class ClaudeManager: NSObject {
    struct ClaudeInstance {
        let process: NSRunningApplication
        var windowID: CGWindowID?
    }
    
    private(set) var instances: [ClaudeInstance] = []
    private let workspace = NSWorkspace.shared
    private var observer: NSObjectProtocol?
    
    override init() {
        super.init()
        detectExistingInstances()
        setupNotifications()
    }
    
    deinit {
        if let observer = observer {
            workspace.notificationCenter.removeObserver(observer)
        }
    }
    
    private func setupNotifications() {
        observer = workspace.notificationCenter.addObserver(
            forName: NSWorkspace.didLaunchApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
               let bundleId = app.bundleIdentifier,
               (bundleId == "com.anthropic.claudefordesktop" || bundleId == "com.anthropic.claude-desktop" || bundleId.lowercased().contains("claude")) {
                self?.handleNewInstance(app)
            }
        }
    }
    
    func detectExistingInstances() {
        // Clear existing instances
        instances.removeAll()
        
        // Try different bundle identifiers
        let possibleBundleIds = [
            "com.anthropic.claudefordesktop",
            "com.anthropic.claude-desktop",
            "com.anthropic.claude",
            "com.anthropic.Claude",
            "com.anthropics.claude"
        ]
        
        let claudeApps = workspace.runningApplications.filter { app in
            // Skip our own app
            if app.processIdentifier == ProcessInfo.processInfo.processIdentifier {
                return false
            }
            
            if let bundleId = app.bundleIdentifier {
                return possibleBundleIds.contains(bundleId) || bundleId.lowercased().contains("claude")
            }
            return app.localizedName?.lowercased().contains("claude") ?? false
        }
        
        print("Found \(claudeApps.count) Claude instances")
        for app in claudeApps {
            print("- \(app.localizedName ?? "Unknown") [\(app.bundleIdentifier ?? "no bundle ID")]")
            instances.append(ClaudeInstance(process: app, windowID: nil))
        }
        
        updateWindowIDs()
    }
    
    private func updateWindowIDs() {
        let options = CGWindowListOption.optionOnScreenOnly
        if let windowList = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] {
            for window in windowList {
                if let ownerPID = window[kCGWindowOwnerPID as String] as? Int32,
                   let windowID = window[kCGWindowNumber as String] as? CGWindowID,
                   let index = instances.firstIndex(where: { $0.process.processIdentifier == ownerPID }) {
                    instances[index].windowID = windowID
                }
            }
        }
    }
    
    private func handleNewInstance(_ app: NSRunningApplication) {
        instances.append(ClaudeInstance(process: app, paneCount: 1, windowID: nil))
        updateWindowIDs()
    }
    
    func launchNewInstance() {
        print("LaunchNewInstance called")
        launchNewClaudeProcess()
    }
    
    
    private func launchNewClaudeProcess() {
        print("Attempting to launch new Claude Desktop process")
        
        // Try multiple approaches to find Claude
        let bundleIds = [
            "com.anthropic.claudefordesktop",
            "com.anthropic.claude-desktop",
            "com.anthropic.claude",
            "com.anthropic.Claude"
        ]
        
        var foundURL: URL?
        for bundleId in bundleIds {
            if let url = workspace.urlForApplication(withBundleIdentifier: bundleId) {
                foundURL = url
                print("Found Claude with bundle ID \(bundleId) at: \(url.path)")
                break
            }
        }
        
        // If not found by bundle ID, try by name
        if foundURL == nil {
            let appNames = ["Claude", "Claude Desktop", "Claude.app"]
            for name in appNames {
                if let url = workspace.urlForApplication(withBundleIdentifier: name) {
                    foundURL = url
                    print("Found Claude by name '\(name)' at: \(url.path)")
                    break
                }
            }
        }
        
        // Last resort - try to open by name
        if foundURL == nil {
            print("Could not find Claude Desktop by bundle ID or URL, trying to open by name")
            workspace.open(URL(fileURLWithPath: "/Applications/Claude.app"))
            return
        }
        
        guard let url = foundURL else {
            print("Failed to find Claude Desktop application")
            return
        }
        
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.createsNewApplicationInstance = true
        configuration.activates = true
        
        workspace.openApplication(at: url, configuration: configuration) { app, error in
            if let error = error {
                print("Error launching Claude Desktop: \(error)")
            } else if let app = app {
                print("Successfully launched Claude Desktop: \(app.bundleIdentifier ?? "unknown")")
            }
        }
    }
    
    
    func focusInstance(at index: Int) {
        guard index < instances.count else { return }
        instances[index].process.activate(options: .activateIgnoringOtherApps)
    }
}