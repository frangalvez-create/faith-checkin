-- Complete fix for auto-profile creation trigger
-- This script will completely reset and fix the trigger system

-- Step 1: Clean up existing data to avoid conflicts
DELETE FROM public.user_profiles WHERE email LIKE '%working.new.test%' OR email LIKE '%test.fresh%';
DELETE FROM public.journal_entries WHERE user_id IN (
    SELECT id FROM auth.users WHERE email LIKE '%working.new.test%' OR email LIKE '%test.fresh%'
);

-- Step 2: Drop existing trigger and function
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user();

-- Step 3: Create improved function with better conflict handling
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    -- Insert with ON CONFLICT to handle any existing profiles gracefully
    INSERT INTO public.user_profiles (id, email, display_name, current_streak, longest_streak, total_journal_entries, created_at)
    VALUES (
        NEW.id, 
        NEW.email, 
        COALESCE(NEW.raw_user_meta_data->>'display_name', split_part(NEW.email, '@', 1)),
        0, 
        0, 
        0, 
        NOW()
    )
    ON CONFLICT (id) DO UPDATE SET
        email = EXCLUDED.email,
        display_name = COALESCE(EXCLUDED.display_name, user_profiles.display_name),
        updated_at = NOW();
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 4: Create the trigger
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Step 5: Verify the setup
SELECT 'Trigger setup complete' as status;
