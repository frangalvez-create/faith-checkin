import Foundation
import SwiftUI
import Combine

@MainActor
class JournalViewModel: ObservableObject {
    @Published var currentQuestion: GuidedQuestion?
    @Published var journalEntries: [JournalEntry] = []
    @Published var currentUser: UserProfile?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isAuthenticated = false
    @Published var openQuestionJournalEntries: [JournalEntry] = []
    @Published var favoriteJournalEntries: [JournalEntry] = []
    @Published var goals: [Goal] = []
    @Published var shouldClearUIState = false
    @Published var followUpQuestionEntries: [JournalEntry] = []
    @Published var analyzerEntries: [AnalyzerEntry] = []
    @Published var currentFollowUpQuestion: String = ""
    @Published var isLoadingFollowUpQuestion: Bool = false // Track if we're fetching a pre-generated question
    @Published var currentRetryAttempt: Int = 1 // Track current retry attempt for UI status
    
    // Callback to clear UI state directly
    var clearUIStateCallback: (() -> Void)?
    
    // Callback to populate UI state from loaded data
    var populateUIStateCallback: (() -> Void)?
    
    // Track the last user ID to detect user changes
    private var lastUserId: UUID?
    
    // Track when we last performed a reset to prevent multiple resets per day
    private var lastResetDate: Date?
    
    let supabaseService = SupabaseService()
    private let openAIService = OpenAIService()
    
    init() {
        // Start with not authenticated for testing
        isAuthenticated = false
    }
    
    // MARK: - Authentication
    func checkAuthenticationStatus() async {
        // For mock data, automatically authenticate with a test user
        if supabaseService.isUsingMockData() {
            print("🔄 Using mock data - auto-authenticating for testing")
            let mockUser = UserProfile(
                id: UUID(),
                email: "test@example.com",
                displayName: "Test User"
            )
            currentUser = mockUser
            lastUserId = mockUser.id
            isAuthenticated = true
            // Don't load data here - let the Journal view's onAppear handle it after LoadingView
            return
        }
        
        if let userId = supabaseService.getCurrentUserId() {
            do {
                let userProfile = try await supabaseService.getUserProfile(userId: userId)
                
                // Check if this is a different user than before
                let isDifferentUser = lastUserId != nil && lastUserId != userProfile.id
                print("🔄 checkAuthenticationStatus - User change detected: \(isDifferentUser), Previous: \(lastUserId?.uuidString ?? "nil"), Current: \(userProfile.id.uuidString)")
                
                // Only clear UI state if switching to a different user
                if isDifferentUser {
                    print("🧹 Different user detected in checkAuthenticationStatus - clearing UI state")
                    await clearUIState()
                } else {
                    print("✅ Same user in checkAuthenticationStatus - preserving UI state")
                }
                
                currentUser = userProfile
                lastUserId = userProfile.id // Update the tracked user ID
                isAuthenticated = true
                // Don't load data here - let the Journal view's onAppear handle it after LoadingView
            } catch {
                print("Error loading user profile: \(error)")
                isAuthenticated = false
            }
        }
    }
    
    // Removed signIn method - using OTP authentication instead
    
    func sendOTP(email: String) async {
        print("📧 sendOTP called with email: \(email)")
        isLoading = true
        errorMessage = nil
        
        do {
            try await supabaseService.signUpWithOTP(email: email)
            print("✅ OTP code sent successfully to \(email)")
            // Don't set isAuthenticated yet - wait for OTP verification
        } catch {
            print("❌ OTP send failed: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func verifyOTP(email: String, token: String) async {
        print("🔐 verifyOTP called with email: \(email), token: \(token)")
        isLoading = true
        errorMessage = nil
        
        do {
            let userProfile = try await supabaseService.verifyOTP(email: email, token: token)
            
            // Check if this is a different user than before
            let isDifferentUser = lastUserId != nil && lastUserId != userProfile.id
            print("🔄 User change detected: \(isDifferentUser), Previous: \(lastUserId?.uuidString ?? "nil"), Current: \(userProfile.id.uuidString)")
            
            // Only clear UI state if switching to a different user
            if isDifferentUser {
                print("🧹 Different user detected - clearing UI state")
                await clearUIState()
            } else {
                print("✅ Same user - preserving UI state")
            }
            
            currentUser = userProfile
            lastUserId = userProfile.id // Update the tracked user ID
            isAuthenticated = true
            print("✅ OTP verification successful")
            await loadInitialData()
        } catch {
            print("❌ OTP verification failed: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // OTP authentication requires explicit verification - no automatic session checking needed
    
    func signOut() async {
        do {
            try await supabaseService.signOut()
            currentUser = nil
            lastUserId = nil // Reset last user ID to allow proper detection on next login
            isAuthenticated = false
            journalEntries = []
            currentQuestion = nil
            openQuestionJournalEntries = []
            favoriteJournalEntries = []
            analyzerEntries = []
            // Clear follow-up question state to prevent user data leakage
            currentFollowUpQuestion = ""
            followUpQuestionEntries = []
            isLoadingFollowUpQuestion = false
            // Don't clear UI state here - let verifyOTP handle it when a different user signs in
            print("🚪 User signed out - cleared all user-specific data including follow-up question")
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - UI State Management
    func clearUIState() async {
        print("🧹 Triggering UI state clear for user isolation - shouldClearUIState set to true")
        
        // Clear all user-specific data including follow-up question to prevent data leakage
        currentFollowUpQuestion = ""
        followUpQuestionEntries = []
        isLoadingFollowUpQuestion = false
        currentQuestion = nil
        journalEntries = []
        openQuestionJournalEntries = []
        favoriteJournalEntries = []
        analyzerEntries = []
        goals = []
        
        // Try both approaches
        shouldClearUIState = true
        
        // Also call the callback directly if available
        if let callback = clearUIStateCallback {
            print("🧹 Calling UI state clear callback directly")
            callback()
        }
        
        // Give the UI time to process the change before resetting
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        shouldClearUIState = false
        print("🧹 Reset shouldClearUIState to false - all user data cleared including follow-up question")
    }
    
    func authenticateTestUser() async {
        let testEmail = "test@example.com"
        
        isLoading = true
        errorMessage = nil
        
        print("🔐 Starting authentication for test user: \(testEmail)")
        
        do {
            // For mock data, just create a test user directly
            print("📝 Creating test user with mock data...")
            try await supabaseService.signUpWithOTP(email: testEmail)
            
            // For mock data, we can directly verify with a dummy OTP
            currentUser = try await supabaseService.verifyOTP(email: testEmail, token: "123456")
            isAuthenticated = true
            // Don't load data here - let the Journal view's onAppear handle it after LoadingView
            print("✅ Test user authenticated successfully")
        } catch {
            print("❌ Test user authentication failed: \(error.localizedDescription)")
            errorMessage = "Authentication failed: \(error.localizedDescription)"
            isAuthenticated = false
        }
        
        isLoading = false
    }
    
    // MARK: - Data Loading
    private func loadInitialData() async {
        await loadTodaysQuestion()
        await loadJournalEntries()
        await loadOpenQuestionJournalEntries()
        await loadAnalyzerEntries()
        await loadGoals() // Load goals for persistence
        
        // Notify UI to populate state from loaded data
        DispatchQueue.main.async {
            if let callback = self.populateUIStateCallback {
                callback()
            }
        }
    }
    
    func loadGoals() async {
        guard let user = currentUser else { return }
        
        do {
            goals = try await supabaseService.fetchGoals(userId: user.id)
            print("✅ Goals loaded: \(goals.count) goals found")
            if let firstGoal = goals.first {
                print("📝 Most recent goal: \(firstGoal.goals)")
            }
        } catch {
            // Handle cancelled requests gracefully
            if error.localizedDescription.contains("cancelled") {
                print("⚠️ loadGoals: Request was cancelled, keeping existing goals")
                // Don't show error for cancelled requests - keep existing data
            } else {
                errorMessage = "Failed to load goals: \(error.localizedDescription)"
                print("❌ Failed to load goals: \(error.localizedDescription)")
            }
        }
    }
    
    func loadTodaysQuestion() async {
        isLoading = true
        
        do {
            guard currentUser != nil else {
                print("❌ loadTodaysQuestion: No current user")
                isLoading = false
                return
            }
            
            // Use date-based question selection - all users get the same question each day
            currentQuestion = try await supabaseService.getTodaysGuidedQuestion()
            print("✅ loadTodaysQuestion: Loaded date-based question: \(currentQuestion?.questionText ?? "nil")")
            
        } catch {
            // Handle specific error types more gracefully
            if error.localizedDescription.contains("cancelled") {
                print("⚠️ loadTodaysQuestion: Request was cancelled, keeping existing question")
                // Don't change currentQuestion if request was cancelled - keep existing question
                // This prevents resetting to orderIndex=1 during pull-to-refresh cancellations
            } else {
                errorMessage = "Failed to load today's question: \(error.localizedDescription)"
                print("❌ loadTodaysQuestion error: \(error.localizedDescription)")
                // Only use fallback if we don't have a question yet
                if currentQuestion == nil {
                    currentQuestion = GuidedQuestion(
                        id: UUID(),
                        questionText: "What thing, person or moment filled you with gratitude today?",
                        isActive: true,
                        orderIndex: 1,
                        createdAt: Date()
                    )
                }
            }
        }
        
        isLoading = false
    }
    
    func loadJournalEntries() async {
        guard let user = currentUser else { return }
        
        do {
            journalEntries = try await supabaseService.fetchJournalEntries(userId: user.id)
        } catch {
            // Handle cancelled requests gracefully
            if error.localizedDescription.contains("cancelled") {
                print("⚠️ loadJournalEntries: Request was cancelled, keeping existing entries")
                // Don't show error for cancelled requests - keep existing data
            } else {
                errorMessage = "Failed to load journal entries: \(error.localizedDescription)"
                print("❌ loadJournalEntries error: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Journal Entry Management
    func createJournalEntry(content: String) async {
        print("🚨🚨🚨 CREATE JOURNAL ENTRY METHOD CALLED!")
        print("🚨🚨🚨 CREATE JOURNAL ENTRY METHOD CALLED!")
        print("🚨🚨🚨 CREATE JOURNAL ENTRY METHOD CALLED!")
        print("🔘🔘🔘 CREATE JOURNAL ENTRY CALLED - Content: \(content)")
        print("🔘🔘🔘 CREATE JOURNAL ENTRY CALLED - Content: \(content)")
        print("🔘🔘🔘 CREATE JOURNAL ENTRY CALLED - Content: \(content)")
        
        guard let user = currentUser else { 
            print("❌❌❌ createJournalEntry: No current user found")
            errorMessage = "No user authenticated"
            return 
        }
        
        print("✅✅✅ createJournalEntry: User found - \(user.id)")
        print("📝📝📝 createJournalEntry: Content - \(content)")
        
        isLoading = true
        errorMessage = nil
        
        do {
            // If currentQuestion is nil, try to load a question first
            if currentQuestion == nil {
                print("⚠️ createJournalEntry: currentQuestion is nil, loading a question first")
                await loadTodaysQuestion()
            }
            
            // Create journal entry with current question (or nil if still no question)
            let entry = JournalEntry(
                userId: user.id,
                guidedQuestionId: currentQuestion?.id,
                content: content
            )
            
            print("📝📝📝 createJournalEntry: Created entry with userId: \(entry.userId), guidedQuestionId: \(entry.guidedQuestionId?.uuidString ?? "nil")")
            
            // Save to database
            let savedEntry = try await supabaseService.createJournalEntry(entry)
            
            // Refresh entries
            await loadJournalEntries()
            
            print("✅✅✅ Journal entry saved successfully: \(savedEntry.content)")
            
        } catch {
            print("❌❌❌ Failed to save journal entry: \(error.localizedDescription)")
            errorMessage = "Failed to save journal entry: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    // AI functionality removed for now - will be added later
    
    func toggleFavorite(_ entry: JournalEntry) async {
        let updatedEntry = JournalEntry(
            userId: entry.userId,
            guidedQuestionId: entry.guidedQuestionId,
            content: entry.content,
            aiPrompt: entry.aiPrompt,
            aiResponse: entry.aiResponse,
            tags: entry.tags,
            isFavorite: !entry.isFavorite
        )
        
        do {
            _ = try await supabaseService.updateJournalEntry(updatedEntry)
            await loadJournalEntries()
        } catch {
            errorMessage = "Failed to update favorite: \(error.localizedDescription)"
        }
    }
    
    func updateCurrentJournalEntryWithAIPrompt(aiPrompt: String) async {
        // Find the most recent journal entry for the current user
        guard currentUser != nil else {
            errorMessage = "User not authenticated."
            return
        }
        
        // Load current entries to find the most recent one
        await loadJournalEntries()
        
        guard let mostRecentEntry = journalEntries.first else {
            errorMessage = "No journal entry found to update."
            return
        }
        
        // Create updated entry with AI prompt
        let tagsArray: [String] = Array(mostRecentEntry.tags)
        let updatedEntry = JournalEntry(
            id: mostRecentEntry.id,
            userId: mostRecentEntry.userId,
            guidedQuestionId: mostRecentEntry.guidedQuestionId,
            content: mostRecentEntry.content,
            aiPrompt: aiPrompt, // Add the AI prompt
            aiResponse: mostRecentEntry.aiResponse,
            tags: tagsArray,
            isFavorite: mostRecentEntry.isFavorite,
            entryType: mostRecentEntry.entryType, // Preserve entry type
            createdAt: mostRecentEntry.createdAt,
            updatedAt: Date(), // Update timestamp
            fuqAiPrompt: mostRecentEntry.fuqAiPrompt,
            fuqAiResponse: mostRecentEntry.fuqAiResponse,
            isFollowUpDay: mostRecentEntry.isFollowUpDay,
            usedForFollowUp: mostRecentEntry.usedForFollowUp,
            followUpQuestion: mostRecentEntry.followUpQuestion
        )
        
        do {
            _ = try await supabaseService.updateJournalEntry(updatedEntry)
            await loadJournalEntries() // Refresh entries
            print("✅ Journal entry updated with AI prompt")
        } catch {
            errorMessage = "Failed to update journal entry with AI prompt: \(error.localizedDescription)"
            print("❌ Failed to update journal entry: \(error.localizedDescription)")
        }
    }
    
    /// Generates AI response using OpenAI and updates the journal entry
    func generateAndSaveAIResponse() async {
        guard currentUser != nil else {
            errorMessage = "User not authenticated."
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // Load current entries to find the most recent one
            await loadJournalEntries()
            
            guard let mostRecentEntry = journalEntries.first else {
                errorMessage = "No journal entry found to generate AI response."
                return
            }
            
            guard let aiPrompt = mostRecentEntry.aiPrompt, !aiPrompt.isEmpty else {
                errorMessage = "No AI prompt found in journal entry."
                return
            }
            
            print("🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀")
            print("🚀 GENERATE AI RESPONSE CALLED - GUIDED QUESTION")
            print("🚀 Prompt length: \(aiPrompt.count) characters")
            print("🚀 Prompt preview: \(aiPrompt.prefix(100))...")
            print("🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀")
            
            // Generate AI response using OpenAI with retry logic
            // Use "journal" analysisType to avoid adding analyzer system message
            // Use gpt-5-mini (no reasoning tokens) with 2000 tokens for journal entries
            let aiResponse = try await generateAIResponseWithRetry(for: aiPrompt, model: "gpt-5-mini", analysisType: "journal")
            
            print("✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅")
            print("✅ AI RESPONSE SUCCESS - Length: \(aiResponse.count) characters")
            print("✅ Response preview: \(aiResponse.prefix(200))...")
            print("✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅")
            
            // Create updated entry with AI response
            let tagsArray: [String] = Array(mostRecentEntry.tags)
            let updatedEntry = JournalEntry(
                id: mostRecentEntry.id,
                userId: mostRecentEntry.userId,
                guidedQuestionId: mostRecentEntry.guidedQuestionId,
                content: mostRecentEntry.content,
                aiPrompt: mostRecentEntry.aiPrompt,
                aiResponse: aiResponse, // Add the AI response
                tags: tagsArray,
                isFavorite: mostRecentEntry.isFavorite,
                entryType: mostRecentEntry.entryType, // Preserve entry type
                createdAt: mostRecentEntry.createdAt,
                updatedAt: Date(), // Update timestamp
                fuqAiPrompt: mostRecentEntry.fuqAiPrompt,
                fuqAiResponse: mostRecentEntry.fuqAiResponse,
                isFollowUpDay: mostRecentEntry.isFollowUpDay,
                usedForFollowUp: mostRecentEntry.usedForFollowUp,
                followUpQuestion: mostRecentEntry.followUpQuestion
            )
            
            // Save updated entry to database
            _ = try await supabaseService.updateJournalEntry(updatedEntry)
            await loadJournalEntries() // Refresh entries
            
            print("✅ AI response generated and saved: \(aiResponse.prefix(100))...")
            
        } catch {
            errorMessage = "The AI was on it's break 😅 please try again."
            print("❌ Failed to generate AI response: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    /// Generates AI response with retry logic (up to 3 attempts with exponential backoff)
    /// - Parameters:
    ///   - prompt: The prompt to send to the AI
    ///   - model: The model to use (default: "gpt-5-mini" for journal entries, "gpt-5" for analyzer)
    ///   - analysisType: The type of analysis ("weekly" or "monthly") - only used for analyzer
    ///   - maxRetries: Maximum number of retry attempts
    private func generateAIResponseWithRetry(for prompt: String, model: String = "gpt-5-mini", analysisType: String = "weekly", maxRetries: Int = 3) async throws -> String {
        var lastError: Error?
        
        for attempt in 1...maxRetries {
            do {
                print("🔄 AI generation attempt \(attempt)/\(maxRetries) using model: \(model)")
                
                // Update UI to show current attempt status
                await MainActor.run {
                    if attempt == 1 {
                        // First attempt - explicitly set to 1 for "Generating..." status
                        self.currentRetryAttempt = 1
                    } else if attempt == 2 {
                        // Second attempt - show "Retrying..."
                        self.currentRetryAttempt = 2
                    } else if attempt == 3 {
                        // Third attempt - show "Retrying again..."
                        self.currentRetryAttempt = 3
                    }
                }
                
                // Use specified model (gpt-5-mini for journal entries, gpt-5 for analyzer)
                print("🔄🔄🔄 CALLING OpenAI API - Model: \(model), AnalysisType: \(analysisType)")
                let response = try await openAIService.generateAIResponse(for: prompt, model: model, analysisType: analysisType)
                print("🔄🔄🔄 OpenAI API RESPONSE RECEIVED - Length: \(response.count) characters")
                
                // Check if response is empty or whitespace-only - treat as failure to retry
                let trimmedResponse = response.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmedResponse.isEmpty {
                    print("⚠️ AI response is empty or whitespace-only, treating as failure for retry")
                    throw OpenAIError.invalidResponse("Empty or whitespace-only response received")
                }
                
                print("✅ AI response successful on attempt \(attempt)")
                
                // Reset retry attempt on success
                await MainActor.run {
                    self.currentRetryAttempt = 1
                }
                
                return response
            } catch {
                lastError = error
                print("❌ AI generation attempt \(attempt) failed: \(error.localizedDescription)")
                
                // Don't retry on certain errors
                if let openAIError = error as? OpenAIError {
                    switch openAIError {
                    case .invalidAPIKey, .quotaExceeded:
                        // Reset retry attempt on non-retryable errors
                        await MainActor.run {
                            self.currentRetryAttempt = 1
                        }
                        throw error // Don't retry these errors
                    default:
                        break // Retry other errors
                    }
                }
                
                // Wait before retrying (exponential backoff: 4s, 7s)
                if attempt < maxRetries {
                    let delay: Double = attempt == 1 ? 4.0 : 7.0 // 4s for first retry, 7s for second retry
                    print("⏳ Waiting \(delay) seconds before retry...")
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
        }
        
        // Reset retry attempt on final failure
        await MainActor.run {
            self.currentRetryAttempt = 1
        }
        
        throw lastError ?? AIError.generationFailed
    }
    
    func deleteJournalEntry(_ entry: JournalEntry) async {
        do {
            try await supabaseService.deleteJournalEntry(id: entry.id)
            await loadJournalEntries()
        } catch {
            errorMessage = "Failed to delete entry: \(error.localizedDescription)"
        }
    }
    
    /// Updates the favorite status of the most recent journal entry
    func updateCurrentJournalEntryFavoriteStatus(isFavorite: Bool) async {
        guard currentUser != nil else {
            errorMessage = "User not authenticated."
            return
        }
        
        // Load current entries to find the most recent one
        await loadJournalEntries()
        
        guard let mostRecentEntry = journalEntries.first else {
            errorMessage = "No journal entry found to update favorite status."
            return
        }
        
        // Create updated entry with the new favorite status
            let tagsArray: [String] = Array(mostRecentEntry.tags)
            let updatedEntry = JournalEntry(
            id: mostRecentEntry.id, // Use existing ID
            userId: mostRecentEntry.userId,
            guidedQuestionId: mostRecentEntry.guidedQuestionId,
            content: mostRecentEntry.content,
            aiPrompt: mostRecentEntry.aiPrompt,
            aiResponse: mostRecentEntry.aiResponse,
            tags: tagsArray,
            isFavorite: isFavorite, // Update favorite status
            entryType: mostRecentEntry.entryType, // Preserve entry type
            createdAt: mostRecentEntry.createdAt,
            updatedAt: Date(), // Update timestamp
            fuqAiPrompt: mostRecentEntry.fuqAiPrompt,
            fuqAiResponse: mostRecentEntry.fuqAiResponse,
            isFollowUpDay: mostRecentEntry.isFollowUpDay,
            usedForFollowUp: mostRecentEntry.usedForFollowUp,
            followUpQuestion: mostRecentEntry.followUpQuestion
        )
        
        do {
            _ = try await supabaseService.updateJournalEntry(updatedEntry)
            await loadJournalEntries() // Reload to reflect changes
            print("✅ Journal entry favorite status updated to: \(isFavorite)")
        } catch {
            errorMessage = "Failed to update journal entry favorite status: \(error.localizedDescription)"
            print("❌ Failed to update journal entry favorite status: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Open Question Journal Entry Management (Duplicate functionality)
    func createOpenQuestionJournalEntry(content: String) async {
        guard let user = currentUser else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // Create journal entry with static open question - store in tags for identification
            let entry = JournalEntry(
                userId: user.id,
                guidedQuestionId: nil, // No actual question ID for open question
                content: content,
                aiPrompt: nil,
                aiResponse: nil,
                tags: ["open_question"], // Tag to identify as open question entry
                isFavorite: false,
                entryType: "open"
            )
            
            // Save to database with special handling for open question
            let savedEntry = try await supabaseService.createOpenQuestionJournalEntry(entry, staticQuestion: "Looking at today or yesterday, share moments or thoughts that stood out.")
            
            // Refresh entries
            await loadOpenQuestionJournalEntries()
            
            print("Open Question journal entry saved successfully: \(savedEntry.content)")
            
        } catch {
            errorMessage = "Failed to save open question journal entry: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func loadOpenQuestionJournalEntries() async {
        guard let user = currentUser else { return }
        
        do {
            openQuestionJournalEntries = try await supabaseService.fetchOpenQuestionJournalEntries(userId: user.id)
        } catch {
            // Handle cancelled requests gracefully
            if error.localizedDescription.contains("cancelled") {
                print("⚠️ loadOpenQuestionJournalEntries: Request was cancelled, keeping existing entries")
                // Don't show error for cancelled requests - keep existing data
            } else {
                errorMessage = "Failed to load open question journal entries: \(error.localizedDescription)"
                print("❌ Failed to load open question journal entries: \(error.localizedDescription)")
            }
        }
    }
    
    func updateCurrentOpenQuestionJournalEntryWithAIPrompt(aiPrompt: String) async {
        // Find the most recent open question journal entry for the current user
        guard currentUser != nil else {
            errorMessage = "User not authenticated."
            return
        }
        
        // Load current entries to find the most recent one
        await loadOpenQuestionJournalEntries()
        
        guard let mostRecentEntry = openQuestionJournalEntries.first else {
            errorMessage = "No open question journal entry found to update."
            return
        }
        
        // Create updated entry with AI prompt
        let tagsArray: [String] = Array(mostRecentEntry.tags)
        let updatedEntry = JournalEntry(
            id: mostRecentEntry.id,
            userId: mostRecentEntry.userId,
            guidedQuestionId: mostRecentEntry.guidedQuestionId,
            content: mostRecentEntry.content,
            aiPrompt: aiPrompt, // Add the AI prompt
            aiResponse: mostRecentEntry.aiResponse,
            tags: tagsArray,
            isFavorite: mostRecentEntry.isFavorite,
            entryType: mostRecentEntry.entryType, // Preserve entry type
            createdAt: mostRecentEntry.createdAt,
            updatedAt: Date(), // Update timestamp
            fuqAiPrompt: mostRecentEntry.fuqAiPrompt,
            fuqAiResponse: mostRecentEntry.fuqAiResponse,
            isFollowUpDay: mostRecentEntry.isFollowUpDay,
            usedForFollowUp: mostRecentEntry.usedForFollowUp,
            followUpQuestion: mostRecentEntry.followUpQuestion
        )
        
        do {
            _ = try await supabaseService.updateJournalEntry(updatedEntry)
            await loadOpenQuestionJournalEntries() // Refresh entries
            print("✅ Open Question journal entry updated with AI prompt")
        } catch {
            errorMessage = "Failed to update open question journal entry with AI prompt: \(error.localizedDescription)"
            print("❌ Failed to update open question journal entry: \(error.localizedDescription)")
        }
    }
    
    /// Generates AI response using OpenAI and updates the open question journal entry
    func generateAndSaveOpenQuestionAIResponse() async {
        guard currentUser != nil else {
            errorMessage = "User not authenticated."
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // Load current entries to find the most recent one
            await loadOpenQuestionJournalEntries()
            
            guard let mostRecentEntry = openQuestionJournalEntries.first else {
                errorMessage = "No open question journal entry found to generate AI response."
                return
            }
            
            guard let aiPrompt = mostRecentEntry.aiPrompt, !aiPrompt.isEmpty else {
                errorMessage = "No AI prompt found in open question journal entry."
                return
            }
            
            print("🤖 Generating Open Question AI response for prompt: \(aiPrompt.prefix(100))...")
            
            // Generate AI response using OpenAI with retry logic
            // Use "journal" analysisType to avoid adding analyzer system message
            // Use gpt-5-mini (no reasoning tokens) with 2000 tokens for journal entries
            let aiResponse = try await generateAIResponseWithRetry(for: aiPrompt, model: "gpt-5-mini", analysisType: "journal")
            
            // Create updated entry with AI response
            let tagsArray: [String] = Array(mostRecentEntry.tags)
            let updatedEntry = JournalEntry(
                id: mostRecentEntry.id,
                userId: mostRecentEntry.userId,
                guidedQuestionId: mostRecentEntry.guidedQuestionId,
                content: mostRecentEntry.content,
                aiPrompt: mostRecentEntry.aiPrompt,
                aiResponse: aiResponse, // Add the AI response
                tags: tagsArray,
                isFavorite: mostRecentEntry.isFavorite,
                entryType: mostRecentEntry.entryType, // Preserve entry type
                createdAt: mostRecentEntry.createdAt,
                updatedAt: Date(), // Update timestamp
                fuqAiPrompt: mostRecentEntry.fuqAiPrompt,
                fuqAiResponse: mostRecentEntry.fuqAiResponse,
                isFollowUpDay: mostRecentEntry.isFollowUpDay,
                usedForFollowUp: mostRecentEntry.usedForFollowUp,
                followUpQuestion: mostRecentEntry.followUpQuestion
            )
            
            // Save updated entry to database
            _ = try await supabaseService.updateJournalEntry(updatedEntry)
            await loadOpenQuestionJournalEntries() // Refresh entries
            
            print("✅ Open Question AI response generated and saved: \(aiResponse.prefix(100))...")
            
        } catch {
            errorMessage = "The AI was on it's break 😅 please try again."
            print("❌ Failed to generate open question AI response: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    /// Updates the favorite status of the most recent open question journal entry
    func updateCurrentOpenQuestionJournalEntryFavoriteStatus(isFavorite: Bool) async {
        guard currentUser != nil else {
            errorMessage = "User not authenticated."
            return
        }
        
        // Load current entries to find the most recent one
        await loadOpenQuestionJournalEntries()
        
        guard let mostRecentEntry = openQuestionJournalEntries.first else {
            errorMessage = "No open question journal entry found to update favorite status."
            return
        }
        
        // Create updated entry with the new favorite status
            let tagsArray: [String] = Array(mostRecentEntry.tags)
            let updatedEntry = JournalEntry(
            id: mostRecentEntry.id, // Use existing ID
            userId: mostRecentEntry.userId,
            guidedQuestionId: mostRecentEntry.guidedQuestionId,
            content: mostRecentEntry.content,
            aiPrompt: mostRecentEntry.aiPrompt,
            aiResponse: mostRecentEntry.aiResponse,
            tags: tagsArray,
            isFavorite: isFavorite, // Update favorite status
            entryType: mostRecentEntry.entryType, // Preserve entry type
            createdAt: mostRecentEntry.createdAt,
            updatedAt: Date(), // Update timestamp
            fuqAiPrompt: mostRecentEntry.fuqAiPrompt,
            fuqAiResponse: mostRecentEntry.fuqAiResponse,
            isFollowUpDay: mostRecentEntry.isFollowUpDay,
            usedForFollowUp: mostRecentEntry.usedForFollowUp,
            followUpQuestion: mostRecentEntry.followUpQuestion
        )
        
        do {
            _ = try await supabaseService.updateJournalEntry(updatedEntry)
            await loadOpenQuestionJournalEntries() // Reload to reflect changes
            print("✅ Open Question journal entry favorite status updated to: \(isFavorite)")
        } catch {
            errorMessage = "Failed to update open question journal entry favorite status: \(error.localizedDescription)"
            print("❌ Failed to update open question journal entry favorite status: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Analyzer Stats
    func calculateAnalyzerStats(startDate: Date, endDate: Date) -> AnalyzerStats {
        let calendar = Calendar.current
        let allEntries = journalEntries + openQuestionJournalEntries + followUpQuestionEntries
        
        // Filter entries within date range
        let entriesInRange = allEntries.filter { entry in
            entry.createdAt >= startDate && entry.createdAt <= endDate
        }
        
        // Calculate logs count (unique days with entries)
        let uniqueDays = Set(entriesInRange.map { calendar.startOfDay(for: $0.createdAt) })
        let logsCount = uniqueDays.count
        
        // Calculate favorite log time (time of day with most entries)
        let timeCategories: [(String, Range<Int>)] = [
            ("Early Morning", 2..<7),
            ("Morning", 7..<10),
            ("Mid Day", 10..<14),
            ("Afternoon", 14..<17),
            ("Evening", 17..<21),
            ("Late Evening", 21..<26) // 21-23, 0-2 (wraps around)
        ]
        
        var timeCounts: [String: Int] = [:]
        for entry in entriesInRange {
            let hour = calendar.component(.hour, from: entry.createdAt)
            for (category, range) in timeCategories {
                if range.contains(hour) || (range.lowerBound == 21 && hour < 2) {
                    timeCounts[category, default: 0] += 1
                    break
                }
            }
        }
        
        let favoriteLogTime = timeCounts.max(by: { $0.value < $1.value })?.key ?? "—"
        
        // Calculate streak (consecutive days with entries within the analysis period)
        // Start from the latest day with an entry in the range and count backwards
        guard let latestDay = uniqueDays.max() else {
            return AnalyzerStats(
                logsCount: logsCount,
                streakCount: 0,
                favoriteLogTime: favoriteLogTime
            )
        }
        
        var streakCount = 0
        var currentDate = calendar.startOfDay(for: latestDay)
        let rangeStart = calendar.startOfDay(for: startDate)
        let rangeEnd = calendar.startOfDay(for: endDate)
        
        // Count consecutive days backwards from the latest day with an entry
        // Only count days that are within the analysis period (startDate to endDate)
        while currentDate >= rangeStart && currentDate <= rangeEnd {
            // Check if this day has an entry
            if uniqueDays.contains(currentDate) {
                streakCount += 1
                // Move to previous day
                if let previousDay = calendar.date(byAdding: .day, value: -1, to: currentDate) {
                    currentDate = previousDay
                } else {
                    break
                }
            } else {
                // No entry for this day - streak is broken
                break
            }
        }
        
        return AnalyzerStats(
            logsCount: logsCount,
            streakCount: streakCount,
            favoriteLogTime: favoriteLogTime
        )
    }
    // MARK: - Analyzer Entries
    func loadAnalyzerEntries() async {
        guard let user = currentUser else {
            print("⚠️ loadAnalyzerEntries: No current user, skipping load")
            return
        }
        
        guard isAuthenticated else {
            print("⚠️ loadAnalyzerEntries: User not authenticated, skipping load")
            return
        }
        
        do {
            analyzerEntries = try await supabaseService.fetchAnalyzerEntries(userId: user.id)
            print("✅ Analyzer entries loaded: \(analyzerEntries.count) entries found")
        } catch {
            // Handle cancelled requests gracefully
            if error.localizedDescription.contains("cancelled") {
                print("⚠️ loadAnalyzerEntries: Request was cancelled, keeping existing entries")
            } else if error.localizedDescription.contains("not authenticated") || error.localizedDescription.contains("authentication") {
                // Don't show error for authentication issues - user might not be logged in yet
                print("⚠️ loadAnalyzerEntries: Authentication issue, skipping error display")
            } else {
                errorMessage = "Failed to load analyzer entries: \(error.localizedDescription)"
                print("❌ Failed to load analyzer entries: \(error.localizedDescription)")
            }
        }
    }
    
    func updateAnalyzerEntryResponse(entryId: UUID, analyzerAiResponse: String) async {
        do {
            let updated = try await supabaseService.updateAnalyzerEntryResponse(
                entryId: entryId,
                analyzerAiResponse: analyzerAiResponse
            )
            
            if let index = analyzerEntries.firstIndex(where: { $0.id == entryId }) {
                analyzerEntries[index] = updated
            } else {
                analyzerEntries.insert(updated, at: 0)
            }
            print("🧠 Updated analyzer entry response for \(entryId)")
        } catch {
            errorMessage = "Failed to update analyzer entry: \(error.localizedDescription)"
            print("❌ Failed to update analyzer entry: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Streak Calculation
    func calculateEntryStreak() -> Int {
        guard currentUser != nil else { return 0 }
        
        // Get all journal entries for the user, sorted by creation date (newest first)
        let allEntries = journalEntries + openQuestionJournalEntries
        let sortedEntries = allEntries.sorted { $0.createdAt > $1.createdAt }
        
        guard !sortedEntries.isEmpty else { return 0 }
        
        let calendar = Calendar.current
        let today = Date()
        var streak = 0
        // Start from yesterday to count streak up to yesterday (not including today)
        var currentDate = calendar.date(byAdding: .day, value: -1, to: today) ?? today
        
        // Start from today and work backwards
        for entry in sortedEntries {
            let entryDate = entry.createdAt
            
            // Check if this entry was created on the current date we're checking
            if calendar.isDate(entryDate, inSameDayAs: currentDate) {
                streak += 1
                // Move to the previous day
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
            } else if entryDate < currentDate {
                // If the entry is older than the current date we're checking, break
                break
            }
        }
        
        print("📊 Calculated entry streak: \(streak) days")
        return streak
    }
    
    // MARK: - Goal Management
    func createGoal(content: String, goals: String) async {
        guard let user = currentUser else { return }
        
        do {
            let goal = Goal(userId: user.id, content: content, goals: goals)
            _ = try await supabaseService.createGoal(goal)
        } catch {
            errorMessage = "Failed to create goal: \(error.localizedDescription)"
        }
    }
    
    func fetchGoals() async -> [Goal] {
        guard let user = currentUser else { return [] }
        do {
            return try await supabaseService.fetchGoals(userId: user.id)
        } catch {
            errorMessage = "Failed to fetch goals: \(error.localizedDescription)"
            return []
        }
    }
    
    func updateGoal(_ goal: Goal) async {
        do {
            _ = try await supabaseService.updateGoal(goal)
        } catch {
            errorMessage = "Failed to update goal: \(error.localizedDescription)"
        }
    }
    
    func deleteGoal(_ goal: Goal) async {
        do {
            try await supabaseService.deleteGoal(id: goal.id)
        } catch {
            errorMessage = "Failed to delete goal: \(error.localizedDescription)"
        }
    }
    
    func saveGoal(_ goalText: String) async {
        guard let user = currentUser else { return }
        guard !goalText.isEmpty else { return }
        
        do {
            // First, try to get existing goals for this user
            let existingGoals = try await supabaseService.fetchGoals(userId: user.id)
            
            if let existingGoal = existingGoals.first {
                // Update the existing goal - we'll need to modify the existing goal's properties
                // Since we can't directly modify the struct, we'll delete the old one and create a new one
                _ = try await supabaseService.deleteGoal(id: existingGoal.id)
                let newGoal = Goal(userId: user.id, content: existingGoal.content, goals: goalText)
                _ = try await supabaseService.createGoal(newGoal)
                print("✅ Goal updated successfully: \(goalText)")
            } else {
                // Create a new goal if none exists
                let newGoal = Goal(userId: user.id, content: "", goals: goalText)
                _ = try await supabaseService.createGoal(newGoal)
                print("✅ Goal created successfully: \(goalText)")
            }
        } catch {
            errorMessage = "Failed to save goal: \(error.localizedDescription)"
            print("❌ Failed to save goal: \(error.localizedDescription)")
        }
        
        // Refresh the goals array to reflect the updated goal
        await loadGoals()
    }
    
    // MARK: - Favorite Journal Entries
    func loadFavoriteEntries() async {
        guard let user = currentUser else {
            print("⚠️ loadFavoriteEntries: No current user, skipping load")
            return
        }
        
        guard isAuthenticated else {
            print("⚠️ loadFavoriteEntries: User not authenticated, skipping load")
            return
        }
        
        do {
            favoriteJournalEntries = try await supabaseService.fetchFavoriteJournalEntries(userId: user.id)
            print("✅ Loaded \(favoriteJournalEntries.count) favorite entries")
        } catch {
            // Handle cancelled requests gracefully
            if error.localizedDescription.contains("cancelled") {
                print("⚠️ loadFavoriteEntries: Request was cancelled, keeping existing entries")
            } else if error.localizedDescription.contains("not authenticated") || error.localizedDescription.contains("authentication") {
                // Don't show error for authentication issues - user might not be logged in yet
                print("⚠️ loadFavoriteEntries: Authentication issue, skipping error display")
            } else {
                errorMessage = "Failed to load favorite entries: \(error.localizedDescription)"
                print("❌ Failed to load favorite entries: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Delete Favorite Entry
    func deleteFavoriteEntries(at offsets: IndexSet) async {
        for index in offsets {
            let entry = favoriteJournalEntries[index]
            
            do {
                // Remove from database
                try await supabaseService.removeFavoriteEntry(entryId: entry.id)
                
                // Remove from local array
                await MainActor.run {
                    favoriteJournalEntries.remove(atOffsets: IndexSet([index]))
                }
                
                print("✅ Successfully removed favorite entry: \(entry.id)")
            } catch {
                errorMessage = "Failed to remove favorite: \(error.localizedDescription)"
                print("❌ Failed to remove favorite entry: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Question Refresh Functions
    
    func refreshGuidedQuestion() async {
        guard let user = currentUser else { 
            errorMessage = "User not authenticated"
            return 
        }
        
        do {
            // Create new guided question entry with empty content (preserve history)
            let newEntry = JournalEntry(
                userId: user.id,
                guidedQuestionId: currentQuestion?.id,
                content: "",
                entryType: "guided"
            )
            
            _ = try await supabaseService.createJournalEntry(newEntry)
            print("✅ Created new guided question entry (preserving history)")
            
            // Reload data to reflect changes
            await loadJournalEntries()
            
        } catch {
            errorMessage = "Failed to refresh guided question: \(error.localizedDescription)"
            print("❌ Failed to refresh guided question: \(error.localizedDescription)")
        }
    }
    
    func refreshOpenQuestion() async {
        guard let user = currentUser else { 
            errorMessage = "User not authenticated"
            return 
        }
        
        do {
            // Create new open question entry with empty content (preserve history)
            let newEntry = JournalEntry(
                userId: user.id,
                guidedQuestionId: nil,
                content: "",
                tags: ["open_question"],
                entryType: "open"
            )
            
            _ = try await supabaseService.createOpenQuestionJournalEntry(newEntry, staticQuestion: "Looking at today or yesterday, share moments or thoughts that stood out.")
            print("✅ Created new open question entry (preserving history)")
            
            // Reload data to reflect changes
            await loadOpenQuestionJournalEntries()
            
        } catch {
            errorMessage = "Failed to refresh open question: \(error.localizedDescription)"
            print("❌ Failed to refresh open question: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Smart Reset Functions (Better than 2AM timer)
    
    func checkAndResetIfNeeded() async {
        guard let user = currentUser else { 
            print("🕐 checkAndResetIfNeeded: No current user, skipping")
            return 
        }
        
        do {
            // Get user's last journal entry date
            let entries = try await supabaseService.fetchJournalEntries(userId: user.id)
            
            guard let lastEntry = entries.max(by: { $0.createdAt < $1.createdAt }) else {
                // No entries yet, nothing to reset
                print("🕐 checkAndResetIfNeeded: No journal entries found, skipping reset")
                return
            }
            
            // Check if it's been past 2AM since last entry
            let calendar = Calendar.current
            let now = Date()
            let lastEntryDate = lastEntry.createdAt
            
            print("🕐 checkAndResetIfNeeded: Last entry at \(lastEntryDate), Current time: \(now)")
            
            // Get 2AM of the day after the last entry
            var components = calendar.dateComponents([.year, .month, .day], from: lastEntryDate)
            components.hour = 2
            components.minute = 0
            components.second = 0
            
            let next2AM = calendar.date(byAdding: .day, value: 1, to: calendar.date(from: components)!)!
            
            print("🕐 checkAndResetIfNeeded: Next 2AM reset time: \(next2AM)")
            print("🕐 checkAndResetIfNeeded: Is now >= next2AM? \(now >= next2AM)")
            
            // If current time is past the next 2AM, reset the UI
            if now >= next2AM {
                // Check if we've already reset today to prevent multiple resets
                let calendar = Calendar.current
                if let lastReset = lastResetDate,
                   calendar.isDate(lastReset, inSameDayAs: now) {
                    print("🕐 Already reset today at \(lastReset), skipping additional reset")
                    return
                }
                
                print("🕐 It's past 2AM since last entry - resetting UI")
                lastResetDate = now
                await resetUIForNewDay()
                
                // OLD: Pre-generation moved to trigger points (Centered button, Analyze button, Follow-up Done button)
                // No longer pre-generating during 2AM reset
            } else {
                print("🕐 Not yet time for reset - skipping")
            }
            
        } catch {
            print("❌ Failed to check reset status: \(error.localizedDescription)")
        }
    }
    
    /// Pre-generates follow-up question after triggers (Centered button, Analyze button, Follow-up Done button)
    /// Checks: same day, last follow-up day, 21 days age
    func preGenerateFollowUpQuestionIfNeeded() async {
        guard let user = currentUser else { 
            print("⚠️ preGenerateFollowUpQuestionIfNeeded: User not authenticated")
            return 
        }
        
        let calendar = Calendar.current
        let today = Date()
        
        // Check 1: Already generated today? Skip if yes (UNLESS it's a follow-up day and user just replied)
        // On follow-up day, we want to generate a NEW question after user replies for the NEXT follow-up day
        let isTodayFollowUpDay = supabaseService.isFollowUpQuestionDay()
        
        // Check if user replied today (needed to allow regeneration on follow-up day)
        await loadFollowUpQuestionEntries()
        let todaysReplies = followUpQuestionEntries.filter { entry in
            calendar.isDate(entry.createdAt, inSameDayAs: today) &&
            entry.entryType == "follow_up" &&
            !entry.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        let userRepliedToday = !todaysReplies.isEmpty
        
        // SAFETY CHECK: If it's a follow-up day and user hasn't replied yet, don't generate
        // This prevents generation when called from guided/open question Centered buttons on follow-up days
        // Only allow generation on follow-up days if user has already replied (triggered from follow-up Done button)
        if isTodayFollowUpDay && !userRepliedToday {
            print("⏭️ Skipping pre-generation - today is follow-up day but user hasn't replied yet")
            print("   - Pre-generation should only happen after user replies to follow-up question")
            return
        }
        
        do {
            if let existingGeneration = try await supabaseService.fetchFollowUpGeneration(userId: user.id) {
                if calendar.isDate(existingGeneration.createdAt, inSameDayAs: today) {
                    // If generation was created today, check if it's already for the next follow-up day
                    // Calculate last follow-up day to determine if existing generation is already for next cycle
                    let referenceDate = calendar.date(from: DateComponents(year: 2024, month: 1, day: 1))!
                    var lastFollowUpDay: Date? = nil
                    var checkDate = today
                    
                    for _ in 0..<30 {
                        let checkDaysSinceReference = calendar.dateComponents([.day], from: referenceDate, to: checkDate).day ?? 0
                        if checkDaysSinceReference % 3 == 0 {
                            lastFollowUpDay = calendar.startOfDay(for: checkDate)
                            break
                        }
                        if let previousDay = calendar.date(byAdding: .day, value: -1, to: checkDate) {
                            checkDate = previousDay
                        } else {
                            break
                        }
                    }
                    
                    // If generation was created today AFTER the last follow-up day start, it's already for next cycle
                    // Don't regenerate on same day - the existing question is already valid for next follow-up day
                    if let lastFollowUp = lastFollowUpDay, existingGeneration.createdAt >= lastFollowUp {
                        print("✅ Follow-up question already generated today for next follow-up day - skipping pre-generation")
                        print("   - Existing generation created: \(existingGeneration.createdAt)")
                        print("   - Last follow-up day: \(lastFollowUp)")
                        print("   - Is follow-up day: \(isTodayFollowUpDay)")
                        print("   - User replied today: \(userRepliedToday)")
                        return
                    }
                    
                    // If today is a follow-up day AND user replied today, and generation is from before last follow-up day
                    // (shouldn't happen, but handle edge case), allow regeneration
                    if isTodayFollowUpDay && userRepliedToday {
                        print("📅 Follow-up day + user replied today - allowing new generation for next follow-up day")
                        print("   - Existing generation created: \(existingGeneration.createdAt)")
                        print("   - User replied: \(userRepliedToday)")
                        // Continue to generation logic below (don't return)
                    } else {
                        print("✅ Follow-up question already generated today - skipping pre-generation")
                        print("   - Is follow-up day: \(isTodayFollowUpDay)")
                        print("   - User replied today: \(userRepliedToday)")
                        return
                    }
                } else {
                    // Existing generation was NOT created today
                    // IMPORTANT: If it's a follow-up day and user hasn't replied yet, don't overwrite the displayed question
                    if isTodayFollowUpDay && !userRepliedToday {
                        // Check if the existing generation is for today's follow-up day
                        // Calculate last follow-up day to see if generation is for today
                        let referenceDate = calendar.date(from: DateComponents(year: 2024, month: 1, day: 1))!
                        var lastFollowUpDay: Date? = nil
                        var checkDate = today
                        
                        for _ in 0..<30 {
                            let checkDaysSinceReference = calendar.dateComponents([.day], from: referenceDate, to: checkDate).day ?? 0
                            if checkDaysSinceReference % 3 == 0 {
                                lastFollowUpDay = calendar.startOfDay(for: checkDate)
                                break
                            }
                            if let previousDay = calendar.date(byAdding: .day, value: -1, to: checkDate) {
                                checkDate = previousDay
                            } else {
                                break
                            }
                        }
                        
                        // If generation was created for today's follow-up day, don't overwrite it
                        if let lastFollowUp = lastFollowUpDay, existingGeneration.createdAt >= lastFollowUp {
                            print("✅ It's a follow-up day and question is already displayed - skipping pre-generation until user replies")
                            print("   - Existing generation created: \(existingGeneration.createdAt)")
                            print("   - Today is follow-up day: \(lastFollowUp)")
                            print("   - User replied today: \(userRepliedToday)")
                            return
                        }
                    }
                }
            }
        } catch {
            print("⚠️ Error checking existing follow-up generation: \(error.localizedDescription)")
            // Continue with checks if we can't fetch
        }
        
        // Check 2: If we passed Check 1 (same day with reply on follow-up day), always generate
        // Otherwise, check if generation is needed based on age and trigger points
        var shouldGenerate = false
        
        do {
            if let existingGeneration = try await supabaseService.fetchFollowUpGeneration(userId: user.id) {
                let daysSinceGeneration = calendar.dateComponents([.day], from: existingGeneration.createdAt, to: today).day ?? 0
                
                // Always generate if:
                // 1. We passed Check 1 (follow-up day + user replied - already handled above, will continue)
                // 2. Question is older than 21 days (refresh old question)
                // 3. Question was generated BEFORE the last follow-up day (it's stale and was used already)
                
                // Calculate last follow-up day
                let referenceDate = calendar.date(from: DateComponents(year: 2024, month: 1, day: 1))!
                var lastFollowUpDay: Date? = nil
                var checkDate = today
                
                // Find the most recent follow-up day by going backwards
                for _ in 0..<30 {
                    let checkDaysSinceReference = calendar.dateComponents([.day], from: referenceDate, to: checkDate).day ?? 0
                    if checkDaysSinceReference % 3 == 0 {
                        lastFollowUpDay = calendar.startOfDay(for: checkDate)
                        break
                    }
                    if let previousDay = calendar.date(byAdding: .day, value: -1, to: checkDate) {
                        checkDate = previousDay
                    } else {
                        break
                    }
                }
                
                // If question was generated BEFORE last follow-up day, it's stale (already used) - generate new
                if let lastFollowUp = lastFollowUpDay {
                    if existingGeneration.createdAt < lastFollowUp {
                        print("📅 Follow-up question was generated BEFORE last follow-up day (stale) - generating new")
                        shouldGenerate = true
                    } else if daysSinceGeneration >= 21 {
                        print("📅 Follow-up question is \(daysSinceGeneration) days old (>= 21 days) - generating new")
                        shouldGenerate = true
                    } else {
                        // Question was generated after last follow-up day and less than 21 days old
                        // This means it's already a valid pre-generated question for the next follow-up day
                        // Only generate a NEW question if:
                        // 1. It's a follow-up day AND user replied today (need new question for next cycle)
                        // Otherwise, the existing pre-generated question is still valid - don't generate
                        if isTodayFollowUpDay && userRepliedToday {
                            print("📅 Follow-up day + user replied today - generating new question for next cycle")
                            print("   - Existing question age: \(daysSinceGeneration) days")
                            print("   - Last follow-up day: \(lastFollowUp)")
                            print("   - Existing question created: \(existingGeneration.createdAt)")
                            print("   - User replied today: \(userRepliedToday)")
                            shouldGenerate = true
                        } else {
                            print("✅ Valid pre-generated question already exists for next follow-up day - skipping generation")
                            print("   - Existing question age: \(daysSinceGeneration) days")
                            print("   - Last follow-up day: \(lastFollowUp)")
                            print("   - Existing question created: \(existingGeneration.createdAt)")
                            print("   - Is follow-up day: \(isTodayFollowUpDay)")
                            print("   - User replied today: \(userRepliedToday)")
                            shouldGenerate = false
                        }
                    }
                } else if daysSinceGeneration >= 21 {
                    print("📅 Follow-up question is \(daysSinceGeneration) days old (>= 21 days) - generating new")
                    shouldGenerate = true
                } else {
                    // Fallback: if we can't determine last follow-up day, only generate if:
                    // 1. It's a follow-up day AND user replied today (need new question for next cycle)
                    // Otherwise, assume existing question is still valid - don't generate
                    if isTodayFollowUpDay && userRepliedToday {
                        print("📅 Trigger point detected (fallback) - follow-up day + user replied - generating new question")
                        shouldGenerate = true
                    } else {
                        print("✅ Existing follow-up question exists (fallback) - skipping generation")
                        shouldGenerate = false
                    }
                }
            } else {
                // No existing generation, generate new
                print("📅 No existing follow-up generation found - generating new")
                shouldGenerate = true
            }
        } catch {
            print("⚠️ Error checking follow-up generation: \(error.localizedDescription)")
            // If we can't check, try to generate (safer to try than skip)
            shouldGenerate = true
        }
        
        if !shouldGenerate {
            print("✅ Pre-generation checks passed - no new generation needed")
            return
        }
        
        // Generate follow-up question in the background
        print("🔮 Pre-generating follow-up question...")
        await generateFollowUpQuestionForPreGeneration()
        print("✅ Pre-generation complete - follow-up question ready for next follow-up day")
    }
    
    /// Generates a new follow-up question and saves it to follow_up_generation table
    private func generateFollowUpQuestionForPreGeneration() async {
        guard let user = currentUser else { return }
        
        do {
            // Select a past journal entry for follow-up
            guard let pastEntry = try await supabaseService.selectPastJournalEntryForFollowUp(userId: user.id) else {
                print("⚠️ No eligible past entry found for follow-up question - UI will display static text")
                return
            }
            
            // Generate the follow-up question prompt
            let fuqAiPrompt = supabaseService.generateFollowUpQuestionPrompt(pastEntry: pastEntry)
            
            // Generate the follow-up question using OpenAI with retry logic (2s, 4s delays)
            // Use "journal" analysisType to avoid adding analyzer system message
            // Use gpt-5-mini (no reasoning tokens) for follow-up questions
            let fuqAiResponse = try await generateAIResponseWithRetry(for: fuqAiPrompt, model: "gpt-5-mini", analysisType: "journal")
            
            // Create follow-up generation entry (saves to follow_up_generation table)
            let followUpGeneration = FollowUpGeneration(
                userId: user.id,
                fuqAiPrompt: fuqAiPrompt,
                fuqAiResponse: fuqAiResponse,
                sourceEntryId: pastEntry.id,
                createdAt: Date(),
                updatedAt: Date()
            )
            
            // Save to follow_up_generation table (upserts, replaces existing)
            _ = try await supabaseService.createOrUpdateFollowUpGeneration(followUpGeneration)
            
            print("✅ Generated new follow-up question and saved to follow_up_generation table")
            print("✅ Question: \(fuqAiResponse.prefix(100))...")
            print("✅ Source entry ID: \(pastEntry.id)")
            
        } catch {
            print("❌ Failed to generate follow-up question: \(error.localizedDescription) - UI will display static text")
        }
    }
    
    // MARK: - User Profile Updates
    
    func updateUserProfile(firstName: String? = nil, lastName: String? = nil, gender: String? = nil, occupation: String? = nil, birthdate: String? = nil, notificationFrequency: String? = nil, streakEndingNotification: Bool? = nil) async {
        print("🔄 JournalViewModel: updateUserProfile() called")
        print("   firstName: '\(firstName ?? "nil")'")
        print("   lastName: '\(lastName ?? "nil")'")
        print("   currentUser: \(currentUser?.email ?? "nil")")
        
        guard currentUser != nil else { 
            errorMessage = "User not authenticated"
            print("❌ JournalViewModel: User not authenticated")
            return 
        }
        
        do {
            print("✅ JournalViewModel: Calling supabaseService.updateUserProfile")
            // Update the user's profile in Supabase
            try await supabaseService.updateUserProfile(
                firstName: firstName,
                lastName: lastName,
                gender: gender,
                occupation: occupation,
                birthdate: birthdate,
                notificationFrequency: notificationFrequency,
                streakEndingNotification: streakEndingNotification
            )
            
            // Update the local user profile
            currentUser?.firstName = firstName
            
            print("✅ Updated user profile with first name: \(firstName ?? "nil")")
            
        } catch {
            errorMessage = "Failed to update user profile: \(error.localizedDescription)"
            print("❌ Failed to update user profile: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Follow-Up Question Management
    
    /// Loads follow-up question entries for the current user
    func loadFollowUpQuestionEntries() async {
        guard let user = currentUser else { return }
        
        do {
            let allEntries = try await supabaseService.fetchJournalEntries(userId: user.id)
            print("🔍 Fetched \(allEntries.count) total entries")
            
            // Filter for follow-up entries
            followUpQuestionEntries = allEntries.filter { $0.entryType == "follow_up" }
            
            print("✅ Follow-up question entries loaded: \(followUpQuestionEntries.count) entries")
            
            // Debug: Print all follow-up entries with their details
            for (index, entry) in followUpQuestionEntries.enumerated() {
                let calendar = Calendar.current
                let isToday = calendar.isDate(entry.createdAt, inSameDayAs: Date())
                print("   Entry \(index): entryType=\(entry.entryType), contentLength=\(entry.content.count), isToday=\(isToday)")
                print("      - followUpQuestion field: \(entry.followUpQuestion != nil ? "exists (\(entry.followUpQuestion?.count ?? 0) chars)" : "nil")")
                if let followUpQuestion = entry.followUpQuestion {
                    print("      - followUpQuestion value: \(followUpQuestion.prefix(50))...")
                }
            }
        } catch {
            // Handle cancelled requests gracefully
            if error.localizedDescription.contains("cancelled") {
                print("⚠️ loadFollowUpQuestionEntries: Request was cancelled, keeping existing entries")
                // Don't show error for cancelled requests - keep existing data
            } else {
                errorMessage = "Failed to load follow-up question entries: \(error.localizedDescription)"
                print("❌ Failed to load follow-up question entries: \(error.localizedDescription)")
            }
        }
    }
    
    /// Checks if today is a follow-up question day and loads/generates the question
    /// NEW: Checks follow_up_generation table first, then journal_entries if user replied today
    /// - Parameter suppressErrors: If true, errors will be logged but not shown to the user (useful for background operations like pull-to-refresh)
    func checkAndLoadFollowUpQuestion(suppressErrors: Bool = false) async {
        guard let user = currentUser else { 
            print("⚠️ checkAndLoadFollowUpQuestion: User not authenticated")
            await MainActor.run {
                currentFollowUpQuestion = ""
                isLoadingFollowUpQuestion = false
            }
            return 
        }
        
        // Safety check: Ensure we're loading for the correct user
        // Clear question if user ID doesn't match lastUserId (user switched)
        if let lastId = lastUserId, lastId != user.id {
            print("⚠️ checkAndLoadFollowUpQuestion: User ID mismatch detected - clearing stale question")
            print("   - Last user ID: \(lastId)")
            print("   - Current user ID: \(user.id)")
            await MainActor.run {
                currentFollowUpQuestion = ""
                isLoadingFollowUpQuestion = false
            }
            // Update lastUserId to current user
            lastUserId = user.id
        }
        
        // Check if today is a follow-up question day
        guard supabaseService.isFollowUpQuestionDay() else {
            print("📅 Today is not a follow-up question day")
            // Clear follow-up question if it's not a follow-up day
            await MainActor.run {
                currentFollowUpQuestion = ""
                isLoadingFollowUpQuestion = false
            }
            return
        }
        
        // Safety check: If question already exists and suppressErrors is false (normal flow), return early
        // BUT: If suppressErrors is true (pull-to-refresh), always fetch fresh to ensure we have the latest
        let existingQuestion = await MainActor.run {
            return currentFollowUpQuestion
        }
        
        // Only skip fetch if question exists AND we're not forcing a refresh (suppressErrors = false means normal flow)
        // During pull-to-refresh (suppressErrors = true), we want to force a fresh fetch even if question exists
        if !existingQuestion.isEmpty && !suppressErrors {
            await MainActor.run {
                isLoadingFollowUpQuestion = false
            }
            print("✅ Follow-up question already loaded (\(existingQuestion.prefix(50))...), skipping fetch")
            return
        }
        
        // During pull-to-refresh, clear existing question to force fresh fetch
        // This ensures we're not using stale cached data from yesterday
        if suppressErrors && !existingQuestion.isEmpty {
            await MainActor.run {
                currentFollowUpQuestion = ""
                print("🔄 Pull-to-refresh: Cleared existing question to force fresh fetch")
            }
        }
        
        // Set loading state (reset it first to handle any stuck states)
        await MainActor.run {
            isLoadingFollowUpQuestion = true
        }
        
        let calendar = Calendar.current
        let today = Date()
        
        // Retry up to 3 times with delays to account for database write delays/race conditions
        // For pull-to-refresh, use more retries to handle potential timing issues
        var retryCount = 0
        let maxRetries = suppressErrors ? 5 : 3 // More retries for pull-to-refresh
        var foundQuestion = false
        
        while retryCount < maxRetries && !foundQuestion {
            // Step 1: Check if user has replied today (check journal_entries for follow_up_question on today)
            await loadFollowUpQuestionEntries()
            
            let todaysReplyEntries = followUpQuestionEntries.filter { entry in
                calendar.isDate(entry.createdAt, inSameDayAs: today) &&
                entry.entryType == "follow_up" &&
                !entry.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }
            
            // If user replied today, use the question from journal_entries.follow_up_question
            if let todaysReplyEntry = todaysReplyEntries.first {
                print("📝 Found today's reply entry - checking follow_up_question field...")
                print("   - Entry ID: \(todaysReplyEntry.id)")
                print("   - Entry created: \(todaysReplyEntry.createdAt)")
                print("   - Entry content length: \(todaysReplyEntry.content.count)")
                print("   - followUpQuestion field exists: \(todaysReplyEntry.followUpQuestion != nil)")
                
                if let followUpQuestion = todaysReplyEntry.followUpQuestion,
                   !followUpQuestion.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    await MainActor.run {
                        currentFollowUpQuestion = followUpQuestion
                        isLoadingFollowUpQuestion = false // Clear loading state immediately when question found
                    }
                    print("✅ Using follow-up question from today's reply: \(currentFollowUpQuestion.prefix(50))...")
                    foundQuestion = true
                    break
                } else {
                    print("⚠️ Today's reply entry exists but follow_up_question field is missing or empty")
                    print("   - This should not happen if entry was created correctly")
                    print("   - Will skip pre-generated question to avoid using future question")
                    // Don't break - let the hasAnyReplyToday check handle this
                }
            }
            
            // Step 2: Check follow_up_generation table for pre-generated question
            // IMPORTANT: Only use pre-generated question if user hasn't replied today
            // If user has replied today, skip pre-generated to avoid using future question
            if !todaysReplyEntries.isEmpty {
                print("⚠️ User has replied today - skipping pre-generated question to avoid using future question")
                print("   - Found \(todaysReplyEntries.count) reply entries for today")
                print("   - If follow_up_question field was missing, this indicates a data issue")
                // Skip pre-generated question entirely - user already replied, so pre-generated is for next time
                // Continue to next retry to see if question appears in journal entry
            } else {
                // Only check pre-generated question if user hasn't replied yet
                do {
                    print("🔍 [PULL-TO-REFRESH] Attempting to fetch from follow_up_generation table (attempt \(retryCount + 1)/\(maxRetries), suppressErrors: \(suppressErrors))...")
                    print("   - User ID: \(user.id)")
                    print("   - Querying: SELECT * FROM follow_up_generation WHERE user_id = '\(user.id)' LIMIT 1")
                    
                    if let generation = try await supabaseService.fetchFollowUpGeneration(userId: user.id) {
                        print("📦 [PULL-TO-REFRESH] ✅ Found follow-up generation in database")
                        print("   - ID: \(generation.id)")
                        print("   - Created: \(generation.createdAt)")
                        print("   - Response length: \(generation.fuqAiResponse.count) characters")
                        print("   - Response preview: \(generation.fuqAiResponse.prefix(100))...")
                        
                        let trimmedResponse = generation.fuqAiResponse.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !trimmedResponse.isEmpty {
                            await MainActor.run {
                                currentFollowUpQuestion = generation.fuqAiResponse
                                isLoadingFollowUpQuestion = false // Clear loading state immediately when question found
                            }
                            print("✅ [PULL-TO-REFRESH] Using pre-generated follow-up question from follow_up_generation table: \(currentFollowUpQuestion.prefix(50))...")
                            foundQuestion = true
                            break
                        } else {
                            print("⚠️ [PULL-TO-REFRESH] Follow-up generation found but response is empty or whitespace-only")
                            print("   - Full response: '\(generation.fuqAiResponse)'")
                        }
                    } else {
                        print("⚠️ [PULL-TO-REFRESH] No follow-up generation found in database for user \(user.id)")
                        print("   - This is attempt \(retryCount + 1) of \(maxRetries)")
                        print("   - Checking if table exists and has RLS policies enabled...")
                    }
                } catch {
                    print("❌ [PULL-TO-REFRESH] ERROR fetching follow-up generation: \(error.localizedDescription)")
                    print("   - Error type: \(type(of: error))")
                    print("   - Error details: \(error)")
                    print("   - suppressErrors: \(suppressErrors)")
                    if !suppressErrors {
                        // Only show error to user if not suppressing errors
                        errorMessage = "Failed to load follow-up question: \(error.localizedDescription)"
                    }
                    if retryCount < maxRetries - 1 {
                        print("⏳ [PULL-TO-REFRESH] Waiting 0.5s before retry...")
                        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 second delay
                    }
                    retryCount += 1
                    continue
                }
            }
            
            // If no question found and not last attempt, wait and retry
            if retryCount < maxRetries - 1 {
                print("⏳ No question found, waiting 0.5s before retry...")
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 second delay
            }
            
            retryCount += 1
        }
        
        // If still no question found, trigger fallback generation if needed
        if !foundQuestion {
            // Check current state before proceeding
            let currentState = await MainActor.run {
                return (currentFollowUpQuestion, isLoadingFollowUpQuestion)
            }
            
            if !currentState.0.isEmpty {
                // Question was found and set during retry loop, exit early
                print("✅ Question was set during retry loop: \(currentState.0.prefix(50))...")
                await MainActor.run {
                    isLoadingFollowUpQuestion = false
                }
                return
            }
            
            print("⚠️ No follow-up question found after \(maxRetries) attempts - triggering fallback if needed")
            
            // Always try one final fetch attempt (in case of race condition or timing issue)
            // This is especially important for pull-to-refresh scenarios
            print("🔄 Attempting final fetch from database...")
            if let generation = try? await supabaseService.fetchFollowUpGeneration(userId: user.id),
               !generation.fuqAiResponse.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                await MainActor.run {
                    currentFollowUpQuestion = generation.fuqAiResponse
                    isLoadingFollowUpQuestion = false
                }
                print("✅ Found question on final fetch attempt: \(currentFollowUpQuestion.prefix(50))...")
                return // Exit early since we found the question
            } else {
                print("⚠️ Final fetch attempt also failed - question may not exist in database")
            }
            
            // Also check journal_entries one more time in case user replied
            print("🔄 Attempting final check in journal_entries...")
            await loadFollowUpQuestionEntries()
            let todaysReplyEntries = followUpQuestionEntries.filter { entry in
                calendar.isDate(entry.createdAt, inSameDayAs: today) &&
                entry.entryType == "follow_up" &&
                !entry.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }
            
            if let todaysReplyEntry = todaysReplyEntries.first,
               let followUpQuestion = todaysReplyEntry.followUpQuestion,
               !followUpQuestion.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                await MainActor.run {
                    currentFollowUpQuestion = followUpQuestion
                    isLoadingFollowUpQuestion = false
                }
                print("✅ Found question from today's reply on final check: \(currentFollowUpQuestion.prefix(50))...")
                return
            }
            
            if !suppressErrors {
                // Only trigger pre-generation if suppressErrors is false (normal app open)
                print("🔄 Triggering fallback pre-generation...")
                await preGenerateFollowUpQuestionIfNeeded()
                // Try one more time after pre-generation
                if let generation = try? await supabaseService.fetchFollowUpGeneration(userId: user.id),
                   !generation.fuqAiResponse.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    await MainActor.run {
                        currentFollowUpQuestion = generation.fuqAiResponse
                        isLoadingFollowUpQuestion = false
                    }
                    print("✅ Using fallback pre-generated question: \(currentFollowUpQuestion.prefix(50))...")
                } else {
                    // If still no question found, clear loading state
                    await MainActor.run {
                        isLoadingFollowUpQuestion = false
                    }
                    print("⚠️ No question found even after fallback generation")
                }
            } else {
                // If suppressErrors is true (pull-to-refresh), try one more aggressive fetch with delay
                // This handles cases where database hasn't fully updated yet
                print("🔄 Pull-to-refresh: Attempting final aggressive fetch after delay...")
                try? await Task.sleep(nanoseconds: 1_500_000_000) // Wait 1.5s for database to catch up
                
                // Final aggressive fetch attempt
                if let generation = try? await supabaseService.fetchFollowUpGeneration(userId: user.id),
                   !generation.fuqAiResponse.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    await MainActor.run {
                        currentFollowUpQuestion = generation.fuqAiResponse
                        isLoadingFollowUpQuestion = false
                    }
                    print("✅ Found question on aggressive final fetch: \(currentFollowUpQuestion.prefix(50))...")
                } else {
                    // If still no question, check journal_entries one more time
                    await loadFollowUpQuestionEntries()
                    let finalReplyEntries = followUpQuestionEntries.filter { entry in
                        calendar.isDate(entry.createdAt, inSameDayAs: today) &&
                        entry.entryType == "follow_up" &&
                        !entry.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    }
                    
                    if let finalReplyEntry = finalReplyEntries.first,
                       let followUpQuestion = finalReplyEntry.followUpQuestion,
                       !followUpQuestion.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        await MainActor.run {
                            currentFollowUpQuestion = followUpQuestion
                            isLoadingFollowUpQuestion = false
                        }
                        print("✅ Found question from journal_entries on aggressive final fetch: \(currentFollowUpQuestion.prefix(50))...")
                    } else {
                        // Finally give up and clear loading state
                        await MainActor.run {
                            isLoadingFollowUpQuestion = false
                        }
                        print("⚠️ Pull-to-refresh: No question found after all attempts, cleared loading state")
                    }
                }
            }
        } else {
            // Question found, clear loading state
            await MainActor.run {
                isLoadingFollowUpQuestion = false
            }
            print("✅ Follow-up question loaded successfully")
        }
        
        // Final safety check: ensure loading state is cleared if question exists
        // This handles edge cases where the question was set but loading state wasn't cleared
        // Also verify question is still set (in case it was cleared somewhere else)
        let finalState = await MainActor.run {
            let question = currentFollowUpQuestion
            if !question.isEmpty {
                isLoadingFollowUpQuestion = false
                print("✅ Final safety check: Question confirmed loaded: \(question.prefix(50))...")
            } else {
                // If question is empty and we're on a follow-up day, log warning
                if supabaseService.isFollowUpQuestionDay() {
                    print("⚠️ Final safety check: Question is empty on follow-up day - may need another fetch")
                }
            }
            return question
        }
        
        // For pull-to-refresh, if question is still empty, log detailed state
        if suppressErrors && finalState.isEmpty {
            print("⚠️ Pull-to-refresh: Question still empty after all attempts")
            print("   - User ID: \(user.id)")
            print("   - Max retries used: \(maxRetries)")
            print("   - Found question flag: \(foundQuestion)")
        }
    }
    
    /// Generates a new follow-up question based on past journal entries
    /// - Parameter suppressErrors: If true, errors will be logged but not shown to the user (useful for background operations like pull-to-refresh)
    private func generateFollowUpQuestion(suppressErrors: Bool = false) async {
        guard let user = currentUser else { return }
        
        // SAFEGUARD: Double-check that we don't already have a follow-up question for today
        // This prevents duplicate generation if the initial check somehow missed it
        await loadFollowUpQuestionEntries()
        let calendar = Calendar.current
        let today = Date()
        let existingTodayEntry = followUpQuestionEntries.first { entry in
            calendar.isDate(entry.createdAt, inSameDayAs: today) &&
            entry.fuqAiResponse != nil &&
            !entry.fuqAiResponse!.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        
        if let existingEntry = existingTodayEntry, let fuqAiResponse = existingEntry.fuqAiResponse, !fuqAiResponse.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            print("🛡️ SAFEGUARD: Found existing follow-up question for today, skipping generation to prevent duplicate")
            print("   Existing question: \(fuqAiResponse.prefix(50))...")
            currentFollowUpQuestion = fuqAiResponse
            return
        }
        
        print("✅ No existing follow-up question found for today, proceeding with generation")
        
        do {
            // Select a past journal entry for follow-up
            guard let pastEntry = try await supabaseService.selectPastJournalEntryForFollowUp(userId: user.id) else {
                print("⚠️ No eligible past entry found for follow-up question")
                return
            }
            
            // Generate the follow-up question prompt
            let fuqAiPrompt = supabaseService.generateFollowUpQuestionPrompt(pastEntry: pastEntry)
            
            // Generate the follow-up question using OpenAI with retry logic (2s, 4s delays)
            // Use "journal" analysisType to avoid adding analyzer system message
            // Use gpt-5-mini (no reasoning tokens) for follow-up questions
            let fuqAiResponse = try await generateAIResponseWithRetry(for: fuqAiPrompt, model: "gpt-5-mini", analysisType: "journal")
            
            // Create the follow-up question entry
            let _ = try await supabaseService.createFollowUpQuestionEntry(
                userId: user.id,
                fuqAiPrompt: fuqAiPrompt,
                fuqAiResponse: fuqAiResponse
            )
            
            // Mark the selected past entry as used for follow-up
            try await supabaseService.markEntryAsUsedForFollowUp(entryId: pastEntry.id)
            
            // CRITICAL: Wait for database write to complete and verify it was saved
            // Add a small delay to ensure the database transaction has committed
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 second delay
            
            // Reload follow-up question entries to ensure we have the latest data
            await loadFollowUpQuestionEntries()
            
            // Verify the entry was actually saved by checking for it
            let calendar = Calendar.current
            let today = Date()
            let savedEntry = followUpQuestionEntries.first { entry in
                calendar.isDate(entry.createdAt, inSameDayAs: today) &&
                entry.fuqAiResponse == fuqAiResponse
            }
            
            if savedEntry == nil {
                print("⚠️ WARNING: Generated follow-up question was not found after save, retrying reload...")
                // Retry reload once more after a brief delay
                try await Task.sleep(nanoseconds: 500_000_000) // Another 0.5 second
                await loadFollowUpQuestionEntries()
            }
            
            // Update the current follow-up question
            currentFollowUpQuestion = fuqAiResponse
            
            print("✅ Generated new follow-up question: \(fuqAiResponse)")
            print("✅ Marked past entry as used for follow-up: \(pastEntry.id)")
            print("✅ Follow-up question entries reloaded: \(followUpQuestionEntries.count) entries")
            
        } catch {
            // Only show error message if not suppressed (e.g., during pull-to-refresh)
            if !suppressErrors {
                errorMessage = "The AI was on it's break 😅 please try again."
            }
            print("❌ Failed to generate follow-up question: \(error.localizedDescription)")
            if suppressErrors {
                print("⚠️ Error suppressed - not showing alert to user (background operation)")
            }
        }
    }
    
    /// Creates a follow-up question journal entry
    /// NEW: Accepts the question as a parameter to ensure we save the correct question the user answered
    /// This prevents issues where currentFollowUpQuestion might be overwritten by pre-generation before saving
    func createFollowUpQuestionJournalEntry(content: String, question: String? = nil) async {
        guard let user = currentUser else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // Use the question passed as parameter (captured at UI level before any pre-generation)
            // If not provided, fallback to currentFollowUpQuestion, then to database
            var followUpQuestionText: String? = nil
            if let providedQuestion = question, !providedQuestion.isEmpty {
                followUpQuestionText = providedQuestion
                print("✅ Using provided question for follow_up_question field: \(followUpQuestionText != nil ? String(followUpQuestionText!.prefix(50)) : "nil")...")
            } else if !currentFollowUpQuestion.isEmpty {
                followUpQuestionText = currentFollowUpQuestion
                print("✅ Using currentFollowUpQuestion for follow_up_question field: \(followUpQuestionText != nil ? String(followUpQuestionText!.prefix(50)) : "nil")...")
            } else {
                // Fallback: try to fetch from follow_up_generation if both are empty
                if let generation = try? await supabaseService.fetchFollowUpGeneration(userId: user.id) {
                    followUpQuestionText = generation.fuqAiResponse
                    print("⚠️ No question provided or in currentFollowUpQuestion, using follow_up_generation table: \(followUpQuestionText != nil ? String(followUpQuestionText!.prefix(50)) : "nil")...")
                } else {
                    print("⚠️ No follow-up question found in provided question, currentFollowUpQuestion, or follow_up_generation table")
                }
            }
            
            // Create journal entry with follow-up question type
            let entry = JournalEntry(
                userId: user.id,
                guidedQuestionId: nil,
                content: content,
                tags: ["follow_up"],
                entryType: "follow_up",
                fuqAiPrompt: nil,
                fuqAiResponse: nil, // No longer stored here
                isFollowUpDay: true,
                usedForFollowUp: nil,
                followUpQuestion: followUpQuestionText // NEW: Store the question that was used
            )
            
            _ = try await supabaseService.createJournalEntry(entry)
            await loadFollowUpQuestionEntries()
            print("✅ Follow-up question journal entry created with follow_up_question: \(followUpQuestionText != nil ? String(followUpQuestionText!.prefix(50)) : "nil")...")
            
        } catch {
            errorMessage = "Failed to create follow-up question journal entry: \(error.localizedDescription)"
            print("❌ Failed to create follow-up question journal entry: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    /// Updates a follow-up question journal entry with AI prompt
    func updateCurrentFollowUpQuestionJournalEntryWithAIPrompt(aiPrompt: String) async {
        guard currentUser != nil else { return }
        
        // Load current entries to find the most recent one
        await loadFollowUpQuestionEntries()
        
        guard let mostRecentEntry = followUpQuestionEntries.first else {
            errorMessage = "No follow-up question journal entry found to update."
            return
        }
        
        // Create updated entry with AI prompt
        let tagsArray: [String] = Array(mostRecentEntry.tags)
        let updatedEntry = JournalEntry(
            id: mostRecentEntry.id,
            userId: mostRecentEntry.userId,
            guidedQuestionId: mostRecentEntry.guidedQuestionId,
            content: mostRecentEntry.content,
            aiPrompt: aiPrompt, // Add the AI prompt
            aiResponse: mostRecentEntry.aiResponse,
            tags: tagsArray,
            isFavorite: mostRecentEntry.isFavorite,
            entryType: mostRecentEntry.entryType,
            createdAt: mostRecentEntry.createdAt,
            updatedAt: Date(), // Update timestamp
            fuqAiPrompt: mostRecentEntry.fuqAiPrompt,
            fuqAiResponse: mostRecentEntry.fuqAiResponse,
            isFollowUpDay: mostRecentEntry.isFollowUpDay,
            usedForFollowUp: mostRecentEntry.usedForFollowUp,
            followUpQuestion: mostRecentEntry.followUpQuestion // Preserve follow_up_question
        )
        
        do {
            _ = try await supabaseService.updateJournalEntry(updatedEntry)
            await loadFollowUpQuestionEntries() // Refresh entries
            print("✅ Follow-up question journal entry updated with AI prompt")
        } catch {
            errorMessage = "Failed to update follow-up question journal entry with AI prompt: \(error.localizedDescription)"
            print("❌ Failed to update follow-up question journal entry: \(error.localizedDescription)")
        }
    }
    
    /// Generates AI response using OpenAI and updates the follow-up question journal entry
    func generateAndSaveFollowUpQuestionAIResponse() async {
        guard currentUser != nil else {
            errorMessage = "User not authenticated."
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // Load current entries to find the most recent one
            await loadFollowUpQuestionEntries()
            
            guard let mostRecentEntry = followUpQuestionEntries.first,
                  let aiPrompt = mostRecentEntry.aiPrompt else {
                errorMessage = "No follow-up question journal entry or AI prompt found."
                isLoading = false
                return
            }
            
            // Generate AI response using OpenAI with retry logic
            // Use "journal" analysisType to avoid adding analyzer system message
            // Use gpt-5-mini (no reasoning tokens) with 2000 tokens for journal entries
            let aiResponse = try await generateAIResponseWithRetry(for: aiPrompt, model: "gpt-5-mini", analysisType: "journal")
            
            // Create updated entry with AI response
            let tagsArray: [String] = Array(mostRecentEntry.tags)
            let updatedEntry = JournalEntry(
                id: mostRecentEntry.id,
                userId: mostRecentEntry.userId,
                guidedQuestionId: mostRecentEntry.guidedQuestionId,
                content: mostRecentEntry.content,
                aiPrompt: mostRecentEntry.aiPrompt,
                aiResponse: aiResponse, // Add the AI response
                tags: tagsArray,
                isFavorite: mostRecentEntry.isFavorite,
                entryType: mostRecentEntry.entryType,
                createdAt: mostRecentEntry.createdAt,
                updatedAt: Date(), // Update timestamp
                fuqAiPrompt: mostRecentEntry.fuqAiPrompt,
                fuqAiResponse: mostRecentEntry.fuqAiResponse,
                isFollowUpDay: mostRecentEntry.isFollowUpDay,
                usedForFollowUp: mostRecentEntry.usedForFollowUp,
                followUpQuestion: mostRecentEntry.followUpQuestion // Preserve follow_up_question
            )
            
            _ = try await supabaseService.updateJournalEntry(updatedEntry)
            await loadFollowUpQuestionEntries() // Refresh entries
            
            print("✅ Follow-up question AI response generated and saved")
            
        } catch {
            errorMessage = "The AI was on it's break 😅 please try again."
            print("❌ Failed to generate follow-up question AI response: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    /// Updates the favorite status of the current follow-up question journal entry
    func updateCurrentFollowUpQuestionJournalEntryFavoriteStatus(isFavorite: Bool) async {
        guard currentUser != nil else {
            errorMessage = "User not authenticated."
            return
        }
        
        // Load current entries to find the most recent one
        await loadFollowUpQuestionEntries()
        
        guard let mostRecentEntry = followUpQuestionEntries.first else {
            errorMessage = "No follow-up question journal entry found to update favorite status."
            return
        }
        
        // Create updated entry with the new favorite status
            let tagsArray: [String] = Array(mostRecentEntry.tags)
            let updatedEntry = JournalEntry(
            id: mostRecentEntry.id, // Use existing ID
            userId: mostRecentEntry.userId,
            guidedQuestionId: mostRecentEntry.guidedQuestionId,
            content: mostRecentEntry.content,
            aiPrompt: mostRecentEntry.aiPrompt,
            aiResponse: mostRecentEntry.aiResponse,
            tags: tagsArray,
            isFavorite: isFavorite, // Update favorite status
            entryType: mostRecentEntry.entryType, // Preserve entry type
            createdAt: mostRecentEntry.createdAt,
            updatedAt: Date(), // Update timestamp
            fuqAiPrompt: mostRecentEntry.fuqAiPrompt,
            fuqAiResponse: mostRecentEntry.fuqAiResponse,
            isFollowUpDay: mostRecentEntry.isFollowUpDay,
            usedForFollowUp: mostRecentEntry.usedForFollowUp,
            followUpQuestion: mostRecentEntry.followUpQuestion // Preserve follow_up_question
        )
        
        do {
            _ = try await supabaseService.updateJournalEntry(updatedEntry)
            await loadFollowUpQuestionEntries() // Reload to reflect changes
            print("✅ Follow-up question journal entry favorite status updated to: \(isFavorite)")
        } catch {
            errorMessage = "Failed to update follow-up question journal entry favorite status: \(error.localizedDescription)"
            print("❌ Failed to update follow-up question journal entry favorite status: \(error.localizedDescription)")
        }
    }
    
    private func resetUIForNewDay() async {
        // Reset UI state without deleting database entries
        // This will be called from ContentView to reset the UI
        print("🔄 Resetting UI for new day (preserving all history)")
        
        // Trigger UI state clear using the callback mechanism
        DispatchQueue.main.async {
            if let callback = self.clearUIStateCallback {
                print("🧹 Calling UI state clear callback for new day reset")
                callback()
            }
        }
    }
    
    // MARK: - Analyzer Entry Functions
    
    /// Determines if analysis should be weekly or monthly based on date
    func determineAnalysisType(for date: Date = Date()) -> String {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: date)
        
        // Calculate what the previous week would be (Sunday to Saturday)
        let weekday = calendar.component(.weekday, from: today)
        let daysSinceSunday = (weekday + 6) % 7
        
        // Calculate previous Sunday (7 days before the current week's Sunday)
        guard let previousSunday = calendar.date(byAdding: .day, value: -(daysSinceSunday + 7), to: today),
              let previousSaturday = calendar.date(byAdding: .day, value: 6, to: previousSunday) else {
            return "weekly"
        }
        
        // Get the last day of the month that contains previousSaturday
        let components = calendar.dateComponents([.year, .month], from: previousSaturday)
        guard let firstOfMonth = calendar.date(from: components),
              let range = calendar.range(of: .day, in: .month, for: firstOfMonth),
              let lastDayOfMonth = range.last,
              let _ = calendar.date(byAdding: .day, value: lastDayOfMonth - 1, to: firstOfMonth) else {
            return "weekly"
        }
        
        // Get the month of the previous week's Sunday and Saturday
        let previousSundayMonth = calendar.component(.month, from: previousSunday)
        let previousSundayYear = calendar.component(.year, from: previousSunday)
        let previousSaturdayMonth = calendar.component(.month, from: previousSaturday)
        let previousSaturdayYear = calendar.component(.year, from: previousSaturday)
        let todayMonth = calendar.component(.month, from: today)
        let todayYear = calendar.component(.year, from: today)
        
        // Check if previous week spans month boundary (Sunday in one month, Saturday in another)
        let previousWeekSpansMonths = (previousSundayMonth != previousSaturdayMonth) || (previousSundayYear != previousSaturdayYear)
        
        // Check if we're now in a different month than the previous week's Sunday
        let isInDifferentMonth = (previousSundayMonth != todayMonth) || (previousSundayYear != todayYear)
        
        // Monthly analysis becomes available when:
        // 1. The previous week spanned month boundaries (Sunday was in month A, Saturday was in month B)
        // 2. We're now in the month that contains the previous week's Saturday (month B)
        // This means the previous week's Sunday was the last Sunday of the completed month
        if previousWeekSpansMonths && isInDifferentMonth {
            // Check if previousSunday was in a different month than today
            // If so, analyze the month that contains previousSunday (the completed month)
            let monthToCheck = previousSunday
            
            // Get the last day of the month that contains previousSunday
            let monthComponents = calendar.dateComponents([.year, .month], from: monthToCheck)
            guard let firstOfMonth = calendar.date(from: monthComponents),
                  let range = calendar.range(of: .day, in: .month, for: firstOfMonth),
                  let lastDayOfMonth = range.last,
                  let lastDateOfMonth = calendar.date(byAdding: .day, value: lastDayOfMonth - 1, to: firstOfMonth) else {
                return "weekly"
            }
            
            // Check if previousSunday is within the last 7 days of its month
            let daysFromEnd = calendar.dateComponents([.day], from: previousSunday, to: lastDateOfMonth).day ?? 0
            if daysFromEnd < 7 {
                // Previous Sunday was in the last week of a completed month - run monthly analysis
                return "monthly"
            }
        }
        
        // Otherwise, use weekly analysis
        return "weekly"
    }
    
    /// Finds the last Sunday of the month for a given date
    private func findLastSundayOfMonth(for date: Date) -> Date? {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: date)
        
        guard let firstOfMonth = calendar.date(from: components),
              let range = calendar.range(of: .day, in: .month, for: firstOfMonth) else {
            return nil
        }
        
        // Find the last Sunday of the month
        for day in range.reversed() {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstOfMonth) {
                if calendar.component(.weekday, from: date) == 1 { // Sunday
                    return date
                }
            }
        }
        
        return nil
    }
    
    /// Checks if user has enough entries for analysis
    func checkAnalyzerEligibility(analysisType: String, startDate: Date, endDate: Date) async throws -> (isEligible: Bool, entryCount: Int, minimumRequired: Int) {
        let entries = try await supabaseService.fetchJournalEntriesForAnalyzer(startDate: startDate, endDate: endDate)
        
        // Count unique days with entries
        let calendar = Calendar.current
        let uniqueDays = Set(entries.map { calendar.startOfDay(for: $0.createdAt) })
        let entryCount = uniqueDays.count
        
        // Determine minimum required based on analysis type
        let minimumRequired = analysisType == "monthly" ? 9 : 2
        
        let isEligible = entryCount >= minimumRequired
        
        print("🔍 checkAnalyzerEligibility: Analysis type: \(analysisType)")
        print("   Date range: \(startDate) to \(endDate)")
        print("   Total entries found: \(entries.count)")
        print("   Unique days with entries: \(entryCount)")
        print("   Minimum required: \(minimumRequired)")
        print("   Is eligible: \(isEligible)")
        
        return (isEligible, entryCount, minimumRequired)
    }
    
    /// Creates a new analyzer entry and generates AI response
    func createAnalyzerEntry(analysisType: String) async throws {
        guard let user = currentUser else {
            throw AIError.userNotAuthenticated
        }
        
        guard isAuthenticated else {
            throw AIError.userNotAuthenticated
        }
        
        isLoading = true
        errorMessage = nil
        currentRetryAttempt = 1
        
        do {
            // Determine date range based on analysis type
            let dateRange: (start: Date, end: Date)
            if analysisType == "monthly" {
                dateRange = supabaseService.calculateDateRangeForMonthlyAnalysis()
            } else {
                dateRange = supabaseService.calculateDateRangeForWeeklyAnalysis()
            }
            
            print("📊 createAnalyzerEntry: Analysis type: \(analysisType)")
            print("   Date range calculated: \(dateRange.start) to \(dateRange.end)")
            
            // Check eligibility BEFORE making any API calls
            let eligibility = try await checkAnalyzerEligibility(
                analysisType: analysisType,
                startDate: dateRange.start,
                endDate: dateRange.end
            )
            
            print("📊 createAnalyzerEntry: Eligibility check completed")
            print("   Is eligible: \(eligibility.isEligible)")
            print("   Entry count: \(eligibility.entryCount)")
            print("   Minimum required: \(eligibility.minimumRequired)")
            
            if !eligibility.isEligible {
                let message = analysisType == "monthly"
                    ? "Sorry, a minimum of \"nine days\" of check-in entries is needed to run the monthly analysis."
                    : "Sorry, a minimum of \"two days\" of check-in entries is needed to run the weekly analysis. Try again next week"
                print("❌ createAnalyzerEntry: Insufficient entries - throwing error: \(message)")
                // Don't set generic error message for minimum entries error - let ContentView handle it
                isLoading = false
                throw NSError(domain: "AnalyzerError", code: 0, userInfo: [NSLocalizedDescriptionKey: message])
            }
            
            print("✅ createAnalyzerEntry: Eligibility check passed, proceeding with analysis")
            
            // Fetch journal entries for the date range
            // For monthly analysis, limit to 8 random entries (prioritizing favorites)
            let entryLimit = analysisType == "monthly" ? 8 : nil
            let entries = try await supabaseService.fetchJournalEntriesForAnalyzer(
                startDate: dateRange.start,
                endDate: dateRange.end,
                limit: entryLimit
            )
            
            // Prepare content with summarization if needed (1000 chars weekly, 1000 chars monthly)
            let content = supabaseService.prepareContentForAnalyzer(entries: entries, analysisType: analysisType)
            
            // Generate analyzer prompt
            let analyzerPrompt: String
            if analysisType == "monthly" {
                analyzerPrompt = supabaseService.generateMonthlyAnalyzerPrompt(content: content)
            } else {
                analyzerPrompt = supabaseService.generateWeeklyAnalyzerPrompt(content: content)
            }
            
            // Create analyzer entry with prompt (no response yet)
            let analyzerEntry = AnalyzerEntry(
                userId: user.id,
                analyzerAiPrompt: analyzerPrompt,
                analyzerAiResponse: nil,
                entryType: analysisType,
                tags: [],
                createdAt: Date(),
                updatedAt: nil
            )
            
            // Save analyzer entry to database
            let createdEntry = try await supabaseService.createAnalyzerEntry(analyzerEntry)
            
            // Generate AI response with retry logic and timeout
            // Monthly analysis gets 60 seconds, weekly gets 30 seconds (monthly is more complex)
            // If all retries fail, the entry will be deleted in the catch block
            let aiResponse: String
            do {
                let timeoutSeconds: TimeInterval = analysisType == "monthly" ? 60.0 : 30.0
                print("⏱️ Setting timeout for \(analysisType) analysis: \(timeoutSeconds) seconds, using GPT-5 model")
                aiResponse = try await withTimeout(seconds: timeoutSeconds) {
                    try await self.generateAIResponseWithRetry(for: analyzerPrompt, model: "gpt-5", analysisType: analysisType)
                }
            } catch {
                // All retries failed - delete the entry since analyzerAiResponse = nil is considered a failure
                print("⚠️ All retry attempts failed - deleting analyzer entry")
                try await supabaseService.deleteAnalyzerEntry(entryId: createdEntry.id)
                // Reload analyzer entries to update UI
                await loadAnalyzerEntries()
                // Re-throw the error
                throw error
            }
            
            // Check if AI response is empty or null - if so, delete the entry and throw error
            let trimmedResponse = aiResponse.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmedResponse.isEmpty {
                print("⚠️ AI response is empty - deleting analyzer entry and keeping button enabled")
                // Delete the created entry since we don't have a valid response
                try await supabaseService.deleteAnalyzerEntry(entryId: createdEntry.id)
                // Reload analyzer entries to update UI
                await loadAnalyzerEntries()
                // Throw error to keep button enabled
                throw NSError(domain: "AnalyzerError", code: 0, userInfo: [NSLocalizedDescriptionKey: "AI response was empty. Please try again."])
            }
            
            // Update analyzer entry with AI response
            let updatedEntry = AnalyzerEntry(
                id: createdEntry.id,
                userId: createdEntry.userId,
                analyzerAiPrompt: createdEntry.analyzerAiPrompt,
                analyzerAiResponse: aiResponse,
                entryType: createdEntry.entryType,
                tags: createdEntry.tags,
                createdAt: createdEntry.createdAt,
                updatedAt: Date()
            )
            
            _ = try await supabaseService.updateAnalyzerEntry(updatedEntry)
            
            // Reload analyzer entries to update UI
            await loadAnalyzerEntries()
            
            print("✅ Analyzer entry created and AI response generated successfully")
            
        } catch {
            // Only set generic error message if it's not a minimum entries error or authentication error
            // Minimum entries errors and authentication errors should be handled by ContentView without showing generic AI error
            let errorDesc = error.localizedDescription.lowercased()
            if !errorDesc.contains("minimum") && !errorDesc.contains("not authenticated") && !errorDesc.contains("authentication") {
                errorMessage = "The AI was on it's break 😅 please try again."
            }
            print("❌ Failed to create analyzer entry: \(error.localizedDescription)")
            throw error
        }
        
        isLoading = false
    }
}

struct AnalyzerStats {
    let logsCount: Int
    let streakCount: Int
    let favoriteLogTime: String
}

// MARK: - Timeout Helper Function
extension JournalViewModel {
    /// Wraps an async operation with a timeout
    /// - Parameters:
    ///   - seconds: Timeout duration in seconds
    ///   - operation: The async operation to execute
    /// - Returns: The result of the operation if completed within timeout
    /// - Throws: TimeoutError if operation exceeds timeout, or the operation's error
    func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
        return try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                return try await operation()
            }
            
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw AnalyzerTimeoutError(seconds: seconds)
            }
            
            guard let result = try await group.next() else {
                throw AnalyzerTimeoutError(seconds: seconds)
            }
            
            group.cancelAll()
            return result
        }
    }
}

// MARK: - Timeout Error
struct AnalyzerTimeoutError: Error, LocalizedError {
    let seconds: TimeInterval
    
    var errorDescription: String? {
        return "Operation timed out after \(Int(seconds)) seconds"
    }
    
    var localizedDescription: String {
        return errorDescription ?? "Operation timed out"
    }
}

// MARK: - AI Error Types
enum AIError: Error, LocalizedError {
    case userNotAuthenticated
    case noJournalEntry
    case noAIPrompt
    case generationFailed
    
    var errorDescription: String? {
        switch self {
        case .userNotAuthenticated:
            return "User not authenticated"
        case .noJournalEntry:
            return "No journal entry found to generate AI response"
        case .noAIPrompt:
            return "No AI prompt found in journal entry"
        case .generationFailed:
            return "AI generation failed after multiple attempts"
        }
    }
}
