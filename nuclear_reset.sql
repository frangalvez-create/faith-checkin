-- Nuclear option: Complete reset
-- This will completely reset everything

-- Step 1: Disable trigger
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Step 2: Delete ALL data
DELETE FROM public.journal_entries;
DELETE FROM public.user_profiles;

-- Step 3: Verify it's empty
SELECT 'After cleanup - user_profiles count:' as info, COUNT(*) as count FROM public.user_profiles;

-- Step 4: Create simple trigger without complex logic
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    INSERT INTO public.user_profiles (id, email, display_name, current_streak, longest_streak, total_journal_entries, created_at)
    VALUES (NEW.id, NEW.email, split_part(NEW.email, '@', 1), 0, 0, 0, NOW())
    ON CONFLICT (id) DO NOTHING;
    RETURN NEW;
END;
$$;

-- Step 5: Recreate trigger
CREATE TRIGGER on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

SELECT 'Complete reset done' as status;
