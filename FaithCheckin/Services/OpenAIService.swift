import Foundation
import Combine

class OpenAIService: ObservableObject {
    private let apiKey: String
    private let chatCompletionsURL = URL(string: "https://api.openai.com/v1/chat/completions")!
    private let responsesURL = URL(string: "https://api.openai.com/v1/responses")!
    
    init() {
        // Initialize with API key from Config.plist
        guard let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
              let config = NSDictionary(contentsOfFile: path),
              let key = config["OpenAIAPIKey"] as? String else {
            fatalError("OpenAI API key not found in Config.plist")
        }
        
        self.apiKey = key
    }
    
    /// Generates AI response using specified GPT model with reasoning and verbosity controls
    /// - Parameters:
    ///   - prompt: The prompt to send to the AI
    ///   - model: The model to use ("gpt-5" uses new /v1/responses endpoint, others use /v1/chat/completions)
    ///   - analysisType: The type of analysis ("weekly" or "monthly") to determine system message
    func generateAIResponse(for prompt: String, model: String = "gpt-5", analysisType: String = "weekly") async throws -> String {
        print("🤖🤖🤖🤖🤖🤖🤖🤖🤖🤖🤖🤖🤖🤖🤖🤖🤖🤖🤖🤖")
        print("🤖 OPENAI API CALL STARTED")
        print("🤖 Model: \(model)")
        print("🤖 AnalysisType: \(analysisType)")
        print("🤖 Prompt length: \(prompt.count) characters")
        print("🤖 Prompt preview: \(prompt.prefix(100))...")
        print("🤖🤖🤖🤖🤖🤖🤖🤖🤖🤖🤖🤖🤖🤖🤖🤖🤖🤖🤖🤖")
        
        // Determine system message based on analysis type
        // Only add system message for analyzer calls (weekly/monthly), not for journal entries
        let systemMessage: String?
        if analysisType == "monthly" {
            systemMessage = """
You are an AI theological and biblical historian. 

Your job is to analyze the user's journal input and produce:

1) top four moods (one word each) + count in format: mood(#), mood(#), ...

2) a summary + actionable faith-based steps + a spiritual goal for the next week

3) a spiritual wellness "faith score" from 60–100

The tone must be encouraging, supportive, and grounded in Christian faith.
"""
        } else if analysisType == "weekly" {
            // Weekly analysis
            systemMessage = """
You are an AI theological and biblical historian. 

Your job is to analyze the user's journal input and produce:

1) top three moods (one word each) + count in format: mood(#), mood(#), ...

2) a summary + actionable faith-based steps + a spiritual goal for the next week

3) a spiritual wellness "faith score" from 60–100

The tone must be encouraging, supportive, and grounded in Christian faith.

Do NOT exceed ~200 words in paragraph 2.
"""
        } else {
            // For journal entries (guided/open/follow-up), don't add system message
            // The prompt itself contains all instructions
            systemMessage = nil
        }
        
        // GPT-5 uses different endpoint and structure depending on use case
        // Guided/open questions (journal): gpt-5 via /v1/chat/completions with reasoning capped at 800
        // Analyzer (weekly/monthly): gpt-5 via /v1/responses
        // gpt-5-mini: /v1/chat/completions
        // Support versioned model IDs (e.g. gpt-5-2025-08-07)
        let isGPT5 = model == "gpt-5" || model.hasPrefix("gpt-5-")
        let useJournalGpt5Format = isGPT5 && analysisType == "journal"  // guided & open questions
        let useResponsesEndpoint = isGPT5 && analysisType != "journal" // analyzer only
        
        // Create the request body - different structure per case
        let requestBody: [String: Any]
        let apiURL: URL
        
        if useJournalGpt5Format {
            // Guided & open questions: gpt-5 via chat/completions – no "reasoning" (API rejects it), use system + user, top_p
            apiURL = chatCompletionsURL
            requestBody = [
                "model": "gpt-5",
                "max_completion_tokens": 2000,
                "temperature": 1,
                "top_p": 1,
                "messages": [
                    [
                        "role": "system",
                        "content": "Keep internal reasoning minimal. Do not plan extensively. Do not justify your output. Respond directly and concisely."
                    ],
                    ["role": "user", "content": prompt]
                ]
            ]
        } else if useResponsesEndpoint {
            // GPT-5 analyzer uses /v1/responses endpoint with new structure
            apiURL = responsesURL
            var body: [String: Any] = [
                "model": model,
                "input": []
            ]
            
            if let systemMessage = systemMessage {
                body["input"] = [
                    ["role": "system", "content": systemMessage],
                    ["role": "user", "content": prompt]
                ]
            } else {
                body["input"] = [["role": "user", "content": prompt]]
            }
            
            body["max_output_tokens"] = 4000
            requestBody = body
        } else {
            // GPT-5-mini and other models use /v1/chat/completions endpoint
            apiURL = chatCompletionsURL
            var messages: [[String: Any]] = []
            if let systemMessage = systemMessage {
                messages.append(["role": "system", "content": systemMessage])
            }
            messages.append(["role": "user", "content": prompt])
            
            requestBody = [
                "model": model,
                "messages": messages,
                "max_completion_tokens": 2000
            ]
        }
        
        // Create URL request
        var request = URLRequest(url: apiURL)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            
            // Log the raw JSON being sent
            if let jsonData = request.httpBody,
               let jsonString = String(data: jsonData, encoding: .utf8) {
                print("📤 RAW JSON SENT TO OPENAI:")
                print("═══════════════════════════════════════════════════")
                print(jsonString)
                print("═══════════════════════════════════════════════════")
            }
        } catch {
            throw OpenAIError.configurationError("Failed to serialize request body: \(error.localizedDescription)")
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // Log the raw JSON being received
            if let responseString = String(data: data, encoding: .utf8) {
                print("📥 RAW JSON RECEIVED FROM OPENAI:")
                print("═══════════════════════════════════════════════════")
                print(responseString)
                print("═══════════════════════════════════════════════════")
            }
            
            // Check HTTP response
            if let httpResponse = response as? HTTPURLResponse {
                print("📡 OpenAI API HTTP Status: \(httpResponse.statusCode)")
                
                if httpResponse.statusCode != 200 {
                    let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                    
                    // Handle specific OpenAI error cases
                    if httpResponse.statusCode == 429 {
                        // Parse error details for quota issues
                        if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                           let error = errorData["error"] as? [String: Any],
                           let type = error["type"] as? String,
                           type == "insufficient_quota" {
                            throw OpenAIError.quotaExceeded
                        } else {
                            throw OpenAIError.rateLimited
                        }
                    } else if httpResponse.statusCode == 401 {
                        throw OpenAIError.invalidAPIKey
                    } else {
                        throw OpenAIError.apiError("HTTP \(httpResponse.statusCode): \(errorMessage)")
                    }
                }
            }
            
            // Parse JSON response
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                throw OpenAIError.invalidResponse("Invalid JSON response")
            }
            
            // Extract the AI response content - different parsing for /v1/responses vs /v1/chat/completions
            if useResponsesEndpoint {
                // GPT-5 /v1/responses endpoint structure
                // Response format: { "output": [{ "type": "reasoning" }, { "type": "message", "content": [...] }] }
                if let output = json["output"] as? [[String: Any]] {
                    // Find the message object (skip reasoning objects)
                    for outputItem in output {
                        if let type = outputItem["type"] as? String, type == "message" {
                            // Try content array with output_text blocks
                            if let contentArray = outputItem["content"] as? [[String: Any]] {
                                let assembled = contentArray.compactMap { block -> String? in
                                    if let blockType = block["type"] as? String, blockType == "output_text" {
                                        return block["text"] as? String
                                    }
                                    return nil
                                }.joined()
                                
                                if !assembled.isEmpty {
                                    print("✅ OpenAI API response received (GPT-5 output_text format): \(assembled.prefix(100))...")
                                    return assembled
                                }
                            }
                            
                            // Try direct string content (legacy format)
                            if let content = outputItem["content"] as? String, !content.isEmpty {
                                print("✅ OpenAI API response received (GPT-5 string format): \(content.prefix(100))...")
                                return content
                            }
                        }
                    }
                }
            } else {
                // Legacy /v1/chat/completions endpoint structure
                guard let choices = json["choices"] as? [[String: Any]],
                      let firstChoice = choices.first else {
                    throw OpenAIError.invalidResponse("No choices in response")
                }
                
                // First: try GPT-4 style (string content)
                if let message = firstChoice["message"] as? [String: Any] {
                    // Check if content exists and is not null
                    if let contentValue = message["content"] {
                        // Try string content (GPT-4 style)
                        if let content = contentValue as? String, !content.isEmpty {
                            print("✅ OpenAI API response received (string format): \(content.prefix(100))...")
                            return content
                        }
                        
                        // Handle null or empty string - log for debugging
                        if contentValue is NSNull || (contentValue as? String)?.isEmpty == true {
                            print("⚠️ Content is null or empty. Checking usage details...")
                            if let usage = json["usage"] as? [String: Any],
                               let completionTokens = usage["completion_tokens"] as? Int,
                               let completionDetails = usage["completion_tokens_details"] as? [String: Any],
                               let reasoningTokens = completionDetails["reasoning_tokens"] as? Int {
                                print("⚠️ Token usage: \(completionTokens) total, \(reasoningTokens) reasoning")
                                if reasoningTokens >= completionTokens {
                                    throw OpenAIError.invalidResponse("All tokens used for reasoning. Increase max_completion_tokens.")
                                }
                            }
                        }
                        
                        // Try array-of-blocks content (GPT-5 format)
                        if let contentBlocks = contentValue as? [[String: Any]] {
                            let assembled = contentBlocks.compactMap { block -> String? in
                                if block["type"] as? String == "text" {
                                    return block["text"] as? String
                                }
                                return nil
                            }.joined()
                            
                            if !assembled.isEmpty {
                                print("✅ OpenAI API response received (block format): \(assembled.prefix(100))...")
                                return assembled
                            }
                        }
                    } else {
                        print("⚠️ No content field found in message")
                    }
                }
                
                // Second: try GPT-5 delta streaming structure
                if let delta = firstChoice["delta"] as? [String: Any] {
                    // Try string content in delta
                    if let deltaContent = delta["content"] as? String, !deltaContent.isEmpty {
                        print("✅ OpenAI API response received (delta format): \(deltaContent.prefix(100))...")
                        return deltaContent
                    }
                    
                    // Try array-of-blocks in delta
                    if let deltaBlocks = delta["content"] as? [[String: Any]] {
                        let assembled = deltaBlocks.compactMap { block -> String? in
                            if block["type"] as? String == "text" {
                                return block["text"] as? String
                            }
                            return nil
                        }.joined()
                        
                        if !assembled.isEmpty {
                            print("✅ OpenAI API response received (delta block format): \(assembled.prefix(100))...")
                            return assembled
                        }
                    }
                }
            }
            
            // Universal fallback: try parsing Responses API output format regardless of branch
            // Handles versioned model IDs and format variations
            if let output = json["output"] as? [[String: Any]] {
                for outputItem in output {
                    if let type = outputItem["type"] as? String, type == "message" {
                        if let contentArray = outputItem["content"] as? [[String: Any]] {
                            let assembled = contentArray.compactMap { block -> String? in
                                let blockType = block["type"] as? String
                                if blockType == "output_text" || blockType == "text" {
                                    return block["text"] as? String
                                }
                                return nil
                            }.joined()
                            if !assembled.isEmpty {
                                print("✅ OpenAI API response received (fallback output_text format): \(assembled.prefix(100))...")
                                return assembled
                            }
                        }
                    }
                }
            }
            
            // If we get here, no content was found in any recognized format
            print("❌ No content found in response. Full response: \(json)")
            throw OpenAIError.invalidResponse("No content in any recognized format")
            
        } catch let error as OpenAIError {
            throw error
        } catch {
            print("❌ OpenAI API network error: \(error.localizedDescription)")
            throw OpenAIError.apiError("Network error: \(error.localizedDescription)")
        }
    }
}

// MARK: - OpenAI Error Types
enum OpenAIError: Error, LocalizedError {
    case invalidResponse(String)
    case apiError(String)
    case configurationError(String)
    case quotaExceeded
    case rateLimited
    case invalidAPIKey
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse(let message):
            return "Invalid OpenAI response: \(message)"
        case .apiError(let message):
            return "OpenAI API error: \(message)"
        case .configurationError(let message):
            return "Configuration error: \(message)"
        case .quotaExceeded:
            return "OpenAI quota exceeded. Please check your billing and usage limits at https://platform.openai.com/usage"
        case .rateLimited:
            return "OpenAI rate limit exceeded. Please wait a moment and try again."
        case .invalidAPIKey:
            return "Invalid OpenAI API key. Please check your API key configuration."
        }
    }
}
