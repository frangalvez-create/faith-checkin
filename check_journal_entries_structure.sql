-- Check current journal_entries table structure
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'journal_entries' 
AND table_schema = 'public'
ORDER BY ordinal_position;
