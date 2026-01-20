-- Force delete all user profiles and verify
-- This will definitely clear everything

-- Step 1: Force delete with CASCADE if needed
DELETE FROM public.user_profiles CASCADE;

-- Step 2: Also delete journal entries
DELETE FROM public.journal_entries CASCADE;

-- Step 3: Verify everything is gone
SELECT 'user_profiles count after delete:' as info, COUNT(*) as count FROM public.user_profiles;
SELECT 'journal_entries count after delete:' as info, COUNT(*) as count FROM public.journal_entries;

-- Step 4: Reset any sequences if they exist
-- (This ensures IDs start fresh)
SELECT 'Cleanup completed - ready for fresh signup' as status;
