-- Fix journal_entries table to match app expectations
-- This will resolve the "Could not find the 'guided_question_id' column" error

-- Add missing columns to journal_entries table
ALTER TABLE journal_entries 
ADD COLUMN guided_question_id UUID REFERENCES guided_questions(id),
ADD COLUMN ai_prompt TEXT,
ADD COLUMN tags TEXT[] DEFAULT '{}';

-- Migrate existing data from question_id to guided_question_id
UPDATE journal_entries 
SET guided_question_id = question_id 
WHERE question_id IS NOT NULL;

-- Drop the old question_id column
ALTER TABLE journal_entries DROP COLUMN question_id;

-- Create index for better performance
CREATE INDEX idx_journal_entries_guided_question_id ON journal_entries(guided_question_id);
CREATE INDEX idx_journal_entries_user_id ON journal_entries(user_id);
CREATE INDEX idx_journal_entries_created_at ON journal_entries(created_at);

-- Success message
SELECT 'journal_entries table schema fixed successfully!' as status;
