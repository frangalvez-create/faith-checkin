//
//  FollowUpGeneration.swift
//  Centered
//
//  Created by Family Galvez on 12/11/25.
//

import Foundation

struct FollowUpGeneration: Identifiable, Codable, Equatable {
    let id: UUID
    let userId: UUID
    let fuqAiPrompt: String
    let fuqAiResponse: String
    let sourceEntryId: UUID? // The past journal entry used to generate this question
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case fuqAiPrompt = "fuq_ai_prompt"
        case fuqAiResponse = "fuq_ai_response"
        case sourceEntryId = "source_entry_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    init(id: UUID = UUID(), userId: UUID, fuqAiPrompt: String, fuqAiResponse: String, sourceEntryId: UUID? = nil, createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.userId = userId
        self.fuqAiPrompt = fuqAiPrompt
        self.fuqAiResponse = fuqAiResponse
        self.sourceEntryId = sourceEntryId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}



