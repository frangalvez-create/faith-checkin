import Foundation

struct GuidedQuestion: Identifiable, Codable {
    let id: UUID
    let questionText: String
    let isActive: Bool
    let orderIndex: Int?
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case questionText = "question_text"
        case isActive = "is_active"
        case orderIndex = "order_index"
        case createdAt = "created_at"
    }
}
