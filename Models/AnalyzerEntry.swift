import Foundation

struct AnalyzerEntry: Identifiable, Codable, Equatable {
    let id: UUID
    let userId: UUID
    let analyzerAiPrompt: String?
    let analyzerAiResponse: String?
    let entryType: String
    let tags: [String]
    let createdAt: Date
    let updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case analyzerAiPrompt = "analyzer_ai_prompt"
        case analyzerAiResponse = "analyzer_ai_response"
        case entryType = "entry_type"
        case tags
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    init(
        id: UUID = UUID(),
        userId: UUID,
        analyzerAiPrompt: String? = nil,
        analyzerAiResponse: String? = nil,
        entryType: String,
        tags: [String] = [],
        createdAt: Date = Date(),
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.userId = userId
        self.analyzerAiPrompt = analyzerAiPrompt
        self.analyzerAiResponse = analyzerAiResponse
        self.entryType = entryType
        self.tags = tags
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

