import Foundation

struct JournalEntry: Identifiable, Codable {
    let id: UUID
    let userId: UUID
    let guidedQuestionId: UUID?
    let content: String
    let aiPrompt: String?
    let aiResponse: String?
    let tags: [String]
    let isFavorite: Bool
    let entryType: String
    let createdAt: Date
    let updatedAt: Date
    let fuqAiPrompt: String?
    let fuqAiResponse: String?
    let isFollowUpDay: Bool?
    let usedForFollowUp: Bool?
    let followUpQuestion: String? // The question that was used when user responded (from follow_up_generation table)
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case guidedQuestionId = "guided_question_id"
        case content
        case aiPrompt = "ai_prompt"
        case aiResponse = "ai_response"
        case tags
        case isFavorite = "is_favorite"
        case entryType = "entry_type"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case fuqAiPrompt = "fuq_ai_prompt"
        case fuqAiResponse = "fuq_ai_response"
        case isFollowUpDay = "is_follow_up_day"
        case usedForFollowUp = "used_for_follow_up"
        case followUpQuestion = "follow_up_question"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        userId = try container.decode(UUID.self, forKey: .userId)
        guidedQuestionId = try container.decodeIfPresent(UUID.self, forKey: .guidedQuestionId)
        content = try container.decode(String.self, forKey: .content)
        aiPrompt = try container.decodeIfPresent(String.self, forKey: .aiPrompt)
        aiResponse = try container.decodeIfPresent(String.self, forKey: .aiResponse)
        tags = try container.decodeIfPresent([String].self, forKey: .tags) ?? []
        isFavorite = try container.decode(Bool.self, forKey: .isFavorite)
        entryType = try container.decode(String.self, forKey: .entryType)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        fuqAiPrompt = try container.decodeIfPresent(String.self, forKey: .fuqAiPrompt)
        fuqAiResponse = try container.decodeIfPresent(String.self, forKey: .fuqAiResponse)
        isFollowUpDay = try container.decodeIfPresent(Bool.self, forKey: .isFollowUpDay)
        usedForFollowUp = try container.decodeIfPresent(Bool.self, forKey: .usedForFollowUp)
        followUpQuestion = try container.decodeIfPresent(String.self, forKey: .followUpQuestion)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(userId, forKey: .userId)
        try container.encodeIfPresent(guidedQuestionId, forKey: .guidedQuestionId)
        try container.encode(content, forKey: .content)
        try container.encodeIfPresent(aiPrompt, forKey: .aiPrompt)
        try container.encodeIfPresent(aiResponse, forKey: .aiResponse)
        try container.encode(tags, forKey: .tags)
        try container.encode(isFavorite, forKey: .isFavorite)
        try container.encode(entryType, forKey: .entryType)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
        try container.encodeIfPresent(fuqAiPrompt, forKey: .fuqAiPrompt)
        try container.encodeIfPresent(fuqAiResponse, forKey: .fuqAiResponse)
        try container.encodeIfPresent(isFollowUpDay, forKey: .isFollowUpDay)
        try container.encodeIfPresent(usedForFollowUp, forKey: .usedForFollowUp)
        try container.encodeIfPresent(followUpQuestion, forKey: .followUpQuestion)
    }
    
    init(userId: UUID, guidedQuestionId: UUID?, content: String, aiPrompt: String? = nil, aiResponse: String? = nil, tags: [String] = [], isFavorite: Bool = false, entryType: String = "guided", fuqAiPrompt: String? = nil, fuqAiResponse: String? = nil, isFollowUpDay: Bool? = nil, usedForFollowUp: Bool? = nil, followUpQuestion: String? = nil) {
        self.id = UUID()
        self.userId = userId
        self.guidedQuestionId = guidedQuestionId
        self.content = content
        self.aiPrompt = aiPrompt
        self.aiResponse = aiResponse
        self.tags = tags
        self.isFavorite = isFavorite
        self.entryType = entryType
        self.createdAt = Date()
        self.updatedAt = Date()
        self.fuqAiPrompt = fuqAiPrompt
        self.fuqAiResponse = fuqAiResponse
        self.isFollowUpDay = isFollowUpDay
        self.usedForFollowUp = usedForFollowUp
        self.followUpQuestion = followUpQuestion
    }
    
    // Full initializer for updates
    init(id: UUID, userId: UUID, guidedQuestionId: UUID?, content: String, aiPrompt: String? = nil, aiResponse: String? = nil, tags: [String] = [], isFavorite: Bool = false, entryType: String = "guided", createdAt: Date, updatedAt: Date, fuqAiPrompt: String? = nil, fuqAiResponse: String? = nil, isFollowUpDay: Bool? = nil, usedForFollowUp: Bool? = nil, followUpQuestion: String? = nil) {
        self.id = id
        self.userId = userId
        self.guidedQuestionId = guidedQuestionId
        self.content = content
        self.aiPrompt = aiPrompt
        self.aiResponse = aiResponse
        self.tags = tags
        self.isFavorite = isFavorite
        self.entryType = entryType
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.fuqAiPrompt = fuqAiPrompt
        self.fuqAiResponse = fuqAiResponse
        self.isFollowUpDay = isFollowUpDay
        self.usedForFollowUp = usedForFollowUp
        self.followUpQuestion = followUpQuestion
    }
}
