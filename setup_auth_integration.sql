-- Setup Supabase Auth Integration
-- This script connects Supabase Auth to your user_profiles table

-- 1. Enable Row Level Security on all tables
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.journal_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.daily_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.goals ENABLE ROW LEVEL SECURITY;

-- 2. Create RLS policies for user_profiles
CREATE POLICY "Users can view own profile" ON public.user_profiles
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON public.user_profiles
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" ON public.user_profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

-- 3. Create RLS policies for journal_entries
CREATE POLICY "Users can view own journal entries" ON public.journal_entries
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own journal entries" ON public.journal_entries
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own journal entries" ON public.journal_entries
    FOR UPDATE USING (auth.uid() = user_id);

-- 4. Create RLS policies for daily_sessions
CREATE POLICY "Users can view own daily sessions" ON public.daily_sessions
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own daily sessions" ON public.daily_sessions
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own daily sessions" ON public.daily_sessions
    FOR UPDATE USING (auth.uid() = user_id);

-- 5. Create RLS policies for goals
CREATE POLICY "Users can view own goals" ON public.goals
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own goals" ON public.goals
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own goals" ON public.goals
    FOR UPDATE USING (auth.uid() = user_id);

-- 6. Create function to handle new user signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.user_profiles (id, email, created_at)
  VALUES (new.id, new.email, new.created_at);
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 7. Create trigger to automatically create profile on signup
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- 8. Create guided_questions table if it doesn't exist
CREATE TABLE IF NOT EXISTS public.guided_questions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    question_text TEXT NOT NULL,
    category TEXT,
    order_index INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 9. Insert some default guided questions
INSERT INTO public.guided_questions (question_text, category, order_index, is_active) VALUES
('What are you grateful for today?', 'gratitude', 1, true),
('What challenged you today and how did you handle it?', 'reflection', 2, true),
('What did you learn about yourself today?', 'self-discovery', 3, true),
('How did you show kindness to yourself or others today?', 'kindness', 4, true),
('What are you looking forward to tomorrow?', 'future', 5, true)
ON CONFLICT DO NOTHING;

-- 10. Grant necessary permissions
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT ALL ON public.user_profiles TO anon, authenticated;
GRANT ALL ON public.journal_entries TO anon, authenticated;
GRANT ALL ON public.daily_sessions TO anon, authenticated;
GRANT ALL ON public.goals TO anon, authenticated;
GRANT ALL ON public.guided_questions TO anon, authenticated;
