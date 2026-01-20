# Follow-Up Day App Open Process

## Summary of Functions Executed When User Opens App on Follow-Up Day

This document details the complete sequence of functions and processes that execute when a user opens the app on a follow-up question day.

---

## Phase 1: App Launch & Authentication (`ContentView.onAppear`)

### 1.1 Root Content View Initialization
**Location**: `ContentView.swift` - `rootContent.onAppear` (line 99)

**Functions Executed**:
1. **`journalViewModel.checkAuthenticationStatus()`**
   - Checks for existing Supabase session
   - Loads user profile if authenticated
   - Detects user changes and clears UI state if different user
   - If authenticated, calls `loadInitialData()`

2. **`journalViewModel.loadInitialData()`**
   - Loads today's guided question (`loadTodaysQuestion()`)
   - Loads journal entries (`loadJournalEntries()`)
   - Loads open question entries (`loadOpenQuestionJournalEntries()`)
   - Loads analyzer entries (`loadAnalyzerEntries()`)
   - Loads goals (`loadGoals()`)
   - Triggers UI state population callback (`populateUIStateCallback`)

3. **Follow-Up Day Check**
   ```swift
   isFollowUpQuestionDay = journalViewModel.supabaseService.isFollowUpQuestionDay()
   ```
   - Uses reference date (Jan 1, 2024) to calculate if today is a follow-up day (every 3rd day)

4. **If Follow-Up Day**:
   - Calls `journalViewModel.checkAndLoadFollowUpQuestion()`

---

## Phase 2: Follow-Up Question Loading (`checkAndLoadFollowUpQuestion`)

### 2.1 Initial Check
**Location**: `JournalViewModel.swift` - `checkAndLoadFollowUpQuestion()` (line 1375)

**Process**:
1. **User Authentication Check**
   - Verifies `currentUser` exists
   - Returns early if not authenticated

2. **Follow-Up Day Verification**
   - Double-checks `supabaseService.isFollowUpQuestionDay()`
   - Clears `currentFollowUpQuestion` if not a follow-up day

3. **Retry Loop** (up to 3 attempts with 0.5s delays)

### 2.2 Step 1: Check for Today's User Reply
**Location**: `JournalViewModel.swift` - `checkAndLoadFollowUpQuestion()` (line 1398-1415)

**Functions Executed**:
1. **`loadFollowUpQuestionEntries()`**
   - Fetches all `journal_entries` from Supabase where `entry_type = "follow_up"`
   - Filters for entries created today
   - Filters for entries with non-empty `content` (user's reply)

2. **Check Today's Reply**
   - Looks for entry with `follow_up_question` field populated
   - If found: Sets `currentFollowUpQuestion = entry.followUpQuestion`
   - **Priority**: If user replied today, use the question they replied to (stored in `journal_entries.follow_up_question`)

### 2.3 Step 2: Check Pre-Generated Question
**Location**: `JournalViewModel.swift` - `checkAndLoadFollowUpQuestion()` (line 1417-1434)

**Functions Executed**:
1. **`supabaseService.fetchFollowUpGeneration(userId:)`**
   - Queries `follow_up_generation` table
   - Fetches the one row per user (UNIQUE constraint)
   - Returns `FollowUpGeneration` object with `fuq_ai_response`

2. **If Pre-Generated Question Found**:
   - Sets `currentFollowUpQuestion = generation.fuqAiResponse`
   - Uses the pre-generated question from `follow_up_generation` table

### 2.4 Step 3: Fallback Generation (if no question found)
**Location**: `JournalViewModel.swift` - `checkAndLoadFollowUpQuestion()` (line 1445-1460)

**Functions Executed** (only if no question found and `suppressErrors = false`):
1. **`preGenerateFollowUpQuestionIfNeeded()`**
   - Checks same-day generation (skip if generated today)
   - Checks last follow-up day (skip if generated after last follow-up day)
   - Checks 21-day age (generate new if >= 21 days old)
   - If checks pass, calls `generateFollowUpQuestionForPreGeneration()`

2. **`generateFollowUpQuestionForPreGeneration()`**
   - Selects past journal entry (`selectPastJournalEntryForFollowUp()`)
   - Generates AI prompt (`generateFollowUpQuestionPrompt()`)
   - Generates follow-up question via OpenAI (`generateAIResponseWithRetry()`)
   - Saves to `follow_up_generation` table (`createOrUpdateFollowUpGeneration()`)

3. **Retry Fetch**:
   - Fetches again after pre-generation
   - Sets `currentFollowUpQuestion` if found

---

## Phase 3: Journal View Initialization (`mainJournalView.onAppear`)

### 3.1 Data Reload Sequence
**Location**: `ContentView.swift` - `mainJournalView.onAppear` (line 1082)

**Functions Executed**:
1. **`reloadJournalDataSequence(suppressErrors: false)`**
   - **Step 1**: Clear UI state (`clearJournalUIState()`)
   - **Step 2**: Load today's question (`loadTodaysQuestion()`)
   - **Step 3**: Check and reset if needed (`checkAndResetIfNeeded()`)
   - **Step 4**: Determine follow-up day status
   - **Step 5**: Load journal data sets:
     - `loadJournalEntries()` - Guided question entries
     - `loadOpenQuestionJournalEntries()` - Open question entries
   - **Step 6**: Load follow-up question (if follow-up day):
     - `checkAndLoadFollowUpQuestion(suppressErrors: false)`
   - **Step 7**: Load goals (`loadGoals()`)
   - **Step 8**: Populate UI state (`populateUIStateFromJournalEntries()`)

### 3.2 UI State Population
**Location**: `ContentView.swift` - `populateUIStateFromJournalEntries()` (line 1644)

**Process**:
1. Finds today's guided entry and populates `journalResponse` and `currentAIResponse`
2. Finds today's open entry and populates `openJournalResponse` and `openCurrentAIResponse`
3. Finds today's follow-up entry and populates:
   - `followUpJournalResponse` - User's reply content
   - `followUpCurrentAIResponse` - AI response to user's reply
4. Loads goal text from most recent goal

---

## Phase 4: UI Display

### 4.1 Question Display Logic
**Location**: `ContentView.swift` - `mainJournalView` (line 545-562)

**Display Priority**:
1. **If Follow-Up Day + Question Found**:
   - Displays `journalViewModel.currentFollowUpQuestion` (color #5F4083)

2. **If Follow-Up Day + No Question Found**:
   - Displays "Generating a follow up question for you..." (italic, color #5F4083)

3. **Otherwise**:
   - Displays static open question: "Looking at today or yesterday, share moments or thoughts that stood out."

---

## Summary: Complete Function Call Sequence

### On App Open (Follow-Up Day):

1. `ContentView.onAppear` (Root Content View)
   - `checkAuthenticationStatus()`
     - `loadInitialData()`
       - `loadTodaysQuestion()`
       - `loadJournalEntries()`
       - `loadOpenQuestionJournalEntries()`
       - `loadAnalyzerEntries()`
       - `loadGoals()`
       - Triggers `populateUIStateCallback`
   - `supabaseService.isFollowUpQuestionDay()`
   - **If follow-up day**: `checkAndLoadFollowUpQuestion()` (First Call)

2. `checkAndLoadFollowUpQuestion()` (First Call)
   - `loadFollowUpQuestionEntries()`
   - Check today's reply entries for `follow_up_question`
   - **OR** `fetchFollowUpGeneration()` - Check pre-generated question
   - **OR** `preGenerateFollowUpQuestionIfNeeded()` (fallback) → `generateFollowUpQuestionForPreGeneration()`

3. `mainJournalView.onAppear`
   - `reloadJournalDataSequence()`
     - `clearJournalUIState()`
     - `loadTodaysQuestion()`
     - `checkAndResetIfNeeded()`
     - `loadJournalEntries()`
     - `loadOpenQuestionJournalEntries()`
     - **If follow-up day**: `checkAndLoadFollowUpQuestion()` (Second Call)
     - `loadGoals()`
     - `populateUIStateFromJournalEntries()`

### Key Data Sources (Priority Order):

1. **Today's User Reply** (`journal_entries.follow_up_question`)
   - If user replied to follow-up question today
   - Question stored when `createFollowUpQuestionJournalEntry()` was called

2. **Pre-Generated Question** (`follow_up_generation.fuq_ai_response`)
   - Pre-generated by triggers (Centered button, Analyze button, Follow-up Done button)
   - One row per user, updated/replaced on each generation

3. **Fallback Generation** (if neither found)
   - Generates on-demand as last resort
   - Saves to `follow_up_generation` table for future use

---

## Notes

- **Two Calls to `checkAndLoadFollowUpQuestion()`**: Once in root `onAppear` and once in `reloadJournalDataSequence()`. This ensures the question is available early and refreshed when the Journal view appears.

- **No 2AM Pre-Generation**: Pre-generation now happens via triggers (after user actions), not during the 2AM reset.

- **Display Logic**: The UI uses `journalViewModel.currentFollowUpQuestion` which is set by `checkAndLoadFollowUpQuestion()`. The display automatically updates based on what's found in the database.

