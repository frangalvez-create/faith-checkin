-- Centered App Database Schema
-- Updated schema for authentication, user profiles, and session tracking

-- Note: Row Level Security will be enabled per table below

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
    
    -- Daily Session Management
    last_journal_session_date DATE,
    journal_session_completed BOOLEAN DEFAULT FALSE,
    
    -- Privacy & Security
    app_lock_enabled BOOLEAN DEFAULT FALSE,
    app_lock_type TEXT DEFAULT 'none' CHECK (app_lock_type IN ('none', 'biometric', 'passcode')),
    
    -- Notification Preferences
    notifications_enabled BOOLEAN DEFAULT TRUE,
    notification_frequency TEXT DEFAULT 'daily' CHECK (notification_frequency IN ('daily', 'weekly', 'custom')),
    daily_reminder_time TIME DEFAULT '20:00:00',
    daily_reminder_days INTEGER[] DEFAULT ARRAY[1,2,3,4,5,6,7], -- 1=Monday, 7=Sunday
    weekly_reminder_day INTEGER DEFAULT 7 CHECK (weekly_reminder_day BETWEEN 1 AND 7),
    timezone TEXT DEFAULT 'UTC',
    
    -- App Preferences
    onboarding_completed BOOLEAN DEFAULT FALSE,
    theme_preference TEXT DEFAULT 'system' CHECK (theme_preference IN ('system', 'light', 'dark'))
);

-- Updated Journal Entries Table
CREATE TABLE IF NOT EXISTS public.journal_entries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    guided_question_id UUID REFERENCES public.guided_questions(id),
    content TEXT NOT NULL,
    ai_prompt TEXT,
    ai_response TEXT,
    is_favorite BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Session Management
    session_date DATE DEFAULT CURRENT_DATE,
    entry_type TEXT NOT NULL CHECK (entry_type IN ('guided', 'open')),
    
    -- Streak Tracking
    contributes_to_streak BOOLEAN DEFAULT TRUE
);

-- Guided Questions Table (unchanged but included for completeness)
CREATE TABLE IF NOT EXISTS public.guided_questions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    question_text TEXT NOT NULL,
    category TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Goals Table (for Centered Page functionality)
CREATE TABLE IF NOT EXISTS public.goals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    goal_text TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    is_active BOOLEAN DEFAULT TRUE,
    achieved_at TIMESTAMPTZ
);

-- Daily Sessions Table (for tracking daily journaling sessions)
CREATE TABLE IF NOT EXISTS public.daily_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    session_date DATE NOT NULL,
    guided_entry_completed BOOLEAN DEFAULT FALSE,
    open_entry_completed BOOLEAN DEFAULT FALSE,
    session_completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE(user_id, session_date)
);

-- Indexes for better performance
CREATE INDEX IF NOT EXISTS idx_journal_entries_user_id ON public.journal_entries(user_id);
CREATE INDEX IF NOT EXISTS idx_journal_entries_session_date ON public.journal_entries(session_date);
CREATE INDEX IF NOT EXISTS idx_journal_entries_created_at ON public.journal_entries(created_at);
CREATE INDEX IF NOT EXISTS idx_daily_sessions_user_date ON public.daily_sessions(user_id, session_date);
CREATE INDEX IF NOT EXISTS idx_user_profiles_email ON public.user_profiles(email);

-- Row Level Security Policies
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.journal_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.goals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.daily_sessions ENABLE ROW LEVEL SECURITY;

-- User Profiles RLS Policies
CREATE POLICY "Users can view own profile" ON public.user_profiles
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON public.user_profiles
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" ON public.user_profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

-- Journal Entries RLS Policies
CREATE POLICY "Users can view own journal entries" ON public.journal_entries
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create own journal entries" ON public.journal_entries
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own journal entries" ON public.journal_entries
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own journal entries" ON public.journal_entries
    FOR DELETE USING (auth.uid() = user_id);

-- Goals RLS Policies
CREATE POLICY "Users can manage own goals" ON public.goals
    FOR ALL USING (auth.uid() = user_id);

-- Daily Sessions RLS Policies
CREATE POLICY "Users can manage own sessions" ON public.daily_sessions
    FOR ALL USING (auth.uid() = user_id);

-- Guided Questions are public (read-only for all authenticated users)
ALTER TABLE public.guided_questions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Authenticated users can view guided questions" ON public.guided_questions
    FOR SELECT TO authenticated USING (true);

-- Functions for automatic updates
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger for user_profiles updated_at
CREATE TRIGGER update_user_profiles_updated_at 
    BEFORE UPDATE ON public.user_profiles 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Function to update user statistics
CREATE OR REPLACE FUNCTION update_user_statistics()
RETURNS TRIGGER AS $$
DECLARE
    user_profile_id UUID;
    entry_count INTEGER;
    last_entry_date DATE;
BEGIN
    -- Get the user_id from the journal entry
    user_profile_id := NEW.user_id;
    
    -- Count total journal entries for this user
    SELECT COUNT(*) INTO entry_count
    FROM public.journal_entries 
    WHERE user_id = user_profile_id;
    
    -- Get the most recent journal entry date
    SELECT MAX(session_date) INTO last_entry_date
    FROM public.journal_entries 
    WHERE user_id = user_profile_id;
    
    -- Update user profile statistics
    UPDATE public.user_profiles 
    SET 
        total_journal_entries = entry_count,
        last_journal_date = last_entry_date,
        updated_at = NOW()
    WHERE id = user_profile_id;
    
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger to automatically update user statistics when journal entries are added
CREATE TRIGGER update_user_stats_on_journal_entry
    AFTER INSERT ON public.journal_entries
    FOR EACH ROW EXECUTE FUNCTION update_user_statistics();

-- Function to calculate and update streaks
CREATE OR REPLACE FUNCTION calculate_user_streak(user_profile_id UUID)
RETURNS INTEGER AS $$
DECLARE
    current_streak INTEGER := 0;
    max_streak INTEGER := 0;
    check_date DATE;
    entry_exists BOOLEAN;
BEGIN
    -- Start from today and work backwards
    check_date := CURRENT_DATE;
    
    -- Check if there's an entry for today or yesterday to start the streak
    SELECT EXISTS(
        SELECT 1 FROM public.journal_entries 
        WHERE user_id = user_profile_id 
        AND session_date = check_date
        AND contributes_to_streak = true
    ) INTO entry_exists;
    
    -- If no entry today, check yesterday
    IF NOT entry_exists THEN
        check_date := check_date - INTERVAL '1 day';
        SELECT EXISTS(
            SELECT 1 FROM public.journal_entries 
            WHERE user_id = user_profile_id 
            AND session_date = check_date
            AND contributes_to_streak = true
        ) INTO entry_exists;
    END IF;
    
    -- Calculate current streak
    WHILE entry_exists LOOP
        current_streak := current_streak + 1;
        check_date := check_date - INTERVAL '1 day';
        
        SELECT EXISTS(
            SELECT 1 FROM public.journal_entries 
            WHERE user_id = user_profile_id 
            AND session_date = check_date
            AND contributes_to_streak = true
        ) INTO entry_exists;
    END LOOP;
    
    -- Get the longest streak from profile or calculate if needed
    SELECT longest_streak INTO max_streak
    FROM public.user_profiles
    WHERE id = user_profile_id;
    
    -- Update longest streak if current is higher
    IF current_streak > max_streak THEN
        max_streak := current_streak;
    END IF;
    
    -- Update user profile with new streak values
    UPDATE public.user_profiles 
    SET 
        current_streak = current_streak,
        longest_streak = max_streak,
        updated_at = NOW()
    WHERE id = user_profile_id;
    
    RETURN current_streak;
END;
$$ language 'plpgsql';

-- Insert some default guided questions
INSERT INTO public.guided_questions (question_text, category) VALUES
('How are you feeling today?', 'emotions'),
('What are you grateful for today?', 'gratitude'),
('What challenged you today?', 'reflection'),
('What did you learn today?', 'growth'),
('What are you looking forward to?', 'future'),
('Describe a moment that made you smile today.', 'positivity'),
('What would you like to improve about today?', 'self-improvement'),
('How did you take care of yourself today?', 'self-care'),
('What are you proud of today?', 'achievement'),
('What thoughts are on your mind right now?', 'mindfulness')
ON CONFLICT DO NOTHING;
