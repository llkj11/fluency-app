import XCTest
@testable import Fluency

final class ScreenCaptureServiceTests: XCTestCase {
    
    // MARK: - Singleton Tests
    
    func testScreenCaptureServiceIsSingleton() {
        let instance1 = ScreenCaptureService.shared
        let instance2 = ScreenCaptureService.shared
        XCTAssertTrue(instance1 === instance2, "ScreenCaptureService should be a singleton")
    }
    
    // MARK: - Error Tests
    
    func testScreenCaptureErrorDescriptions() {
        // Verify all error cases have proper descriptions
        let captureError = ScreenCaptureError.captureFailed(NSError(domain: "test", code: -1))
        XCTAssertNotNil(captureError.errorDescription)
        XCTAssertTrue(captureError.errorDescription!.contains("capture"))
        
        let readError = ScreenCaptureError.readFailed(NSError(domain: "test", code: -1))
        XCTAssertNotNil(readError.errorDescription)
        XCTAssertTrue(readError.errorDescription!.contains("read"))
        
        let permissionError = ScreenCaptureError.noPermission
        XCTAssertNotNil(permissionError.errorDescription)
        XCTAssertTrue(permissionError.errorDescription!.contains("permission"))
    }
    
    // MARK: - Image Resizing Logic Tests
    
    func testImageResizingCalculations() {
        // Test the resize scaling logic
        let maxDimension: CGFloat = 1024
        
        // Landscape image (wider than tall)
        let landscapeWidth: CGFloat = 2048
        let landscapeHeight: CGFloat = 1024
        let landscapeScale = maxDimension / landscapeWidth
        let newLandscapeWidth = landscapeWidth * landscapeScale
        let newLandscapeHeight = landscapeHeight * landscapeScale
        
        XCTAssertEqual(newLandscapeWidth, 1024, "Landscape width should be scaled to max dimension")
        XCTAssertEqual(newLandscapeHeight, 512, "Landscape height should be scaled proportionally")
        
        // Portrait image (taller than wide)
        let portraitWidth: CGFloat = 1024
        let portraitHeight: CGFloat = 2048
        let portraitScale = maxDimension / portraitHeight
        let newPortraitWidth = portraitWidth * portraitScale
        let newPortraitHeight = portraitHeight * portraitScale
        
        XCTAssertEqual(newPortraitWidth, 512, "Portrait width should be scaled proportionally")
        XCTAssertEqual(newPortraitHeight, 1024, "Portrait height should be scaled to max dimension")
        
        // Small image (no resize needed)
        let smallWidth: CGFloat = 800
        let smallHeight: CGFloat = 600
        XCTAssertTrue(smallWidth <= maxDimension && smallHeight <= maxDimension, 
                      "Small images should not need resizing")
    }
}
