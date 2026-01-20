# Analyzer Button Click Process - Complete Function Flow

This document details all functions executed after the Analyze button is clicked in the Analyzer view, from button click to final UI display of analysis results.

---

## Overview
The Analyze button is available every Sunday at 2 AM. When clicked, it generates a weekly or monthly analysis of the user's journal entries, creates an AI prompt, generates an AI response, and displays the results in three sections: Mood Tracker, Statistics, and Summary.

---

## Phase 1: Button Click & Initial Setup

### 1.1 Analyze Button Tapped
**Location:** `ContentView.swift` - `analyzeButtonTapped()`
- Checks `!analyzerViewModel.isAnalyzing` to prevent multiple clicks
- Sets `analyzerViewModel.isAnalyzing = true`
- Sets `journalViewModel.currentRetryAttempt = 1`
- Calls `journalViewModel.determineAnalysisType()` to determine weekly or monthly
- Calls `journalViewModel.createAnalyzerEntry(analysisType:)` in Task

### 1.2 Determine Analysis Type
**Location:** `JournalViewModel.swift` - `determineAnalysisType(for:)`
- Checks if today is the last Sunday of the month
- If yes, returns `"monthly"`
- Otherwise, returns `"weekly"`

---

## Phase 2: Eligibility Check & Date Range Calculation

### 2.1 Create Analyzer Entry
**Location:** `JournalViewModel.swift` - `createAnalyzerEntry(analysisType:)`
- Sets `isLoading = true`
- Sets `errorMessage = nil`
- Sets `currentRetryAttempt = 1`

### 2.2 Calculate Date Range
**Location:** `SupabaseService.swift`

#### Weekly Analysis:
- `calculateDateRangeForWeeklyAnalysis(for:)`
  - Calculates previous Sunday to Saturday (7 days)
  - Returns `(start: Date, end: Date)`

#### Monthly Analysis:
- `calculateDateRangeForMonthlyAnalysis(for:)`
  - Calculates previous last Sunday of month to current last Saturday of month
  - Returns `(start: Date, end: Date)`

### 2.3 Check Eligibility
**Location:** `JournalViewModel.swift` - `checkAnalyzerEligibility(analysisType:startDate:endDate:)`
- Calls `supabaseService.fetchJournalEntriesForAnalyzer(startDate:endDate:)` to get entries in range
- Counts unique days with entries
- Determines minimum required:
  - Weekly: 2 days minimum
  - Monthly: 9 days minimum
- Returns `(isEligible: Bool, entryCount: Int, minimumRequired: Int)`

### 2.4 Eligibility Validation
**Location:** `JournalViewModel.swift` - `createAnalyzerEntry(analysisType:)`
- If `!eligibility.isEligible`:
  - Throws error with message:
    - Weekly: "Sorry, a minimum of \"two days\" of journal entries is needed to run the weekly analysis. Try again next week"
    - Monthly: "Sorry, a minimum of \"nine days\" of journal entries is needed to run the monthly analysis."
  - Error is caught in `analyzeButtonTapped()` and shows alert

---

## Phase 3: Fetch Journal Entries & Generate Prompt

### 3.1 Fetch Journal Entries for Analyzer
**Location:** `SupabaseService.swift` - `fetchJournalEntriesForAnalyzer(startDate:endDate:)`
- Fetches all journal entries within date range:
  - `entry.createdAt >= startDate && entry.createdAt <= endDate`
- Includes all entry types: guided, open, follow-up
- Returns `[JournalEntry]` sorted by creation date (newest first)

### 3.2 Combine Entry Content
**Location:** `JournalViewModel.swift` - `createAnalyzerEntry(analysisType:)`
- Combines all entry content:
  - `entries.map { $0.content }.joined(separator: "\n\n")`
- Creates single content string for AI analysis

### 3.3 Generate Analyzer Prompt
**Location:** `SupabaseService.swift`

#### Weekly Analysis:
- `generateWeeklyAnalyzerPrompt(content:)`
  - Uses weekly analyzer AI prompt template:
    ```
    Role: Mental health/Behavioral therapist.
    Task: Analyze and evaluate all the user's inputs from the last 7 days
    User Input: {content}
    Output: Create three paragraphs. The first paragraph, list the top three moods with number (#) of instances found in the user input analysis. Ex. "mood1(#), mood2(#), mood3(#)". Only display moods (#). Second paragraph, first bullet = summary of the inputs, second bullet = action the user can make to address input summary and goal for the next week. Tone = encouraging and supportive. Limit to 200 words. Last paragraph, evaluate the inputs and generate a "centered score" from 60 to 100. (60-70=professional therapy help may be needed, 70-80=normal but needs improvement, 80-90=normal human emotions, 90-100=well balanced mental health). Only display score number.
    ```
  - Replaces `{content}` with combined journal entries
  - Returns prompt string

#### Monthly Analysis:
- `generateMonthlyAnalyzerPrompt(content:)`
  - Uses monthly analyzer AI prompt template:
    ```
    Role: Mental health/Behavioral therapist.
    Task: Analyze and evaluate all the user's inputs from the last month
    User Input: {content}
    Output: Create three paragraphs. The first paragraph, list the top five moods with number (#) of instances found in the user input analysis. Ex. "mood1(#), mood2(#), mood3(#), mood4(#), mood5(#)". Only display moods (#). Second paragraph, first bullet = summary of the inputs, second bullet = action the user can make to address input summary and goal for the next week. Tone = encouraging and supportive. Limit to 200 words. Last paragraph, evaluate the inputs and generate a "centered score" from 60 to 100. (60-70=professional therapy help may be needed, 70-80=normal but needs improvement, 80-90=normal human emotions, 90-100=well balanced mental health). Only display score number.
    ```
  - Replaces `{content}` with combined journal entries
  - Returns prompt string

---

## Phase 4: Create Analyzer Entry in Database

### 4.1 Create Analyzer Entry Object
**Location:** `JournalViewModel.swift` - `createAnalyzerEntry(analysisType:)`
- Creates `AnalyzerEntry` with:
  - `userId = user.id`
  - `analyzerAiPrompt = analyzerPrompt`
  - `analyzerAiResponse = nil` (will be filled after AI generation)
  - `entryType = analysisType` ("weekly" or "monthly")
  - `tags = []`
  - `createdAt = Date()`
  - `updatedAt = nil`

### 4.2 Save to Database
**Location:** `SupabaseService.swift` - `createAnalyzerEntry(_:)`
- Inserts entry into `analyzer_entries` table
- Returns created entry with generated `id`

---

## Phase 5: Generate AI Response

### 5.1 Generate AI Response with Retry
**Location:** `JournalViewModel.swift` - `generateAIResponseWithRetry(for:)`
- **Retry Logic:** 3 attempts with exponential backoff
- **Attempt 1:** Sets `currentRetryAttempt = 1` → Shows "Analyzing..."
- **Attempt 2:** Sets `currentRetryAttempt = 2` → Shows "Retrying..." (2s delay)
- **Attempt 3:** Sets `currentRetryAttempt = 3` → Shows "Retrying again..." (4s delay)
- **Empty Response Check:** Validates response is not empty/whitespace-only
- **Error Handling:**
  - Non-retryable errors (invalid API key, quota exceeded): throws immediately
  - Other errors: retries up to 3 times
- **Success:** Returns AI response string
- **Failure:** Throws error with last error message

### 5.2 OpenAI API Call
**Location:** `OpenAIService.swift` - `generateAIResponse(for:)`
- **Create Request:**
  - Model: `gpt-5-mini`
  - System message: "You are an AI Behavioral Therapist/Scientist..."
  - User message: The analyzer AI prompt
  - Parameters: `max_completion_tokens: 500`, `reasoning_effort: "low"`, `verbosity: "medium"`
- **Send Request:**
  - POST to `https://api.openai.com/v1/chat/completions`
  - Authorization: Bearer token
  - Content-Type: application/json
- **Handle Response:**
  - Checks HTTP status code (200 = success)
  - Parses JSON response
  - Extracts content from `choices[0].message.content`
  - Returns AI response string
- **Error Handling:**
  - 429: Rate limited or quota exceeded
  - 401: Invalid API key
  - Other: API error with status code
  - Network errors: Wrapped in OpenAIError

### 5.3 Update Entry with AI Response
**Location:** `JournalViewModel.swift` - `createAnalyzerEntry(analysisType:)`
- Creates updated `AnalyzerEntry` with:
  - `id = createdEntry.id`
  - `analyzerAiResponse = aiResponse`
  - `updatedAt = Date()`
- Calls `supabaseService.updateAnalyzerEntry(updatedEntry)` to save

### 5.4 Update Database
**Location:** `SupabaseService.swift` - `updateAnalyzerEntry(_:)`
- Updates `analyzer_entries` table
- Sets `analyzer_ai_response = aiResponse`
- Updates `updated_at` timestamp
- Returns updated entry

---

## Phase 6: Reload & Recalculate State

### 6.1 Reload Analyzer Entries
**Location:** `JournalViewModel.swift` - `loadAnalyzerEntries()`
- Calls `supabaseService.fetchAnalyzerEntries()` to get all analyzer entries
- Updates `analyzerEntries` array
- Handles cancelled requests gracefully

### 6.2 Recalculate Analyzer State
**Location:** `ContentView.swift` - `recalculateAnalyzerState()`
- Calls `analyzerViewModel.update(with: journalViewModel.analyzerEntries)`
- Calls `analyzerViewModel.computeDisplayData(for:)` to get date range
- Calls `analyzerViewModel.refreshDateRangeDisplay(referenceDate:)` to update date range text
- Calls `journalViewModel.calculateAnalyzerStats(startDate:endDate:)` to calculate statistics
- Calls `analyzerViewModel.refreshStats(using:)` to update statistics
- Calls `analyzerViewModel.determineAnalysisAvailability()` to update button state

### 6.3 Update Analyzer ViewModel
**Location:** `AnalyzerViewModel.swift` - `update(with:)`
- Finds latest entry: `entries.sorted { $0.createdAt > $1.createdAt }.first`
- Sets `latestEntry = latestEntry`
- Determines mode: `"monthly"` or `"weekly"`
- If `analyzerAiResponse` exists:
  - Calls `parseMoodCounts(from:)` to extract mood data
  - Calls `parseCenteredScore(from:)` to extract centered score
  - Calls `parseSummaryText(from:)` to extract summary text
- Otherwise, clears all data

### 6.4 Parse AI Response Data
**Location:** `AnalyzerViewModel.swift`

#### Parse Mood Counts:
- `parseMoodCounts(from:)`
  - Extracts first paragraph from AI response
  - Parses format: `"mood1(#), mood2(#), mood3(#)"` (weekly) or `"mood1(#), mood2(#), mood3(#), mood4(#), mood5(#)"` (monthly)
  - Creates `MoodCount` objects with `order`, `mood`, `count`
  - Returns `[MoodCount]` array

#### Parse Centered Score:
- `parseCenteredScore(from:)`
  - Extracts last paragraph from AI response
  - Finds last 2 digits (the score number)
  - Returns `Int?` (score from 60-100)

#### Parse Summary Text:
- `parseSummaryText(from:)`
  - Extracts second paragraph from AI response
  - Returns `String?` (summary with bullet points)

### 6.5 Compute Display Data
**Location:** `AnalyzerViewModel.swift` - `computeDisplayData(for:mode:)`
- Calculates date range based on mode:
  - Weekly: Previous Sunday to Saturday
  - Monthly: Previous last Sunday of month to current last Saturday of month
- Formats date range text:
  - Weekly: "Oct 26 to Nov 1st"
  - Monthly: "Oct Month"
- Returns `AnalyzerDisplayData` with date range and dates

### 6.6 Refresh Date Range Display
**Location:** `AnalyzerViewModel.swift` - `refreshDateRangeDisplay(referenceDate:)`
- Calls `computeDisplayData(for:)` to get display data
- Sets `dateRangeDisplay = displayData.dateRangeText`

### 6.7 Calculate Analyzer Statistics
**Location:** `JournalViewModel.swift` - `calculateAnalyzerStats(startDate:endDate:)`
- Combines all entries: `journalEntries + openQuestionJournalEntries + followUpQuestionEntries`
- Filters entries within date range
- **Calculate # Logs:**
  - Counts unique days with entries
  - Returns `logsCount = uniqueDays.count`
- **Calculate Log Streak:**
  - Calculates consecutive days with entries from `endDate` backwards
  - Returns `streakCount`
- **Calculate Fav Log Time:**
  - Categorizes entries by time of day:
    - Early Morning: 2-7 AM
    - Morning: 7-10 AM
    - Mid Day: 10 AM-2 PM
    - Afternoon: 2-5 PM
    - Evening: 5-9 PM
    - Late Evening: 9 PM-2 AM
  - Finds category with most entries
  - Returns `favoriteLogTime`
- Returns `AnalyzerStats(logsCount:streakCount:favoriteLogTime:)`

### 6.8 Refresh Statistics
**Location:** `AnalyzerViewModel.swift` - `refreshStats(using:)`
- Sets `logsCount = stats.logsCount`
- Sets `streakDuringRange = stats.streakCount`
- Sets `favoriteLogTime = stats.favoriteLogTime`

### 6.9 Determine Analysis Availability
**Location:** `AnalyzerViewModel.swift` - `determineAnalysisAvailability(for:)`
- Checks if today is Sunday (weekday == 1)
- If not Sunday: Sets `isAnalyzeButtonEnabled = false`
- If Sunday:
  - Checks if analysis already exists for today
  - If exists: Sets `isAnalyzeButtonEnabled = false`
  - If not exists: Sets `isAnalyzeButtonEnabled = true`

---

## Phase 7: UI Display Update

### 7.1 Update UI State
**Location:** `ContentView.swift` - `analyzeButtonTapped()`
- After successful completion:
  - Sets `analyzerViewModel.isAnalyzing = false`
  - Button changes from "Analyze Button Click.png" (greyed out) back to "Analyze Button.png" (active)
  - Shows "New analysis available next Sunday morning" text below button

### 7.2 Display Analysis Results
**Location:** `ContentView.swift` - `analyzerPageView`

#### Date Range Display:
- Displays `analyzerViewModel.dateRangeDisplay`
- Format: "Oct 26 to Nov 1st" (weekly) or "Oct Month" (monthly)
- Lines on either side

#### Mood Tracker Section:
- Displays `analyzerViewModel.moodCounts`
- Creates bar chart with:
  - Moods on x-axis
  - Counts on y-axis (dynamic max units)
  - Bar colors: Mood 1-5 with specified colors
- Empty state if no data

#### Statistics Section:
- Displays four metric cards:
  - **# Logs:** `analyzerViewModel.logsCount`
  - **Streak:** `analyzerViewModel.streakDuringRange` days
  - **Fav Log Time:** `analyzerViewModel.favoriteLogTime`
  - **Centered Score:** `analyzerViewModel.centeredScore`
- Empty state shows "0" for null values

#### Summary Section:
- Displays `analyzerViewModel.summaryText`
- Formats with paragraph breaks between bullet points
- Empty state if no data

---

## Phase 8: Error Handling

### 8.1 Minimum Entries Error
**Location:** `ContentView.swift` - `analyzeButtonTapped()`
- If error contains "minimum":
  - Sets `analyzerViewModel.showMinimumEntriesAlert = true`
  - Sets `analyzerViewModel.minimumEntriesMessage = error.localizedDescription`
  - Shows alert popup with error message
  - Sets `analyzerViewModel.isAnalyzing = false`

### 8.2 AI Generation Error
**Location:** `ContentView.swift` - `analyzeButtonTapped()`
- If AI generation fails:
  - Sets `analyzerViewModel.isAnalyzing = false`
  - Error message already set in `JournalViewModel.errorMessage`
  - Shows "Oops" alert with message: "The AI's taking a short break 😅 please try again shortly."

### 8.3 Loading Overlay
**Location:** `ContentView.swift` - `analyzerPageView.overlay`
- Shows overlay when `analyzerViewModel.isAnalyzing = true`
- Displays `ProgressView` and text:
  - Attempt 1: "Analyzing..."
  - Attempt 2: "Retrying..."
  - Attempt 3: "Retrying again..."
- Blocks user interaction: `allowsHitTesting(true)`

---

## Complete Function Execution Order

1. `analyzeButtonTapped()` (ContentView)
2. `determineAnalysisType()` (JournalViewModel)
3. `createAnalyzerEntry(analysisType:)` (JournalViewModel)
4. `calculateDateRangeForWeeklyAnalysis()` OR `calculateDateRangeForMonthlyAnalysis()` (SupabaseService)
5. `checkAnalyzerEligibility(analysisType:startDate:endDate:)` (JournalViewModel)
6. `fetchJournalEntriesForAnalyzer(startDate:endDate:)` (SupabaseService)
7. `generateWeeklyAnalyzerPrompt(content:)` OR `generateMonthlyAnalyzerPrompt(content:)` (SupabaseService)
8. `createAnalyzerEntry(_:)` (SupabaseService) - Save entry with prompt
9. `generateAIResponseWithRetry(for:)` (JournalViewModel)
10. `generateAIResponse(for:)` (OpenAIService) - Up to 3 attempts
11. `updateAnalyzerEntry(_:)` (SupabaseService) - Save entry with AI response
12. `loadAnalyzerEntries()` (JournalViewModel)
13. `recalculateAnalyzerState()` (ContentView)
14. `update(with:)` (AnalyzerViewModel)
15. `parseMoodCounts(from:)` (AnalyzerViewModel)
16. `parseCenteredScore(from:)` (AnalyzerViewModel)
17. `parseSummaryText(from:)` (AnalyzerViewModel)
18. `computeDisplayData(for:)` (AnalyzerViewModel)
19. `refreshDateRangeDisplay(referenceDate:)` (AnalyzerViewModel)
20. `calculateAnalyzerStats(startDate:endDate:)` (JournalViewModel)
21. `refreshStats(using:)` (AnalyzerViewModel)
22. `determineAnalysisAvailability(for:)` (AnalyzerViewModel)
23. Set `analyzerViewModel.isAnalyzing = false` (ContentView)
24. Display analysis results in UI

---

## Key Database Operations

### SupabaseService Functions:
1. `calculateDateRangeForWeeklyAnalysis(for:)` - Calculates weekly date range
2. `calculateDateRangeForMonthlyAnalysis(for:)` - Calculates monthly date range
3. `fetchJournalEntriesForAnalyzer(startDate:endDate:)` - Fetches entries in date range
4. `generateWeeklyAnalyzerPrompt(content:)` - Creates weekly AI prompt
5. `generateMonthlyAnalyzerPrompt(content:)` - Creates monthly AI prompt
6. `createAnalyzerEntry(_:)` - Creates analyzer entry in database
7. `updateAnalyzerEntry(_:)` - Updates analyzer entry with AI response
8. `fetchAnalyzerEntries()` - Fetches all analyzer entries

### JournalViewModel Functions:
1. `determineAnalysisType(for:)` - Determines weekly or monthly
2. `createAnalyzerEntry(analysisType:)` - Orchestrates analyzer entry creation
3. `checkAnalyzerEligibility(analysisType:startDate:endDate:)` - Checks minimum entries
4. `generateAIResponseWithRetry(for:)` - Generates AI response with retry logic
5. `loadAnalyzerEntries()` - Loads analyzer entries from database
6. `calculateAnalyzerStats(startDate:endDate:)` - Calculates statistics (# Logs, Streak, Fav Log Time)

### AnalyzerViewModel Functions:
1. `update(with:)` - Updates view model with analyzer entries
2. `parseMoodCounts(from:)` - Parses mood data from AI response
3. `parseCenteredScore(from:)` - Parses centered score from AI response
4. `parseSummaryText(from:)` - Parses summary text from AI response
5. `computeDisplayData(for:mode:)` - Computes date range display data
6. `refreshDateRangeDisplay(referenceDate:)` - Updates date range text
7. `refreshStats(using:)` - Updates statistics properties
8. `determineAnalysisAvailability(for:)` - Determines if button should be enabled

### ContentView Functions:
1. `analyzeButtonTapped()` - Handles Analyze button click
2. `recalculateAnalyzerState()` - Recalculates all analyzer state
3. `getAnalyzerLoadingText()` - Returns loading text based on retry attempt

### OpenAIService Functions:
1. `generateAIResponse(for:)` - Makes API call to OpenAI
   - Creates request with model, messages, parameters
   - Sends POST request to OpenAI API
   - Parses JSON response
   - Returns AI response string
   - Handles errors (rate limit, quota, API key, network)

---

## State Variables

### AnalyzerViewModel:
- `isAnalyzing: Bool` - Whether analysis is in progress
- `isAnalyzeButtonEnabled: Bool` - Whether button is enabled
- `latestEntry: AnalyzerEntry?` - Most recent analyzer entry
- `mode: AnalyzerMode` - Weekly or monthly
- `dateRangeDisplay: String` - Formatted date range text
- `moodCounts: [MoodCount]` - Parsed mood data
- `logsCount: Int` - Number of unique days with entries
- `streakDuringRange: Int` - Consecutive days with entries
- `favoriteLogTime: String` - Most common time of day for entries
- `centeredScore: Int?` - Parsed centered score (60-100)
- `summaryText: String?` - Parsed summary text
- `showMinimumEntriesAlert: Bool` - Whether to show minimum entries alert
- `minimumEntriesMessage: String` - Minimum entries error message

### JournalViewModel:
- `currentRetryAttempt: Int` - Current retry attempt (1, 2, 3)
- `errorMessage: String?` - Error message to display
- `isLoading: Bool` - Whether data is loading
- `analyzerEntries: [AnalyzerEntry]` - All analyzer entries
- `journalEntries: [JournalEntry]` - Guided question entries
- `openQuestionJournalEntries: [JournalEntry]` - Open question entries
- `followUpQuestionEntries: [JournalEntry]` - Follow-up question entries

---

## AI Response Format

### Expected AI Response Structure:
1. **First Paragraph:** Mood counts
   - Weekly: `"mood1(#), mood2(#), mood3(#)"`
   - Monthly: `"mood1(#), mood2(#), mood3(#), mood4(#), mood5(#)"`
2. **Second Paragraph:** Summary
   - First bullet: Summary of inputs
   - Second bullet: Action items and goals
   - Tone: Encouraging and supportive
   - Limit: 200 words
3. **Last Paragraph:** Centered Score
   - Last 2 digits: Score from 60-100
   - Example: "Your centered score is 85" → Score: 85

---

## Error Handling

### Retry Logic:
- **3 Attempts:** Maximum 3 retries for AI generation
- **Delays:** 2s between attempt 1 and 2, 4s between attempt 2 and 3
- **Status Updates:** "Analyzing..." → "Retrying..." → "Retrying again..."
- **Empty Response Check:** Validates response is not empty/whitespace-only
- **Non-Retryable Errors:** Invalid API key, quota exceeded (throws immediately)

### Error Messages:
- **After 3 Failed Attempts:** "The AI's taking a short break 😅 please try again shortly."
- **Minimum Entries:** 
  - Weekly: "Sorry, a minimum of \"two days\" of journal entries is needed to run the weekly analysis. Try again next week"
  - Monthly: "Sorry, a minimum of \"nine days\" of journal entries is needed to run the monthly analysis."
- **Network Errors:** Wrapped in OpenAIError
- **API Errors:** HTTP status code and error message

### UI Error Handling:
- Loading overlay blocks user interaction during generation
- Button state prevents multiple clicks
- Error alerts shown after retries exhausted or eligibility check fails
- State reset on error (button state, loading flags)

---

## UI Display Flow

### Button States:
1. **Active State:** "Analyze Button.png" - Enabled on Sundays when no analysis exists
2. **Disabled State:** "Analyze Button Click.png" - Greyed out after analysis or on non-Sundays
3. **Analyzing State:** "Analyze Button Click.png" with ProgressView overlay

### Loading Overlay:
- **During Generation:** Shows overlay with ProgressView and status text
- **Status Text:** Based on `currentRetryAttempt`:
  - 1: "Analyzing..."
  - 2: "Retrying..."
  - 3: "Retrying again..."
- **Blocks Interaction:** `allowsHitTesting(true)` prevents user input
- **Auto-Hides:** Disappears when AI generation completes

### Analysis Display:
- **Date Range:** Displays formatted date range with divider lines
- **Mood Tracker:** Bar chart with moods and counts
- **Statistics:** Four metric cards with calculated values
- **Summary:** Formatted text with paragraph breaks
- **Button Text:** "New analysis available next Sunday morning" when disabled

---

## Database Schema

### analyzer_entries Table:
- `id: UUID` - Primary key
- `user_id: UUID` - User identifier
- `analyzer_ai_prompt: String?` - AI prompt (nullable)
- `analyzer_ai_response: String?` - AI-generated response (nullable)
- `entry_type: String` - Entry type ("weekly" or "monthly")
- `tags: [String]` - Tags (currently empty array)
- `created_at: Date` - Creation timestamp
- `updated_at: Date?` - Update timestamp (nullable)

---

## Key Differences: Weekly vs Monthly

### Weekly Analysis:
- **Date Range:** Previous Sunday to Saturday (7 days)
- **Minimum Entries:** 2 days
- **Mood Count:** Top 3 moods
- **Date Display:** "Oct 26 to Nov 1st"

### Monthly Analysis:
- **Date Range:** Previous last Sunday of month to current last Saturday of month
- **Minimum Entries:** 9 days
- **Mood Count:** Top 5 moods
- **Date Display:** "Oct Month"
- **Replaces:** Last weekly analysis if it exists

---

## Notes

- Analysis is only available on Sundays (weekday == 1)
- Button is disabled if analysis already exists for today
- Analysis data persists until a new analysis is run
- Statistics are calculated from all entry types (guided, open, follow-up)
- Streak is calculated backwards from end date
- Favorite log time uses 6 time categories
- Centered score is extracted from last 2 digits of AI response
- Summary text is extracted from second paragraph of AI response
- Mood counts are extracted from first paragraph of AI response
- All parsing handles missing or malformed data gracefully

