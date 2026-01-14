import Cocoa
import Foundation
import Carbon.HIToolbox

class HotkeyService {
    private var flagsMonitor: Any?
    private var localMonitor: Any?
    private var isRecording = false
    private var fnPressed = false
    private var optionWasPressed = false
    private var controlWasPressed = false
    private var retryTimer: Timer?
    
    private let hotkeyConfig: HotkeyConfigurationManager

    private let onRecordingStart: () -> Void
    private let onRecordingStop: () -> Void
    private let onRecordingCancel: () -> Void
    private let onTTSTriggered: () -> Void
    private let onSmartOCRTriggered: () -> Void
    private let onSceneDescriptionTriggered: () -> Void

    init(
        hotkeyConfig: HotkeyConfigurationManager,
        onRecordingStart: @escaping () -> Void,
        onRecordingStop: @escaping () -> Void,
        onRecordingCancel: @escaping () -> Void = {},
        onTTSTriggered: @escaping () -> Void = {},
        onSmartOCRTriggered: @escaping () -> Void = {},
        onSceneDescriptionTriggered: @escaping () -> Void = {}
    ) {
        self.hotkeyConfig = hotkeyConfig
        self.onRecordingStart = onRecordingStart
        self.onRecordingStop = onRecordingStop
        self.onRecordingCancel = onRecordingCancel
        self.onTTSTriggered = onTTSTriggered
        self.onSmartOCRTriggered = onSmartOCRTriggered
        self.onSceneDescriptionTriggered = onSceneDescriptionTriggered
    }

    func start() {
        // Check accessibility permission (don't prompt automatically)
        let accessibilityEnabled = AXIsProcessTrusted()
        print("🔐 Accessibility enabled: \(accessibilityEnabled)")

        if !accessibilityEnabled {
            print("⚠️ Accessibility permission not granted. Please enable in System Settings.")
            promptForAccessibility()
            startRetryTimer()
        }
        
        // Always try to start monitors - the check can be unreliable after rebuilds
        // The monitors will simply not receive events if not trusted
        startMonitors()
    }
    
    private func startMonitors() {
        // Remove existing monitors first
        stop()
        
        // Monitor for Fn key using global event monitor
        flagsMonitor = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            self?.handleFlagsChanged(event: event)
        }

        // Also add local monitor to catch events when app is focused
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            self?.handleFlagsChanged(event: event)
            return event
        }

        if flagsMonitor != nil {
            print("✅ Hotkey service started - Hold Fn key to record!")
            print("💡 Make sure System Settings → Keyboard → 'Press fn key to' is set to 'Do Nothing'")
        } else {
            print("❌ Failed to create global event monitor - Accessibility likely not granted")
        }
    }
    
    private func startRetryTimer() {
        retryTimer?.invalidate()
        retryTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            if AXIsProcessTrusted() {
                print("✅ Accessibility permission now granted!")
                self?.retryTimer?.invalidate()
                self?.retryTimer = nil
                self?.startMonitors()
            } else {
                print("⏳ Still waiting for Accessibility permission...")
            }
        }
    }

    func stop() {
        retryTimer?.invalidate()
        retryTimer = nil
        if let monitor = flagsMonitor {
            NSEvent.removeMonitor(monitor)
            flagsMonitor = nil
        }
        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
            localMonitor = nil
        }
    }

    private var startRecordingWorkItem: DispatchWorkItem?
    private var ttsTriggered = false
    private var cancelTriggered = false
    private var smartOCRTriggered = false
    private var sceneDescriptionTriggered = false
    private var requireRelease = false  // Blocks new recordings until Fn is fully released

    private func handleFlagsChanged(event: NSEvent) {
        let flags = event.modifierFlags
        let keyCode = event.keyCode

        // Check which configured actions match the current modifier state
        let matchesSTT = hotkeyConfig.matchesAction(.startRecording, flags: flags)
        let matchesCancel = hotkeyConfig.matchesAction(.cancelRecording, flags: flags)
        let matchesTTS = hotkeyConfig.matchesAction(.triggerTTS, flags: flags)
        let matchesOCR = hotkeyConfig.matchesAction(.smartOCR, flags: flags)
        let matchesScene = hotkeyConfig.matchesAction(.sceneDescription, flags: flags)
        
        // Get the primary modifier for STT to detect release
        let sttBinding = hotkeyConfig.binding(for: .startRecording)
        let primaryPressed = flags.contains(sttBinding.primaryModifier.nsEventFlag)

        // Debug: print all flag changes
        print("🔑 Flags: keyCode=\(keyCode), stt=\(matchesSTT), cancel=\(matchesCancel), tts=\(matchesTTS), fnPressed=\(fnPressed), requireRelease=\(requireRelease), raw=\(flags.rawValue)")
        
        // Clear requireRelease when primary modifier is fully released
        if !primaryPressed && requireRelease {
            print("🔓 Primary modifier released - allowing new recordings")
            requireRelease = false
        }

        // Handle TTS trigger (tap action, not hold)
        if matchesTTS && !ttsTriggered {
            ttsTriggered = true
            
            // Cancel any pending STT start
            startRecordingWorkItem?.cancel()
            startRecordingWorkItem = nil
            
            // If we were recording, stop it
            if isRecording {
                print("⏹️ Stopping recording for TTS trigger")
                stopRecording()
            }
            
            // Reset fnPressed and require full release before new recording
            fnPressed = false
            requireRelease = true
            
            print("🔊 TTS hotkey detected - triggering TTS!")
            DispatchQueue.main.async { [weak self] in
                self?.onTTSTriggered()
            }
            return // Skip further processing
        }
        
        // Reset TTS trigger when the combination is broken
        if !matchesTTS {
            ttsTriggered = false
        }
        
        // Handle Cancel trigger (tap action, not hold)
        if matchesCancel && !cancelTriggered {
            cancelTriggered = true
            
            // Cancel any pending STT start
            startRecordingWorkItem?.cancel()
            startRecordingWorkItem = nil
            
            // If we were recording, cancel it (don't process)
            if isRecording {
                print("❌ Cancel hotkey - cancelling recording!")
                cancelRecording()
            }
            
            // Reset fnPressed and require full release before new recording
            fnPressed = false
            requireRelease = true
            print("🔒 Cancel triggered - requiring full release before new recording")
            return // Skip further processing
        }
        
        // Reset cancel trigger when the combination is broken
        if !matchesCancel {
            cancelTriggered = false
        }
        
        // Handle Smart OCR trigger (tap action)
        if matchesOCR && !smartOCRTriggered {
            smartOCRTriggered = true
            
            // Cancel any pending STT start
            startRecordingWorkItem?.cancel()
            startRecordingWorkItem = nil
            
            // If we were recording, stop it
            if isRecording {
                print("⏹️ Stopping recording for Smart OCR trigger")
                stopRecording()
            }
            
            fnPressed = false
            requireRelease = true
            
            print("📷 Smart OCR hotkey detected - triggering capture!")
            DispatchQueue.main.async { [weak self] in
                self?.onSmartOCRTriggered()
            }
            return
        }
        
        // Reset OCR trigger when the combination is broken
        if !matchesOCR {
            smartOCRTriggered = false
        }
        
        // Handle Scene Description trigger (tap action)
        if matchesScene && !sceneDescriptionTriggered {
            sceneDescriptionTriggered = true
            
            // Cancel any pending STT start
            startRecordingWorkItem?.cancel()
            startRecordingWorkItem = nil
            
            // If we were recording, stop it
            if isRecording {
                print("⏹️ Stopping recording for Scene Description trigger")
                stopRecording()
            }
            
            fnPressed = false
            requireRelease = true
            
            print("🎨 Scene Description hotkey detected - triggering capture!")
            DispatchQueue.main.async { [weak self] in
                self?.onSceneDescriptionTriggered()
            }
            return
        }
        
        // Reset scene description trigger when the combination is broken
        if !matchesScene {
            sceneDescriptionTriggered = false
        }

        // Handle STT (hold action)
        // Only start if: matches STT, not already pressed, no other action active, AND not requiring release
        if matchesSTT && !fnPressed && !ttsTriggered && !cancelTriggered && !smartOCRTriggered && !sceneDescriptionTriggered && !requireRelease {
            fnPressed = true
            
            // Cancel any existing work item
            startRecordingWorkItem?.cancel()
            
            let workItem = DispatchWorkItem { [weak self] in
                guard let self = self, self.fnPressed else { return }
                print("🎙️ STT hotkey (debounced) - starting recording!")
                self.startRecording()
            }
            
            startRecordingWorkItem = workItem
            // Short delay to allow for modifier combinations
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15, execute: workItem)
            
        } else if !primaryPressed && fnPressed {
            // Primary modifier released
            fnPressed = false
            
            // Cancel pending start if any
            startRecordingWorkItem?.cancel()
            startRecordingWorkItem = nil
            
            if isRecording {
                print("⏹️ Primary modifier released - stopping recording!")
                stopRecording()
            }
        }
    }

    private func startRecording() {
        guard !isRecording else { return }
        isRecording = true
        DispatchQueue.main.async { [weak self] in
            self?.onRecordingStart()
        }
    }

    private func stopRecording() {
        guard isRecording else { return }
        isRecording = false
        DispatchQueue.main.async { [weak self] in
            self?.onRecordingStop()
        }
    }
    
    private func cancelRecording() {
        guard isRecording else { return }
        isRecording = false
        DispatchQueue.main.async { [weak self] in
            self?.onRecordingCancel()
        }
    }

    private func promptForAccessibility() {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "Accessibility Permission Required"
            alert.informativeText = """
            Fluency needs Accessibility permission to detect the Fn key.
            
            1. Click "Open System Settings"
            2. If Fluency is already listed, REMOVE it first (click -)
            3. Click + and add Fluency again
            4. Make sure the toggle is ON
            
            Note: Each rebuild requires re-adding the app.
            """
            alert.alertStyle = .warning
            alert.addButton(withTitle: "Open System Settings")
            alert.addButton(withTitle: "Later")

            if alert.runModal() == .alertFirstButtonReturn {
                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                    NSWorkspace.shared.open(url)
                }
            }
        }
    }
}
