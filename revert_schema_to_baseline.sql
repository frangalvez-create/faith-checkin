-- Revert Supabase Schema to Baseline State
-- This script removes all session management additions and reverts to the working OTP authentication state

-- 1. Drop the journal_sessions table (if it exists)
DROP TABLE IF EXISTS journal_sessions CASCADE;

-- 2. Remove columns added to journal_entries table
-- Remove entry_type column
ALTER TABLE journal_entries DROP COLUMN IF EXISTS entry_type;

-- Remove ai_prompt column  
ALTER TABLE journal_entries DROP COLUMN IF EXISTS ai_prompt;

-- Remove ai_response column
ALTER TABLE journal_entries DROP COLUMN IF EXISTS ai_response;

-- Remove tags column
ALTER TABLE journal_entries DROP COLUMN IF EXISTS tags;

-- Remove guided_question_id column
ALTER TABLE journal_entries DROP COLUMN IF EXISTS guided_question_id;

-- 3. Remove columns added to guided_questions table
-- Remove order_index column
ALTER TABLE guided_questions DROP COLUMN IF EXISTS order_index;

-- 4. Clean up any indexes that might have been created
DROP INDEX IF EXISTS idx_journal_entries_user_id;
DROP INDEX IF EXISTS idx_journal_entries_guided_question_id;
DROP INDEX IF EXISTS idx_journal_entries_entry_type;
DROP INDEX IF EXISTS idx_journal_sessions_user_id;
DROP INDEX IF EXISTS idx_journal_sessions_date;

-- 5. Verify the baseline schema
-- The baseline should have these core tables:
-- - auth.users (managed by Supabase Auth)
-- - guided_questions (with basic columns: id, question, created_at, updated_at)
-- - journal_entries (with basic columns: id, user_id, content, is_favorite, created_at, updated_at)
-- - goals (if it exists)

-- 6. Optional: If you want to completely reset journal_entries to minimal schema
-- (Only run this if you want to remove ALL data and start fresh)
-- TRUNCATE TABLE journal_entries;
-- ALTER TABLE journal_entries DROP COLUMN IF EXISTS user_id;
-- ALTER TABLE journal_entries DROP COLUMN IF EXISTS content;
-- ALTER TABLE journal_entries DROP COLUMN IF EXISTS is_favorite;
-- ALTER TABLE journal_entries DROP COLUMN IF EXISTS created_at;
-- ALTER TABLE journal_entries DROP COLUMN IF EXISTS updated_at;

-- Note: The baseline schema should match what was working with OTP authentication
-- before we added session management features.
