-- Fix existing user profile conflicts
-- This script handles users that exist in auth but have profile issues

-- 1. First, let's see what users exist in auth.users
-- (You can run this to see the user ID for test.fresh@gmail.com)
SELECT id, email, created_at FROM auth.users WHERE email = 'test.fresh@gmail.com';

-- 2. If the user exists, let's manually create their profile
-- Replace 'USER_ID_HERE' with the actual UUID from step 1
-- Example: INSERT INTO public.user_profiles (id, email, display_name, current_streak, longest_streak, total_journal_entries, created_at)
-- VALUES ('12345678-1234-1234-1234-123456789012', 'test.fresh@gmail.com', 'test.fresh', 0, 0, 0, NOW())
-- ON CONFLICT (id) DO UPDATE SET
--   email = EXCLUDED.email,
--   display_name = EXCLUDED.display_name;

-- 3. Or we can use our helper function to create the profile
-- Replace 'USER_ID_HERE' with the actual UUID from step 1
-- SELECT public.create_user_profile_if_missing('USER_ID_HERE'::UUID, 'test.fresh@gmail.com');

-- 4. Verify the profile was created
SELECT id, email, display_name FROM public.user_profiles WHERE email = 'test.fresh@gmail.com';
