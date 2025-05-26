import Cocoa

class PreferencesWindow: NSWindowController {
    private var allowMultipleInstancesCheckbox: NSButton!
    private var maxPanesSlider: NSSlider!
    private var maxPanesLabel: NSTextField!
    
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
        
        allowMultipleInstancesCheckbox = NSButton(checkboxWithTitle: "Allow multiple Claude Desktop instances", target: self, action: #selector(toggleMultipleInstances))
        
        let panesContainer = NSStackView()
        panesContainer.orientation = .horizontal
        panesContainer.spacing = 10
        
        let panesTitle = NSTextField(labelWithString: "Maximum panes per instance:")
        maxPanesSlider = NSSlider(value: 4, minValue: 1, maxValue: 4, target: self, action: #selector(maxPanesChanged))
        maxPanesSlider.numberOfTickMarks = 4
        maxPanesSlider.allowsTickMarkValuesOnly = true
        maxPanesLabel = NSTextField(labelWithString: "4")
        
        panesContainer.addArrangedSubview(panesTitle)
        panesContainer.addArrangedSubview(maxPanesSlider)
        panesContainer.addArrangedSubview(maxPanesLabel)
        
        let noteLabel = NSTextField(wrappingLabelWithString: "Note: ClaudeZ will use panes (like iTerm2) when multiple instances are not allowed.")
        noteLabel.font = .systemFont(ofSize: 11)
        noteLabel.textColor = .secondaryLabelColor
        
        stackView.addArrangedSubview(allowMultipleInstancesCheckbox)
        stackView.addArrangedSubview(panesContainer)
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
        allowMultipleInstancesCheckbox.state = defaults.bool(forKey: "ClaudeZ.AllowMultipleInstances") ? .on : .off
        let maxPanes = defaults.integer(forKey: "ClaudeZ.MaxPanes")
        maxPanesSlider.integerValue = maxPanes > 0 ? maxPanes : 4
        maxPanesLabel.stringValue = "\(maxPanesSlider.integerValue)"
    }
    
    @objc private func toggleMultipleInstances(_ sender: NSButton) {
        UserDefaults.standard.set(sender.state == .on, forKey: "ClaudeZ.AllowMultipleInstances")
    }
    
    @objc private func maxPanesChanged(_ sender: NSSlider) {
        maxPanesLabel.stringValue = "\(sender.integerValue)"
        UserDefaults.standard.set(sender.integerValue, forKey: "ClaudeZ.MaxPanes")
    }
}