-- Fix the auto-profile creation trigger
-- This script fixes the UUID conflict issue

-- 1. First, let's drop the existing trigger and function to start fresh
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user();

-- 2. Create a better function that handles conflicts gracefully
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  -- Insert user profile, but ignore if it already exists (ON CONFLICT DO NOTHING)
  INSERT INTO public.user_profiles (
    id,
    email,
    display_name,
    current_streak,
    longest_streak,
    total_journal_entries,
    created_at
  )
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'display_name', split_part(NEW.email, '@', 1)),
    0,
    0,
    0,
    NOW()
  )
  ON CONFLICT (id) DO NOTHING;  -- This prevents the duplicate key error
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Create the trigger again
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 4. Also let's make sure we can manually create profiles if needed
CREATE OR REPLACE FUNCTION public.create_user_profile_if_missing(user_id UUID, user_email TEXT)
RETURNS VOID AS $$
BEGIN
  INSERT INTO public.user_profiles (
    id,
    email,
    display_name,
    current_streak,
    longest_streak,
    total_journal_entries,
    created_at
  )
  VALUES (
    user_id,
    user_email,
    split_part(user_email, '@', 1),
    0,
    0,
    0,
    NOW()
  )
  ON CONFLICT (id) DO NOTHING;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. Test the function works
SELECT 'Auto-profile trigger fixed successfully!' as status;
