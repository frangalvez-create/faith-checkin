import Foundation

struct Goal: Identifiable, Codable {
    let id: UUID
    let userId: UUID
    let content: String
    let goals: String
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case content
        case goals
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    init(userId: UUID, content: String, goals: String) {
        self.id = UUID()
        self.userId = userId
        self.content = content
        self.goals = goals
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
