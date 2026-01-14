import Foundation
import AppKit
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

/// Service for capturing screen regions interactively using macOS native tools
class ScreenCaptureService {
    static let shared = ScreenCaptureService()
    
    /// Maximum dimension (width or height) for resized images to optimize API bandwidth
    private let maxImageDimension: CGFloat = 1024
    
    /// Track if a capture is currently in progress
    private var isCaptureInProgress = false
    
    /// Reference to current process for potential cancellation
    private var currentProcess: Process?
    
    private init() {}
    
    /// Captures a user-selected screen region interactively
    /// - Returns: Image data (PNG) of the captured region, or nil if cancelled
    func captureRegion() async throws -> Data? {
        // Guard against multiple simultaneous captures
        guard !isCaptureInProgress else {
            print("⚠️ Screen capture already in progress, ignoring request")
            return nil
        }
        
        isCaptureInProgress = true
        print("📷 Starting screen capture...")
        
        defer {
            isCaptureInProgress = false
            currentProcess = nil
            print("📷 Capture session ended")
        }
        
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
        
        currentProcess = process
        
        // Run the process and wait for completion
        return try await withCheckedThrowingContinuation { [weak self] continuation in
            do {
                process.terminationHandler = { proc in
                    print("📷 Screencapture process terminated with status: \(proc.terminationStatus)")
                    
                    // Check if file was created (user completed selection)
                    if FileManager.default.fileExists(atPath: tempPath.path) {
                        print("📷 Screenshot file exists at: \(tempPath.path)")
                        do {
                            let imageData = try Data(contentsOf: tempPath)
                            print("📷 Loaded image data: \(imageData.count) bytes")
                            // Clean up temp file
                            try? FileManager.default.removeItem(at: tempPath)
                            
                            // Resize image for API optimization
                            if let resizedData = self?.resizeImage(data: imageData) {
                                continuation.resume(returning: resizedData)
                            } else {
                                continuation.resume(returning: imageData)
                            }
                        } catch {
                            print("❌ Failed to read image: \(error)")
                            try? FileManager.default.removeItem(at: tempPath)
                            continuation.resume(throwing: ScreenCaptureError.readFailed(error))
                        }
                    } else {
                        // User cancelled (pressed ESC) or capture failed
                        print("📷 No screenshot file created (user cancelled or capture failed)")
                        continuation.resume(returning: nil)
                    }
                }
                
                try process.run()
                print("📷 Screencapture process started with PID: \(process.processIdentifier)")
            } catch {
                print("❌ Failed to start screencapture: \(error)")
                continuation.resume(throwing: ScreenCaptureError.captureFailed(error))
            }
        }
    }
    
    /// Cancel any in-progress capture
    func cancelCapture() {
        if let process = currentProcess, process.isRunning {
            print("📷 Cancelling in-progress capture")
            process.terminate()
        }
    }
    
    /// Resizes image data to optimize for API transmission
    /// - Parameter data: Original PNG image data
    /// - Returns: Resized image data, or original if resize fails
    private func resizeImage(data: Data) -> Data? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            print("⚠️ Could not create CGImage from data")
            return nil
        }
        
        let originalWidth = CGFloat(cgImage.width)
        let originalHeight = CGFloat(cgImage.height)
        
        // Check if resize is needed
        guard originalWidth > maxImageDimension || originalHeight > maxImageDimension else {
            print("📸 Image size \(Int(originalWidth))x\(Int(originalHeight)) - no resize needed")
            return data // No resize needed
        }
        
        // Calculate new size maintaining aspect ratio
        let scale: CGFloat
        if originalWidth > originalHeight {
            scale = maxImageDimension / originalWidth
        } else {
            scale = maxImageDimension / originalHeight
        }
        
        let newWidth = Int(originalWidth * scale)
        let newHeight = Int(originalHeight * scale)
        
        // Create resized image using Core Graphics (thread-safe)
        // Use standard sRGB color space and premultiplied alpha (universally supported)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
        
        guard let context = CGContext(
                data: nil,
                width: newWidth,
                height: newHeight,
                bitsPerComponent: 8,
                bytesPerRow: 0,
                space: colorSpace,
                bitmapInfo: bitmapInfo
              ) else {
            print("⚠️ Could not create CGContext for resizing")
            return data
        }
        
        context.interpolationQuality = .high
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))
        
        guard let resizedCGImage = context.makeImage() else {
            print("⚠️ Could not create resized image")
            return data
        }
        
        // Convert to PNG data
        let mutableData = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(mutableData as CFMutableData, UTType.png.identifier as CFString, 1, nil) else {
            print("⚠️ Could not create image destination")
            return data
        }
        
        CGImageDestinationAddImage(destination, resizedCGImage, nil)
        
        guard CGImageDestinationFinalize(destination) else {
            print("⚠️ Could not finalize image destination")
            return data
        }
        
        print("📸 Resized image from \(Int(originalWidth))x\(Int(originalHeight)) to \(newWidth)x\(newHeight)")
        return mutableData as Data
    }
}

// MARK: - Errors

enum ScreenCaptureError: LocalizedError {
    case captureFailed(Error)
    case readFailed(Error)
    case noPermission
    case alreadyInProgress
    
    var errorDescription: String? {
        switch self {
        case .captureFailed(let error):
            return "Screen capture failed: \(error.localizedDescription)"
        case .readFailed(let error):
            return "Failed to read captured image: \(error.localizedDescription)"
        case .noPermission:
            return "Screen recording permission not granted"
        case .alreadyInProgress:
            return "Another screen capture is already in progress"
        }
    }
}
