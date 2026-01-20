-- Complete Database Schema for Faith Check-in App
-- This script creates all necessary tables, policies, and functions
-- Run this in your Supabase SQL Editor after creating the project

-- ========================================
-- 1. USER PROFILES TABLE
-- ========================================
DROP TABLE IF EXISTS public.user_profiles CASCADE;

CREATE TABLE public.user_profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL,
    display_name TEXT,
    first_name TEXT,
    last_name TEXT,
    gender TEXT,
    occupation TEXT,
    birthdate TEXT,
    current_streak INTEGER DEFAULT 0,
    longest_streak INTEGER DEFAULT 0,
    total_journal_entries INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
DROP POLICY IF EXISTS "Users can view their own profile" ON public.user_profiles;
CREATE POLICY "Users can view their own profile" ON public.user_profiles
    FOR SELECT USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can insert their own profile" ON public.user_profiles;
CREATE POLICY "Users can insert their own profile" ON public.user_profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

DROP POLICY IF EXISTS "Users can update their own profile" ON public.user_profiles;
CREATE POLICY "Users can update their own profile" ON public.user_profiles
    FOR UPDATE USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can delete their own profile" ON public.user_profiles;
CREATE POLICY "Users can delete their own profile" ON public.user_profiles
    FOR DELETE USING (auth.uid() = id);

-- ========================================
-- 2. GUIDED QUESTIONS TABLE
-- ========================================
DROP TABLE IF EXISTS public.guided_questions CASCADE;

CREATE TABLE public.guided_questions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    question_text TEXT NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    order_index INTEGER,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS for guided_questions
ALTER TABLE public.guided_questions ENABLE ROW LEVEL SECURITY;

-- Create RLS policies (all authenticated users can read)
DROP POLICY IF EXISTS "Authenticated users can view guided questions" ON public.guided_questions;
CREATE POLICY "Authenticated users can view guided questions" ON public.guided_questions
    FOR SELECT USING (auth.role() = 'authenticated');

-- ========================================
-- 3. JOURNAL ENTRIES TABLE
-- ========================================
DROP TABLE IF EXISTS public.journal_entries CASCADE;

CREATE TABLE public.journal_entries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    guided_question_id UUID REFERENCES public.guided_questions(id) ON DELETE SET NULL,
    content TEXT NOT NULL,
    ai_prompt TEXT,
    ai_response TEXT,
    tags TEXT[] DEFAULT '{}',
    is_favorite BOOLEAN DEFAULT FALSE,
    entry_type TEXT NOT NULL CHECK (entry_type IN ('guided', 'open', 'follow_up')),
    fuq_ai_prompt TEXT,
    fuq_ai_response TEXT,
    is_follow_up_day BOOLEAN DEFAULT FALSE,
    used_for_follow_up BOOLEAN DEFAULT FALSE,
    follow_up_question TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS for journal_entries
ALTER TABLE public.journal_entries ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
DROP POLICY IF EXISTS "Users can view their own journal entries" ON public.journal_entries;
CREATE POLICY "Users can view their own journal entries" ON public.journal_entries
    FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert their own journal entries" ON public.journal_entries;
CREATE POLICY "Users can insert their own journal entries" ON public.journal_entries
    FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their own journal entries" ON public.journal_entries;
CREATE POLICY "Users can update their own journal entries" ON public.journal_entries
    FOR UPDATE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete their own journal entries" ON public.journal_entries;
CREATE POLICY "Users can delete their own journal entries" ON public.journal_entries
    FOR DELETE USING (auth.uid() = user_id);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_journal_entries_user_id ON public.journal_entries(user_id);
CREATE INDEX IF NOT EXISTS idx_journal_entries_created_at ON public.journal_entries(created_at);
CREATE INDEX IF NOT EXISTS idx_journal_entries_entry_type ON public.journal_entries(entry_type);

-- ========================================
-- 4. GOALS TABLE
-- ========================================
DROP TABLE IF EXISTS public.goals CASCADE;

CREATE TABLE public.goals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    goals TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS for goals
ALTER TABLE public.goals ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
DROP POLICY IF EXISTS "Users can view their own goals" ON public.goals;
CREATE POLICY "Users can view their own goals" ON public.goals
    FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert their own goals" ON public.goals;
CREATE POLICY "Users can insert their own goals" ON public.goals
    FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their own goals" ON public.goals;
CREATE POLICY "Users can update their own goals" ON public.goals
    FOR UPDATE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete their own goals" ON public.goals;
CREATE POLICY "Users can delete their own goals" ON public.goals
    FOR DELETE USING (auth.uid() = user_id);

-- Create index
CREATE INDEX IF NOT EXISTS idx_goals_user_id ON public.goals(user_id);

-- ========================================
-- 5. ANALYZER ENTRIES TABLE
-- ========================================
DROP TABLE IF EXISTS public.analyzer_entries CASCADE;

CREATE TABLE public.analyzer_entries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    analyzer_ai_prompt TEXT,
    analyzer_ai_response TEXT,
    entry_type TEXT NOT NULL CHECK (entry_type IN ('weekly', 'monthly')),
    tags TEXT[] DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ
);

-- Enable RLS for analyzer_entries
ALTER TABLE public.analyzer_entries ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
DROP POLICY IF EXISTS "Users can view their own analyzer entries" ON public.analyzer_entries;
CREATE POLICY "Users can view their own analyzer entries" ON public.analyzer_entries
    FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert their own analyzer entries" ON public.analyzer_entries;
CREATE POLICY "Users can insert their own analyzer entries" ON public.analyzer_entries
    FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their own analyzer entries" ON public.analyzer_entries;
CREATE POLICY "Users can update their own analyzer entries" ON public.analyzer_entries
    FOR UPDATE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete their own analyzer entries" ON public.analyzer_entries;
CREATE POLICY "Users can delete their own analyzer entries" ON public.analyzer_entries
    FOR DELETE USING (auth.uid() = user_id);

-- Create index
CREATE INDEX IF NOT EXISTS idx_analyzer_entries_user_id ON public.analyzer_entries(user_id);
CREATE INDEX IF NOT EXISTS idx_analyzer_entries_entry_type ON public.analyzer_entries(entry_type);

-- ========================================
-- 6. FOLLOW-UP GENERATION TABLE
-- ========================================
DROP TABLE IF EXISTS public.follow_up_generation CASCADE;

CREATE TABLE public.follow_up_generation (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    fuq_ai_prompt TEXT NOT NULL,
    fuq_ai_response TEXT NOT NULL,
    source_entry_id UUID REFERENCES public.journal_entries(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id)
);

-- Enable RLS for follow_up_generation
ALTER TABLE public.follow_up_generation ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
DROP POLICY IF EXISTS "Users can view their own follow-up generation" ON public.follow_up_generation;
CREATE POLICY "Users can view their own follow-up generation" ON public.follow_up_generation
    FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert their own follow-up generation" ON public.follow_up_generation;
CREATE POLICY "Users can insert their own follow-up generation" ON public.follow_up_generation
    FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their own follow-up generation" ON public.follow_up_generation;
CREATE POLICY "Users can update their own follow-up generation" ON public.follow_up_generation
    FOR UPDATE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete their own follow-up generation" ON public.follow_up_generation;
CREATE POLICY "Users can delete their own follow-up generation" ON public.follow_up_generation
    FOR DELETE USING (auth.uid() = user_id);

-- Create index
CREATE INDEX IF NOT EXISTS idx_follow_up_generation_user_id ON public.follow_up_generation(user_id);

-- ========================================
-- 7. HELPER FUNCTIONS
-- ========================================

-- Function to automatically create user profile on signup
DROP FUNCTION IF EXISTS public.handle_new_user() CASCADE;
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.user_profiles (id, email, created_at, updated_at)
    VALUES (
        NEW.id,
        NEW.email,
        NOW(),
        NOW()
    )
    ON CONFLICT (id) DO NOTHING;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger to automatically create user profile
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Function to update updated_at timestamp
DROP FUNCTION IF EXISTS public.update_updated_at_column() CASCADE;
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers to automatically update updated_at
DROP TRIGGER IF EXISTS update_user_profiles_updated_at ON public.user_profiles;
CREATE TRIGGER update_user_profiles_updated_at
    BEFORE UPDATE ON public.user_profiles
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS update_journal_entries_updated_at ON public.journal_entries;
CREATE TRIGGER update_journal_entries_updated_at
    BEFORE UPDATE ON public.journal_entries
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS update_goals_updated_at ON public.goals;
CREATE TRIGGER update_goals_updated_at
    BEFORE UPDATE ON public.goals
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS update_follow_up_generation_updated_at ON public.follow_up_generation;
CREATE TRIGGER update_follow_up_generation_updated_at
    BEFORE UPDATE ON public.follow_up_generation
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- ========================================
-- 8. VERIFICATION
-- ========================================
SELECT 'Faith Check-in database schema created successfully!' as status;
SELECT 'Tables created: user_profiles, guided_questions, journal_entries, goals, analyzer_entries, follow_up_generation' as tables_created;
