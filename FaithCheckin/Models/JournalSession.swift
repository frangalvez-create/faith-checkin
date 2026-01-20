import Foundation

struct JournalSession: Identifiable, Codable {
    let id: UUID
    let userId: UUID
    let sessionDate: Date
    let guidedQuestionCompleted: Bool
    let openQuestionCompleted: Bool
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case sessionDate = "session_date"
        case guidedQuestionCompleted = "guided_question_completed"
        case openQuestionCompleted = "open_question_completed"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    init(id: UUID = UUID(), userId: UUID, sessionDate: Date, guidedQuestionCompleted: Bool = false, openQuestionCompleted: Bool = false, createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.userId = userId
        self.sessionDate = sessionDate
        self.guidedQuestionCompleted = guidedQuestionCompleted
        self.openQuestionCompleted = openQuestionCompleted
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
