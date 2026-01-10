import AppKit
import ApplicationServices

class PasteService {
    func paste(text: String) {
        // Try direct paste first via Accessibility API
        if pasteDirectly(text: text) {
            return
        }

        // Fallback: Use pasteboard + simulated Cmd+V
        pasteViaPasteboard(text: text)
    }

    private func pasteDirectly(text: String) -> Bool {
        guard let focusedElement = getFocusedElement() else {
            return false
        }

        // Check if element accepts text input
        var settable: DarwinBoolean = false
        let settableResult = AXUIElementIsAttributeSettable(focusedElement, kAXValueAttribute as CFString, &settable)

        if settableResult == .success && settable.boolValue {
            let result = AXUIElementSetAttributeValue(focusedElement, kAXValueAttribute as CFString, text as CFTypeRef)
            if result == .success {
                return true
            }

            // Try inserting at selection instead of replacing all
            var selectedRange: CFTypeRef?
            let rangeResult = AXUIElementCopyAttributeValue(focusedElement, kAXSelectedTextRangeAttribute as CFString, &selectedRange)

            if rangeResult == .success {
                let insertResult = AXUIElementSetAttributeValue(focusedElement, kAXSelectedTextAttribute as CFString, text as CFTypeRef)
                if insertResult == .success {
                    return true
                }
            }
        }

        return false
    }

    private func pasteViaPasteboard(text: String) {
        // Save current pasteboard content
        let pasteboard = NSPasteboard.general
        let previousContent = pasteboard.string(forType: .string)

        // Set new content
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)

        // Simulate Cmd+V
        simulateKeyPress(keyCode: 9, flags: .maskCommand) // 9 = V

        // Restore previous content after a short delay
        if let previous = previousContent {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                pasteboard.clearContents()
                pasteboard.setString(previous, forType: .string)
            }
        }
    }

    private func getFocusedElement() -> AXUIElement? {
        let systemWide = AXUIElementCreateSystemWide()

        var focusedApp: CFTypeRef?
        let appResult = AXUIElementCopyAttributeValue(systemWide, kAXFocusedApplicationAttribute as CFString, &focusedApp)

        guard appResult == .success, let app = focusedApp else {
            return nil
        }

        var focusedElement: CFTypeRef?
        let elementResult = AXUIElementCopyAttributeValue(app as! AXUIElement, kAXFocusedUIElementAttribute as CFString, &focusedElement)

        guard elementResult == .success else {
            return nil
        }

        return (focusedElement as! AXUIElement)
    }

    private func simulateKeyPress(keyCode: CGKeyCode, flags: CGEventFlags) {
        let source = CGEventSource(stateID: .hidSystemState)

        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true)
        keyDown?.flags = flags
        keyDown?.post(tap: .cghidEventTap)

        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false)
        keyUp?.flags = flags
        keyUp?.post(tap: .cghidEventTap)
    }
}
