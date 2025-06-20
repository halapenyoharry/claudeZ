import Cocoa

@objc class ClaudeManager: NSObject {
    struct ClaudeInstance {
        let process: NSRunningApplication
        var windowID: CGWindowID?
    }
    
    private(set) var instances: [ClaudeInstance] = []
    private let workspace = NSWorkspace.shared
    private var launchObserver: NSObjectProtocol?
    private var terminateObserver: NSObjectProtocol?
    
    override init() {
        super.init()
        setupNotifications()
        // Delay initial detection to avoid race conditions on startup
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            print("🚀 Initial instance detection (delayed)")
            self?.detectExistingInstances()
        }
    }
    
    deinit {
        if let observer = launchObserver {
            workspace.notificationCenter.removeObserver(observer)
        }
        if let observer = terminateObserver {
            workspace.notificationCenter.removeObserver(observer)
        }
    }
    
    private func setupNotifications() {
        // Observe app launches
        launchObserver = workspace.notificationCenter.addObserver(
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
        
        // Also observe app terminations
        terminateObserver = workspace.notificationCenter.addObserver(
            forName: NSWorkspace.didTerminateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication {
                self?.handleTerminatedInstance(app)
            }
        }
    }
    
    func detectExistingInstances() {
        print("\n=== Detecting Claude Instances ===")
        print("Before cleanup: \(instances.count) instances tracked")
        
        // First, remove any terminated instances
        let removedCount = instances.filter { $0.process.isTerminated }.count
        instances.removeAll { instance in
            let isTerminated = instance.process.isTerminated
            if isTerminated {
                print("Removing terminated instance: PID \(instance.process.processIdentifier)")
            }
            return isTerminated
        }
        print("Removed \(removedCount) terminated instances")
        
        // Try different bundle identifiers
        let possibleBundleIds = [
            "com.anthropic.claudefordesktop",
            "com.anthropic.claude-desktop",
            "com.anthropic.claude",
            "com.anthropic.Claude",
            "com.anthropics.claude"
        ]
        
        // Debug: Show all running applications
        print("\nChecking all running applications:")
        let allApps = workspace.runningApplications
        for app in allApps {
            if let name = app.localizedName, name.lowercased().contains("claude") {
                print("  - \(name) [PID: \(app.processIdentifier), Bundle: \(app.bundleIdentifier ?? "none"), Terminated: \(app.isTerminated)]")
            }
        }
        
        let claudeApps = allApps.filter { app in
            // Skip our own app (ClaudeZ)
            if app.processIdentifier == ProcessInfo.processInfo.processIdentifier {
                return false
            }
            
            // Skip if it's ClaudeZ by name
            if let appName = app.localizedName, appName == "ClaudeZ" {
                print("  Skipping ClaudeZ app")
                return false
            }
            
            // Skip background/helper processes (they often don't have bundle IDs)
            guard let bundleId = app.bundleIdentifier else {
                if let name = app.localizedName {
                    print("  Skipping app without bundle ID: \(name)")
                }
                return false
            }
            
            // Skip helper processes - only count main Claude app
            if let appPath = app.bundleURL?.path,
               appPath.contains("Helper") || appPath.contains("Frameworks") {
                print("  Skipping helper process: \(app.localizedName ?? "Unknown")")
                return false
            }
            
            // Also check executable path
            if let execPath = app.executableURL?.path,
               !execPath.contains("/MacOS/Claude") || execPath.contains("Helper") {
                print("  Skipping non-main Claude process: \(execPath)")
                return false
            }
            
            // Only match exact Claude Desktop bundle IDs
            let isClaudeDesktop = possibleBundleIds.contains(bundleId)
            
            if isClaudeDesktop {
                print("  ✓ Found Claude Desktop: \(app.localizedName ?? "Unknown") [Bundle: \(bundleId), Path: \(app.bundleURL?.path ?? "unknown")]")
            }
            
            return isClaudeDesktop
        }
        
        print("\nFound \(claudeApps.count) Claude apps in system")
        
        // Add new instances that aren't already tracked
        for app in claudeApps {
            let isAlreadyTracked = instances.contains { instance in
                instance.process.processIdentifier == app.processIdentifier
            }
            
            if !isAlreadyTracked {
                print("Adding new Claude instance: \(app.localizedName ?? "Unknown") [PID: \(app.processIdentifier), Bundle: \(app.bundleIdentifier ?? "no bundle ID")]")
                instances.append(ClaudeInstance(process: app, windowID: nil))
            } else {
                print("Already tracking: \(app.localizedName ?? "Unknown") [PID: \(app.processIdentifier)]")
            }
        }
        
        print("\nFinal state: tracking \(instances.count) Claude instances")
        for (index, instance) in instances.enumerated() {
            print("  Instance \(index + 1): PID \(instance.process.processIdentifier), Terminated: \(instance.process.isTerminated)")
        }
        print("=== End Detection ===\n")
        
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
        instances.append(ClaudeInstance(process: app, windowID: nil))
        updateWindowIDs()
    }
    
    private func handleTerminatedInstance(_ app: NSRunningApplication) {
        instances.removeAll { instance in
            instance.process.processIdentifier == app.processIdentifier
        }
        print("Removed terminated Claude instance. Now tracking \(instances.count) instances")
    }
    
    func launchNewInstance() {
        print("Launching new Claude instance")
        
        // First refresh the instance list to ensure accurate count
        detectExistingInstances()
        
        // Check instance limit
        let maxInstances = UserDefaults.standard.integer(forKey: "ClaudeZ.MaxInstances")
        let limit = maxInstances > 0 ? maxInstances : 5
        
        print("Current instances: \(instances.count), Limit: \(limit)")
        
        if instances.count >= limit {
            showInstanceLimitAlert(limit: limit)
            return
        }
        
        launchNewClaudeProcess()
    }
    
    private func showInstanceLimitAlert(limit: Int) {
        let alert = NSAlert()
        alert.messageText = "Instance Limit Reached"
        alert.informativeText = "You've reached the maximum of \(limit) Claude instances. You can change this limit in Preferences."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
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
                print("Successfully launched new Claude instance: \(app.bundleIdentifier ?? "unknown")")
                self.handleNewInstance(app)
            }
        }
    }
    
    
    func focusInstance(at index: Int) {
        guard index < instances.count else { return }
        instances[index].process.activate(options: .activateIgnoringOtherApps)
    }
    
    func clearAllInstances() {
        print("Clearing all tracked instances")
        instances.removeAll()
    }
}