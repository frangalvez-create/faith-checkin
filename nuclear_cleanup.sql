-- Nuclear cleanup - this will completely reset everything
-- IMPORTANT: This will delete ALL users and data

-- Step 1: Disable the trigger temporarily
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Step 2: Delete all data
DELETE FROM public.journal_entries;
DELETE FROM public.user_profiles;

-- Step 3: Delete ALL auth users (this is the key step)
-- Note: You need to do this in the Authentication tab of Supabase Dashboard
-- OR run this if you have the right permissions:
-- DELETE FROM auth.users;

-- Step 4: Recreate the trigger with better error handling
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
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
        NEW.id, 
        NEW.email, 
        split_part(NEW.email, '@', 1), 
        0, 
        0, 
        0, 
        NOW()
    )
    ON CONFLICT (id) DO UPDATE SET
        email = EXCLUDED.email,
        display_name = EXCLUDED.display_name;
    
    RETURN NEW;
EXCEPTION
    WHEN OTHERS THEN
        -- Log the error but don't fail the user creation
        RAISE WARNING 'Failed to create user profile for %: %', NEW.email, SQLERRM;
        RETURN NEW;
END;
$$;

-- Step 5: Recreate the trigger
CREATE TRIGGER on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

SELECT 'Nuclear cleanup completed' as status;
