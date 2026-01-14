import Foundation
import AppKit
import CoreGraphics

/// Service for capturing screen regions interactively using macOS native tools
class ScreenCaptureService {
    static let shared = ScreenCaptureService()
    
    /// Maximum dimension (width or height) for resized images to optimize API bandwidth
    private let maxImageDimension: CGFloat = 1024
    
    private init() {}
    
    /// Captures a user-selected screen region interactively
    /// - Returns: Image data (PNG) of the captured region, or nil if cancelled
    func captureRegion() async throws -> Data? {
        // Create a temporary file path for the screenshot
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "fluency_capture_\(UUID().uuidString).png"
        let tempPath = tempDir.appendingPathComponent(fileName)
        
        // Use macOS screencapture utility in interactive mode
        // -i: interactive mode (crosshair selection)
        // -x: no sound
        // -t png: output format
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
        process.arguments = ["-i", "-x", "-t", "png", tempPath.path]
        
        // Run the process and wait for completion
        return try await withCheckedThrowingContinuation { continuation in
            do {
                process.terminationHandler = { [weak self] proc in
                    // Check if file was created (user completed selection)
                    if FileManager.default.fileExists(atPath: tempPath.path) {
                        do {
                            let imageData = try Data(contentsOf: tempPath)
                            // Clean up temp file
                            try? FileManager.default.removeItem(at: tempPath)
                            
                            // Resize image for API optimization
                            if let resizedData = self?.resizeImage(data: imageData) {
                                continuation.resume(returning: resizedData)
                            } else {
                                continuation.resume(returning: imageData)
                            }
                        } catch {
                            try? FileManager.default.removeItem(at: tempPath)
                            continuation.resume(throwing: ScreenCaptureError.readFailed(error))
                        }
                    } else {
                        // User cancelled (pressed ESC)
                        continuation.resume(returning: nil)
                    }
                }
                
                try process.run()
            } catch {
                continuation.resume(throwing: ScreenCaptureError.captureFailed(error))
            }
        }
    }
    
    /// Resizes image data to optimize for API transmission
    /// - Parameter data: Original PNG image data
    /// - Returns: Resized image data, or original if resize fails
    private func resizeImage(data: Data) -> Data? {
        guard let image = NSImage(data: data) else { return nil }
        
        let originalSize = image.size
        
        // Check if resize is needed
        guard originalSize.width > maxImageDimension || originalSize.height > maxImageDimension else {
            return data // No resize needed
        }
        
        // Calculate new size maintaining aspect ratio
        let scale: CGFloat
        if originalSize.width > originalSize.height {
            scale = maxImageDimension / originalSize.width
        } else {
            scale = maxImageDimension / originalSize.height
        }
        
        let newSize = NSSize(
            width: originalSize.width * scale,
            height: originalSize.height * scale
        )
        
        // Create resized image
        let resizedImage = NSImage(size: newSize)
        resizedImage.lockFocus()
        image.draw(
            in: NSRect(origin: .zero, size: newSize),
            from: NSRect(origin: .zero, size: originalSize),
            operation: .copy,
            fraction: 1.0
        )
        resizedImage.unlockFocus()
        
        // Convert to PNG data
        guard let tiffData = resizedImage.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let pngData = bitmap.representation(using: .png, properties: [:]) else {
            return data // Return original if resize fails
        }
        
        print("📸 Resized image from \(Int(originalSize.width))x\(Int(originalSize.height)) to \(Int(newSize.width))x\(Int(newSize.height))")
        return pngData
    }
}

// MARK: - Errors

enum ScreenCaptureError: LocalizedError {
    case captureFailed(Error)
    case readFailed(Error)
    case noPermission
    
    var errorDescription: String? {
        switch self {
        case .captureFailed(let error):
            return "Screen capture failed: \(error.localizedDescription)"
        case .readFailed(let error):
            return "Failed to read captured image: \(error.localizedDescription)"
        case .noPermission:
            return "Screen recording permission not granted"
        }
    }
}
