import Foundation

/// Service for analyzing images using Gemini 3 Flash vision capabilities
class VisionService {
    static let shared = VisionService()
    
    private let endpoint = "https://generativelanguage.googleapis.com/v1beta/models/gemini-3-flash-preview:generateContent"
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Extracts text from an image using OCR
    /// - Parameter imageData: PNG image data
    /// - Returns: Extracted text formatted for natural speech
    func extractText(from imageData: Data) async throws -> String {
        let prompt = """
        Extract the main content text from this image. Ignore UI chrome, menus, navigation bars, and buttons. 
        Format the text for natural speech - clean up any formatting artifacts, fix obvious OCR errors, 
        and present it as flowing text. If there's no readable text, say "No text found in the selected area."
        """
        
        return try await analyzeImage(imageData: imageData, prompt: prompt)
    }
    
    /// Describes the visual content of an image
    /// - Parameter imageData: PNG image data
    /// - Returns: Concise description of the visual content
    func describeScene(from imageData: Data) async throws -> String {
        let prompt = """
        Describe the visual content of this image concisely. If it's a chart or graph, summarize the trend or key data points. 
        If it's a photo, describe the scene and main subjects. If it's a diagram, explain what it shows. 
        If it's code, summarize what the code does. Keep the description brief and suitable for text-to-speech.
        """
        
        return try await analyzeImage(imageData: imageData, prompt: prompt)
    }
    
    // MARK: - Private Methods
    
    private func analyzeImage(imageData: Data, prompt: String) async throws -> String {
        guard let apiKey = KeychainHelper.getAPIKey(for: .gemini), !apiKey.isEmpty else {
            throw VisionError.noAPIKey
        }
        
        // Build request URL with API key
        guard var urlComponents = URLComponents(string: endpoint) else {
            throw VisionError.invalidURL
        }
        urlComponents.queryItems = [URLQueryItem(name: "key", value: apiKey)]
        
        guard let url = urlComponents.url else {
            throw VisionError.invalidURL
        }
        
        // Encode image as Base64
        let base64Image = imageData.base64EncodedString()
        
        // Build request body with minimal thinking for speed
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt],
                        [
                            "inline_data": [
                                "mime_type": "image/png",
                                "data": base64Image
                            ]
                        ]
                    ]
                ]
            ],
            "generationConfig": [
                "temperature": 1.0,
                "maxOutputTokens": 1024
            ],
            "thinkingConfig": [
                "thinkingLevel": "minimal"  // Lowest latency for Gemini 3 Flash
            ]
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        // Make API request
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw VisionError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            // Try to extract error message
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = errorJson["error"] as? [String: Any],
               let message = error["message"] as? String {
                throw VisionError.apiError(message)
            }
            throw VisionError.apiError("HTTP \(httpResponse.statusCode)")
        }
        
        // Parse response
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]],
              let firstCandidate = candidates.first,
              let content = firstCandidate["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let textPart = parts.first(where: { $0["text"] != nil }),
              let text = textPart["text"] as? String else {
            throw VisionError.invalidResponse
        }
        
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Errors

enum VisionError: LocalizedError {
    case noAPIKey
    case invalidURL
    case invalidResponse
    case apiError(String)
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .noAPIKey:
            return "Gemini API key not configured. Please add your API key in Settings."
        case .invalidURL:
            return "Invalid API URL"
        case .invalidResponse:
            return "Invalid response from vision API"
        case .apiError(let message):
            return "Vision API error: \(message)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}
