import Foundation
import Supabase

class SupabaseService: ObservableObject {
    private let useMockData = false // Using live Supabase data with OTP authentication
    private let supabase: SupabaseClient
    
    // Mock data storage
    private var mockJournalEntries: [JournalEntry] = []
    private var mockGoals: [Goal] = []
    private var mockUserProfile: UserProfile?
    private var mockAnalyzerEntries: [AnalyzerEntry] = []
    
    init() {
        if useMockData {
            // Mock initialization
            print("Using mock Supabase service")
            // Create a dummy client to satisfy compiler
            self.supabase = SupabaseClient(
                supabaseURL: URL(string: "https://example.com")!,
                supabaseKey: "dummy"
            )
        } else {
            // Real Supabase initialization
            print("🚀 Connecting to real Supabase database...")
            self.supabase = SupabaseClient(
                supabaseURL: URL(string: "https://vozayapiwlbndqwztvwa.supabase.co")!,
                supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZvemF5YXBpd2xibmRxd3p0dndhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTY2NjA4NjEsImV4cCI6MjA3MjIzNjg2MX0.owG2uIaB6KQFVlgH9tSZJGZVe9YnLv_hHQDcfqsNtdI"
            )
        }
    }
    
    func isUsingMockData() -> Bool {
        return useMockData
    }
    
    // MARK: - Authentication
    func signUpWithOTP(email: String) async throws {
        if useMockData {
            // Mock implementation - always succeeds for testing
            print("Mock: OTP code sent to \(email)")
        } else {
            // Real implementation - send OTP code (not Magic Link)
            _ = try await supabase.auth.signInWithOTP(
                email: email,
                shouldCreateUser: true
            )
            print("OTP code sent to \(email)")
        }
    }
    
    func verifyOTP(email: String, token: String) async throws -> UserProfile {
        if useMockData {
            // Mock implementation - always succeeds for testing
            let userProfile = UserProfile(
                id: UUID(),
                email: email,
                displayName: "Test User"
            )
            mockUserProfile = userProfile
            print("Mock: OTP verified for \(email)")
            return userProfile
        } else {
            // Real implementation - verify OTP
            let authResponse = try await supabase.auth.verifyOTP(email: email, token: token, type: .email)
            let user = authResponse.user
            
            // After successful OTP verification, load the full user profile from user_profiles table
            do {
                let fullProfile = try await loadUserProfile()
                if let profile = fullProfile {
                    print("✅ OTP verified and full profile loaded for \(email)")
                    return profile
                } else {
                    // If no profile exists, create a basic one
                    let userProfile = UserProfile(
                        id: user.id,
                        email: user.email ?? email,
                        displayName: user.userMetadata["full_name"]?.stringValue ?? "User"
                    )
                    print("✅ OTP verified for \(email) - no profile found, created basic profile")
                    return userProfile
                }
            } catch {
                // Fallback to basic profile if loading fails
                let userProfile = UserProfile(
                    id: user.id,
                    email: user.email ?? email,
                    displayName: user.userMetadata["full_name"]?.stringValue ?? "User"
                )
                print("⚠️ OTP verified for \(email) - profile loading failed, using basic profile")
                return userProfile
            }
        }
    }    
    func signOut() async throws {
        if useMockData {
            // Mock implementation
        } else {
            try await supabase.auth.signOut()
        }
    }
    
    func getCurrentSession() async throws -> Session? {
        if useMockData {
            // Mock implementation - return mock session if user exists
            if let mockUser = mockUserProfile {
                return Session(
                    providerToken: nil,
                    providerRefreshToken: nil,
                    accessToken: "mock_token",
                    tokenType: "bearer",
                    expiresIn: 3600,
                    expiresAt: Date().timeIntervalSince1970 + 3600,
                    refreshToken: "mock_refresh_token",
                    weakPassword: nil,
                    user: User(
                        id: mockUser.id,
                        appMetadata: [:],
                        userMetadata: [:],
                        aud: "authenticated",
                        createdAt: mockUser.createdAt,
                        updatedAt: mockUser.updatedAt
                    )
                )
            }
            return nil
        } else {
            // Real implementation - get current session
            return try await supabase.auth.session
        }
    }
    
    func getCurrentUserId() -> UUID? {
        if useMockData {
            return mockUserProfile?.id
        } else {
            // Get current authenticated user ID
            return supabase.auth.currentUser?.id
        }
    }
    
    func getUserProfile(userId: UUID) async throws -> UserProfile {
        if useMockData {
            // Mock implementation - return a test user profile
            return UserProfile(
                id: userId,
                email: "test@example.com",
                displayName: "Test User"
            )
        } else {
            // Real implementation - get user info from auth.users table
            // Since we're using simplified OTP auth, we don't have a separate user_profiles table
            // We'll create a basic UserProfile from the auth session
            let session = try await supabase.auth.session
            return UserProfile(
                id: session.user.id,
                email: session.user.email ?? "unknown@example.com",
                displayName: session.user.userMetadata["full_name"]?.stringValue ?? "User"
            )
        }
    }
    
    // MARK: - Guided Questions
    func fetchGuidedQuestions() async throws -> [GuidedQuestion] {
        if useMockData {
            // Return mock guided questions that match your database
            return [
                GuidedQuestion(
                    id: UUID(),
                    questionText: "What thing, person or moment filled you with gratitude today?",
                    isActive: true,
                    orderIndex: 1,
                    createdAt: Date()
                ),
                GuidedQuestion(
                    id: UUID(),
                    questionText: "What went well today and why?",
                    isActive: true,
                    orderIndex: 2,
                    createdAt: Date()
                ),
                GuidedQuestion(
                    id: UUID(),
                    questionText: "How are you feeling today? Mind and body",
                    isActive: true,
                    orderIndex: 3,
                    createdAt: Date()
                ),
                GuidedQuestion(
                    id: UUID(),
                    questionText: "If you dream, what would you like to dream about tonight?",
                    isActive: true,
                    orderIndex: 4,
                    createdAt: Date()
                ),
                GuidedQuestion(
                    id: UUID(),
                    questionText: "How was your time management today? Anything to improve?",
                    isActive: true,
                    orderIndex: 5,
                    createdAt: Date()
                )
            ]
        } else {
            // Real implementation - fetch guided questions from database
            let response: [GuidedQuestion] = try await supabase
                .from("guided_questions")
                .select()
                .eq("is_active", value: true)
                .order("order_index")
                .execute()
                .value
            
            return response
        }
    }
    
    func getRandomGuidedQuestion() async throws -> GuidedQuestion? {
        let questions = try await fetchGuidedQuestions()
        return questions.randomElement()
    }
    
    func getTodaysGuidedQuestion() async throws -> GuidedQuestion? {
        let questions = try await fetchGuidedQuestions()
        
        // Sort questions by order_index to ensure consistent ordering
        let sortedQuestions = questions.sorted { $0.orderIndex ?? 0 < $1.orderIndex ?? 0 }
        
        // Calculate days since a reference date (January 1, 2024)
        let referenceDate = Calendar.current.date(from: DateComponents(year: 2024, month: 1, day: 1))!
        let today = Calendar.current.startOfDay(for: Date())
        let daysSinceReference = Calendar.current.dateComponents([.day], from: referenceDate, to: today).day ?? 0
        
        // Use modulo to cycle through questions
        let questionIndex = daysSinceReference % sortedQuestions.count
        let todaysQuestion = sortedQuestions[questionIndex]
        
        print("📅 Date-based question selection: Day \(daysSinceReference), Question index \(questionIndex), Question: \(todaysQuestion.questionText)")
        
        return todaysQuestion
    }
    
    // MARK: - Follow-Up Question Logic
    
    /// Determines if today is a follow-up question day (every 3rd day)
    func isFollowUpQuestionDay() -> Bool {
        let calendar = Calendar.current
        let today = Date()
        
        // Calculate days since January 1, 2024 (same reference as guided questions)
        let referenceDate = calendar.date(from: DateComponents(year: 2024, month: 1, day: 1))!
        let daysSinceReference = calendar.dateComponents([.day], from: referenceDate, to: today).day ?? 0
        
        // Every 3rd day (days 0, 3, 6, 9, etc.)
        return daysSinceReference % 3 == 0
    }
    
    /// Selects a past journal entry for follow-up question generation
    /// Option B: Checks source_entry_id in follow_up_generation to exclude already used entries
    func selectPastJournalEntryForFollowUp(userId: UUID) async throws -> JournalEntry? {
        let calendar = Calendar.current
        let today = Date()
        
        // Calculate date range: 5 to 15 days ago
        let fifteenDaysAgo = calendar.date(byAdding: .day, value: -15, to: today)!
        let fiveDaysAgo = calendar.date(byAdding: .day, value: -5, to: today)!
        
        // Calculate 3 days ago for Priority 3
        let threeDaysAgo = calendar.date(byAdding: .day, value: -3, to: today)!
        
        if useMockData {
            // Mock implementation - return a mock entry if available
            let mockEntries = mockJournalEntries.filter { entry in
                entry.userId == userId && 
                entry.createdAt >= fifteenDaysAgo && 
                entry.createdAt <= fiveDaysAgo
            }
            return mockEntries.first
        } else {
            // Get list of already used entry IDs from follow_up_generation table
            // Fetch all generations for this user and extract non-null source_entry_id values
            let allGenerations: [FollowUpGeneration] = try await supabase
                .from("follow_up_generation")
                .select()
                .eq("user_id", value: userId)
                .execute()
                .value
            
            let usedEntryIds: [UUID] = allGenerations.compactMap { generation -> UUID? in
                return generation.sourceEntryId
            }
            
            print("📋 Found \(usedEntryIds.count) already used entries for follow-up generation")
            
            // Convert UUIDs to strings for query
            let usedEntryIdStrings = usedEntryIds.map { $0.uuidString }
            
            // Priority 1: is_favorite = TRUE entries (not yet used for follow-up)
            var favoriteQuery = supabase
                .from("journal_entries")
                .select()
                .eq("user_id", value: userId)
                .eq("is_favorite", value: true)
                .gte("created_at", value: fifteenDaysAgo.ISO8601Format())
                .lte("created_at", value: fiveDaysAgo.ISO8601Format())
                .order("created_at", ascending: true) // Oldest first
            
            // Exclude already used entries - filter in memory after fetch if query syntax doesn't work
            let favoriteEntriesAll: [JournalEntry] = try await favoriteQuery
                .execute()
                .value
            
            let favoriteEntries = favoriteEntriesAll.filter { entry in
                !usedEntryIdStrings.contains(entry.id.uuidString)
            }
            
            if let favoriteEntry = favoriteEntries.first {
                print("✅ Selected favorite entry for follow-up: \(favoriteEntry.content.prefix(50))...")
                return favoriteEntry
            }
            
            // Priority 2: tags = "open_question" entries (not yet used for follow-up)
            let openQuestionEntriesAll: [JournalEntry] = try await supabase
                .from("journal_entries")
                .select()
                .eq("user_id", value: userId)
                .contains("tags", value: ["open_question"])
                .gte("created_at", value: fifteenDaysAgo.ISO8601Format())
                .lte("created_at", value: fiveDaysAgo.ISO8601Format())
                .order("created_at", ascending: true) // Oldest first
                .execute()
                .value
            
            let openQuestionEntries = openQuestionEntriesAll.filter { entry in
                !usedEntryIdStrings.contains(entry.id.uuidString)
            }
            
            if let openQuestionEntry = openQuestionEntries.first {
                print("✅ Selected open question entry for follow-up: \(openQuestionEntry.content.prefix(50))...")
                return openQuestionEntry
            }
            
            // Priority 3: Most recent entry older than 3 days ago (not yet used for follow-up)
            let recentEntriesAll: [JournalEntry] = try await supabase
                .from("journal_entries")
                .select()
                .eq("user_id", value: userId)
                .lt("created_at", value: threeDaysAgo.ISO8601Format())
                .order("created_at", ascending: false) // Most recent first
                .execute()
                .value
            
            let recentEntries = recentEntriesAll.filter { entry in
                !usedEntryIdStrings.contains(entry.id.uuidString)
            }
            
            if let recentEntry = recentEntries.first {
                print("✅ Selected most recent entry for follow-up: \(recentEntry.content.prefix(50))...")
                return recentEntry
            }
            
            print("⚠️ No eligible entries found for follow-up question")
            return nil
        }
    }
    
    /// Generates a follow-up question AI prompt template
    func generateFollowUpQuestionPrompt(pastEntry: JournalEntry) -> String {
        let content = pastEntry.content
        let aiResponse = pastEntry.aiResponse ?? ""
        
        // Extract first paragraph from ai_response
        let firstParagraph = aiResponse.components(separatedBy: "\n\n").first ?? aiResponse.components(separatedBy: "\n").first ?? aiResponse
        
        print("📝 FUQ Prompt - Using first paragraph of AI response:")
        print("   Original length: \(aiResponse.count) characters")
        print("   First paragraph length: \(firstParagraph.count) characters")
        print("   First paragraph: \(firstParagraph.prefix(100))...")
        
        let promptTemplate = """
        Past Client statements: {content} 
        Therapist response: {ai_response} 
        Create a "follow up" style question (25 word limit) from the above conversation previously had. Question structure: "You previously mentioned… Summarize past client statements, then ask a complete probing question regarding either client's current progress or mindset or realizations or feelings"
        """
        
        return promptTemplate
            .replacingOccurrences(of: "{content}", with: content)
            .replacingOccurrences(of: "{ai_response}", with: firstParagraph)
    }
    
    /// Creates a follow-up question journal entry
    func createFollowUpQuestionEntry(userId: UUID, fuqAiPrompt: String, fuqAiResponse: String) async throws -> JournalEntry {
        let followUpEntry = JournalEntry(
            id: UUID(),
            userId: userId,
            guidedQuestionId: nil,
            content: "", // Empty initially, user will fill this
            aiPrompt: nil, // Will be filled when user generates AI response
            aiResponse: nil, // Will be filled when user generates AI response
            tags: ["follow_up"],
            isFavorite: false,
            entryType: "follow_up",
            createdAt: Date(),
            updatedAt: Date(),
            fuqAiPrompt: fuqAiPrompt,
            fuqAiResponse: fuqAiResponse,
            isFollowUpDay: true,
            usedForFollowUp: false // New entries start as not used
        )
        
        return try await createJournalEntry(followUpEntry)
    }
    
    /// Marks a journal entry as used for follow-up question generation
    /// NOTE: With Option B implementation, we track usage via source_entry_id in follow_up_generation table
    /// This function is kept for backward compatibility but may be deprecated in the future
    func markEntryAsUsedForFollowUp(entryId: UUID) async throws {
        do {
            try await supabase
                .from("journal_entries")
                .update(["used_for_follow_up": true])
                .eq("id", value: entryId)
                .execute()
            
            print("✅ Marked entry \(entryId) as used for follow-up")
        } catch {
            print("❌ Failed to mark entry as used for follow-up: \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - Follow-Up Generation (Pre-generated Questions)
    
    /// Fetches the current follow-up generation for a user
    func fetchFollowUpGeneration(userId: UUID) async throws -> FollowUpGeneration? {
        if useMockData {
            // Mock implementation - return nil for now
            return nil
        } else {
            // Real implementation - query database
            print("🔍 [SupabaseService] fetchFollowUpGeneration: Querying follow_up_generation table")
            print("   - User ID: \(userId)")
            print("   - Table: follow_up_generation")
            print("   - Query: SELECT * FROM follow_up_generation WHERE user_id = '\(userId)' LIMIT 1")
            
            let response: [FollowUpGeneration] = try await supabase
                .from("follow_up_generation")
                .select()
                .eq("user_id", value: userId)
                .limit(1)
                .execute()
                .value
            
            print("🔍 [SupabaseService] fetchFollowUpGeneration: Query result")
            print("   - Rows returned: \(response.count)")
            if let generation = response.first {
                print("   - ✅ Found generation: ID=\(generation.id), Response length=\(generation.fuqAiResponse.count)")
            } else {
                print("   - ⚠️ No generation found for user \(userId)")
            }
            
            return response.first
        }
    }
    
    /// Creates or updates (upserts) a follow-up generation entry
    /// Since we have UNIQUE constraint on user_id, this will update if exists, create if not
    func createOrUpdateFollowUpGeneration(_ generation: FollowUpGeneration) async throws -> FollowUpGeneration {
        if useMockData {
            // Mock implementation - return the generation as-is
            return generation
        } else {
            // Real implementation - upsert to database
            let response: [FollowUpGeneration] = try await supabase
                .from("follow_up_generation")
                .upsert(generation, onConflict: "user_id")
                .select()
                .execute()
                .value
            
            guard let savedGeneration = response.first else {
                throw NSError(domain: "DatabaseError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to save follow-up generation"])
            }
            
            print("✅ Follow-up generation saved/updated for user \(generation.userId)")
            return savedGeneration
        }
    }
    
    /// Deletes a follow-up generation entry (if needed)
    func deleteFollowUpGeneration(userId: UUID) async throws {
        if useMockData {
            // Mock implementation - do nothing
            return
        } else {
            try await supabase
                .from("follow_up_generation")
                .delete()
                .eq("user_id", value: userId)
                .execute()
            
            print("✅ Follow-up generation deleted for user \(userId)")
        }
    }
    
    // MARK: - Journal Entries
    func createJournalEntry(_ entry: JournalEntry) async throws -> JournalEntry {
        print("🔘🔘🔘 SUPABASE CREATE JOURNAL ENTRY CALLED - Content: \(entry.content)")
        print("🔘🔘🔘 SUPABASE CREATE JOURNAL ENTRY CALLED - Content: \(entry.content)")
        print("🔘🔘🔘 SUPABASE CREATE JOURNAL ENTRY CALLED - Content: \(entry.content)")
        
        if useMockData {
            // Mock implementation - store the entry
            let savedEntry = JournalEntry(
                id: UUID(),
                userId: entry.userId,
                guidedQuestionId: entry.guidedQuestionId,
                content: entry.content,
                aiPrompt: entry.aiPrompt,
                aiResponse: entry.aiResponse,
                tags: entry.tags,
                isFavorite: entry.isFavorite,
                entryType: entry.entryType,
                createdAt: Date(),
                updatedAt: Date()
            )
            mockJournalEntries.append(savedEntry)
            print("Mock: Saved journal entry - Content: \(entry.content), User ID: \(entry.userId), Total entries: \(mockJournalEntries.count)")
            print("Mock: Saved journal entry - Content: \(entry.content), User ID: \(entry.userId), Total entries: \(mockJournalEntries.count)")
            print("Mock: Saved journal entry - Content: \(entry.content), User ID: \(entry.userId), Total entries: \(mockJournalEntries.count)")
            return savedEntry
        } else {
            // Real implementation - save journal entry to database
            let response: [JournalEntry] = try await supabase
                .from("journal_entries")
                .insert(entry)
                .select()
                .execute()
                .value
            
            guard let savedEntry = response.first else {
                throw NSError(domain: "DatabaseError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to save journal entry"])
            }
            
            return savedEntry
        }
    }
    
    func updateJournalEntry(_ entry: JournalEntry) async throws -> JournalEntry {
        if useMockData {
            // Mock implementation
            print("Mock: Updating journal entry - ID: \(entry.id), Content: \(entry.content), AI Prompt: \(entry.aiPrompt ?? "nil"), AI Response: \(entry.aiResponse ?? "nil")")
            
            // Find and update the entry in mock storage
            if let index = mockJournalEntries.firstIndex(where: { $0.id == entry.id }) {
                mockJournalEntries[index] = entry
                print("Mock: Updated journal entry at index \(index), Total entries: \(mockJournalEntries.count)")
            } else {
                print("Mock: Entry not found for update, adding new entry")
                mockJournalEntries.append(entry)
            }
            
            // Create a new entry with updated timestamp
            let updatedEntry = JournalEntry(
                id: entry.id,
                userId: entry.userId,
                guidedQuestionId: entry.guidedQuestionId,
                content: entry.content,
                aiPrompt: entry.aiPrompt,
                aiResponse: entry.aiResponse,
                tags: entry.tags,
                isFavorite: entry.isFavorite,
                entryType: entry.entryType,
                createdAt: entry.createdAt,
                updatedAt: Date()
            )
            return updatedEntry
        } else {
            // Real implementation
            let response: [JournalEntry] = try await supabase.from("journal_entries")
                .update(entry)
                .eq("id", value: entry.id)
                .select()
                .execute()
                .value
            
            guard let updatedEntry = response.first else {
                throw NSError(domain: "DatabaseError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to update journal entry"])
            }
            
            return updatedEntry
        }
    }
    
    func fetchJournalEntries(userId: UUID) async throws -> [JournalEntry] {
        if useMockData {
            // Mock implementation - return only guided question entries for this user (exclude open question entries)
            let userEntries = mockJournalEntries.filter { 
                $0.userId == userId && $0.guidedQuestionId != nil 
            }
            print("Mock: Returning \(userEntries.count) guided question journal entries for user \(userId)")
            for entry in userEntries {
                print("Mock: Entry - Content: \(entry.content), AI Prompt: \(entry.aiPrompt ?? "nil"), AI Response: \(entry.aiResponse ?? "nil")")
            }
            return userEntries
        } else {
            // Real implementation - only fetch guided question entries (exclude open question entries)
            let response: [JournalEntry] = try await supabase.from("journal_entries")
                .select()
                .eq("user_id", value: userId)
                .not("entry_type", operator: .eq, value: "open") // Exclude open question entries
                .order("created_at", ascending: false)
                .execute()
                .value
            
            return response
        }
    }
    
    func deleteJournalEntry(id: UUID) async throws {
        if useMockData {
            // Mock implementation - remove from mock storage
            mockJournalEntries.removeAll { $0.id == id }
            print("Mock: Deleted journal entry with ID: \(id), Remaining entries: \(mockJournalEntries.count)")
        } else {
            // Real implementation
            try await supabase
                .from("journal_entries")
                .delete()
                .eq("id", value: id)
                .execute()
            print("Real: Deleted journal entry with ID: \(id)")
        }
    }
    
    // MARK: - Open Question Journal Entries (Special handling)
    func createOpenQuestionJournalEntry(_ entry: JournalEntry, staticQuestion: String) async throws -> JournalEntry {
        if useMockData {
            // Mock implementation - store the entry
            let savedEntry = JournalEntry(
                id: UUID(),
                userId: entry.userId,
                guidedQuestionId: nil, // Open question entries have null guided_question_id
                content: entry.content,
                aiPrompt: entry.aiPrompt,
                aiResponse: entry.aiResponse,
                tags: entry.tags,
                isFavorite: entry.isFavorite,
                entryType: entry.entryType,
                createdAt: Date(),
                updatedAt: Date()
            )
            mockJournalEntries.append(savedEntry)
            print("Mock: Saved open question journal entry - \(entry.content)")
            return savedEntry
        } else {
            // Real implementation - save open question journal entry to database
            // For open questions, we use tags to identify them as open question entries
            let response: [JournalEntry] = try await supabase
                .from("journal_entries")
                .insert(entry)
                .select()
                .execute()
                .value
            
            guard let savedEntry = response.first else {
                throw NSError(domain: "DatabaseError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to save open question journal entry"])
            }
            
            return savedEntry
        }
    }
    
    func fetchOpenQuestionJournalEntries(userId: UUID) async throws -> [JournalEntry] {
        if useMockData {
            // Mock implementation - return stored open question entries for this user
            let userEntries = mockJournalEntries.filter { 
                $0.userId == userId && $0.guidedQuestionId == nil 
            }
            print("Mock: Returning \(userEntries.count) open question entries for user")
            return userEntries
        } else {
            // Real implementation - fetch entries tagged as open questions
            let response: [JournalEntry] = try await supabase.from("journal_entries")
                .select()
                .eq("user_id", value: userId)
                .contains("tags", value: ["open_question"]) // Filter by open_question tag
                .order("created_at", ascending: false)
                .execute()
                .value
            
            return response
        }
    }
    
    // MARK: - Goals
    func createGoal(_ goal: Goal) async throws -> Goal {
        if useMockData {
            // Mock implementation - store the goal
            let savedGoal = Goal(
                userId: goal.userId,
                content: goal.content,
                goals: goal.goals
            )
            mockGoals.append(savedGoal)
            print("Mock: Saved goal - \(goal.content)")
            return savedGoal
        } else {
            // Real implementation
            let newGoal: [Goal] = try await supabase.from("goals")
                .insert(goal)
                .select()
                .execute()
                .value
            
            guard let savedGoal = newGoal.first else {
                throw NSError(domain: "DatabaseError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to create goal"])
            }
            return savedGoal
        }
    }
    
    func fetchGoals(userId: UUID) async throws -> [Goal] {
        if useMockData {
            // Mock implementation - return stored goals for this user
            let userGoals = mockGoals.filter { $0.userId == userId }
            print("Mock: Returning \(userGoals.count) goals for user")
            return userGoals
        } else {
            // Real implementation
            let goals: [Goal] = try await supabase.from("goals")
                .select()
                .eq("user_id", value: userId)
                .execute()
                .value
            return goals
        }
    }
    
    func updateGoal(_ goal: Goal) async throws -> Goal {
        if useMockData {
            let updatedGoal = Goal(
                userId: goal.userId,
                content: goal.content,
                goals: goal.goals
            )
            return updatedGoal
        } else {
            // Real implementation
            let updatedGoal: [Goal] = try await supabase.from("goals")
                .update(goal)
                .eq("id", value: goal.id)
                .select()
                .execute()
                .value
            
            guard let newGoal = updatedGoal.first else {
                throw NSError(domain: "DatabaseError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to update goal"])
            }
            return newGoal
        }
    }
    
    func deleteGoal(id: UUID) async throws {
        if useMockData {
            print("Mock: Deleted goal with ID: \(id)")
        } else {
            // Real implementation
            try await supabase.from("goals").delete().eq("id", value: id).execute()
        }
    }
    
    // MARK: - Favorite Journal Entries
    func fetchFavoriteJournalEntries(userId: UUID) async throws -> [JournalEntry] {
        if useMockData {
            // Mock implementation - return sample favorite entries
            return [
                JournalEntry(
                    id: UUID(),
                    userId: userId,
                    guidedQuestionId: UUID(),
                    content: "I learned that vibe coding is doable and I'm excited for the future of this app!",
                    aiPrompt: "Sample AI prompt",
                    aiResponse: "It's wonderful to hear that your family relationships are going well. Positive connections with family can significantly enhance emotional well-being and contribute to a supportive environment.",
                    tags: [],
                    isFavorite: true,
                    entryType: "guided",
                    createdAt: Date(),
                    updatedAt: Date()
                ),
                JournalEntry(
                    id: UUID(),
                    userId: userId,
                    guidedQuestionId: UUID(),
                    content: "So far all my family relationships are going well.",
                    aiPrompt: "Sample AI prompt",
                    aiResponse: "To further strengthen these relationships, consider setting aside regular time for family activities, practicing active listening during conversations, and expressing appreciation for each family member's contributions.",
                    tags: [],
                    isFavorite: true,
                    entryType: "guided",
                    createdAt: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(),
                    updatedAt: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
                )
            ]
        } else {
            // Real implementation
            let favoriteEntries: [JournalEntry] = try await supabase.from("journal_entries")
                .select()
                .eq("user_id", value: userId)
                .eq("is_favorite", value: true)
                .order("created_at", ascending: false) // Newest first
                .execute()
                .value
            return favoriteEntries
        }
    }
    
    // MARK: - Analyzer Entries
    func fetchAnalyzerEntries(userId: UUID) async throws -> [AnalyzerEntry] {
        if useMockData {
            let entries = mockAnalyzerEntries.filter { $0.userId == userId }
                .sorted { $0.createdAt > $1.createdAt }
            print("Mock: Returning \(entries.count) analyzer entries for user \(userId)")
            return entries
        } else {
            let response: [AnalyzerEntry] = try await supabase
                .from("analyzer_entries")
                .select()
                .eq("user_id", value: userId)
                .order("created_at", ascending: false)
                .execute()
                .value
            return response
        }
    }
    
    func createAnalyzerEntry(
        userId: UUID,
        entryType: String,
        tags: [String],
        analyzerAiPrompt: String?
    ) async throws -> AnalyzerEntry {
        let newEntry = AnalyzerEntry(
            userId: userId,
            analyzerAiPrompt: analyzerAiPrompt,
            analyzerAiResponse: nil,
            entryType: entryType,
            tags: tags
        )
        
        if useMockData {
            mockAnalyzerEntries.append(newEntry)
            print("Mock: Created analyzer entry \(newEntry.id) for user \(userId)")
            return newEntry
        } else {
            let response: [AnalyzerEntry] = try await supabase
                .from("analyzer_entries")
                .insert(newEntry)
                .select()
                .execute()
                .value
            
            guard let savedEntry = response.first else {
                throw NSError(
                    domain: "DatabaseError",
                    code: 0,
                    userInfo: [NSLocalizedDescriptionKey: "Failed to create analyzer entry"]
                )
            }
            
            return savedEntry
        }
    }
    
    func updateAnalyzerEntryResponse(
        entryId: UUID,
        analyzerAiResponse: String
    ) async throws -> AnalyzerEntry {
        if useMockData {
            guard let index = mockAnalyzerEntries.firstIndex(where: { $0.id == entryId }) else {
                throw NSError(
                    domain: "MockDataError",
                    code: 0,
                    userInfo: [NSLocalizedDescriptionKey: "Analyzer entry not found"]
                )
            }
            
            let updated = AnalyzerEntry(
                id: mockAnalyzerEntries[index].id,
                userId: mockAnalyzerEntries[index].userId,
                analyzerAiPrompt: mockAnalyzerEntries[index].analyzerAiPrompt,
                analyzerAiResponse: analyzerAiResponse,
                entryType: mockAnalyzerEntries[index].entryType,
                tags: mockAnalyzerEntries[index].tags,
                createdAt: mockAnalyzerEntries[index].createdAt,
                updatedAt: Date()
            )
            mockAnalyzerEntries[index] = updated
            print("Mock: Updated analyzer entry response for \(entryId)")
            return updated
        } else {
            let response: [AnalyzerEntry] = try await supabase
                .from("analyzer_entries")
                .update([
                    "analyzer_ai_response": analyzerAiResponse,
                    "updated_at": ISO8601DateFormatter().string(from: Date())
                ])
                .eq("id", value: entryId)
                .select()
                .execute()
                .value
            
            guard let updatedEntry = response.first else {
                throw NSError(
                    domain: "DatabaseError",
                    code: 0,
                    userInfo: [NSLocalizedDescriptionKey: "Failed to update analyzer entry response"]
                )
            }
            
            return updatedEntry
        }
    }
    
    func deleteAnalyzerEntry(entryId: UUID) async throws {
        if useMockData {
            mockAnalyzerEntries.removeAll { $0.id == entryId }
            print("Mock: Deleted analyzer entry \(entryId)")
        } else {
            try await supabase
                .from("analyzer_entries")
                .delete()
                .eq("id", value: entryId)
                .execute()
            print("✅ Deleted analyzer entry \(entryId)")
        }
    }
    
    // MARK: - Delete Favorite Entry
    func removeFavoriteEntry(entryId: UUID) async throws {
        if useMockData {
            print("Mock: Removed favorite status for entry ID: \(entryId)")
        } else {
            // Real implementation - set is_favorite to FALSE
            try await supabase
                .from("journal_entries")
                .update(["is_favorite": false])
                .eq("id", value: entryId)
                .execute()
        }
    }
    
    // MARK: - User Profile Updates
    func updateUserProfile(firstName: String? = nil, lastName: String? = nil, gender: String? = nil, occupation: String? = nil, birthdate: String? = nil, notificationFrequency: String? = nil, streakEndingNotification: Bool? = nil) async throws {
        if useMockData {
            print("Mock: Updated user profile with first name: \(firstName)")
        } else {
            // Use the same pattern as existing working code
            guard let userId = supabase.auth.currentUser?.id else {
                throw NSError(domain: "AuthError", code: 0, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
            }
            
            // Real implementation - save to user_profiles table
            struct ProfileData: Codable {
                let user_id: String
                let first_name: String?
                let last_name: String?
                let gender: String?
                let occupation: String?
                let birthdate: String?
                let updated_at: String
            }
            
            let profileData = ProfileData(
                user_id: userId.uuidString,
                first_name: firstName,
                last_name: lastName,
                gender: gender,
                occupation: occupation,
                birthdate: birthdate,
                updated_at: ISO8601DateFormatter().string(from: Date())
            )
            
            // Try to update first, if no rows affected, then insert
            do {
                let updateResponse = try await supabase
                    .from("user_profiles")
                    .update([
                        "first_name": firstName,
                        "last_name": lastName,
                        "gender": gender,
                        "occupation": occupation,
                        "birthdate": birthdate,
                        "updated_at": ISO8601DateFormatter().string(from: Date())
                    ])
                    .eq("user_id", value: userId.uuidString)
                    .execute()
                
                // Check if any rows were actually updated by parsing the response
                if let responseData = try JSONSerialization.jsonObject(with: updateResponse.data) as? [[String: Any]],
                   responseData.isEmpty {
                    // No rows were updated, insert a new record
                    let _ = try await supabase
                        .from("user_profiles")
                        .insert(profileData)
                        .execute()
                }
            } catch {
                // If update fails, try to insert a new record
                let _ = try await supabase
                    .from("user_profiles")
                    .insert(profileData)
                    .execute()
            }
            
            print("✅ User profile updated successfully for user: \(userId)")
            print("   First Name: \(firstName)")
            print("   Last Name: \(lastName ?? "nil")")
            print("   Birthdate: \(birthdate ?? "nil")")
        }
    }
    
    func loadUserProfile() async throws -> UserProfile? {
        if useMockData {
            print("Mock: Loading user profile")
            return UserProfile(
                id: UUID(),
                email: "test@example.com",
                displayName: "Test User",
                firstName: "Test",
                lastName: "User",
                gender: "Non-binary",
                occupation: "Software Developer",
                birthdate: "01/15/1990",
                currentStreak: 5,
                longestStreak: 10,
                totalJournalEntries: 15,
                createdAt: Date(),
                updatedAt: Date()
            )
        } else {
            // Use the same pattern as existing working code
            guard let userId = supabase.auth.currentUser?.id else {
                throw NSError(domain: "AuthError", code: 0, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
            }
            
            // Real implementation - fetch from user_profiles table
            let response = try await supabase
                .from("user_profiles")
                .select()
                .eq("user_id", value: userId.uuidString)
                .execute()
            
            if let profileData = try JSONSerialization.jsonObject(with: response.data) as? [[String: Any]],
               let profile = profileData.first {
                print("✅ User profile loaded successfully for user: \(userId)")
                
                return UserProfile(
                    id: userId,
                    email: supabase.auth.currentUser?.email ?? "unknown@example.com",
                    displayName: profile["first_name"] as? String ?? "User",
                    firstName: profile["first_name"] as? String,
                    lastName: profile["last_name"] as? String,
                    gender: profile["gender"] as? String,
                    occupation: profile["occupation"] as? String,
                    birthdate: profile["birthdate"] as? String,
                    currentStreak: 0, // Default values for now
                    longestStreak: 0,
                    totalJournalEntries: 0,
                    createdAt: Date(),
                    updatedAt: Date()
                )
            } else {
                print("ℹ️ No user profile found for user: \(userId) - returning nil")
                return nil
            }
        }
    }
    
    func fetchUserProfile() async throws -> [String: Any]? {
        if useMockData {
            print("Mock: Fetching user profile")
            return [
                "first_name": "Test",
                "last_name": "User",
                "notification_frequency": "Weekly",
                "streak_ending_notification": true
            ]
        } else {
            // Use the same pattern as existing working code
            guard let userId = supabase.auth.currentUser?.id else {
                throw NSError(domain: "AuthError", code: 0, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
            }
            
            // Real implementation - fetch from user_profiles table
            let response = try await supabase
                .from("user_profiles")
                .select()
                .eq("user_id", value: userId.uuidString)
                .execute()
            
            if let profileData = try JSONSerialization.jsonObject(with: response.data) as? [String: Any] {
                print("✅ User profile fetched successfully for user: \(userId)")
                return profileData
            } else {
                print("ℹ️ No user profile found for user: \(userId) - returning default values")
                // Return default values so existing users don't break
                return [
                    "first_name": "" as Any,
                    "last_name": "" as Any,
                    "notification_frequency": "Weekly",
                    "streak_ending_notification": true
                ]
            }
        }
    }
    
    // MARK: - Delete Account Functions
    
    /// Deletes all user data associated with the currently logged-in user
    /// Returns true if successful, false otherwise
    func deleteUserAccount() async throws -> Bool {
        do {
            // Use the same pattern as existing working code
            guard let userId = supabase.auth.currentUser?.id else {
                throw NSError(domain: "AuthError", code: 0, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
            }
            
            // Delete journal entries for this user
            try await supabase
                .from("journal_entries")
                .delete()
                .eq("user_id", value: userId)
                .execute()
            
            // Delete goals for this user
            try await supabase
                .from("goals")
                .delete()
                .eq("user_id", value: userId)
                .execute()
            
            // Delete user profile for this user
            try await supabase
                .from("user_profiles")
                .delete()
                .eq("user_id", value: userId)
                .execute()
            
            // Sign out the user instead of deleting auth record (admin API not available)
            try await supabase.auth.signOut()
            
            return true
            
        } catch {
            if error.localizedDescription.contains("No current user") {
                return false
            }
            throw error
        }
    }
    
    // MARK: - Analyzer Entry Functions
    
    /// Creates a new analyzer entry in the analyzer_entries table
    func createAnalyzerEntry(_ entry: AnalyzerEntry) async throws -> AnalyzerEntry {
        if useMockData {
            print("Mock: Creating analyzer entry")
            var newEntry = entry
            mockAnalyzerEntries.append(newEntry)
            return newEntry
        } else {
            guard let userId = supabase.auth.currentUser?.id else {
                throw NSError(domain: "AuthError", code: 0, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
            }
            
            // Use Supabase client's automatic Codable serialization
            let response: [AnalyzerEntry] = try await supabase
                .from("analyzer_entries")
                .insert(entry)
                .select()
                .execute()
                .value
            
            guard let savedEntry = response.first else {
                throw NSError(domain: "DatabaseError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to create analyzer entry"])
            }
            
            return savedEntry
        }
    }
    
    /// Fetches all analyzer entries for the current user
    func fetchAnalyzerEntries() async throws -> [AnalyzerEntry] {
        if useMockData {
            print("Mock: Fetching analyzer entries")
            return mockAnalyzerEntries
        } else {
            guard let userId = supabase.auth.currentUser?.id else {
                throw NSError(domain: "AuthError", code: 0, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
            }
            
            // Use Supabase client's automatic Codable deserialization
            let response: [AnalyzerEntry] = try await supabase
                .from("analyzer_entries")
                .select()
                .eq("user_id", value: userId)
                .order("created_at", ascending: false)
                .execute()
                .value
            
            return response
        }
    }
    
    /// Updates an existing analyzer entry
    func updateAnalyzerEntry(_ entry: AnalyzerEntry) async throws -> AnalyzerEntry {
        if useMockData {
            print("Mock: Updating analyzer entry")
            if let index = mockAnalyzerEntries.firstIndex(where: { $0.id == entry.id }) {
                mockAnalyzerEntries[index] = entry
                return entry
            }
            throw NSError(domain: "DatabaseError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Analyzer entry not found"])
        } else {
            guard let userId = supabase.auth.currentUser?.id else {
                throw NSError(domain: "AuthError", code: 0, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
            }
            
            // Create updated entry with current timestamp
            let updatedEntry = AnalyzerEntry(
                id: entry.id,
                userId: entry.userId,
                analyzerAiPrompt: entry.analyzerAiPrompt,
                analyzerAiResponse: entry.analyzerAiResponse,
                entryType: entry.entryType,
                tags: entry.tags,
                createdAt: entry.createdAt,
                updatedAt: Date()
            )
            
            // Use Supabase client's automatic Codable serialization
            let response: [AnalyzerEntry] = try await supabase
                .from("analyzer_entries")
                .update(updatedEntry)
                .eq("id", value: entry.id)
                .eq("user_id", value: userId)
                .select()
                .execute()
                .value
            
            guard let savedEntry = response.first else {
                throw NSError(domain: "DatabaseError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to update analyzer entry"])
            }
            
            return savedEntry
        }
    }
    
    /// Parses an analyzer entry from a dictionary
    private func parseAnalyzerEntry(from dict: [String: Any]) throws -> AnalyzerEntry {
        guard let idString = dict["id"] as? String,
              let id = UUID(uuidString: idString),
              let userIdString = dict["user_id"] as? String,
              let userId = UUID(uuidString: userIdString),
              let entryType = dict["entry_type"] as? String,
              let createdAtString = dict["created_at"] as? String else {
            throw NSError(domain: "ParseError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid analyzer entry data"])
        }
        
        let formatter = ISO8601DateFormatter()
        let createdAt = formatter.date(from: createdAtString) ?? Date()
        
        let analyzerAiPrompt = dict["analyzer_ai_prompt"] as? String
        let analyzerAiResponse = dict["analyzer_ai_response"] as? String
        let tags = dict["tags"] as? [String] ?? []
        let updatedAtString = dict["updated_at"] as? String
        let updatedAt = updatedAtString != nil ? formatter.date(from: updatedAtString!) : nil
        
        return AnalyzerEntry(
            id: id,
            userId: userId,
            analyzerAiPrompt: analyzerAiPrompt,
            analyzerAiResponse: analyzerAiResponse,
            entryType: entryType,
            tags: tags,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
    
    /// Fetches journal entries within a date range for analyzer
    /// - Parameters:
    ///   - startDate: Start date of the range
    ///   - endDate: End date of the range
    ///   - limit: Optional limit on number of entries to return (for monthly analysis)
    ///            When limit is provided, prioritizes entries with is_favorite = true
    func fetchJournalEntriesForAnalyzer(startDate: Date, endDate: Date, limit: Int? = nil) async throws -> [JournalEntry] {
        if useMockData {
            print("Mock: Fetching journal entries for analyzer")
            var entries = mockJournalEntries.filter { entry in
                entry.createdAt >= startDate && entry.createdAt <= endDate
            }
            
            // Apply limit with favorite prioritization if needed
            if let limit = limit {
                entries = selectEntriesWithFavoritePriority(entries: entries, limit: limit)
            }
            return entries
        } else {
            guard let userId = supabase.auth.currentUser?.id else {
                throw NSError(domain: "AuthError", code: 0, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
            }
            
            let formatter = ISO8601DateFormatter()
            let startDateString = formatter.string(from: startDate)
            let endDateString = formatter.string(from: endDate)
            
            print("📅 fetchJournalEntriesForAnalyzer: Fetching entries from \(startDateString) to \(endDateString)")
            
            // Use Supabase client's automatic deserialization
            // Fetch more entries if limit is specified to ensure good randomization
            let fetchLimit = limit != nil ? (limit! * 3) : nil
            var query = supabase
                .from("journal_entries")
                .select()
                .eq("user_id", value: userId)
                .gte("created_at", value: startDateString)
                .lte("created_at", value: endDateString)
                .order("created_at", ascending: false)
            
            if let fetchLimit = fetchLimit {
                query = query.limit(fetchLimit)
            }
            
            let response: [JournalEntry] = try await query
                .execute()
                .value
            
            // Additional filtering in memory to ensure entries are truly within the range
            // This prevents timezone or timestamp precision issues
            var filteredEntries = response.filter { entry in
                let entryDate = entry.createdAt
                return entryDate >= startDate && entryDate <= endDate
            }
            
            print("📅 fetchJournalEntriesForAnalyzer: Found \(response.count) entries from DB, \(filteredEntries.count) after filtering")
            
            // Apply limit with favorite prioritization if needed
            if let limit = limit {
                filteredEntries = selectEntriesWithFavoritePriority(entries: filteredEntries, limit: limit)
                print("📅 fetchJournalEntriesForAnalyzer: Selected \(filteredEntries.count) entries (prioritizing favorites)")
            }
            
            for entry in filteredEntries {
                let favoriteTag = entry.isFavorite ? "⭐" : ""
                print("   \(favoriteTag) Entry at \(entry.createdAt): \(entry.content.prefix(50))...")
            }
            
            return filteredEntries
        }
    }
    
    /// Selects entries up to the limit, prioritizing favorites
    /// - Parameters:
    ///   - entries: Array of entries to select from
    ///   - limit: Maximum number of entries to return
    /// - Returns: Array of selected entries (favorites first, then random non-favorites)
    private func selectEntriesWithFavoritePriority(entries: [JournalEntry], limit: Int) -> [JournalEntry] {
        guard entries.count > limit else {
            return entries
        }
        
        // Separate favorites from non-favorites
        let favorites = entries.filter { $0.isFavorite }
        let nonFavorites = entries.filter { !$0.isFavorite }
        
        var selected: [JournalEntry] = []
        
        // First, add favorites (randomly selected if more than limit)
        if favorites.count <= limit {
            // All favorites fit, add them all
            selected.append(contentsOf: favorites.shuffled())
        } else {
            // More favorites than limit - randomly select up to limit
            selected.append(contentsOf: favorites.shuffled().prefix(limit))
        }
        
        // If we have room, add random non-favorites
        if selected.count < limit {
            let remaining = limit - selected.count
            let shuffledNonFavorites = nonFavorites.shuffled()
            selected.append(contentsOf: shuffledNonFavorites.prefix(remaining))
        }
        
        return selected
    }
    
    /// Prepares content for analyzer with character limits and sentence-aware truncation
    /// Weekly: 1000 chars, Monthly: 1000 chars
    /// Only includes complete sentences - entries without sentence endings are either included fully or skipped
    func prepareContentForAnalyzer(entries: [JournalEntry], analysisType: String) -> String {
        let maxChars = 1000
        
        guard !entries.isEmpty else { return "" }
        
        // Sort entries chronologically
        let sortedEntries = entries.sorted { $0.createdAt < $1.createdAt }
        
        // Calculate total size
        let totalChars = sortedEntries.reduce(0) { $0 + $1.content.count }
        
        // If already under limit, return all (but still check for complete sentences)
        if totalChars <= maxChars {
            // Verify all entries have complete sentences or are short enough
            let allValid = sortedEntries.allSatisfy { entry in
                let content = entry.content.trimmingCharacters(in: .whitespacesAndNewlines)
                return content.count <= 100 || hasCompleteSentence(content)
            }
            if allValid {
                return sortedEntries.map { $0.content }.joined(separator: "\n\n")
            }
        }
        
        // Need to summarize - only include complete sentences
        let separatorChars = (sortedEntries.count - 1) * 2 // "\n\n" between entries
        let availableChars = maxChars - separatorChars
        let charsPerEntry = availableChars / sortedEntries.count
        let minCharsPerEntry = max(30, charsPerEntry / 3) // At least 30 chars per entry
        
        var summaries: [String] = []
        var remainingChars = availableChars
        
        for (index, entry) in sortedEntries.enumerated() {
            let isLast = index == sortedEntries.count - 1
            let allocated = isLast ? remainingChars : max(minCharsPerEntry, min(charsPerEntry, remainingChars))
            
            guard allocated > 0 else { break }
            
            var summary: String? = nil
            let content = entry.content.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if content.count <= allocated {
                // Entry fits completely - check if it has complete sentences or is short enough
                if content.count <= 100 || hasCompleteSentence(content) {
                    summary = content
                }
                // Otherwise skip (entry is too long and has no complete sentences)
            } else {
                // Truncate with sentence awareness - ONLY include complete sentences
                let truncated = String(content.prefix(allocated))
                
                // Try to find the last complete sentence boundary
                // Search backwards from the end to find a sentence end (., !, ?)
                let searchStartPercent = 0.5
                let minSearchPosition = max(Int(Double(truncated.count) * searchStartPercent), truncated.count - 200)
                let minSearchIndex = truncated.index(truncated.startIndex, offsetBy: min(minSearchPosition, truncated.count))
                
                var bestSentenceEnd: String.Index? = nil
                var currentIndex = truncated.endIndex
                
                // Search backwards from the end
                while currentIndex > minSearchIndex && currentIndex > truncated.startIndex {
                    let charIndex = truncated.index(before: currentIndex)
                    let char = truncated[charIndex]
                    
                    // Check if this is a sentence-ending punctuation
                    if char == "." || char == "!" || char == "?" {
                        // Check if it's followed by space, newline, or end of string
                        let isAtEnd = charIndex == truncated.index(before: truncated.endIndex)
                        var isValidBoundary = false
                        
                        if isAtEnd {
                            // At the very end of truncated string - check if original has more
                            // If original content continues, this might not be a real sentence end
                            if charIndex == content.index(before: content.endIndex) {
                                // This is actually the end of the content - valid boundary
                                isValidBoundary = true
                            } else {
                                // Check the character after in original content
                                let nextIndex = content.index(after: charIndex)
                                if nextIndex < content.endIndex {
                                    let nextChar = content[nextIndex]
                                    isValidBoundary = (nextChar == " " || nextChar == "\n" || nextChar == "\t")
                                } else {
                                    isValidBoundary = true
                                }
                            }
                        } else {
                            // Check the character after the punctuation in truncated string
                            let nextIndex = truncated.index(after: charIndex)
                            if nextIndex < truncated.endIndex {
                                let nextChar = truncated[nextIndex]
                                // Valid if followed by space, newline, or tab
                                isValidBoundary = (nextChar == " " || nextChar == "\n" || nextChar == "\t")
                            } else {
                                isValidBoundary = true
                            }
                        }
                        
                        if isValidBoundary {
                            // Found a valid sentence boundary - use the position after the punctuation
                            bestSentenceEnd = truncated.index(after: charIndex)
                            break
                        }
                    }
                    
                    currentIndex = charIndex
                }
                
                if let sentenceEnd = bestSentenceEnd {
                    // Found a sentence boundary - use everything up to and including the sentence
                    summary = String(truncated[..<sentenceEnd]).trimmingCharacters(in: .whitespaces)
                }
                // If no sentence boundary found, summary remains nil (we'll skip this entry)
            }
            
            // Only add summary if we found one (complete sentence or short entry)
            if let summary = summary {
                summaries.append(summary)
                
                // Update remaining characters (subtract summary length + separator if not last)
                remainingChars -= summary.count
                if index < sortedEntries.count - 1 {
                    remainingChars -= 2 // "\n\n"
                }
            }
            
            if remainingChars <= 0 { break }
        }
        
        let result = summaries.joined(separator: "\n\n")
        
        // Final safety check: ensure we didn't exceed limit due to rounding
        if result.count > maxChars {
            return String(result.prefix(maxChars))
        }
        
        return result
    }
    
    /// Checks if content has at least one complete sentence (ending with . ! or ?)
    private func hasCompleteSentence(_ content: String) -> Bool {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        
        // Check if content ends with sentence-ending punctuation
        if trimmed.hasSuffix(".") || trimmed.hasSuffix("!") || trimmed.hasSuffix("?") {
            return true
        }
        
        // Check for sentence-ending punctuation followed by whitespace
        let pattern = #"[.!?]+[\s\n]+"#
        if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
            let range = NSRange(location: 0, length: trimmed.utf16.count)
            return regex.firstMatch(in: trimmed, options: [], range: range) != nil
        }
        
        return false
    }
    
    /// Generates a weekly analyzer prompt based on journal entries
    /// Uses improved prompt structure optimized for GPT-5 model
    func generateWeeklyAnalyzerPrompt(content: String) -> String {
        let promptTemplate = """
Analyze the following journal entry:

"{content}"

Output format (exactly):

1st paragraph:
mood1(#), mood2(#), mood3(#)

2nd paragraph (two bullets):
- Summary: <summary of user input>
- Action & goal for next week: <action steps + weekly goal>

3rd paragraph:
<score only, number from 60–100>

Important:
- Moods must be one word each.
- Score must be the final line and only the number—no text.
"""
        return promptTemplate.replacingOccurrences(of: "{content}", with: content)
    }
    
    /// Generates a monthly analyzer prompt based on journal entries
    /// Uses improved prompt structure optimized for GPT-5 model
    func generateMonthlyAnalyzerPrompt(content: String) -> String {
        let promptTemplate = """
Analyze the following journal entry:

"{content}"

Output format (exactly):

1st paragraph:
mood1(#), mood2(#), mood3(#), mood4(#)

2nd paragraph (two bullets):
- Summary: <summary of user input>
- Action & goal for next week: <action steps + weekly goal>

3rd paragraph:
<score only, number from 60–100>

Important:
- Moods must be one word each.
- Score must be the final line and only the number—no text.
"""
        return promptTemplate.replacingOccurrences(of: "{content}", with: content)
    }
    
    /// Calculates the date range for weekly analysis (previous Sunday to Saturday)
    func calculateDateRangeForWeeklyAnalysis(for date: Date = Date()) -> (start: Date, end: Date) {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let weekday = calendar.component(.weekday, from: startOfDay)
        let daysSinceSunday = (weekday + 6) % 7
        
        // Calculate previous Sunday (7 days before the current week's Sunday)
        guard let previousSunday = calendar.date(byAdding: .day, value: -(daysSinceSunday + 7), to: startOfDay),
              let lastSaturday = calendar.date(byAdding: .day, value: 6, to: previousSunday) else {
            return (startOfDay, startOfDay)
        }
        
        // Set start to beginning of Sunday (00:00:00)
        let rangeStart = calendar.startOfDay(for: previousSunday)
        
        // Set end to end of Saturday (23:59:59.999) to include all entries from Saturday
        guard let endOfSaturday = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: lastSaturday) else {
            return (rangeStart, calendar.startOfDay(for: lastSaturday))
        }
        let rangeEnd = calendar.date(byAdding: .nanosecond, value: 999_000_000, to: endOfSaturday) ?? endOfSaturday
        
        return (rangeStart, rangeEnd)
    }
    
    /// Calculates the date range for monthly analysis
    /// When monthly analysis is triggered, it analyzes the month that contains the previous week's Saturday
    /// (which is in the last 7 days of that month)
    func calculateDateRangeForMonthlyAnalysis(for date: Date = Date()) -> (start: Date, end: Date) {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        
        // Calculate what the previous week would be (Sunday to Saturday)
        let weekday = calendar.component(.weekday, from: startOfDay)
        let daysSinceSunday = (weekday + 6) % 7
        
        // Calculate previous Sunday (7 days before the current week's Sunday)
        guard let previousSunday = calendar.date(byAdding: .day, value: -(daysSinceSunday + 7), to: startOfDay),
              let previousSaturday = calendar.date(byAdding: .day, value: 6, to: previousSunday) else {
            // Fallback to previous month if calculation fails
            return calculateDateRangeForPreviousMonth(for: date)
        }
        
        // The month to analyze is the month that contains previousSunday
        // When monthly analysis is triggered, the previous week spanned months (Sunday in month A, Saturday in month B)
        // We want to analyze the month that contains previousSunday (the completed month A)
        let monthToAnalyze = previousSunday
        
        // Get the first day of the month that contains previousSaturday
        let components = calendar.dateComponents([.year, .month], from: monthToAnalyze)
        guard let firstOfMonth = calendar.date(from: components) else {
            return calculateDateRangeForPreviousMonth(for: date)
        }
        
        // Get the last day of that month
        guard let range = calendar.range(of: .day, in: .month, for: firstOfMonth),
              let lastDayOfMonth = range.last,
              let lastDateOfMonth = calendar.date(byAdding: .day, value: lastDayOfMonth - 1, to: firstOfMonth) else {
            return calculateDateRangeForPreviousMonth(for: date)
        }
        
        // Set start to beginning of first day (00:00:00)
        let rangeStart = calendar.startOfDay(for: firstOfMonth)
        
        // Set end to end of last day (23:59:59.999) to include all entries from the last day
        guard let endOfLastDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: lastDateOfMonth) else {
            return (rangeStart, calendar.startOfDay(for: lastDateOfMonth))
        }
        let rangeEnd = calendar.date(byAdding: .nanosecond, value: 999_000_000, to: endOfLastDay) ?? endOfLastDay
        
        return (rangeStart, rangeEnd)
    }
    
    /// Helper function to calculate date range for the previous month (fallback)
    private func calculateDateRangeForPreviousMonth(for date: Date) -> (start: Date, end: Date) {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        
        // Get the previous month
        guard let previousMonth = calendar.date(byAdding: .month, value: -1, to: startOfDay) else {
            // Fallback to weekly range if calculation fails
            return calculateDateRangeForWeeklyAnalysis(for: date)
        }
        
        // Get the first day of the previous month
        let components = calendar.dateComponents([.year, .month], from: previousMonth)
        guard let firstOfPreviousMonth = calendar.date(from: components) else {
            return calculateDateRangeForWeeklyAnalysis(for: date)
        }
        
        // Get the last day of the previous month
        guard let range = calendar.range(of: .day, in: .month, for: firstOfPreviousMonth),
              let lastDayOfMonth = range.last,
              let lastDateOfMonth = calendar.date(byAdding: .day, value: lastDayOfMonth - 1, to: firstOfPreviousMonth) else {
            return calculateDateRangeForWeeklyAnalysis(for: date)
        }
        
        // Set start to beginning of first day (00:00:00)
        let rangeStart = calendar.startOfDay(for: firstOfPreviousMonth)
        
        // Set end to end of last day (23:59:59.999) to include all entries from the last day
        guard let endOfLastDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: lastDateOfMonth) else {
            return (rangeStart, calendar.startOfDay(for: lastDateOfMonth))
        }
        let rangeEnd = calendar.date(byAdding: .nanosecond, value: 999_000_000, to: endOfLastDay) ?? endOfLastDay
        
        return (rangeStart, rangeEnd)
    }
    
    /// Checks if analyzer is available (every Sunday at 2 AM)
    func isAnalyzerAvailable(for date: Date = Date()) -> Bool {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)
        
        // Analyzer is available on Sundays (weekday == 1)
        return weekday == 1
    }
}