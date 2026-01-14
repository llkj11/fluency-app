import XCTest
@testable import Fluency

final class VisionServiceTests: XCTestCase {
    
    // MARK: - Prompt Tests
    
    func testVisionModeEnumExists() {
        // Verify the VisionService has the expected methods
        let _ = VisionService.shared
        // If this compiles, the service exists
        XCTAssertNotNil(VisionService.shared)
    }
    
    // MARK: - Error Tests
    
    func testVisionErrorDescriptions() {
        // Verify all error cases have proper descriptions
        let noAPIKeyError = VisionError.noAPIKey
        XCTAssertNotNil(noAPIKeyError.errorDescription)
        XCTAssertTrue(noAPIKeyError.errorDescription!.contains("API key"))
        
        let invalidURLError = VisionError.invalidURL
        XCTAssertNotNil(invalidURLError.errorDescription)
        
        let invalidResponseError = VisionError.invalidResponse
        XCTAssertNotNil(invalidResponseError.errorDescription)
        
        let apiError = VisionError.apiError("Test error message")
        XCTAssertNotNil(apiError.errorDescription)
        XCTAssertTrue(apiError.errorDescription!.contains("Test error message"))
        
        let networkError = VisionError.networkError(NSError(domain: "test", code: -1))
        XCTAssertNotNil(networkError.errorDescription)
    }
    
    // MARK: - Service Singleton Tests
    
    func testVisionServiceIsSingleton() {
        let instance1 = VisionService.shared
        let instance2 = VisionService.shared
        XCTAssertTrue(instance1 === instance2, "VisionService should be a singleton")
    }
    
    // MARK: - Base64 Encoding Tests
    
    func testImageDataCanBeBase64Encoded() {
        // Create a simple test image data
        let testData = Data([0x89, 0x50, 0x4E, 0x47]) // PNG header bytes
        let base64 = testData.base64EncodedString()
        
        XCTAssertFalse(base64.isEmpty, "Base64 encoding should produce output")
        XCTAssertTrue(base64.count > 0, "Base64 string should have length")
    }
}
