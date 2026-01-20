-- Add column to track follow-up question usage
ALTER TABLE public.journal_entries ADD COLUMN IF NOT EXISTS used_for_follow_up BOOLEAN DEFAULT FALSE;

-- Add comment for documentation
COMMENT ON COLUMN public.journal_entries.used_for_follow_up IS 'Flag indicating if this entry has been used to generate a follow-up question';

-- Verify the change
SELECT column_name, data_type, is_nullable, column_default 
FROM information_schema.columns 
WHERE table_name = 'journal_entries' 
  AND column_name = 'used_for_follow_up';
