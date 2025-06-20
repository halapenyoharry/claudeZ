import Foundation
import Speech
import Cocoa
import AVFoundation

class VoiceTypingManager: NSObject {
    static let shared = VoiceTypingManager()
    
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    private var transcriptionWindow: NSWindow?
    private var transcriptionTextView: NSTextView?
    private var toggleButton: NSButton?
    private var copyButton: NSButton?
    private var statusLabel: NSTextField?
    private var recordingDot: NSView?
    private(set) var isRecording = false
    
    override init() {
        super.init()
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    }
    
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            DispatchQueue.main.async {
                completion(authStatus == .authorized)
            }
        }
    }
    
    func showVoiceTyping() {
        requestAuthorization { [weak self] authorized in
            if authorized {
                self?.showTranscriptionWindow()
            } else {
                self?.showAuthorizationAlert()
            }
        }
    }
    
    private func showAuthorizationAlert() {
        let alert = NSAlert()
        alert.messageText = "Speech Recognition Permission Required"
        alert.informativeText = "Please grant ClaudeZ permission to use speech recognition in System Settings > Privacy & Security > Speech Recognition."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Open Settings")
        alert.addButton(withTitle: "Cancel")
        
        if alert.runModal() == .alertFirstButtonReturn {
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_SpeechRecognition") {
                NSWorkspace.shared.open(url)
            }
        }
    }
    
    private func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }
    
    private func startRecording() {
        guard !isRecording else { return }
        
        // Clear previous text
        transcriptionTextView?.string = ""
        updateStatus("Listening...")
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { return }
        
        recognitionRequest.shouldReportPartialResults = true
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }
        
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
            isRecording = true
            updateRecordingUI(true)
            
            recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
                if let result = result {
                    self?.updateTranscription(result.bestTranscription.formattedString)
                }
                
                if let error = error {
                    print("Recognition error: \(error)")
                    if (error as NSError).code == 203 { // No speech detected
                        self?.updateStatus("No speech detected. Keep talking...")
                    } else {
                        self?.updateStatus("Error: \(error.localizedDescription)")
                    }
                }
                
                if result?.isFinal ?? false {
                    self?.updateStatus("Speech ended. Press Start to record more.")
                }
            }
        } catch {
            print("Error starting audio engine: \(error)")
            updateStatus("Error: Could not start recording")
            stopRecording()
        }
    }
    
    private func stopRecording() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        
        recognitionRequest = nil
        recognitionTask = nil
        
        isRecording = false
        updateRecordingUI(false)
        updateStatus("Recording stopped. Press Start to record again.")
    }
    
    private func showTranscriptionWindow() {
        if transcriptionWindow == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 500, height: 400),
                styleMask: [.titled, .closable, .resizable],
                backing: .buffered,
                defer: false
            )
            window.title = "Voice Typing for Claude"
            window.level = .floating
            window.center()
            window.delegate = self
            
            let contentView = NSView(frame: window.contentView!.bounds)
            contentView.autoresizingMask = [.width, .height]
            
            // Recording indicator (red dot)
            recordingDot = NSView(frame: NSRect(x: 20, y: 365, width: 10, height: 10))
            recordingDot?.wantsLayer = true
            recordingDot?.layer?.backgroundColor = NSColor.red.cgColor
            recordingDot?.layer?.cornerRadius = 5
            recordingDot?.isHidden = true
            contentView.addSubview(recordingDot!)
            
            // Status label
            statusLabel = NSTextField(labelWithString: "Press Start to begin recording")
            statusLabel?.frame = NSRect(x: 40, y: 360, width: 440, height: 20)
            statusLabel?.font = .systemFont(ofSize: 12)
            statusLabel?.textColor = .secondaryLabelColor
            contentView.addSubview(statusLabel!)
            
            // Scroll view for text
            let scrollView = NSScrollView(frame: NSRect(x: 20, y: 60, width: 460, height: 290))
            scrollView.autoresizingMask = [.width, .height]
            scrollView.hasVerticalScroller = true
            scrollView.borderType = .bezelBorder
            
            let textView = NSTextView(frame: scrollView.bounds)
            textView.autoresizingMask = [.width, .height]
            textView.isEditable = true
            textView.font = NSFont.systemFont(ofSize: 14)
            textView.textContainerInset = NSSize(width: 10, height: 10)
            textView.isRichText = false
            textView.string = "Your transcribed text will appear here..."
            textView.textColor = .placeholderTextColor
            
            scrollView.documentView = textView
            contentView.addSubview(scrollView)
            
            // Buttons
            toggleButton = NSButton(frame: NSRect(x: 20, y: 20, width: 100, height: 30))
            toggleButton?.title = "Start"
            toggleButton?.bezelStyle = .rounded
            toggleButton?.target = self
            toggleButton?.action = #selector(toggleButtonClicked)
            toggleButton?.keyEquivalent = " " // Space bar
            contentView.addSubview(toggleButton!)
            
            copyButton = NSButton(frame: NSRect(x: 380, y: 20, width: 100, height: 30))
            copyButton?.title = "Copy Text"
            copyButton?.bezelStyle = .rounded
            copyButton?.target = self
            copyButton?.action = #selector(copyButtonClicked)
            copyButton?.keyEquivalent = "c" // Cmd+C
            copyButton?.keyEquivalentModifierMask = .command
            contentView.addSubview(copyButton!)
            
            // Instructions label
            let instructionsLabel = NSTextField(labelWithString: "After copying, paste into any Claude instance with ⌘V")
            instructionsLabel.frame = NSRect(x: 130, y: 25, width: 240, height: 20)
            instructionsLabel.font = .systemFont(ofSize: 11)
            instructionsLabel.textColor = .tertiaryLabelColor
            instructionsLabel.alignment = .center
            contentView.addSubview(instructionsLabel)
            
            window.contentView = contentView
            transcriptionWindow = window
            transcriptionTextView = textView
        }
        
        // Reset UI state
        updateRecordingUI(false)
        transcriptionTextView?.string = ""
        transcriptionTextView?.textColor = .textColor
        
        transcriptionWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        
        // Auto-start recording
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.startRecording()
        }
    }
    
    private func updateTranscription(_ text: String) {
        DispatchQueue.main.async { [weak self] in
            if self?.transcriptionTextView?.textColor == .placeholderTextColor {
                self?.transcriptionTextView?.string = ""
                self?.transcriptionTextView?.textColor = .textColor
            }
            self?.transcriptionTextView?.string = text
            self?.transcriptionTextView?.scrollToEndOfDocument(nil)
        }
    }
    
    private func updateStatus(_ status: String) {
        DispatchQueue.main.async { [weak self] in
            self?.statusLabel?.stringValue = status
        }
    }
    
    private func updateRecordingUI(_ recording: Bool) {
        DispatchQueue.main.async { [weak self] in
            self?.toggleButton?.title = recording ? "Stop" : "Start"
            self?.recordingDot?.isHidden = !recording
            
            // Animate the recording dot
            if recording {
                self?.animateRecordingDot()
            } else {
                self?.recordingDot?.layer?.removeAllAnimations()
            }
        }
    }
    
    private func animateRecordingDot() {
        guard let layer = recordingDot?.layer else { return }
        
        let animation = CABasicAnimation(keyPath: "opacity")
        animation.fromValue = 1.0
        animation.toValue = 0.3
        animation.duration = 0.6
        animation.autoreverses = true
        animation.repeatCount = .infinity
        
        layer.add(animation, forKey: "pulse")
    }
    
    @objc private func toggleButtonClicked() {
        toggleRecording()
    }
    
    @objc private func copyButtonClicked() {
        if let text = transcriptionTextView?.string, 
           !text.isEmpty,
           text != "Your transcribed text will appear here..." {
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.setString(text, forType: .string)
            
            // Show confirmation
            updateStatus("✓ Text copied to clipboard! Paste it into Claude with ⌘V")
            
            // Flash the copy button
            copyButton?.isEnabled = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.copyButton?.isEnabled = true
            }
        } else {
            updateStatus("No text to copy. Record something first!")
        }
    }
}

// MARK: - NSWindowDelegate
extension VoiceTypingManager: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        // Clean up when window closes
        if isRecording {
            stopRecording()
        }
        transcriptionWindow = nil
        transcriptionTextView = nil
        toggleButton = nil
        copyButton = nil
        statusLabel = nil
        recordingDot = nil
    }
}