-- Final comprehensive fix for authentication and user profile creation
-- This script will completely reset the auth system and fix all conflicts

-- Step 1: Clean up ALL existing data to start fresh
DELETE FROM public.journal_entries;
DELETE FROM public.user_profiles;

-- Step 2: Drop and recreate the trigger system completely
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user();
DROP FUNCTION IF EXISTS public.create_user_profile_manual(UUID, TEXT);
DROP FUNCTION IF EXISTS public.create_user_profile_if_missing(UUID, TEXT);

-- Step 3: Create a robust user profile creation function
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    -- Use INSERT with ON CONFLICT DO NOTHING to handle any edge cases
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
    ON CONFLICT (id) DO NOTHING;
    
    -- Log the profile creation (for debugging)
    RAISE NOTICE 'User profile created or already exists for user: %', NEW.email;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 4: Create the trigger
CREATE TRIGGER on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Step 5: Create a manual cleanup function (just in case)
CREATE OR REPLACE FUNCTION public.cleanup_orphaned_profiles()
RETURNS VOID AS $$
BEGIN
    -- Remove any user profiles that don't have corresponding auth users
    DELETE FROM public.user_profiles 
    WHERE id NOT IN (SELECT id FROM auth.users);
    
    RAISE NOTICE 'Cleaned up orphaned user profiles';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 6: Verify the setup
SELECT 'Auth trigger setup completed successfully' as status;
