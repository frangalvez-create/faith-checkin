-- Check what's actually in the user_profiles table
SELECT 'USER PROFILES DETAILS:' as section, id, email, display_name, created_at FROM public.user_profiles ORDER BY created_at DESC;
