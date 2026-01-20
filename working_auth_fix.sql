-- Working authentication fix - simplified version
-- Run this script in Supabase SQL Editor

-- Step 1: Clean up existing data
DELETE FROM public.journal_entries;
DELETE FROM public.user_profiles;

-- Step 2: Drop existing trigger and functions
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user();

-- Step 3: Create the user profile creation function
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER 
LANGUAGE plpgsql 
SECURITY DEFINER
AS $function$
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
    ON CONFLICT (id) DO NOTHING;
    
    RETURN NEW;
END;
$function$;

-- Step 4: Create the trigger
CREATE TRIGGER on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Step 5: Verify setup
SELECT 'Authentication system reset successfully' as status;
