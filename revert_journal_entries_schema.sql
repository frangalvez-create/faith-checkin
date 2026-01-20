-- Update journal_entries table to match the restored Swift code
-- The restored JournalEntry model expects these columns:
-- id, user_id, guided_question_id, content, ai_prompt, ai_response, tags, is_favorite, created_at, updated_at

-- First, let's see what columns currently exist
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'journal_entries' 
ORDER BY ordinal_position;

-- Add missing columns that the restored JournalEntry model expects
ALTER TABLE journal_entries ADD COLUMN IF NOT EXISTS user_id UUID;
ALTER TABLE journal_entries ADD COLUMN IF NOT EXISTS guided_question_id UUID;
ALTER TABLE journal_entries ADD COLUMN IF NOT EXISTS tags TEXT[] DEFAULT '{}';
ALTER TABLE journal_entries ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

-- Update existing entries to have default values for new columns
UPDATE journal_entries 
SET 
    user_id = gen_random_uuid(),  -- Generate random UUID for existing entries
    tags = '{}',                  -- Empty array for tags
    updated_at = created_at       -- Set updated_at to created_at for existing entries
WHERE user_id IS NULL;

-- Make user_id NOT NULL after setting default values
ALTER TABLE journal_entries ALTER COLUMN user_id SET NOT NULL;

SELECT 'Journal entries table updated successfully' as status;
