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
    
    func toggleVoiceTyping() {
        if isRecording {
            stopRecording()
        } else {
            requestAuthorization { [weak self] authorized in
                if authorized {
                    self?.startRecording()
                } else {
                    self?.showAuthorizationAlert()
                }
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
    
    private func startRecording() {
        guard !isRecording else { return }
        
        showTranscriptionWindow()
        
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
            
            recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
                if let result = result {
                    self?.updateTranscription(result.bestTranscription.formattedString)
                }
                
                if error != nil || (result?.isFinal ?? false) {
                    self?.stopRecording()
                }
            }
        } catch {
            print("Error starting audio engine: \\(error)")
            stopRecording()
        }
    }
    
    private func stopRecording() {
        guard isRecording else { return }
        
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        
        isRecording = false
        
        // Send transcription to Claude if window is open
        if let text = transcriptionTextView?.string, !text.isEmpty {
            sendTextToClaude(text)
        }
        
        // Hide transcription window
        transcriptionWindow?.orderOut(nil)
    }
    
    private func showTranscriptionWindow() {
        if transcriptionWindow == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 400, height: 200),
                styleMask: [.titled, .closable, .resizable],
                backing: .buffered,
                defer: false
            )
            window.title = "Voice Typing"
            window.level = .floating
            window.center()
            
            let scrollView = NSScrollView(frame: window.contentView!.bounds)
            scrollView.autoresizingMask = [.width, .height]
            scrollView.hasVerticalScroller = true
            
            let textView = NSTextView(frame: scrollView.bounds)
            textView.autoresizingMask = [.width, .height]
            textView.isEditable = false
            textView.font = NSFont.systemFont(ofSize: 14)
            textView.textContainerInset = NSSize(width: 10, height: 10)
            
            scrollView.documentView = textView
            window.contentView?.addSubview(scrollView)
            
            transcriptionWindow = window
            transcriptionTextView = textView
        }
        
        transcriptionTextView?.string = ""
        transcriptionWindow?.makeKeyAndOrderFront(nil)
    }
    
    private func updateTranscription(_ text: String) {
        DispatchQueue.main.async { [weak self] in
            self?.transcriptionTextView?.string = text
            self?.transcriptionTextView?.scrollToEndOfDocument(nil)
        }
    }
    
    private func sendTextToClaude(_ text: String) {
        // Use AppleScript to paste text into Claude
        let script = """
        tell application "System Events"
            tell process "Claude"
                set frontmost to true
                delay 0.5
                keystroke "\\(text.replacingOccurrences(of: "\\"", with: "\\\\\""))"
            end tell
        end tell
        """
        
        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: script) {
            scriptObject.executeAndReturnError(&error)
            if error != nil {
                print("Error sending text to Claude: \(error!)")
            }
        }
    }
}