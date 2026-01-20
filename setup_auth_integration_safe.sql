-- Setup Supabase Auth Integration (Safe Version)
-- This script connects Supabase Auth to your user_profiles table

-- 1. Enable Row Level Security on all tables (safe to run multiple times)
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.journal_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.daily_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.goals ENABLE ROW LEVEL SECURITY;

-- 2. Drop existing policies first, then recreate them
DROP POLICY IF EXISTS "Users can view own profile" ON public.user_profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON public.user_profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON public.user_profiles;

CREATE POLICY "Users can view own profile" ON public.user_profiles
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON public.user_profiles
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" ON public.user_profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

-- 3. Journal entries policies
DROP POLICY IF EXISTS "Users can view own journal entries" ON public.journal_entries;
DROP POLICY IF EXISTS "Users can insert own journal entries" ON public.journal_entries;
DROP POLICY IF EXISTS "Users can update own journal entries" ON public.journal_entries;

CREATE POLICY "Users can view own journal entries" ON public.journal_entries
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own journal entries" ON public.journal_entries
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own journal entries" ON public.journal_entries
    FOR UPDATE USING (auth.uid() = user_id);

-- 4. Daily sessions policies
DROP POLICY IF EXISTS "Users can view own daily sessions" ON public.daily_sessions;
DROP POLICY IF EXISTS "Users can insert own daily sessions" ON public.daily_sessions;
DROP POLICY IF EXISTS "Users can update own daily sessions" ON public.daily_sessions;

CREATE POLICY "Users can view own daily sessions" ON public.daily_sessions
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own daily sessions" ON public.daily_sessions
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own daily sessions" ON public.daily_sessions
    FOR UPDATE USING (auth.uid() = user_id);

-- 5. Goals policies
DROP POLICY IF EXISTS "Users can view own goals" ON public.goals;
DROP POLICY IF EXISTS "Users can insert own goals" ON public.goals;
DROP POLICY IF EXISTS "Users can update own goals" ON public.goals;

CREATE POLICY "Users can view own goals" ON public.goals
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own goals" ON public.goals
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own goals" ON public.goals
    FOR UPDATE USING (auth.uid() = user_id);

-- 6. Create function to handle new user signup (safe to run multiple times)
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.user_profiles (id, email, created_at)
  VALUES (new.id, new.email, new.created_at);
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 7. Create trigger to automatically create profile on signup (safe to run multiple times)
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- 8. Create guided_questions table if it doesn't exist
CREATE TABLE IF NOT EXISTS public.guided_questions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    question_text TEXT NOT NULL,
    order_index INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 8a. Add unique constraint if it doesn't exist (safe to run multiple times)
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'guided_questions_question_text_key'
    ) THEN
        ALTER TABLE public.guided_questions ADD CONSTRAINT guided_questions_question_text_key UNIQUE (question_text);
    END IF;
END $$;

-- 9. Enable RLS on guided_questions
ALTER TABLE public.guided_questions ENABLE ROW LEVEL SECURITY;

-- 10. Create policy for guided_questions (everyone can read them)
DROP POLICY IF EXISTS "Anyone can view guided questions" ON public.guided_questions;
CREATE POLICY "Anyone can view guided questions" ON public.guided_questions
    FOR SELECT USING (true);

-- 11. Insert some default guided questions (safe to run multiple times)
INSERT INTO public.guided_questions (question_text, order_index, is_active) VALUES
('What are you grateful for today?', 1, true),
('What challenged you today and how did you handle it?', 2, true),
('What did you learn about yourself today?', 3, true),
('How did you show kindness to yourself or others today?', 4, true),
('What are you looking forward to tomorrow?', 5, true)
ON CONFLICT (question_text) DO NOTHING;

-- 12. Grant necessary permissions
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT ALL ON public.user_profiles TO anon, authenticated;
GRANT ALL ON public.journal_entries TO anon, authenticated;
GRANT ALL ON public.daily_sessions TO anon, authenticated;
GRANT ALL ON public.goals TO anon, authenticated;
GRANT SELECT ON public.guided_questions TO anon, authenticated;
