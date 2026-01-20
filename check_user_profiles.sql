-- Check what's actually in user_profiles table
SELECT 'USER PROFILES:' as section, id, email, created_at FROM public.user_profiles;

-- Also check if there are any constraints or issues
SELECT 'TABLE INFO:' as section, COUNT(*) as count FROM public.user_profiles;
