# Follow-Up Question Done Button to FUQ AI Response Process - Complete Function Flow

This document details all functions executed from when the user clicks the Done button after entering their response to a follow-up question, through to when the FUQ (Follow-Up Question) AI response is displayed in the UI.

---

## Overview
The process begins when a user types their response to a follow-up question, clicks "Done" to save, then clicks "Centered" to generate an AI response. The AI response is generated using a follow-up question-specific template that includes the therapist's question and the client's response.

---

## Phase 1: User Input

### 1.1 User Types Response
- User enters text in the follow-up question text field
- State variable updates: `followUpJournalResponse` (ContentView)
- Text editor height adjusts dynamically via `updateFollowUpTextEditorHeight()`

### 1.2 Text Editor Height Update
**Location:** `ContentView.swift` - `updateFollowUpTextEditorHeight()`
- If AI response exists: Sets height to 250pt (fixed for scrolling)
- If text is empty: Sets height to 150pt (default)
- If text exists: Calculates dynamic height based on text content
- Uses `UIFont.systemFont(ofSize: 16)` for calculation
- Validates calculated height to prevent NaN/Infinity
- Returns height between 150pt and 250pt

---

## Phase 2: Done Button - Save Entry

### 2.1 Done Button Tapped
**Location:** `ContentView.swift` - `followUpDoneButtonTapped()`
- Sets `followUpShowCenteredButton = true`
- Sets `followUpIsTextLocked = true`
- Sets `followUpIsLoadingGenerating = false` (saving, not generating)
- Performs haptic feedback: `UIImpactFeedbackGenerator(style: .medium)`
- Calls `journalViewModel.createFollowUpQuestionJournalEntry(content:)` in Task

### 2.2 Create Follow-Up Question Journal Entry
**Location:** `JournalViewModel.swift` - `createFollowUpQuestionJournalEntry(content:)`
- Sets `isLoading = true`
- Sets `errorMessage = nil`
- Creates `JournalEntry` with:
  - `userId = user.id`
  - `guidedQuestionId = nil`
  - `content = content` (user's response to follow-up question)
  - `tags = ["follow_up"]`
  - `entryType = "follow_up"`
  - `fuqAiPrompt = nil` (will be filled when Centered button is clicked)
  - `fuqAiResponse = currentFollowUpQuestion` (the follow-up question itself)
  - `isFollowUpDay = true`
- Calls `supabaseService.createJournalEntry(entry)` to save
- Calls `loadFollowUpQuestionEntries()` to refresh entries
- Sets `isLoading = false`

### 2.3 Save to Database
**Location:** `SupabaseService.swift` - `createJournalEntry(_:)`
- Inserts entry into `journal_entries` table
- Entry is tagged with `tags = ["follow_up"]`
- Entry type is `entry_type = "follow_up"`
- `fuq_ai_response` field stores the follow-up question text
- Returns saved entry with generated `id`

---

## Phase 3: Centered Button - Generate AI Response

### 3.1 Centered Button Tapped
**Location:** `ContentView.swift` - `followUpCenteredButtonTapped()`
- **Guard Check:** Ensures `!followUpIsGeneratingAI` to prevent multiple clicks
- Sets `followUpShowCenteredButtonClick = true`
- Sets `followUpIsGeneratingAI = true`
- Sets `followUpIsLoadingGenerating = true` (generating AI, not saving)
- Sets `journalViewModel.currentRetryAttempt = 1`
- Performs haptic feedback: `UIImpactFeedbackGenerator(style: .medium)`
- Calls `generateAndSaveFollowUpAIPrompt()` in Task

### 3.2 Generate and Save Follow-Up AI Prompt
**Location:** `ContentView.swift` - `generateAndSaveFollowUpAIPrompt()`
- Gets `currentFollowUpQuestion` from `journalViewModel` (the follow-up question text)
- Calls `createFollowUpAIPromptText(content:fuqAiResponse:)` to create prompt
- Calls `journalViewModel.updateCurrentFollowUpQuestionJournalEntryWithAIPrompt(aiPrompt:)` to update entry
- Calls `journalViewModel.generateAndSaveFollowUpQuestionAIResponse()` with 30s timeout
- Calls `updateFollowUpAIResponseDisplay()` to update UI
- **Error Handling:**
  - On success: Resets `followUpIsGeneratingAI = false` and `followUpIsLoadingGenerating = false`
  - On error: Resets button state and flags

### 3.3 Create Follow-Up AI Prompt Text
**Location:** `ContentView.swift` - `createFollowUpAIPromptText(content:fuqAiResponse:)`
- Uses follow-up question AI prompt template:
  ```
  Therapist: {fuq_ai_response}
  Client: {content}
  Output: Provide only a succinct response to the above therapist/client conversation. First be encouraging, supportive, with a pleasant tone to their progress. Then provide additional insight on the action item mentioned by the therapist. Based on relevant behavioral, CBT, EFT, IPT or other therapy modalities. In a new paragraph, end with related, "quote" from well known figures
  Constraints: Focus on capturing the main points succinctly: complete sentences and in an encouraging, supportive, pleasant tone. Ignore fluff, background information. Do not include your own analysis or opinion. Do not reiterate the input.
  Capabilities and Reminders: You have access to the web search tools, published research papers/studies and your gained knowledge to find and retrieve behavioral science and therapy related data. Limit the entire response to 150 words.
  ```
- **Replace Placeholders:**
  - `{content}` → User's response to follow-up question (`followUpJournalResponse`)
  - `{fuq_ai_response}` → The follow-up question itself (`currentFollowUpQuestion`)
- Returns the complete prompt string

### 3.4 Update Entry with AI Prompt
**Location:** `JournalViewModel.swift` - `updateCurrentFollowUpQuestionJournalEntryWithAIPrompt(aiPrompt:)`
- Calls `loadFollowUpQuestionEntries()` to get latest entries
- Finds most recent entry (first in array, which is the user's response entry)
- Creates updated entry with `aiPrompt = aiPrompt`
- Preserves all other fields including `fuqAiResponse` (the question)
- Calls `supabaseService.updateJournalEntry(updatedEntry)` to save
- Calls `loadFollowUpQuestionEntries()` to refresh

### 3.5 Generate AI Response
**Location:** `JournalViewModel.swift` - `generateAndSaveFollowUpQuestionAIResponse()`
- Sets `isLoading = true`
- Sets `errorMessage = nil`
- Calls `loadFollowUpQuestionEntries()` to get latest entry
- Gets `aiPrompt` from most recent entry
- Calls `generateAIResponseWithRetry(for: aiPrompt)` to generate AI response
- Creates updated entry with `aiResponse = aiResponse`
- Calls `supabaseService.updateJournalEntry(updatedEntry)` to save
- Calls `loadFollowUpQuestionEntries()` to refresh
- Sets `isLoading = false`

### 3.6 Generate AI Response with Retry
**Location:** `JournalViewModel.swift` - `generateAIResponseWithRetry(for:maxRetries:)`
- **Retry Logic:** 3 attempts with exponential backoff
- **Attempt 1:** Sets `currentRetryAttempt = 1` → Shows "Generating..." in overlay
- **Attempt 2:** Sets `currentRetryAttempt = 2` → Shows "Retrying..." (2s delay)
- **Attempt 3:** Sets `currentRetryAttempt = 3` → Shows "Retrying again..." (4s delay)
- **Empty Response Check:** Validates response is not empty/whitespace-only (throws error to retry)
- **Error Handling:**
  - Non-retryable errors (invalid API key, quota exceeded): throws immediately
  - Other errors: retries up to 3 times
- **Success:** Returns AI response string
- **Failure:** Throws error with last error message

### 3.7 OpenAI API Call
**Location:** `OpenAIService.swift` - `generateAIResponse(for:)`
- **Create Request:**
  - Model: `gpt-5-mini`
  - System message: "You are an AI Behavioral Therapist/Scientist tasked with acknowledging daily journal logs and providing constructive suggestions or helpful tips."
  - User message: The follow-up AI prompt (therapist/client conversation)
  - Parameters: 
    - `max_completion_tokens: 500`
    - `reasoning_effort: "low"`
    - `verbosity: "medium"`
- **Send Request:**
  - POST to `https://api.openai.com/v1/chat/completions`
  - Authorization: Bearer token (from Config.plist)
  - Content-Type: application/json
- **Handle Response:**
  - Checks HTTP status code (200 = success)
  - Parses JSON response
  - Extracts content from `choices[0].message.content`
  - Returns AI response string
- **Error Handling:**
  - 429: Rate limited or quota exceeded → `OpenAIError.rateLimited` or `OpenAIError.quotaExceeded`
  - 401: Invalid API key → `OpenAIError.invalidAPIKey`
  - Other: API error with status code → `OpenAIError.apiError`
  - Network errors: Wrapped in `OpenAIError.apiError`

### 3.8 Update Entry with AI Response
**Location:** `SupabaseService.swift` - `updateJournalEntry(_:)`
- Updates `journal_entries` table
- Sets `ai_response = aiResponse`
- Updates `updated_at` timestamp
- Returns updated entry

---

## Phase 4: UI Display Update

### 4.1 Update Follow-Up AI Response Display
**Location:** `ContentView.swift` - `updateFollowUpAIResponseDisplay()`
- Calls `journalViewModel.loadFollowUpQuestionEntries()` to refresh entries
- Gets most recent entry (first in array)
- Checks if entry has non-empty `aiResponse`
- Sets `followUpCurrentAIResponse = aiResponse` on main thread
- Calls `updateFollowUpTextEditorHeight()` to adjust UI
- Shows favorite button after delay (if applicable)

### 4.2 Load Follow-Up Question Entries
**Location:** `JournalViewModel.swift` - `loadFollowUpQuestionEntries()`
- Gets current user
- Calls `supabaseService.fetchJournalEntries(userId:)` to fetch all entries
- Filters entries where `entryType == "follow_up"`
- Updates `followUpQuestionEntries` array
- **Error Handling:**
  - Cancelled requests: Gracefully handled, keeps existing entries
  - Other errors: Sets error message and logs error

### 4.3 Fetch Journal Entries
**Location:** `SupabaseService.swift` - `fetchJournalEntries(userId:)`
- Queries `journal_entries` table
- Filters by `user_id = userId`
- Excludes open question entries: `not("entry_type", operator: .eq, value: "open")`
- Orders by `created_at` descending (newest first)
- Returns `[JournalEntry]`

---

## Phase 5: UI State Updates

### 5.1 Text Display Update
**Location:** `ContentView.swift` - `mainJournalView`

When `followUpIsTextLocked && !followUpCurrentAIResponse.isEmpty`:
- Shows both journal text and AI response in ScrollView
- **Journal Text:**
  - Color: `textGrey`
  - Font: 16pt
  - Alignment: Leading
- **AI Response:**
  - Color: `#3F5E82` (blue)
  - Font: 15pt
  - Alignment: Leading
  - Left indent: 12pt (3 characters)
- Scrolls to top when AI response appears
- Shows favorite button after 0.5s delay

### 5.2 Text Editor Height Update
**Location:** `ContentView.swift` - `updateFollowUpTextEditorHeight()`
- If AI response exists: Sets height to 250pt (fixed for scrolling)
- Otherwise: Calculates dynamic height based on text content
- Validates height to prevent NaN/Infinity
- Returns height between 150pt and 250pt

### 5.3 Loading Overlay
**Location:** `ContentView.swift` - `mainJournalView` (for follow-up question section)

When `followUpIsGeneratingAI = true`:
- Shows overlay with `ProgressView` and text
- Text based on `journalViewModel.currentRetryAttempt`:
  - Attempt 1: "Generating..."
  - Attempt 2: "Retrying..."
  - Attempt 3: "Retrying again..."
- Blocks user interaction
- Auto-hides when AI generation completes

### 5.4 Button States
**Location:** `ContentView.swift` - `mainJournalView`

- **Done Button:** 
  - Hidden when text is empty or AI response exists
  - Shows when text is entered and no AI response
- **Centered Button:** 
  - Shows when text is locked and no AI response
  - Hidden when AI response exists
- **Centered Button Click:** 
  - Shows during AI generation
  - Replaces Centered Button
- **Favorite Button:** 
  - Shows when AI response exists and user scrolled to bottom
  - Appears after 0.5s delay

---

## Phase 6: Favorite Button (Optional)

### 6.1 Favorite Button Tapped
**Location:** `ContentView.swift` - `followUpFavoriteButtonTapped()`
- **Guard Check:** Ensures `!followUpIsFavoriteClicked` (prevents duplicate clicks)
- Sets `followUpIsFavoriteClicked = true`
- Performs haptic feedback: `UIImpactFeedbackGenerator(style: .light)`
- Calls `journalViewModel.updateCurrentFollowUpQuestionJournalEntryFavoriteStatus(isFavorite: true)`

### 6.2 Update Favorite Status
**Location:** `JournalViewModel.swift` - `updateCurrentFollowUpQuestionJournalEntryFavoriteStatus(isFavorite:)`
- Calls `loadFollowUpQuestionEntries()` to get latest entry
- Creates updated entry with `isFavorite = isFavorite`
- Calls `supabaseService.updateJournalEntry(updatedEntry)` to save
- Calls `loadFollowUpQuestionEntries()` to refresh

---

## Complete Function Execution Order

1. **User Input:**
   - User types response → `followUpJournalResponse` updates
   - `updateFollowUpTextEditorHeight()` - Adjusts text editor height

2. **Done Button:**
   - `followUpDoneButtonTapped()` (ContentView)
   - `createFollowUpQuestionJournalEntry(content:)` (JournalViewModel)
   - `createJournalEntry(_:)` (SupabaseService)
   - `loadFollowUpQuestionEntries()` (JournalViewModel)
   - `fetchJournalEntries(userId:)` (SupabaseService)

3. **Centered Button:**
   - `followUpCenteredButtonTapped()` (ContentView)
   - `generateAndSaveFollowUpAIPrompt()` (ContentView)
   - `createFollowUpAIPromptText(content:fuqAiResponse:)` (ContentView)
   - `updateCurrentFollowUpQuestionJournalEntryWithAIPrompt(aiPrompt:)` (JournalViewModel)
   - `loadFollowUpQuestionEntries()` (JournalViewModel)
   - `fetchJournalEntries(userId:)` (SupabaseService)
   - `updateJournalEntry(_:)` (SupabaseService)
   - `generateAndSaveFollowUpQuestionAIResponse()` (JournalViewModel)
   - `loadFollowUpQuestionEntries()` (JournalViewModel)
   - `fetchJournalEntries(userId:)` (SupabaseService)
   - `generateAIResponseWithRetry(for:)` (JournalViewModel)
   - `generateAIResponse(for:)` (OpenAIService) - Up to 3 attempts
   - `updateJournalEntry(_:)` (SupabaseService)
   - `loadFollowUpQuestionEntries()` (JournalViewModel)
   - `fetchJournalEntries(userId:)` (SupabaseService)
   - `updateFollowUpAIResponseDisplay()` (ContentView)
   - `loadFollowUpQuestionEntries()` (JournalViewModel)
   - `fetchJournalEntries(userId:)` (SupabaseService)
   - Set `followUpCurrentAIResponse` (ContentView)
   - `updateFollowUpTextEditorHeight()` (ContentView)
   - Display FUQ AI response in UI

---

## Key Database Operations

### SupabaseService Functions:
1. `createJournalEntry(_:)` - Creates follow-up question journal entry
2. `updateJournalEntry(_:)` - Updates entry with AI prompt/response
3. `fetchJournalEntries(userId:)` - Fetches all journal entries (filtered for follow-up)

### JournalViewModel Functions:
1. `createFollowUpQuestionJournalEntry(content:)` - Creates user's response entry
2. `loadFollowUpQuestionEntries()` - Loads follow-up question entries
3. `updateCurrentFollowUpQuestionJournalEntryWithAIPrompt(aiPrompt:)` - Updates entry with AI prompt
4. `generateAndSaveFollowUpQuestionAIResponse()` - Generates AI response
5. `generateAIResponseWithRetry(for:)` - Shared retry logic (3 attempts, 2s/4s delays)
6. `updateCurrentFollowUpQuestionJournalEntryFavoriteStatus(isFavorite:)` - Updates favorite status

### ContentView Functions:
1. `followUpDoneButtonTapped()` - Handles Done button tap
2. `followUpCenteredButtonTapped()` - Handles Centered button tap
3. `generateAndSaveFollowUpAIPrompt()` - Orchestrates AI prompt generation and response
4. `createFollowUpAIPromptText(content:fuqAiResponse:)` - Creates follow-up AI prompt text
5. `updateFollowUpAIResponseDisplay()` - Updates UI with AI response
6. `updateFollowUpTextEditorHeight()` - Updates text editor height
7. `followUpFavoriteButtonTapped()` - Handles favorite button (optional)

### OpenAIService Functions:
1. `generateAIResponse(for:)` - Makes API call to OpenAI
   - Model: `gpt-5-mini`
   - System message: Behavioral therapist role
   - User message: Follow-up AI prompt (therapist/client conversation)
   - Returns AI response string
   - Handles errors (rate limit, quota, API key, network)

---

## Follow-Up AI Prompt Template

### Template Structure:
```
Therapist: {fuq_ai_response}
Client: {content}
Output: Provide only a succinct response to the above therapist/client conversation. First be encouraging, supportive, with a pleasant tone to their progress. Then provide additional insight on the action item mentioned by the therapist. Based on relevant behavioral, CBT, EFT, IPT or other therapy modalities. In a new paragraph, end with related, "quote" from well known figures
Constraints: Focus on capturing the main points succinctly: complete sentences and in an encouraging, supportive, pleasant tone. Ignore fluff, background information. Do not include your own analysis or opinion. Do not reiterate the input.
Capabilities and Reminders: You have access to the web search tools, published research papers/studies and your gained knowledge to find and retrieve behavioral science and therapy related data. Limit the entire response to 150 words.
```

### Placeholder Replacement:
- `{fuq_ai_response}` → The follow-up question text (stored in `currentFollowUpQuestion`)
- `{content}` → User's response to the follow-up question (stored in `followUpJournalResponse`)

### Key Differences from Guided/Open Prompts:
- Uses therapist/client conversation format
- Includes the follow-up question as "Therapist" message
- User's response as "Client" message
- Focuses on progress, encouragement, and action items
- Response limit: 150 words (vs 230 words for guided/open)
- Does not include user profile data (gender, occupation, birthdate)
- Does not include user goal
- Does not include guided question text

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
- **No Entry Found:** "No follow-up question journal entry found to update."
- **No AI Prompt:** "No follow-up question journal entry or AI prompt found."
- **Network Errors:** Wrapped in OpenAIError
- **API Errors:** HTTP status code and error message

### UI Error Handling:
- Loading overlay blocks user interaction during generation
- Button state prevents multiple clicks
- Error alerts shown after retries exhausted
- State reset on error (button state, loading flags)

---

## State Variables

### ContentView Follow-Up Question State:
- `followUpJournalResponse: String` - User's response text
- `followUpCurrentAIResponse: String` - AI-generated response
- `followUpIsTextLocked: Bool` - Whether text is locked
- `followUpShowCenteredButton: Bool` - Whether to show Centered button
- `followUpShowCenteredButtonClick: Bool` - Whether button is in clicked state
- `followUpIsGeneratingAI: Bool` - Whether AI is being generated
- `followUpIsLoadingGenerating: Bool` - Whether loading is for generation vs saving
- `followUpShowFavoriteButton: Bool` - Whether to show favorite button
- `followUpIsFavoriteClicked: Bool` - Whether favorite is clicked
- `followUpTextEditorHeight: CGFloat` - Dynamic text editor height
- `isFollowUpQuestionDay: Bool` - Whether today is a follow-up day

### JournalViewModel Follow-Up Question State:
- `currentFollowUpQuestion: String` - The current follow-up question text
- `followUpQuestionEntries: [JournalEntry]` - Array of all follow-up entries
- `currentRetryAttempt: Int` - Current retry attempt (1, 2, 3)
- `errorMessage: String?` - Error message to display
- `isLoading: Bool` - Whether data is loading

---

## Database Schema

### journal_entries Table (Follow-Up Question Entry):
- `id: UUID` - Primary key
- `user_id: UUID` - User identifier
- `guided_question_id: UUID?` - NULL for follow-up entries
- `content: String` - User's response to follow-up question
- `ai_prompt: String?` - AI prompt (filled when Centered button clicked)
- `ai_response: String?` - AI-generated response (FUQ AI response)
- `tags: [String]` - `["follow_up"]`
- `is_favorite: Bool` - Favorite status
- `entry_type: String` - `"follow_up"`
- `fuq_ai_prompt: String?` - Follow-up question prompt (nullable, used for question generation)
- `fuq_ai_response: String?` - Follow-up question text (the question itself)
- `created_at: Date` - Creation timestamp
- `updated_at: Date` - Update timestamp

---

## UI Display Flow

### Text Editor States:
1. **Empty State:** Shows text editor with Q icon placeholder
2. **Text Entered:** Shows text, Done button appears
3. **Done Clicked:** Text locked, Centered button appears
4. **Centered Clicked:** Button changes to "Centered Button Click", loading overlay appears
5. **AI Generated:** Text editor shows journal text + FUQ AI response in ScrollView
6. **Favorite Button:** Appears after AI response is displayed and user scrolled to bottom

### Loading Overlay:
- **During Generation:** Shows overlay with ProgressView and status text
- **Status Text:** Based on `currentRetryAttempt`:
  - Attempt 1: "Generating..."
  - Attempt 2: "Retrying..."
  - Attempt 3: "Retrying again..."
- **Blocks Interaction:** `allowsHitTesting(true)` prevents user input
- **Auto-Hides:** Disappears when AI generation completes

### ScrollView Display:
- **Journal Text:** Displayed first, color `textGrey`, 16pt font
- **FUQ AI Response:** Displayed below, color `#3F5E82`, 15pt font, 12pt left indent
- **Auto-Scroll:** Scrolls to top when AI response appears
- **Fade Mask:** Gradient mask at bottom to prevent text overlap with favorite button

---

## Key Differences from Guided/Open Questions

### Follow-Up Question Specific:
1. **AI Prompt Template:** Uses therapist/client conversation format instead of search terms format
2. **No User Profile:** Does not load user profile (gender, occupation, birthdate)
3. **No User Goal:** Does not include user goal in prompt
4. **Question Source:** Uses `currentFollowUpQuestion` (AI-generated) instead of guided question
5. **Response Limit:** 150 words (vs 230 words for guided/open)
6. **Entry Type:** `"follow_up"` (vs `"guided"` or `"open"`)
7. **Tag:** `["follow_up"]` (vs `["open_question"]` or none)
8. **Question Storage:** Stores question in `fuq_ai_response` field

### Shared with Guided/Open:
- Same retry logic (`generateAIResponseWithRetry`)
- Same OpenAI API service (`OpenAIService.generateAIResponse`)
- Same database update function (`updateJournalEntry`)
- Same error handling
- Same loading overlay display
- Same favorite button functionality

---

## Timeout Handling

### AI Generation Timeout:
- **Timeout:** 30 seconds via `withTimeout(seconds: 30)`
- **Operation:** Wraps `generateAndSaveFollowUpQuestionAIResponse()`
- **Error:** Throws `TimeoutError` if operation exceeds 30 seconds
- **UI:** Shows error message to user

---

## Complete Function Execution Order (Detailed)

### Step-by-Step Flow:

1. **User Input:**
   - User types in follow-up question text field
   - `followUpJournalResponse` state variable updates
   - `updateFollowUpTextEditorHeight()` called automatically

2. **Done Button Clicked:**
   - `followUpDoneButtonTapped()` called
   - Updates UI state flags
   - Performs haptic feedback
   - Calls `createFollowUpQuestionJournalEntry(content:)` asynchronously

3. **Create Entry:**
   - `createFollowUpQuestionJournalEntry(content:)` creates entry object
   - Entry includes `fuqAiResponse = currentFollowUpQuestion`
   - Calls `supabaseService.createJournalEntry(entry)`
   - Calls `loadFollowUpQuestionEntries()` to refresh

4. **Centered Button Clicked:**
   - `followUpCenteredButtonTapped()` called
   - Validates `!followUpIsGeneratingAI`
   - Updates UI state flags
   - Performs haptic feedback
   - Calls `generateAndSaveFollowUpAIPrompt()` asynchronously

5. **Create AI Prompt:**
   - `generateAndSaveFollowUpAIPrompt()` called
   - Gets `currentFollowUpQuestion` from `journalViewModel`
   - Calls `createFollowUpAIPromptText(content:fuqAiResponse:)`
   - Replaces placeholders in template
   - Returns complete prompt string

6. **Update Entry with Prompt:**
   - `updateCurrentFollowUpQuestionJournalEntryWithAIPrompt(aiPrompt:)` called
   - Loads latest follow-up entries
   - Finds most recent entry (user's response entry)
   - Creates updated entry with `aiPrompt = aiPrompt`
   - Calls `supabaseService.updateJournalEntry(updatedEntry)`
   - Refreshes entries

7. **Generate AI Response:**
   - `generateAndSaveFollowUpQuestionAIResponse()` called
   - Loads latest follow-up entries
   - Gets `aiPrompt` from most recent entry
   - Calls `generateAIResponseWithRetry(for: aiPrompt)`

8. **Retry Logic:**
   - `generateAIResponseWithRetry()` called
   - Attempt 1: Sets `currentRetryAttempt = 1`, calls OpenAI API
   - If empty/whitespace response: Retries
   - If error: Waits 2s, attempts again
   - Attempt 2: Sets `currentRetryAttempt = 2`, calls OpenAI API
   - If error: Waits 4s, attempts again
   - Attempt 3: Sets `currentRetryAttempt = 3`, calls OpenAI API
   - Returns AI response string or throws error

9. **OpenAI API Call:**
   - `openAIService.generateAIResponse(for:)` called
   - Creates HTTP request with model, messages, parameters
   - Sends POST request to OpenAI API
   - Parses JSON response
   - Returns AI response string

10. **Update Entry with AI Response:**
    - `generateAndSaveFollowUpQuestionAIResponse()` continues
    - Creates updated entry with `aiResponse = aiResponse`
    - Calls `supabaseService.updateJournalEntry(updatedEntry)`
    - Refreshes entries

11. **Update UI:**
    - `updateFollowUpAIResponseDisplay()` called
    - Loads latest follow-up entries
    - Gets most recent entry with non-empty `aiResponse`
    - Sets `followUpCurrentAIResponse = aiResponse` on main thread
    - Calls `updateFollowUpTextEditorHeight()` to adjust UI

12. **Display AI Response:**
    - UI switches from text editor to ScrollView
    - Displays journal text + FUQ AI response
    - Scrolls to top
    - Shows favorite button after delay

---

## Notes

- The follow-up question text (`currentFollowUpQuestion`) is stored in the entry's `fuq_ai_response` field
- The user's response is stored in the entry's `content` field
- The AI prompt uses both the question and user's response in a therapist/client conversation format
- The FUQ AI response is stored in the entry's `ai_response` field
- All database operations preserve the `fuq_ai_response` field (the question itself)
- The entry type is always `"follow_up"` for follow-up question entries
- The entry is tagged with `["follow_up"]` for identification
- Retry logic is shared with guided/open questions
- Error handling is consistent across all entry types
- Loading states are tracked separately to prevent conflicts with other entry types

---

## Function Count Summary

### Total Functions Executed: 22+

1. `followUpDoneButtonTapped()` (ContentView)
2. `createFollowUpQuestionJournalEntry(content:)` (JournalViewModel)
3. `createJournalEntry(_:)` (SupabaseService)
4. `loadFollowUpQuestionEntries()` (JournalViewModel)
5. `fetchJournalEntries(userId:)` (SupabaseService)
6. `followUpCenteredButtonTapped()` (ContentView)
7. `generateAndSaveFollowUpAIPrompt()` (ContentView)
8. `createFollowUpAIPromptText(content:fuqAiResponse:)` (ContentView)
9. `updateCurrentFollowUpQuestionJournalEntryWithAIPrompt(aiPrompt:)` (JournalViewModel)
10. `loadFollowUpQuestionEntries()` (JournalViewModel) - Called again
11. `fetchJournalEntries(userId:)` (SupabaseService) - Called again
12. `updateJournalEntry(_:)` (SupabaseService) - Update with prompt
13. `generateAndSaveFollowUpQuestionAIResponse()` (JournalViewModel)
14. `loadFollowUpQuestionEntries()` (JournalViewModel) - Called again
15. `fetchJournalEntries(userId:)` (SupabaseService) - Called again
16. `generateAIResponseWithRetry(for:)` (JournalViewModel)
17. `generateAIResponse(for:)` (OpenAIService) - Up to 3 attempts
18. `updateJournalEntry(_:)` (SupabaseService) - Update with AI response
19. `loadFollowUpQuestionEntries()` (JournalViewModel) - Called again
20. `fetchJournalEntries(userId:)` (SupabaseService) - Called again
21. `updateFollowUpAIResponseDisplay()` (ContentView)
22. `loadFollowUpQuestionEntries()` (JournalViewModel) - Called again
23. `fetchJournalEntries(userId:)` (SupabaseService) - Called again
24. `updateFollowUpTextEditorHeight()` (ContentView)

---

## Performance Considerations

### Database Calls:
- `loadFollowUpQuestionEntries()` is called multiple times (after each database update)
- `fetchJournalEntries()` is called multiple times to refresh data
- Consider batching or caching to reduce database calls

### API Calls:
- OpenAI API is called with retry logic (up to 3 attempts)
- Each attempt includes delay (2s, 4s) for exponential backoff
- Total maximum time: ~30s (timeout) + retry delays (6s) = ~36s worst case

### UI Updates:
- Multiple `MainActor.run` blocks ensure UI updates on main thread
- State variables update separately for follow-up questions to prevent conflicts
- Loading overlay blocks interaction during generation



