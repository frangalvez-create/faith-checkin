-- STEP 3: Create the function (run this third)
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
    ON CONFLICT (id) DO NOTHING;
    
    RETURN NEW;
END;
$$;
