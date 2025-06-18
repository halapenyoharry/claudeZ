import Cocoa

class PreferencesWindow: NSWindowController {
    private var launchAtLoginCheckbox: NSButton!
    private var maxInstancesSlider: NSSlider!
    private var maxInstancesLabel: NSTextField!
    
    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 200),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "ClaudeZ Preferences"
        window.center()
        
        self.init(window: window)
        setupUI()
        loadPreferences()
    }
    
    private func setupUI() {
        guard let contentView = window?.contentView else { return }
        
        let stackView = NSStackView()
        stackView.orientation = .vertical
        stackView.spacing = 20
        stackView.edgeInsets = NSEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        launchAtLoginCheckbox = NSButton(checkboxWithTitle: "Launch ClaudeZ at login", target: self, action: #selector(toggleLaunchAtLogin))
        
        // Max instances control
        let instancesContainer = NSStackView()
        instancesContainer.orientation = .horizontal
        instancesContainer.spacing = 10
        
        let instancesTitle = NSTextField(labelWithString: "Maximum Claude instances:")
        maxInstancesSlider = NSSlider(value: 5, minValue: 1, maxValue: 10, target: self, action: #selector(maxInstancesChanged))
        maxInstancesSlider.numberOfTickMarks = 10
        maxInstancesSlider.allowsTickMarkValuesOnly = true
        maxInstancesLabel = NSTextField(labelWithString: "5")
        maxInstancesLabel.frame.size.width = 30
        
        instancesContainer.addArrangedSubview(instancesTitle)
        instancesContainer.addArrangedSubview(maxInstancesSlider)
        instancesContainer.addArrangedSubview(maxInstancesLabel)
        
        let noteLabel = NSTextField(wrappingLabelWithString: "ClaudeZ helps you manage Claude Desktop instances and MCP servers.")
        noteLabel.font = .systemFont(ofSize: 11)
        noteLabel.textColor = .secondaryLabelColor
        
        stackView.addArrangedSubview(launchAtLoginCheckbox)
        stackView.addArrangedSubview(instancesContainer)
        stackView.addArrangedSubview(noteLabel)
        
        contentView.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }
    
    private func loadPreferences() {
        let defaults = UserDefaults.standard
        launchAtLoginCheckbox.state = defaults.bool(forKey: "ClaudeZ.LaunchAtLogin") ? .on : .off
        
        let maxInstances = defaults.integer(forKey: "ClaudeZ.MaxInstances")
        maxInstancesSlider.integerValue = maxInstances > 0 ? maxInstances : 5
        maxInstancesLabel.stringValue = "\(maxInstancesSlider.integerValue)"
    }
    
    @objc private func toggleLaunchAtLogin(_ sender: NSButton) {
        UserDefaults.standard.set(sender.state == .on, forKey: "ClaudeZ.LaunchAtLogin")
        // TODO: Actually implement launch at login functionality
    }
    
    @objc private func maxInstancesChanged(_ sender: NSSlider) {
        maxInstancesLabel.stringValue = "\(sender.integerValue)"
        UserDefaults.standard.set(sender.integerValue, forKey: "ClaudeZ.MaxInstances")
    }
}