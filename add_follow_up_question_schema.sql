-- Add Follow-Up Question Feature to journal_entries table
-- This adds the necessary columns for the follow-up question functionality

-- Add new columns for Follow-Up Question feature
ALTER TABLE public.journal_entries ADD COLUMN IF NOT EXISTS fuq_ai_prompt TEXT;
ALTER TABLE public.journal_entries ADD COLUMN IF NOT EXISTS fuq_ai_response TEXT;
ALTER TABLE public.journal_entries ADD COLUMN IF NOT EXISTS is_follow_up_day BOOLEAN DEFAULT FALSE;

-- Add comments for documentation
COMMENT ON COLUMN public.journal_entries.fuq_ai_prompt IS 'AI prompt template for generating follow-up questions';
COMMENT ON COLUMN public.journal_entries.fuq_ai_response IS 'AI-generated follow-up question text';
COMMENT ON COLUMN public.journal_entries.is_follow_up_day IS 'Flag indicating if this entry was created on a follow-up question day';

-- Verify the changes
SELECT column_name, data_type, is_nullable, column_default 
FROM information_schema.columns 
WHERE table_name = 'journal_entries' 
  AND column_name IN ('fuq_ai_prompt', 'fuq_ai_response', 'is_follow_up_day')
ORDER BY column_name;
