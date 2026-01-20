-- Check existing users and their status
-- Run this first to see what users exist

-- Check auth.users
SELECT 
    id, 
    email, 
    email_confirmed_at, 
    created_at,
    CASE 
        WHEN email_confirmed_at IS NOT NULL THEN 'Confirmed'
        ELSE 'Unconfirmed'
    END as status
FROM auth.users 
ORDER BY created_at DESC;

-- Check user_profiles
SELECT 
    id, 
    email, 
    created_at
FROM user_profiles 
ORDER BY created_at DESC;

-- Check if frangalvez.premium@gmail.com exists anywhere
SELECT 'auth.users' as table_name, id, email, email_confirmed_at
FROM auth.users 
WHERE email = 'frangalvez.premium@gmail.com'

UNION ALL

SELECT 'user_profiles' as table_name, id, email, NULL as email_confirmed_at
FROM user_profiles 
WHERE email = 'frangalvez.premium@gmail.com';
