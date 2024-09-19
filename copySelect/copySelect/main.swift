//
//  main.swift
//  copySelect
//
//  Created by Robert J. P. Oberg on 9/16/24.
//

import Cocoa
import ApplicationServices

func requestAccessibilityPermission() {
    let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
    let accessEnabled = AXIsProcessTrustedWithOptions(options)
    
    if !accessEnabled {
        NSLog("Accessibility permission is required. Please grant permission in System Preferences > Security & Privacy > Privacy > Accessibility.")
        NSLog("After granting permission, please run the application again.")
        exit(1)
    } else {
        NSLog("Accessibility permission is granted.")
    }
}

func checkTextSelectionAndCopyToClipboard() -> Bool {
    NSLog("Starting text selection check")
    
    let systemWideElement = AXUIElementCreateSystemWide()
    NSLog("Created system-wide element")
    
    var focusedApp: AXUIElement?
    var value: CFTypeRef?
    let focusedAppResult = AXUIElementCopyAttributeValue(systemWideElement, kAXFocusedApplicationAttribute as CFString, &value)
    
    NSLog("Focused app result: \(focusedAppResult.rawValue)")
    
    if focusedAppResult == .success {
        focusedApp = (value as! AXUIElement)
        NSLog("Successfully got focused app")
    } else {
        NSLog("Failed to get focused app. Error code: \(focusedAppResult.rawValue)")
        NSLog("Attempting to get frontmost application")
        
        if let frontmostApp = NSWorkspace.shared.frontmostApplication {
            NSLog("Got frontmost application")
            focusedApp = AXUIElementCreateApplication(frontmostApp.processIdentifier)
        } else {
            NSLog("Failed to get frontmost application")
            return false
        }
    }
    
    guard let app = focusedApp else {
        NSLog("No focused app available")
        return false
    }
    
    var focusedElement: AXUIElement?
    value = nil
    let focusedElementResult = AXUIElementCopyAttributeValue(app, kAXFocusedUIElementAttribute as CFString, &value)
    
    NSLog("Focused element result: \(focusedElementResult.rawValue)")
    
    if focusedElementResult == .success {
        focusedElement = (value as! AXUIElement)
    } else {
        NSLog("Failed to get focused element. Error code: \(focusedElementResult.rawValue)")
        return false
    }
    
    guard let element = focusedElement else {
        NSLog("No focused element available")
        return false
    }
    
    value = nil
    let selectedTextResult = AXUIElementCopyAttributeValue(element, kAXSelectedTextAttribute as CFString, &value)
    
    NSLog("Selected text result: \(selectedTextResult.rawValue)")
    
    if selectedTextResult == .success, let text = value as? String {
        NSLog("Selected text: \(text)")
        
        // Copy the selected text to clipboard
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        NSLog("Copied selected text to clipboard")
        
        return !text.isEmpty
    } else {
        NSLog("Failed to get selected text or text is empty. Error code: \(selectedTextResult.rawValue)")
    }
    
    return false
}

NSLog("Application started")
requestAccessibilityPermission()
if checkTextSelectionAndCopyToClipboard() {
    // print("true")
    NSLog("Text is selected and copied to clipboard")
} else {
    // print("false")
    NSLog("No text selected")
}
NSLog("Application finished")
