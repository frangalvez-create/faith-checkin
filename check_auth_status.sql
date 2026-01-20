-- Check current auth and user profile status
-- Run this to see what users exist and identify conflicts

-- 1. Check auth.users table
SELECT 'AUTH USERS:' as section;
SELECT id, email, created_at, email_confirmed_at 
FROM auth.users 
ORDER BY created_at DESC;

-- 2. Check user_profiles table
SELECT 'USER PROFILES:' as section;
SELECT id, email, display_name, created_at 
FROM public.user_profiles 
ORDER BY created_at DESC;

-- 3. Check for mismatches
SELECT 'MISMATCHES:' as section;
SELECT 
    'Auth user without profile' as issue,
    au.id,
    au.email
FROM auth.users au
LEFT JOIN public.user_profiles up ON au.id = up.id
WHERE up.id IS NULL

UNION ALL

SELECT 
    'Profile without auth user' as issue,
    up.id,
    up.email
FROM public.user_profiles up
LEFT JOIN auth.users au ON up.id = au.id
WHERE au.id IS NULL;

-- 4. Count totals
SELECT 
    (SELECT COUNT(*) FROM auth.users) as auth_users_count,
    (SELECT COUNT(*) FROM public.user_profiles) as user_profiles_count;
