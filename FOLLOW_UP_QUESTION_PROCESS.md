# Follow-Up Question Process - Complete Function Flow

This document details all functions executed during the entire follow-up question process, from initial generation to user interaction and AI response.

## Overview
Follow-up questions are generated every 3rd day (based on days since January 1, 2024) and can be pre-generated at 2 AM during the daily reset, or generated on-demand when the user opens the app.

---

## Phase 1: Initial Setup & Detection

### 1.1 App Launch / View Appear
**Location:** `ContentView.swift` - `mainJournalView.onAppear`
- Calls `reloadJournalDataSequence()` which includes:
  - `checkAndResetIfNeeded()` (if past 2 AM)
  - `checkAndLoadFollowUpQuestion()`

### 1.2 Daily Reset Check (2 AM)
**Location:** `JournalViewModel.swift` - `checkAndResetIfNeeded()`
- Checks if it's past 2 AM since last entry
- If yes, calls:
  - `resetUIForNewDay()` - Clears UI state
  - `preGenerateFollowUpQuestionIfNeeded()` - Pre-generates follow-up question if today is a follow-up day

### 1.3 Follow-Up Day Detection
**Location:** `SupabaseService.swift` - `isFollowUpQuestionDay()`
- Calculates days since January 1, 2024
- Returns `true` if `daysSinceReference % 3 == 0` (every 3rd day)

---

## Phase 2: Pre-Generation (2 AM Reset)

### 2.1 Pre-Generation Check
**Location:** `JournalViewModel.swift` - `preGenerateFollowUpQuestionIfNeeded()`
- Checks if today is a follow-up day via `supabaseService.isFollowUpQuestionDay()`
- Loads existing entries via `loadFollowUpQuestionEntries()`
- Checks if follow-up question already exists for today
- If not, calls `generateFollowUpQuestion()`

---

## Phase 3: Question Generation

### 3.1 Load Follow-Up Entries
**Location:** `JournalViewModel.swift` - `loadFollowUpQuestionEntries()`
- Calls `supabaseService.fetchJournalEntries(userId:)`
- Filters entries where `entryType == "follow_up"`
- Stores in `followUpQuestionEntries` array

### 3.2 Check and Load Follow-Up Question
**Location:** `JournalViewModel.swift` - `checkAndLoadFollowUpQuestion(suppressErrors:)`
- Checks if today is a follow-up day
- **Retry Logic:** Attempts up to 3 times with 0.5s delays to find today's entry
- Filters entries created today
- Prioritizes entries with:
  1. Empty content + non-empty `fuqAiResponse` (the question entry)
  2. Non-empty `fuqAiResponse` (fallback)
- If found, sets `currentFollowUpQuestion = fuqAiResponse`
- If not found, calls `generateFollowUpQuestion()`

### 3.3 Generate Follow-Up Question
**Location:** `JournalViewModel.swift` - `generateFollowUpQuestion(suppressErrors:)`
- **Safeguard:** Double-checks for existing question to prevent duplicates
- Calls `supabaseService.selectPastJournalEntryForFollowUp(userId:)` to select a past entry
- Calls `supabaseService.generateFollowUpQuestionPrompt(pastEntry:)` to create the prompt
- Calls `generateAIResponseWithRetry(for:)` to generate the question via OpenAI API
- Calls `supabaseService.createFollowUpQuestionEntry()` to save the question entry
- Calls `supabaseService.markEntryAsUsedForFollowUp(entryId:)` to mark past entry as used
- **Verification:** Waits 0.5s, reloads entries, verifies question was saved
- Sets `currentFollowUpQuestion = fuqAiResponse`

### 3.4 Select Past Journal Entry
**Location:** `SupabaseService.swift` - `selectPastJournalEntryForFollowUp(userId:)`
- Searches for entries from 5-15 days ago
- **Priority Order:**
  1. Favorite entries (`is_favorite = true`) not yet used
  2. Open question entries (`tags = ["open_question"]`) not yet used
  3. Most recent entry older than today not yet used
- Returns the selected entry or `nil`

### 3.5 Generate Follow-Up Question Prompt
**Location:** `SupabaseService.swift` - `generateFollowUpQuestionPrompt(pastEntry:)`
- Extracts first paragraph from `pastEntry.aiResponse`
- Creates prompt template:
  ```
  Past Client statements: {content}
  Therapist response: {ai_response}
  Create a "follow up" style question (25 word limit)...
  ```
- Replaces placeholders with past entry content and first paragraph of AI response
- Returns the prompt string

### 3.6 Generate AI Response with Retry
**Location:** `JournalViewModel.swift` - `generateAIResponseWithRetry(for:)`
- **Retry Logic:** 3 attempts with delays (2s, 4s)
- Sets `currentRetryAttempt = 1, 2, 3`
- Calls `openAIService.generateAIResponse(prompt:)` via `OpenAIService.swift`
- Validates response is not empty/whitespace
- Returns the AI-generated follow-up question

### 3.7 Create Follow-Up Question Entry
**Location:** `SupabaseService.swift` - `createFollowUpQuestionEntry(userId:fuqAiPrompt:fuqAiResponse:)`
- Creates `JournalEntry` with:
  - `entryType = "follow_up"`
  - `content = ""` (empty - user will fill later)
  - `tags = ["follow_up"]`
  - `fuqAiPrompt = fuqAiPrompt`
  - `fuqAiResponse = fuqAiResponse` (the question itself)
- Calls `createJournalEntry()` to save to database
- Returns the created entry

### 3.8 Mark Entry as Used
**Location:** `SupabaseService.swift` - `markEntryAsUsedForFollowUp(entryId:)`
- Updates `journal_entries` table
- Sets `used_for_follow_up = true` for the selected past entry
- Prevents the same entry from being used again

---

## Phase 4: Display in UI

### 4.1 UI State Population
**Location:** `ContentView.swift` - `populateUIStateFromJournalEntries()`
- Finds today's follow-up entry (user's response entry, not question entry)
- Sets `followUpJournalResponse = entry.content`
- Sets `followUpCurrentAIResponse = entry.aiResponse` (if exists)
- Updates UI state flags based on entry status

### 4.2 Display Question
**Location:** `ContentView.swift` - `mainJournalView`
- Checks `isFollowUpQuestionDay` flag
- If `currentFollowUpQuestion.isEmpty`, shows "Generating a follow up question for you..." (italic, #5F4083)
- If `currentFollowUpQuestion` exists, displays the question text (color #5F4083)

---

## Phase 5: User Interaction - Saving Response

### 5.1 User Types Response
- User enters text in follow-up question text field
- `followUpJournalResponse` state variable updates

### 5.2 Done Button Tapped
**Location:** `ContentView.swift` - `followUpDoneButtonTapped()`
- Sets `followUpShowCenteredButton = true`
- Sets `followUpIsTextLocked = true`
- Performs haptic feedback
- Calls `journalViewModel.createFollowUpQuestionJournalEntry(content:)`

### 5.3 Create Follow-Up Question Journal Entry
**Location:** `JournalViewModel.swift` - `createFollowUpQuestionJournalEntry(content:)`
- Creates `JournalEntry` with:
  - `entryType = "follow_up"`
  - `content = content` (user's response)
  - `tags = ["follow_up"]`
  - `fuqAiResponse = currentFollowUpQuestion` (the question)
- Calls `supabaseService.createJournalEntry()` to save
- Calls `loadFollowUpQuestionEntries()` to refresh

---

## Phase 6: User Interaction - Generating AI Response

### 6.1 Centered Button Tapped
**Location:** `ContentView.swift` - `followUpCenteredButtonTapped()`
- Sets `followUpShowCenteredButtonClick = true`
- Sets `followUpIsGeneratingAI = true`
- Sets `followUpIsLoadingGenerating = true`
- Sets `journalViewModel.currentRetryAttempt = 1`
- Performs haptic feedback
- Calls `generateAndSaveFollowUpAIPrompt()`

### 6.2 Generate and Save Follow-Up AI Prompt
**Location:** `ContentView.swift` - `generateAndSaveFollowUpAIPrompt()`
- Gets `currentFollowUpQuestion` from `journalViewModel`
- Calls `createFollowUpAIPromptText(content:fuqAiResponse:)` to create prompt
- Calls `journalViewModel.updateCurrentFollowUpQuestionJournalEntryWithAIPrompt(aiPrompt:)`
- Calls `journalViewModel.generateAndSaveFollowUpQuestionAIResponse()` with timeout
- Calls `updateFollowUpAIResponseDisplay()` to refresh UI

### 6.3 Create Follow-Up AI Prompt Text
**Location:** `ContentView.swift` - `createFollowUpAIPromptText(content:fuqAiResponse:)`
- Creates prompt template:
  ```
  Therapist: {fuq_ai_response}
  Client: {content}
  Output: Provide only a succinct response...
  ```
- Replaces placeholders with user's response and follow-up question
- Returns the prompt string

### 6.4 Update Entry with AI Prompt
**Location:** `JournalViewModel.swift` - `updateCurrentFollowUpQuestionJournalEntryWithAIPrompt(aiPrompt:)`
- Calls `loadFollowUpQuestionEntries()` to get latest entries
- Finds most recent follow-up entry
- Creates updated entry with `aiPrompt = aiPrompt`
- Calls `supabaseService.updateJournalEntry()` to save
- Calls `loadFollowUpQuestionEntries()` to refresh

### 6.5 Generate and Save AI Response
**Location:** `JournalViewModel.swift` - `generateAndSaveFollowUpQuestionAIResponse()`
- Calls `loadFollowUpQuestionEntries()` to get latest entry
- Gets `aiPrompt` from most recent entry
- Calls `generateAIResponseWithRetry(for: aiPrompt)` to generate AI response
- Creates updated entry with `aiResponse = aiResponse`
- Calls `supabaseService.updateJournalEntry()` to save
- Calls `loadFollowUpQuestionEntries()` to refresh

### 6.6 Update UI with AI Response
**Location:** `ContentView.swift` - `updateFollowUpAIResponseDisplay()`
- Calls `journalViewModel.loadFollowUpQuestionEntries()`
- Gets most recent entry with non-empty `aiResponse`
- Sets `followUpCurrentAIResponse = aiResponse`
- Calls `updateFollowUpTextEditorHeight()` to adjust UI
- Shows favorite button

---

## Phase 7: Additional User Interactions

### 7.1 Favorite Button Tapped
**Location:** `ContentView.swift` - `followUpFavoriteButtonTapped()`
- Sets `followUpIsFavoriteClicked = true`
- Performs haptic feedback
- Calls `journalViewModel.updateCurrentFollowUpQuestionJournalEntryFavoriteStatus(isFavorite: true)`

### 7.2 Update Favorite Status
**Location:** `JournalViewModel.swift` - `updateCurrentFollowUpQuestionJournalEntryFavoriteStatus(isFavorite:)`
- Calls `loadFollowUpQuestionEntries()` to get latest entry
- Creates updated entry with `isFavorite = isFavorite`
- Calls `supabaseService.updateJournalEntry()` to save
- Calls `loadFollowUpQuestionEntries()` to refresh

### 7.3 Edit Log Selected
**Location:** `ContentView.swift` - `followUpEditLogSelected()`
- Unlocks text field
- Clears AI response from UI
- Resets button states

### 7.4 Delete Log Selected
**Location:** `ContentView.swift` - `followUpDeleteLogSelected()`
- Clears all follow-up question UI state
- Resets text editor height
- Performs haptic feedback

---

## Phase 8: Pull-to-Refresh

### 8.1 Pull-to-Refresh Triggered
**Location:** `ContentView.swift` - `.refreshable` modifier
- Sets `isRefreshing = true`
- Calls `reloadJournalDataSequence(suppressErrors: true)`
- Ensures minimum 2-second display of overlay
- Sets `isRefreshing = false` after completion

### 8.2 Reload Journal Data Sequence
**Location:** `ContentView.swift` - `reloadJournalDataSequence(suppressErrors:)`
- Calls `clearJournalUIState()` to clear UI
- Calls `journalViewModel.loadTodaysQuestion()`
- Calls `journalViewModel.checkAndResetIfNeeded()`
- Determines if today is follow-up day
- Calls `journalViewModel.checkAndLoadFollowUpQuestion(suppressErrors:)`
- Calls `populateUIStateFromJournalEntries()` to repopulate UI

---

## Key Database Operations

### SupabaseService Functions:
1. `isFollowUpQuestionDay()` - Checks if today is a follow-up day
2. `selectPastJournalEntryForFollowUp(userId:)` - Selects past entry for question generation
3. `generateFollowUpQuestionPrompt(pastEntry:)` - Creates the AI prompt
4. `createFollowUpQuestionEntry(userId:fuqAiPrompt:fuqAiResponse:)` - Creates question entry
5. `markEntryAsUsedForFollowUp(entryId:)` - Marks past entry as used
6. `fetchJournalEntries(userId:)` - Fetches all journal entries
7. `createJournalEntry(_:)` - Creates new journal entry
8. `updateJournalEntry(_:)` - Updates existing journal entry

### JournalViewModel Functions:
1. `checkAndResetIfNeeded()` - Checks for 2 AM reset
2. `preGenerateFollowUpQuestionIfNeeded()` - Pre-generates question at 2 AM
3. `loadFollowUpQuestionEntries()` - Loads follow-up entries
4. `checkAndLoadFollowUpQuestion(suppressErrors:)` - Checks and loads/generates question
5. `generateFollowUpQuestion(suppressErrors:)` - Generates new question
6. `createFollowUpQuestionJournalEntry(content:)` - Saves user's response
7. `updateCurrentFollowUpQuestionJournalEntryWithAIPrompt(aiPrompt:)` - Updates with AI prompt
8. `generateAndSaveFollowUpQuestionAIResponse()` - Generates and saves AI response
9. `updateCurrentFollowUpQuestionJournalEntryFavoriteStatus(isFavorite:)` - Updates favorite status
10. `generateAIResponseWithRetry(for:)` - Generates AI response with retry logic

### ContentView Functions:
1. `followUpDoneButtonTapped()` - Handles Done button tap
2. `followUpCenteredButtonTapped()` - Handles Centered button tap
3. `generateAndSaveFollowUpAIPrompt()` - Generates and saves AI prompt
4. `createFollowUpAIPromptText(content:fuqAiResponse:)` - Creates prompt text
5. `updateFollowUpAIResponseDisplay()` - Updates UI with AI response
6. `followUpFavoriteButtonTapped()` - Handles favorite button
7. `followUpEditLogSelected()` - Handles edit action
8. `followUpDeleteLogSelected()` - Handles delete action
9. `reloadJournalDataSequence(suppressErrors:)` - Reloads all journal data
10. `populateUIStateFromJournalEntries()` - Populates UI from entries

---

## Error Handling

- **Cancelled Requests:** Gracefully handled in `loadFollowUpQuestionEntries()` - keeps existing data
- **Retry Logic:** 
  - Question generation: 3 retries with 0.5s delays
  - AI response generation: 3 retries with 2s, 4s delays
- **Duplicate Prevention:** Safeguard in `generateFollowUpQuestion()` checks for existing question
- **Database Write Verification:** 0.5s delay + reload after creating question entry

---

## State Variables

### JournalViewModel:
- `currentFollowUpQuestion: String` - The current follow-up question text
- `followUpQuestionEntries: [JournalEntry]` - Array of all follow-up entries
- `currentRetryAttempt: Int` - Current retry attempt (1, 2, 3)
- `errorMessage: String?` - Error message to display

### ContentView:
- `isFollowUpQuestionDay: Bool` - Whether today is a follow-up day
- `followUpJournalResponse: String` - User's response text
- `followUpCurrentAIResponse: String` - AI-generated response
- `followUpIsTextLocked: Bool` - Whether text is locked
- `followUpShowCenteredButton: Bool` - Whether to show Centered button
- `followUpShowCenteredButtonClick: Bool` - Whether button is in clicked state
- `followUpIsGeneratingAI: Bool` - Whether AI is being generated
- `followUpIsLoadingGenerating: Bool` - Whether loading is for generation vs saving
- `followUpShowFavoriteButton: Bool` - Whether to show favorite button
- `followUpIsFavoriteClicked: Bool` - Whether favorite is clicked



