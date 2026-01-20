-- Fix the entry_type constraint issue
-- The restored JournalEntry model doesn't have entry_type, but the database does

-- First, let's see the current constraints
SELECT conname, contype, pg_get_constraintdef(oid) 
FROM pg_constraint 
WHERE conrelid = 'journal_entries'::regclass;

-- Remove the NOT NULL constraint on entry_type
ALTER TABLE journal_entries ALTER COLUMN entry_type DROP NOT NULL;

-- Or better yet, remove the entry_type column entirely since the restored model doesn't use it
ALTER TABLE journal_entries DROP COLUMN IF EXISTS entry_type;

-- Also remove any check constraints related to entry_type
ALTER TABLE journal_entries DROP CONSTRAINT IF EXISTS journal_entries_entry_type_check;

SELECT 'Entry_type constraint removed successfully' as status;
