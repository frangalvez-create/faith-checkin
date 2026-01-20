-- Clean up authentication state after reverting to "Fixed goal persistence and UI details"
-- This script removes all existing users and related data to start fresh

-- Delete all user profiles first (to avoid foreign key constraints)
DELETE FROM user_profiles;

-- Delete all auth users
DELETE FROM auth.users;

-- Reset any sequences if needed
-- (Supabase usually handles this automatically, but just in case)

-- Verify cleanup
SELECT 'Auth users remaining: ' || COUNT(*) as auth_count FROM auth.users;
SELECT 'User profiles remaining: ' || COUNT(*) as profile_count FROM user_profiles;
