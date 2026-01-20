-- Simple authentication fix
DELETE FROM public.journal_entries;
DELETE FROM public.user_profiles;
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user();

CREATE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS '
BEGIN
    INSERT INTO public.user_profiles (id, email, display_name, current_streak, longest_streak, total_journal_entries, created_at)
    VALUES (NEW.id, NEW.email, split_part(NEW.email, ''@'', 1), 0, 0, 0, NOW())
    ON CONFLICT (id) DO NOTHING;
    RETURN NEW;
END;
' LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

SELECT 'Setup complete' as status;
