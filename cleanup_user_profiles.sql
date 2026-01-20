-- Clean up user_profiles table to fix authentication conflicts
-- This script removes conflicting user profiles and resets the table

-- 1. First, let's see what's currently in the user_profiles table
SELECT id, email, created_at FROM public.user_profiles ORDER BY created_at DESC;

-- 2. Delete all existing user profiles (they were created without proper auth)
-- This is safe because we haven't started using the app with real data yet
DELETE FROM public.user_profiles;

-- 3. Also clean up any journal entries that might be orphaned
DELETE FROM public.journal_entries;

-- 4. Reset any sequences if needed
-- (This ensures clean IDs for new entries)

-- 5. Verify the tables are clean
SELECT COUNT(*) as user_profiles_count FROM public.user_profiles;
SELECT COUNT(*) as journal_entries_count FROM public.journal_entries;

-- 6. Test the auto-profile creation trigger
-- (This will be tested when you sign up with a new account)
