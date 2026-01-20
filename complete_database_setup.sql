-- Complete database setup for Centered app
-- This script creates all necessary tables and fixes the user profile issue

-- ========================================
-- 1. CREATE USER PROFILES TABLE
-- ========================================

-- Drop the table if it exists (to start fresh)
DROP TABLE IF EXISTS user_profiles CASCADE;

-- Create the user_profiles table with the correct schema
CREATE TABLE user_profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL,
    full_name TEXT,
    avatar_url TEXT,
    goals TEXT[], -- Array of goal strings
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "Users can view their own profile" ON user_profiles
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can insert their own profile" ON user_profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update their own profile" ON user_profiles
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can delete their own profile" ON user_profiles
    FOR DELETE USING (auth.uid() = id);

-- ========================================
-- 2. CREATE JOURNAL ENTRIES TABLE
-- ========================================

DROP TABLE IF EXISTS journal_entries CASCADE;
CREATE TABLE journal_entries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    guided_question_id UUID,
    content TEXT NOT NULL,
    ai_prompt TEXT,
    ai_response TEXT,
    tags TEXT[],
    is_favorite BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS for journal_entries
ALTER TABLE journal_entries ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for journal_entries
CREATE POLICY "Users can view their own journal entries" ON journal_entries
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own journal entries" ON journal_entries
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own journal entries" ON journal_entries
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own journal entries" ON journal_entries
    FOR DELETE USING (auth.uid() = user_id);

-- ========================================
-- 3. CREATE GOALS TABLE
-- ========================================

DROP TABLE IF EXISTS goals CASCADE;
CREATE TABLE goals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    goals TEXT[] NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS for goals
ALTER TABLE goals ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for goals
CREATE POLICY "Users can view their own goals" ON goals
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own goals" ON goals
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own goals" ON goals
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own goals" ON goals
    FOR DELETE USING (auth.uid() = user_id);

-- ========================================
-- 4. CREATE GUIDED QUESTIONS TABLE
-- ========================================

DROP TABLE IF EXISTS guided_questions CASCADE;
CREATE TABLE guided_questions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    question TEXT NOT NULL,
    category TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insert some sample guided questions
INSERT INTO guided_questions (id, question, category, is_active) VALUES
    (gen_random_uuid(), 'What are three things you''re grateful for today?', 'gratitude', TRUE),
    (gen_random_uuid(), 'What was the most challenging part of your day?', 'reflection', TRUE),
    (gen_random_uuid(), 'What did you learn about yourself today?', 'self-discovery', TRUE),
    (gen_random_uuid(), 'How did you show kindness to others today?', 'kindness', TRUE),
    (gen_random_uuid(), 'What are you looking forward to tomorrow?', 'future', TRUE);

-- Enable RLS for guided_questions (read-only for all authenticated users)
ALTER TABLE guided_questions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "All authenticated users can view guided questions" ON guided_questions
    FOR SELECT USING (auth.role() = 'authenticated');

-- ========================================
-- 5. CREATE HELPER FUNCTIONS
-- ========================================

-- Create a function to automatically create user profile on signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.user_profiles (id, email, full_name, avatar_url, goals, created_at, updated_at)
    VALUES (
        NEW.id,
        NEW.email,
        NEW.raw_user_meta_data->>'full_name',
        NEW.raw_user_meta_data->>'avatar_url',
        ARRAY[]::TEXT[],
        NOW(),
        NOW()
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ========================================
-- 6. CREATE TRIGGERS
-- ========================================

-- Create trigger to automatically create user profile
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Create triggers to automatically update updated_at
CREATE TRIGGER update_user_profiles_updated_at
    BEFORE UPDATE ON user_profiles
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_journal_entries_updated_at
    BEFORE UPDATE ON journal_entries
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_goals_updated_at
    BEFORE UPDATE ON goals
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_guided_questions_updated_at
    BEFORE UPDATE ON guided_questions
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- ========================================
-- 7. MIGRATE EXISTING USERS
-- ========================================

-- Insert any existing users from auth.users who don't have profiles
INSERT INTO user_profiles (id, email, full_name, avatar_url, goals, created_at, updated_at)
SELECT 
    au.id,
    au.email,
    au.raw_user_meta_data->>'full_name',
    au.raw_user_meta_data->>'avatar_url',
    ARRAY[]::TEXT[],
    au.created_at,
    NOW()
FROM auth.users au
LEFT JOIN user_profiles up ON au.id = up.id
WHERE up.id IS NULL;

-- ========================================
-- 8. VERIFICATION
-- ========================================

-- Verify the tables were created correctly
SELECT 'Database setup completed successfully!' as status;

-- Show table counts
SELECT 
    'user_profiles' as table_name, 
    COUNT(*) as record_count 
FROM user_profiles
UNION ALL
SELECT 
    'journal_entries' as table_name, 
    COUNT(*) as record_count 
FROM journal_entries
UNION ALL
SELECT 
    'goals' as table_name, 
    COUNT(*) as record_count 
FROM goals
UNION ALL
SELECT 
    'guided_questions' as table_name, 
    COUNT(*) as record_count 
FROM guided_questions;
