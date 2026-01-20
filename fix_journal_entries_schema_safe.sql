-- Fix journal_entries table to match app expectations (SAFE VERSION)
-- This will resolve the "Could not find the 'guided_question_id' column" error

-- Add missing columns to journal_entries table (only if they don't exist)
DO $$ 
BEGIN
    -- Add guided_question_id column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'journal_entries' AND column_name = 'guided_question_id') THEN
        ALTER TABLE journal_entries 
        ADD COLUMN guided_question_id UUID REFERENCES guided_questions(id);
    END IF;
    
    -- Add ai_prompt column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'journal_entries' AND column_name = 'ai_prompt') THEN
        ALTER TABLE journal_entries 
        ADD COLUMN ai_prompt TEXT;
    END IF;
    
    -- Add tags column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'journal_entries' AND column_name = 'tags') THEN
        ALTER TABLE journal_entries 
        ADD COLUMN tags TEXT[] DEFAULT '{}';
    END IF;
END $$;

-- Migrate existing data from question_id to guided_question_id (if question_id exists)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.columns 
               WHERE table_name = 'journal_entries' AND column_name = 'question_id') THEN
        UPDATE journal_entries 
        SET guided_question_id = question_id 
        WHERE question_id IS NOT NULL AND guided_question_id IS NULL;
        
        -- Drop the old question_id column
        ALTER TABLE journal_entries DROP COLUMN question_id;
    END IF;
END $$;

-- Create indexes only if they don't exist
CREATE INDEX IF NOT EXISTS idx_journal_entries_guided_question_id ON journal_entries(guided_question_id);
CREATE INDEX IF NOT EXISTS idx_journal_entries_user_id ON journal_entries(user_id);
CREATE INDEX IF NOT EXISTS idx_journal_entries_created_at ON journal_entries(created_at);

-- Success message
SELECT 'journal_entries table schema fixed successfully!' as status;
