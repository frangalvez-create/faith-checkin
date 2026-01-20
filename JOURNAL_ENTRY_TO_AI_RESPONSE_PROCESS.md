# Journal Entry to AI Response UI Display Process - Complete Function Flow

This document details all functions executed during the entire journal entry to AI response UI display process for **Guided Questions**, **Open Questions**, and **Follow-Up Questions**.

---

## Overview
The process begins when a user types their journal entry, clicks the "Done" button to save, then clicks the "Centered" button to generate an AI response. The AI response is then displayed in the UI.

---

## Phase 1: User Input

### 1.1 User Types Response
- User enters text in the text field
- State variables update:
  - **Guided:** `journalResponse` (ContentView)
  - **Open:** `openJournalResponse` (ContentView)
  - **Follow-Up:** `followUpJournalResponse` (ContentView)

### 1.2 Text Editor Height Updates
- **Guided:** `updateTextEditorHeight()` - Calculates dynamic height based on text content
- **Open:** `updateOpenTextEditorHeight()` - Calculates dynamic height based on text content
- **Follow-Up:** `updateFollowUpTextEditorHeight()` - Calculates dynamic height based on text content

---

## Phase 2: Done Button - Save Entry

### 2.1 Done Button Tapped
**Location:** `ContentView.swift`

#### Guided Question:
- `doneButtonTapped()`
  - Sets `showCenteredButton = true`
  - Sets `isTextLocked = true`
  - Sets `isLoadingGenerating = false` (saving, not generating)
  - Performs haptic feedback
  - Calls `journalViewModel.createJournalEntry(content:)`

#### Open Question:
- `openDoneButtonTapped()`
  - Sets `openShowCenteredButton = true`
  - Sets `openIsTextLocked = true`
  - Sets `openIsLoadingGenerating = false` (saving, not generating)
  - Performs haptic feedback
  - Calls `journalViewModel.createOpenQuestionJournalEntry(content:)`

#### Follow-Up Question:
- `followUpDoneButtonTapped()`
  - Sets `followUpShowCenteredButton = true`
  - Sets `followUpIsTextLocked = true`
  - Sets `followUpIsLoadingGenerating = false` (saving, not generating)
  - Performs haptic feedback
  - Calls `journalViewModel.createFollowUpQuestionJournalEntry(content:)`

### 2.2 Create Journal Entry
**Location:** `JournalViewModel.swift`

#### Guided Question:
- `createJournalEntry(content:)`
  - Checks if `currentQuestion` exists, loads if nil
  - Creates `JournalEntry` with:
    - `userId = user.id`
    - `guidedQuestionId = currentQuestion?.id`
    - `content = content`
    - `entryType = "guided"` (default)
  - Calls `supabaseService.createJournalEntry(entry)`
  - Calls `loadJournalEntries()` to refresh

#### Open Question:
- `createOpenQuestionJournalEntry(content:)`
  - Creates `JournalEntry` with:
    - `userId = user.id`
    - `guidedQuestionId = nil`
    - `content = content`
    - `tags = ["open_question"]`
    - `entryType = "open"`
  - Calls `supabaseService.createOpenQuestionJournalEntry(entry, staticQuestion:)`
  - Calls `loadOpenQuestionJournalEntries()` to refresh

#### Follow-Up Question:
- `createFollowUpQuestionJournalEntry(content:)`
  - Creates `JournalEntry` with:
    - `userId = user.id`
    - `guidedQuestionId = nil`
    - `content = content` (user's response)
    - `tags = ["follow_up"]`
    - `entryType = "follow_up"`
    - `fuqAiResponse = currentFollowUpQuestion` (the question itself)
  - Calls `supabaseService.createJournalEntry(entry)`
  - Calls `loadFollowUpQuestionEntries()` to refresh

### 2.3 Save to Database
**Location:** `SupabaseService.swift`

#### Guided Question:
- `createJournalEntry(_:)`
  - Inserts entry into `journal_entries` table
  - Returns saved entry

#### Open Question:
- `createOpenQuestionJournalEntry(_:, staticQuestion:)`
  - Inserts entry into `journal_entries` table with `tags = ["open_question"]`
  - Returns saved entry

#### Follow-Up Question:
- `createJournalEntry(_:)`
  - Inserts entry into `journal_entries` table with `entryType = "follow_up"`
  - Returns saved entry

---

## Phase 3: Centered Button - Generate AI Response

### 3.1 Centered Button Tapped
**Location:** `ContentView.swift`

#### Guided Question:
- `centeredButtonTapped()`
  - Checks `!isGeneratingAI` to prevent multiple clicks
  - Sets `showCenteredButtonClick = true`
  - Sets `isGeneratingAI = true`
  - Sets `isLoadingGenerating = true` (generating AI)
  - Sets `journalViewModel.currentRetryAttempt = 1`
  - Performs haptic feedback
  - Calls `generateAndSaveAIPrompt()` in Task

#### Open Question:
- `openCenteredButtonTapped()`
  - Checks `!openIsGeneratingAI` to prevent multiple clicks
  - Sets `openShowCenteredButtonClick = true`
  - Sets `openIsGeneratingAI = true`
  - Sets `openIsLoadingGenerating = true` (generating AI)
  - Sets `journalViewModel.currentRetryAttempt = 1`
  - Performs haptic feedback
  - Calls `generateAndSaveOpenAIPrompt()` in Task

#### Follow-Up Question:
- `followUpCenteredButtonTapped()`
  - Checks `!followUpIsGeneratingAI` to prevent multiple clicks
  - Sets `followUpShowCenteredButtonClick = true`
  - Sets `followUpIsGeneratingAI = true`
  - Sets `followUpIsLoadingGenerating = true` (generating AI)
  - Sets `journalViewModel.currentRetryAttempt = 1`
  - Performs haptic feedback
  - Calls `generateAndSaveFollowUpAIPrompt()` in Task

### 3.2 Generate and Save AI Prompt
**Location:** `ContentView.swift`

#### Guided Question:
- `generateAndSaveAIPrompt()`
  1. **Load User Profile:**
     - Calls `journalViewModel.supabaseService.loadUserProfile()`
     - Updates `journalViewModel.currentUser` with profile data
  2. **Get Goal:**
     - Gets `mostRecentGoal` from `journalViewModel.goals.first?.goals ?? ""`
  3. **Create AI Prompt:**
     - Calls `createAIPromptText(content:goal:questionText:)`
     - Uses guided question template with user profile data
  4. **Update Entry with Prompt:**
     - Calls `journalViewModel.updateCurrentJournalEntryWithAIPrompt(aiPrompt:)`
  5. **Generate AI Response:**
     - Calls `journalViewModel.generateAndSaveAIResponse()` with 30s timeout
  6. **Update UI:**
     - Calls `updateAIResponseDisplay()`

#### Open Question:
- `generateAndSaveOpenAIPrompt()`
  1. **Get Goal:**
     - Gets `mostRecentGoal` from `journalViewModel.goals.first?.goals ?? ""`
  2. **Create AI Prompt:**
     - Calls `createAIPromptText(content:goal:questionText:)`
     - Uses static question: "Looking at today or yesterday, share moments or thoughts that stood out"
  3. **Update Entry with Prompt:**
     - Calls `journalViewModel.updateCurrentOpenQuestionJournalEntryWithAIPrompt(aiPrompt:)`
  4. **Generate AI Response:**
     - Calls `journalViewModel.generateAndSaveOpenQuestionAIResponse()` with 30s timeout
  5. **Update UI:**
     - Calls `updateOpenAIResponseDisplay()`

#### Follow-Up Question:
- `generateAndSaveFollowUpAIPrompt()`
  1. **Get Follow-Up Question:**
     - Gets `currentFollowUpQuestion` from `journalViewModel`
  2. **Create AI Prompt:**
     - Calls `createFollowUpAIPromptText(content:fuqAiResponse:)`
     - Uses follow-up question template
  3. **Update Entry with Prompt:**
     - Calls `journalViewModel.updateCurrentFollowUpQuestionJournalEntryWithAIPrompt(aiPrompt:)`
  4. **Generate AI Response:**
     - Calls `journalViewModel.generateAndSaveFollowUpQuestionAIResponse()` with 30s timeout
  5. **Update UI:**
     - Calls `updateFollowUpAIResponseDisplay()`

### 3.3 Create AI Prompt Text
**Location:** `ContentView.swift`

#### Guided Question:
- `createAIPromptText(content:goal:questionText:)`
  - Uses guided question AI prompt template
  - Replaces placeholders:
    - `{content}` → user's journal entry
    - `{goal}` → user's goal
    - `{question_text}` → guided question text
    - `{gender}` → user's gender
    - `{occupation}` → user's occupation
    - `{birthdate}` → user's birthdate
  - Returns the complete prompt string

#### Open Question:
- `createAIPromptText(content:goal:questionText:)`
  - Uses same guided question template
  - Uses static question: "Looking at today or yesterday, share moments or thoughts that stood out"
  - Replaces placeholders with user data
  - Returns the complete prompt string

#### Follow-Up Question:
- `createFollowUpAIPromptText(content:fuqAiResponse:)`
  - Uses follow-up question AI prompt template
  - Replaces placeholders:
    - `{content}` → user's response to follow-up question
    - `{fuq_ai_response}` → the follow-up question itself
  - Returns the complete prompt string

### 3.4 Update Entry with AI Prompt
**Location:** `JournalViewModel.swift`

#### Guided Question:
- `updateCurrentJournalEntryWithAIPrompt(aiPrompt:)`
  1. Calls `loadJournalEntries()` to get latest entries
  2. Finds most recent entry (first in array)
  3. Creates updated entry with `aiPrompt = aiPrompt`
  4. Calls `supabaseService.updateJournalEntry(updatedEntry)`
  5. Calls `loadJournalEntries()` to refresh

#### Open Question:
- `updateCurrentOpenQuestionJournalEntryWithAIPrompt(aiPrompt:)`
  1. Calls `loadOpenQuestionJournalEntries()` to get latest entries
  2. Finds most recent entry (first in array)
  3. Creates updated entry with `aiPrompt = aiPrompt`
  4. Calls `supabaseService.updateJournalEntry(updatedEntry)`
  5. Calls `loadOpenQuestionJournalEntries()` to refresh

#### Follow-Up Question:
- `updateCurrentFollowUpQuestionJournalEntryWithAIPrompt(aiPrompt:)`
  1. Calls `loadFollowUpQuestionEntries()` to get latest entries
  2. Finds most recent entry (first in array)
  3. Creates updated entry with `aiPrompt = aiPrompt`
  4. Calls `supabaseService.updateJournalEntry(updatedEntry)`
  5. Calls `loadFollowUpQuestionEntries()` to refresh

### 3.5 Generate AI Response
**Location:** `JournalViewModel.swift`

#### Guided Question:
- `generateAndSaveAIResponse()`
  1. Calls `loadJournalEntries()` to get latest entry
  2. Gets `aiPrompt` from most recent entry
  3. Calls `generateAIResponseWithRetry(for: aiPrompt)`
  4. Creates updated entry with `aiResponse = aiResponse`
  5. Calls `supabaseService.updateJournalEntry(updatedEntry)`
  6. Calls `loadJournalEntries()` to refresh

#### Open Question:
- `generateAndSaveOpenQuestionAIResponse()`
  1. Calls `loadOpenQuestionJournalEntries()` to get latest entry
  2. Gets `aiPrompt` from most recent entry
  3. Calls `generateAIResponseWithRetry(for: aiPrompt)`
  4. Creates updated entry with `aiResponse = aiResponse`
  5. Calls `supabaseService.updateJournalEntry(updatedEntry)`
  6. Calls `loadOpenQuestionJournalEntries()` to refresh

#### Follow-Up Question:
- `generateAndSaveFollowUpQuestionAIResponse()`
  1. Calls `loadFollowUpQuestionEntries()` to get latest entry
  2. Gets `aiPrompt` from most recent entry
  3. Calls `generateAIResponseWithRetry(for: aiPrompt)`
  4. Creates updated entry with `aiResponse = aiResponse`
  5. Calls `supabaseService.updateJournalEntry(updatedEntry)`
  6. Calls `loadFollowUpQuestionEntries()` to refresh

### 3.6 Generate AI Response with Retry
**Location:** `JournalViewModel.swift` - `generateAIResponseWithRetry(for:maxRetries:)`

**Shared by all three types:**
- **Retry Logic:** 3 attempts with exponential backoff
- **Attempt 1:** Sets `currentRetryAttempt = 1` → Shows "Generating..."
- **Attempt 2:** Sets `currentRetryAttempt = 2` → Shows "Retrying..." (2s delay)
- **Attempt 3:** Sets `currentRetryAttempt = 3` → Shows "Retrying again..." (4s delay)
- **Empty Response Check:** Validates response is not empty/whitespace-only
- **Error Handling:** 
  - Non-retryable errors (invalid API key, quota exceeded): throws immediately
  - Other errors: retries up to 3 times
- **Success:** Returns AI response string
- **Failure:** Throws error with last error message

### 3.7 OpenAI API Call
**Location:** `OpenAIService.swift` - `generateAIResponse(for:)`

**Shared by all three types:**
1. **Create Request:**
   - Model: `gpt-5-mini`
   - System message: "You are an AI Behavioral Therapist/Scientist..."
   - User message: The AI prompt
   - Parameters: `max_completion_tokens: 500`, `reasoning_effort: "low"`, `verbosity: "medium"`
2. **Send Request:**
   - POST to `https://api.openai.com/v1/chat/completions`
   - Authorization: Bearer token
   - Content-Type: application/json
3. **Handle Response:**
   - Checks HTTP status code (200 = success)
   - Parses JSON response
   - Extracts content from `choices[0].message.content`
   - Returns AI response string
4. **Error Handling:**
   - 429: Rate limited or quota exceeded
   - 401: Invalid API key
   - Other: API error with status code
   - Network errors: Wrapped in OpenAIError

### 3.8 Update Entry with AI Response
**Location:** `SupabaseService.swift` - `updateJournalEntry(_:)`

**Shared by all three types:**
- Updates `journal_entries` table
- Sets `ai_response = aiResponse`
- Updates `updated_at` timestamp
- Returns updated entry

---

## Phase 4: UI Display Update

### 4.1 Update AI Response Display
**Location:** `ContentView.swift`

#### Guided Question:
- `updateAIResponseDisplay()`
  1. Calls `journalViewModel.loadJournalEntries()` to refresh
  2. Gets most recent entry with non-empty `aiResponse`
  3. Sets `currentAIResponse = aiResponse` on main thread
  4. Calls `updateTextEditorHeight()` to adjust UI
  5. Shows favorite button after delay

#### Open Question:
- `updateOpenAIResponseDisplay()`
  1. Calls `journalViewModel.loadOpenQuestionJournalEntries()` to refresh
  2. Gets most recent entry with non-empty `aiResponse`
  3. Sets `openCurrentAIResponse = aiResponse` on main thread
  4. Calls `updateOpenTextEditorHeight()` to adjust UI
  5. Shows favorite button after delay

#### Follow-Up Question:
- `updateFollowUpAIResponseDisplay()`
  1. Calls `journalViewModel.loadFollowUpQuestionEntries()` to refresh
  2. Gets most recent entry with non-empty `aiResponse`
  3. Sets `followUpCurrentAIResponse = aiResponse` on main thread
  4. Calls `updateFollowUpTextEditorHeight()` to adjust UI
  5. Shows favorite button after delay

### 4.2 UI State Updates
**Location:** `ContentView.swift`

#### Text Display:
- When `isTextLocked && !currentAIResponse.isEmpty`:
  - Shows both journal text and AI response in ScrollView
  - Journal text: Color `textGrey`, 16pt font
  - AI response: Color `#3F5E82`, 15pt font, 12pt left indent
  - Scrolls to top when AI response appears
  - Shows favorite button after 0.5s delay

#### Loading Overlay:
- When `isGeneratingAI || openIsGeneratingAI || followUpIsGeneratingAI`:
  - Shows overlay with `ProgressView` and text
  - Text based on `currentRetryAttempt`:
    - Attempt 1: "Generating..."
    - Attempt 2: "Retrying..."
    - Attempt 3: "Retrying again..."
  - Blocks user interaction

#### Button States:
- **Done Button:** Hidden when text is empty or AI response exists
- **Centered Button:** Shows when text is locked, hidden when AI response exists
- **Centered Button Click:** Shows during AI generation
- **Favorite Button:** Shows when AI response exists and user scrolled to bottom

---

## Phase 5: Favorite Button (Optional)

### 5.1 Favorite Button Tapped
**Location:** `ContentView.swift`

#### Guided Question:
- `favoriteButtonTapped()`
  - Sets `isFavoriteClicked = true`
  - Performs haptic feedback
  - Calls `journalViewModel.updateCurrentJournalEntryFavoriteStatus(isFavorite: true)`

#### Open Question:
- `openFavoriteButtonTapped()`
  - Sets `openIsFavoriteClicked = true`
  - Performs haptic feedback
  - Calls `journalViewModel.updateCurrentOpenQuestionJournalEntryFavoriteStatus(isFavorite: true)`

#### Follow-Up Question:
- `followUpFavoriteButtonTapped()`
  - Sets `followUpIsFavoriteClicked = true`
  - Performs haptic feedback
  - Calls `journalViewModel.updateCurrentFollowUpQuestionJournalEntryFavoriteStatus(isFavorite: true)`

### 5.2 Update Favorite Status
**Location:** `JournalViewModel.swift`

#### Guided Question:
- `updateCurrentJournalEntryFavoriteStatus(isFavorite:)`
  1. Calls `loadJournalEntries()` to get latest entry
  2. Creates updated entry with `isFavorite = isFavorite`
  3. Calls `supabaseService.updateJournalEntry(updatedEntry)`
  4. Calls `loadJournalEntries()` to refresh

#### Open Question:
- `updateCurrentOpenQuestionJournalEntryFavoriteStatus(isFavorite:)`
  1. Calls `loadOpenQuestionJournalEntries()` to get latest entry
  2. Creates updated entry with `isFavorite = isFavorite`
  3. Calls `supabaseService.updateJournalEntry(updatedEntry)`
  4. Calls `loadOpenQuestionJournalEntries()` to refresh

#### Follow-Up Question:
- `updateCurrentFollowUpQuestionJournalEntryFavoriteStatus(isFavorite:)`
  1. Calls `loadFollowUpQuestionEntries()` to get latest entry
  2. Creates updated entry with `isFavorite = isFavorite`
  3. Calls `supabaseService.updateJournalEntry(updatedEntry)`
  4. Calls `loadFollowUpQuestionEntries()` to refresh

---

## Complete Function Flow Summary

### Guided Question Flow:
1. User types → `journalResponse` updates
2. Done button → `doneButtonTapped()` → `createJournalEntry()` → Save to DB
3. Centered button → `centeredButtonTapped()` → `generateAndSaveAIPrompt()`
4. Load profile → `loadUserProfile()`
5. Create prompt → `createAIPromptText()` → `updateCurrentJournalEntryWithAIPrompt()`
6. Generate AI → `generateAndSaveAIResponse()` → `generateAIResponseWithRetry()` → `openAIService.generateAIResponse()`
7. Update entry → `updateJournalEntry()` → Save AI response to DB
8. Update UI → `updateAIResponseDisplay()` → `loadJournalEntries()` → Set `currentAIResponse`
9. Display → Shows journal text + AI response in ScrollView

### Open Question Flow:
1. User types → `openJournalResponse` updates
2. Done button → `openDoneButtonTapped()` → `createOpenQuestionJournalEntry()` → Save to DB
3. Centered button → `openCenteredButtonTapped()` → `generateAndSaveOpenAIPrompt()`
4. Create prompt → `createAIPromptText()` (static question) → `updateCurrentOpenQuestionJournalEntryWithAIPrompt()`
5. Generate AI → `generateAndSaveOpenQuestionAIResponse()` → `generateAIResponseWithRetry()` → `openAIService.generateAIResponse()`
6. Update entry → `updateJournalEntry()` → Save AI response to DB
7. Update UI → `updateOpenAIResponseDisplay()` → `loadOpenQuestionJournalEntries()` → Set `openCurrentAIResponse`
8. Display → Shows journal text + AI response in ScrollView

### Follow-Up Question Flow:
1. User types → `followUpJournalResponse` updates
2. Done button → `followUpDoneButtonTapped()` → `createFollowUpQuestionJournalEntry()` → Save to DB
3. Centered button → `followUpCenteredButtonTapped()` → `generateAndSaveFollowUpAIPrompt()`
4. Create prompt → `createFollowUpAIPromptText()` → `updateCurrentFollowUpQuestionJournalEntryWithAIPrompt()`
5. Generate AI → `generateAndSaveFollowUpQuestionAIResponse()` → `generateAIResponseWithRetry()` → `openAIService.generateAIResponse()`
6. Update entry → `updateJournalEntry()` → Save AI response to DB
7. Update UI → `updateFollowUpAIResponseDisplay()` → `loadFollowUpQuestionEntries()` → Set `followUpCurrentAIResponse`
8. Display → Shows journal text + AI response in ScrollView

---

## Key Database Operations

### SupabaseService Functions:
1. `createJournalEntry(_:)` - Creates new journal entry
2. `createOpenQuestionJournalEntry(_:, staticQuestion:)` - Creates open question entry
3. `updateJournalEntry(_:)` - Updates entry with AI prompt/response
4. `fetchJournalEntries(userId:)` - Fetches guided question entries
5. `fetchOpenQuestionJournalEntries(userId:)` - Fetches open question entries
6. `loadUserProfile()` - Loads user profile data

### JournalViewModel Functions:
1. `createJournalEntry(content:)` - Creates guided question entry
2. `createOpenQuestionJournalEntry(content:)` - Creates open question entry
3. `createFollowUpQuestionJournalEntry(content:)` - Creates follow-up question entry
4. `updateCurrentJournalEntryWithAIPrompt(aiPrompt:)` - Updates guided entry with prompt
5. `updateCurrentOpenQuestionJournalEntryWithAIPrompt(aiPrompt:)` - Updates open entry with prompt
6. `updateCurrentFollowUpQuestionJournalEntryWithAIPrompt(aiPrompt:)` - Updates follow-up entry with prompt
7. `generateAndSaveAIResponse()` - Generates AI response for guided entry
8. `generateAndSaveOpenQuestionAIResponse()` - Generates AI response for open entry
9. `generateAndSaveFollowUpQuestionAIResponse()` - Generates AI response for follow-up entry
10. `generateAIResponseWithRetry(for:)` - Shared retry logic for all types
11. `loadJournalEntries()` - Loads guided question entries
12. `loadOpenQuestionJournalEntries()` - Loads open question entries
13. `loadFollowUpQuestionEntries()` - Loads follow-up question entries
14. `updateCurrentJournalEntryFavoriteStatus(isFavorite:)` - Updates favorite status
15. `updateCurrentOpenQuestionJournalEntryFavoriteStatus(isFavorite:)` - Updates favorite status
16. `updateCurrentFollowUpQuestionJournalEntryFavoriteStatus(isFavorite:)` - Updates favorite status

### ContentView Functions:
1. `doneButtonTapped()` - Handles Done button for guided question
2. `openDoneButtonTapped()` - Handles Done button for open question
3. `followUpDoneButtonTapped()` - Handles Done button for follow-up question
4. `centeredButtonTapped()` - Handles Centered button for guided question
5. `openCenteredButtonTapped()` - Handles Centered button for open question
6. `followUpCenteredButtonTapped()` - Handles Centered button for follow-up question
7. `generateAndSaveAIPrompt()` - Generates and saves AI prompt for guided question
8. `generateAndSaveOpenAIPrompt()` - Generates and saves AI prompt for open question
9. `generateAndSaveFollowUpAIPrompt()` - Generates and saves AI prompt for follow-up question
10. `createAIPromptText(content:goal:questionText:)` - Creates AI prompt text (guided/open)
11. `createFollowUpAIPromptText(content:fuqAiResponse:)` - Creates AI prompt text (follow-up)
12. `updateAIResponseDisplay()` - Updates UI with AI response (guided)
13. `updateOpenAIResponseDisplay()` - Updates UI with AI response (open)
14. `updateFollowUpAIResponseDisplay()` - Updates UI with AI response (follow-up)
15. `favoriteButtonTapped()` - Handles favorite button (guided)
16. `openFavoriteButtonTapped()` - Handles favorite button (open)
17. `followUpFavoriteButtonTapped()` - Handles favorite button (follow-up)
18. `updateTextEditorHeight()` - Updates text editor height (guided)
19. `updateOpenTextEditorHeight()` - Updates text editor height (open)
20. `updateFollowUpTextEditorHeight()` - Updates text editor height (follow-up)

### OpenAIService Functions:
1. `generateAIResponse(for:)` - Makes API call to OpenAI
   - Creates request with model, messages, parameters
   - Sends POST request to OpenAI API
   - Parses JSON response
   - Returns AI response string
   - Handles errors (rate limit, quota, API key, network)

---

## Error Handling

### Retry Logic:
- **3 Attempts:** Maximum 3 retries for AI generation
- **Delays:** 2s between attempt 1 and 2, 4s between attempt 2 and 3
- **Status Updates:** "Generating..." → "Retrying..." → "Retrying again..."
- **Empty Response Check:** Validates response is not empty/whitespace-only
- **Non-Retryable Errors:** Invalid API key, quota exceeded (throws immediately)

### Error Messages:
- **After 3 Failed Attempts:** "The AI's taking a short break 😅 please try again shortly."
- **Network Errors:** Wrapped in OpenAIError
- **API Errors:** HTTP status code and error message
- **Cancelled Requests:** Gracefully handled, keeps existing data

### UI Error Handling:
- Loading overlay blocks user interaction during generation
- Button states prevent multiple clicks
- Error alerts shown after retries exhausted
- State reset on error (button state, loading flags)

---

## State Variables

### Guided Question (ContentView):
- `journalResponse: String` - User's journal entry text
- `currentAIResponse: String` - AI-generated response
- `isTextLocked: Bool` - Whether text is locked
- `showCenteredButton: Bool` - Whether to show Centered button
- `showCenteredButtonClick: Bool` - Whether button is in clicked state
- `isGeneratingAI: Bool` - Whether AI is being generated
- `isLoadingGenerating: Bool` - Whether loading is for generation vs saving
- `showFavoriteButton: Bool` - Whether to show favorite button
- `isFavoriteClicked: Bool` - Whether favorite is clicked
- `textEditorHeight: CGFloat` - Dynamic text editor height

### Open Question (ContentView):
- `openJournalResponse: String` - User's journal entry text
- `openCurrentAIResponse: String` - AI-generated response
- `openIsTextLocked: Bool` - Whether text is locked
- `openShowCenteredButton: Bool` - Whether to show Centered button
- `openShowCenteredButtonClick: Bool` - Whether button is in clicked state
- `openIsGeneratingAI: Bool` - Whether AI is being generated
- `openIsLoadingGenerating: Bool` - Whether loading is for generation vs saving
- `openShowFavoriteButton: Bool` - Whether to show favorite button
- `openIsFavoriteClicked: Bool` - Whether favorite is clicked
- `openTextEditorHeight: CGFloat` - Dynamic text editor height

### Follow-Up Question (ContentView):
- `followUpJournalResponse: String` - User's journal entry text
- `followUpCurrentAIResponse: String` - AI-generated response
- `followUpIsTextLocked: Bool` - Whether text is locked
- `followUpShowCenteredButton: Bool` - Whether to show Centered button
- `followUpShowCenteredButtonClick: Bool` - Whether button is in clicked state
- `followUpIsGeneratingAI: Bool` - Whether AI is being generated
- `followUpIsLoadingGenerating: Bool` - Whether loading is for generation vs saving
- `followUpShowFavoriteButton: Bool` - Whether to show favorite button
- `followUpIsFavoriteClicked: Bool` - Whether favorite is clicked
- `followUpTextEditorHeight: CGFloat` - Dynamic text editor height

### JournalViewModel (Shared):
- `currentRetryAttempt: Int` - Current retry attempt (1, 2, 3)
- `errorMessage: String?` - Error message to display
- `isLoading: Bool` - Whether data is loading
- `journalEntries: [JournalEntry]` - Guided question entries
- `openQuestionJournalEntries: [JournalEntry]` - Open question entries
- `followUpQuestionEntries: [JournalEntry]` - Follow-up question entries
- `currentQuestion: GuidedQuestion?` - Current guided question
- `currentFollowUpQuestion: String` - Current follow-up question
- `goals: [Goal]` - User's goals
- `currentUser: UserProfile?` - Current user profile

---

## UI Display Flow

### Text Editor States:
1. **Empty State:** Shows text editor with placeholder/Q icon
2. **Text Entered:** Shows text, Done button appears
3. **Done Clicked:** Text locked, Centered button appears
4. **Centered Clicked:** Button changes to "Centered Button Click", loading overlay appears
5. **AI Generated:** Text editor shows journal text + AI response in ScrollView
6. **Favorite Button:** Appears after AI response is displayed and user scrolled to bottom

### Loading Overlay:
- **During Generation:** Shows overlay with ProgressView and status text
- **Status Text:** Based on `currentRetryAttempt`:
  - 1: "Generating..."
  - 2: "Retrying..."
  - 3: "Retrying again..."
- **Blocks Interaction:** `allowsHitTesting(true)` prevents user input
- **Auto-Hides:** Disappears when AI generation completes

### ScrollView Display:
- **Journal Text:** Displayed first, color `textGrey`, 16pt font
- **AI Response:** Displayed below, color `#3F5E82`, 15pt font, 12pt left indent
- **Auto-Scroll:** Scrolls to top when AI response appears
- **Fade Mask:** Gradient mask at bottom to prevent text overlap with favorite button

---

## Key Differences Between Entry Types

### Guided Question:
- Uses `currentQuestion` from database (date-based rotation)
- AI prompt includes guided question text
- Loads user profile for personalized prompts
- Entry type: `"guided"`

### Open Question:
- Uses static question: "Looking at today or yesterday, share moments or thoughts that stood out"
- AI prompt uses static question text
- Loads user profile for personalized prompts
- Entry type: `"open"`
- Tag: `["open_question"]`

### Follow-Up Question:
- Uses `currentFollowUpQuestion` (AI-generated question)
- AI prompt uses follow-up question template (different from guided/open)
- Does not load user profile (uses existing follow-up question context)
- Entry type: `"follow_up"`
- Tag: `["follow_up"]`
- Stores question in `fuqAiResponse` field

---

## Timeout Handling

### AI Generation Timeout:
- **Timeout:** 30 seconds via `withTimeout(seconds: 30)`
- **Operation:** Wraps `generateAndSaveAIResponse()` / `generateAndSaveOpenQuestionAIResponse()` / `generateAndSaveFollowUpQuestionAIResponse()`
- **Error:** Throws `TimeoutError` if operation exceeds 30 seconds
- **UI:** Shows error message to user

---

## Database Schema

### journal_entries Table:
- `id: UUID` - Primary key
- `user_id: UUID` - User identifier
- `guided_question_id: UUID?` - Guided question ID (nullable)
- `content: String` - User's journal entry text
- `ai_prompt: String?` - AI prompt (nullable)
- `ai_response: String?` - AI-generated response (nullable)
- `tags: [String]` - Tags (e.g., ["open_question"], ["follow_up"])
- `is_favorite: Bool` - Favorite status
- `entry_type: String` - Entry type ("guided", "open", "follow_up")
- `fuq_ai_prompt: String?` - Follow-up question prompt (nullable)
- `fuq_ai_response: String?` - Follow-up question text (nullable)
- `created_at: Date` - Creation timestamp
- `updated_at: Date` - Update timestamp

---

## Complete Function Execution Order

### Guided Question:
1. `doneButtonTapped()` (ContentView)
2. `createJournalEntry(content:)` (JournalViewModel)
3. `createJournalEntry(_:)` (SupabaseService)
4. `loadJournalEntries()` (JournalViewModel)
5. `centeredButtonTapped()` (ContentView)
6. `generateAndSaveAIPrompt()` (ContentView)
7. `loadUserProfile()` (SupabaseService)
8. `createAIPromptText(content:goal:questionText:)` (ContentView)
9. `updateCurrentJournalEntryWithAIPrompt(aiPrompt:)` (JournalViewModel)
10. `loadJournalEntries()` (JournalViewModel)
11. `updateJournalEntry(_:)` (SupabaseService)
12. `generateAndSaveAIResponse()` (JournalViewModel)
13. `loadJournalEntries()` (JournalViewModel)
14. `generateAIResponseWithRetry(for:)` (JournalViewModel)
15. `generateAIResponse(for:)` (OpenAIService) - Up to 3 attempts
16. `updateJournalEntry(_:)` (SupabaseService)
17. `loadJournalEntries()` (JournalViewModel)
18. `updateAIResponseDisplay()` (ContentView)
19. `loadJournalEntries()` (JournalViewModel)
20. Set `currentAIResponse` (ContentView)
21. `updateTextEditorHeight()` (ContentView)
22. Display AI response in UI

### Open Question:
1. `openDoneButtonTapped()` (ContentView)
2. `createOpenQuestionJournalEntry(content:)` (JournalViewModel)
3. `createOpenQuestionJournalEntry(_:, staticQuestion:)` (SupabaseService)
4. `loadOpenQuestionJournalEntries()` (JournalViewModel)
5. `openCenteredButtonTapped()` (ContentView)
6. `generateAndSaveOpenAIPrompt()` (ContentView)
7. `createAIPromptText(content:goal:questionText:)` (ContentView)
8. `updateCurrentOpenQuestionJournalEntryWithAIPrompt(aiPrompt:)` (JournalViewModel)
9. `loadOpenQuestionJournalEntries()` (JournalViewModel)
10. `updateJournalEntry(_:)` (SupabaseService)
11. `generateAndSaveOpenQuestionAIResponse()` (JournalViewModel)
12. `loadOpenQuestionJournalEntries()` (JournalViewModel)
13. `generateAIResponseWithRetry(for:)` (JournalViewModel)
14. `generateAIResponse(for:)` (OpenAIService) - Up to 3 attempts
15. `updateJournalEntry(_:)` (SupabaseService)
16. `loadOpenQuestionJournalEntries()` (JournalViewModel)
17. `updateOpenAIResponseDisplay()` (ContentView)
18. `loadOpenQuestionJournalEntries()` (JournalViewModel)
19. Set `openCurrentAIResponse` (ContentView)
20. `updateOpenTextEditorHeight()` (ContentView)
21. Display AI response in UI

### Follow-Up Question:
1. `followUpDoneButtonTapped()` (ContentView)
2. `createFollowUpQuestionJournalEntry(content:)` (JournalViewModel)
3. `createJournalEntry(_:)` (SupabaseService)
4. `loadFollowUpQuestionEntries()` (JournalViewModel)
5. `followUpCenteredButtonTapped()` (ContentView)
6. `generateAndSaveFollowUpAIPrompt()` (ContentView)
7. `createFollowUpAIPromptText(content:fuqAiResponse:)` (ContentView)
8. `updateCurrentFollowUpQuestionJournalEntryWithAIPrompt(aiPrompt:)` (JournalViewModel)
9. `loadFollowUpQuestionEntries()` (JournalViewModel)
10. `updateJournalEntry(_:)` (SupabaseService)
11. `generateAndSaveFollowUpQuestionAIResponse()` (JournalViewModel)
12. `loadFollowUpQuestionEntries()` (JournalViewModel)
13. `generateAIResponseWithRetry(for:)` (JournalViewModel)
14. `generateAIResponse(for:)` (OpenAIService) - Up to 3 attempts
15. `updateJournalEntry(_:)` (SupabaseService)
16. `loadFollowUpQuestionEntries()` (JournalViewModel)
17. `updateFollowUpAIResponseDisplay()` (ContentView)
18. `loadFollowUpQuestionEntries()` (JournalViewModel)
19. Set `followUpCurrentAIResponse` (ContentView)
20. `updateFollowUpTextEditorHeight()` (ContentView)
21. Display AI response in UI

---

## Notes

- All three entry types share the same retry logic (`generateAIResponseWithRetry`)
- All three types use the same OpenAI API service (`OpenAIService.generateAIResponse`)
- Guided and Open questions use the same AI prompt template
- Follow-Up questions use a different AI prompt template
- All three types update the database with the same `updateJournalEntry` function
- UI state management is separate for each type to prevent conflicts
- Error handling is consistent across all three types
- Loading states are tracked separately for each type
- Favorite button functionality is identical for all three types



