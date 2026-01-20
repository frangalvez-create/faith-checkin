-- Complete trigger fix with better error handling
-- This will fix the trigger to handle conflicts properly

-- Step 1: Drop the existing trigger
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user();

-- Step 2: Create a new function that handles conflicts better
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Try to insert, but if it fails, just continue
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
        );
    EXCEPTION
        WHEN unique_violation THEN
            -- Profile already exists, that's fine
            RAISE NOTICE 'User profile already exists for: %', NEW.email;
        WHEN OTHERS THEN
            -- Any other error, log it but don't fail
            RAISE WARNING 'Failed to create user profile for %: %', NEW.email, SQLERRM;
    END;
    
    RETURN NEW;
END;
$$;

-- Step 3: Create the trigger
CREATE TRIGGER on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

SELECT 'Trigger fixed with better error handling' as status;
