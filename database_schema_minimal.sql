-- Minimal Database Schema - Only create what doesn't exist
-- Run this if you get "already exists" errors

-- User Profiles Table (extends Supabase auth.users)
CREATE TABLE IF NOT EXISTS public.user_profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    display_name TEXT,
    email TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Progress & Insights
    current_streak INTEGER DEFAULT 0,
    longest_streak INTEGER DEFAULT 0,
    total_journal_entries INTEGER DEFAULT 0,
    last_journal_date DATE,
    
    -- Settings
    notification_enabled BOOLEAN DEFAULT true,
    notification_time TIME DEFAULT '09:00:00',
    timezone TEXT DEFAULT 'America/Los_Angeles',
    app_lock_enabled BOOLEAN DEFAULT false,
    biometric_enabled BOOLEAN DEFAULT false
);

-- Journal Entries Table (updated for authentication)
CREATE TABLE IF NOT EXISTS public.journal_entries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    ai_prompt TEXT,
    ai_response TEXT,
    entry_type TEXT NOT NULL CHECK (entry_type IN ('guided', 'open')),
    session_date DATE NOT NULL DEFAULT CURRENT_DATE,
    is_favorite BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Daily Sessions Table (tracks daily journaling sessions)
CREATE TABLE IF NOT EXISTS public.daily_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    session_date DATE NOT NULL DEFAULT CURRENT_DATE,
    guided_entries_count INTEGER DEFAULT 0,
    open_entries_count INTEGER DEFAULT 0,
    total_entries_count INTEGER DEFAULT 0,
    session_completed BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE(user_id, session_date)
);

-- Goals Table
CREATE TABLE IF NOT EXISTS public.goals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    target_date DATE,
    is_completed BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Guided Questions Table (for future use)
CREATE TABLE IF NOT EXISTS public.guided_questions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    question_text TEXT NOT NULL,
    category TEXT,
    order_index INTEGER,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_journal_entries_user_id ON journal_entries(user_id);
CREATE INDEX IF NOT EXISTS idx_journal_entries_session_date ON journal_entries(session_date);
CREATE INDEX IF NOT EXISTS idx_journal_entries_entry_type ON journal_entries(entry_type);
CREATE INDEX IF NOT EXISTS idx_journal_entries_is_favorite ON journal_entries(is_favorite);
CREATE INDEX IF NOT EXISTS idx_daily_sessions_user_id ON daily_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_daily_sessions_session_date ON daily_sessions(session_date);
CREATE INDEX IF NOT EXISTS idx_goals_user_id ON goals(user_id);

-- Enable Row Level Security (only if not already enabled)
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_tables 
        WHERE schemaname = 'public' 
        AND tablename = 'user_profiles' 
        AND rowsecurity = true
    ) THEN
        ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
    END IF;
END $$;

DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_tables 
        WHERE schemaname = 'public' 
        AND tablename = 'journal_entries' 
        AND rowsecurity = true
    ) THEN
        ALTER TABLE public.journal_entries ENABLE ROW LEVEL SECURITY;
    END IF;
END $$;

DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_tables 
        WHERE schemaname = 'public' 
        AND tablename = 'daily_sessions' 
        AND rowsecurity = true
    ) THEN
        ALTER TABLE public.daily_sessions ENABLE ROW LEVEL SECURITY;
    END IF;
END $$;

DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_tables 
        WHERE schemaname = 'public' 
        AND tablename = 'goals' 
        AND rowsecurity = true
    ) THEN
        ALTER TABLE public.goals ENABLE ROW LEVEL SECURITY;
    END IF;
END $$;

-- Create RLS policies (only if they don't exist)
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE schemaname = 'public' 
        AND tablename = 'user_profiles' 
        AND policyname = 'Users can view own profile'
    ) THEN
        CREATE POLICY "Users can view own profile" ON public.user_profiles
            FOR SELECT USING (auth.uid() = id);
    END IF;
END $$;

DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE schemaname = 'public' 
        AND tablename = 'user_profiles' 
        AND policyname = 'Users can update own profile'
    ) THEN
        CREATE POLICY "Users can update own profile" ON public.user_profiles
            FOR UPDATE USING (auth.uid() = id);
    END IF;
END $$;

DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE schemaname = 'public' 
        AND tablename = 'user_profiles' 
        AND policyname = 'Users can insert own profile'
    ) THEN
        CREATE POLICY "Users can insert own profile" ON public.user_profiles
            FOR INSERT WITH CHECK (auth.uid() = id);
    END IF;
END $$;

-- Journal entries policies
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE schemaname = 'public' 
        AND tablename = 'journal_entries' 
        AND policyname = 'Users can view own journal entries'
    ) THEN
        CREATE POLICY "Users can view own journal entries" ON public.journal_entries
            FOR SELECT USING (auth.uid() = user_id);
    END IF;
END $$;

DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE schemaname = 'public' 
        AND tablename = 'journal_entries' 
        AND policyname = 'Users can insert own journal entries'
    ) THEN
        CREATE POLICY "Users can insert own journal entries" ON public.journal_entries
            FOR INSERT WITH CHECK (auth.uid() = user_id);
    END IF;
END $$;

DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE schemaname = 'public' 
        AND tablename = 'journal_entries' 
        AND policyname = 'Users can update own journal entries'
    ) THEN
        CREATE POLICY "Users can update own journal entries" ON public.journal_entries
            FOR UPDATE USING (auth.uid() = user_id);
    END IF;
END $$;

-- Daily sessions policies
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE schemaname = 'public' 
        AND tablename = 'daily_sessions' 
        AND policyname = 'Users can view own daily sessions'
    ) THEN
        CREATE POLICY "Users can view own daily sessions" ON public.daily_sessions
            FOR SELECT USING (auth.uid() = user_id);
    END IF;
END $$;

DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE schemaname = 'public' 
        AND tablename = 'daily_sessions' 
        AND policyname = 'Users can insert own daily sessions'
    ) THEN
        CREATE POLICY "Users can insert own daily sessions" ON public.daily_sessions
            FOR INSERT WITH CHECK (auth.uid() = user_id);
    END IF;
END $$;

DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE schemaname = 'public' 
        AND tablename = 'daily_sessions' 
        AND policyname = 'Users can update own daily sessions'
    ) THEN
        CREATE POLICY "Users can update own daily sessions" ON public.daily_sessions
            FOR UPDATE USING (auth.uid() = user_id);
    END IF;
END $$;

-- Goals policies
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE schemaname = 'public' 
        AND tablename = 'goals' 
        AND policyname = 'Users can view own goals'
    ) THEN
        CREATE POLICY "Users can view own goals" ON public.goals
            FOR SELECT USING (auth.uid() = user_id);
    END IF;
END $$;

DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE schemaname = 'public' 
        AND tablename = 'goals' 
        AND policyname = 'Users can insert own goals'
    ) THEN
        CREATE POLICY "Users can insert own goals" ON public.goals
            FOR INSERT WITH CHECK (auth.uid() = user_id);
    END IF;
END $$;

DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE schemaname = 'public' 
        AND tablename = 'goals' 
        AND policyname = 'Users can update own goals'
    ) THEN
        CREATE POLICY "Users can update own goals" ON public.goals
            FOR UPDATE USING (auth.uid() = user_id);
    END IF;
END $$;

-- Functions for automatic timestamp updates
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers for updated_at (only if they don't exist)
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_trigger 
        WHERE tgname = 'update_user_profiles_updated_at'
    ) THEN
        CREATE TRIGGER update_user_profiles_updated_at 
            BEFORE UPDATE ON public.user_profiles 
            FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    END IF;
END $$;

DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_trigger 
        WHERE tgname = 'update_journal_entries_updated_at'
    ) THEN
        CREATE TRIGGER update_journal_entries_updated_at 
            BEFORE UPDATE ON public.journal_entries 
            FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    END IF;
END $$;

DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_trigger 
        WHERE tgname = 'update_daily_sessions_updated_at'
    ) THEN
        CREATE TRIGGER update_daily_sessions_updated_at 
            BEFORE UPDATE ON public.daily_sessions 
            FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    END IF;
END $$;

DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_trigger 
        WHERE tgname = 'update_goals_updated_at'
    ) THEN
        CREATE TRIGGER update_goals_updated_at 
            BEFORE UPDATE ON public.goals 
            FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    END IF;
END $$;
