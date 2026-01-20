-- Debug current database state
-- Run this to see what's actually in the database right now

SELECT 'AUTH USERS COUNT:' as info, COUNT(*) as count FROM auth.users
UNION ALL
SELECT 'USER PROFILES COUNT:' as info, COUNT(*) as count FROM public.user_profiles
UNION ALL
SELECT 'JOURNAL ENTRIES COUNT:' as info, COUNT(*) as count FROM public.journal_entries;

-- Show actual auth users
SELECT 'AUTH USERS:' as section, id, email, created_at FROM auth.users;

-- Show actual user profiles  
SELECT 'USER PROFILES:' as section, id, email, created_at FROM public.user_profiles;
