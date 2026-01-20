-- OTP Authentication Schema for Centered App
-- Simplified schema without user_profiles table
-- Uses Supabase Auth directly with auth.users table

-- ========================================
-- 1. CLEAN UP EXISTING SCHEMA
-- ========================================

-- Drop triggers first
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP TRIGGER IF EXISTS update_user_profiles_updated_at ON user_profiles;
DROP TRIGGER IF EXISTS update_journal_entries_updated_at ON journal_entries;
DROP TRIGGER IF EXISTS update_goals_updated_at ON goals;
DROP TRIGGER IF EXISTS update_guided_questions_updated_at ON guided_questions;

-- Drop functions
DROP FUNCTION IF EXISTS public.handle_new_user();
DROP FUNCTION IF EXISTS public.update_updated_at_column();

-- Drop tables (CASCADE will handle dependencies)
DROP TABLE IF EXISTS user_profiles CASCADE;
DROP TABLE IF EXISTS journal_entries CASCADE;
DROP TABLE IF EXISTS goals CASCADE;
DROP TABLE IF EXISTS guided_questions CASCADE;

-- ========================================
-- 2. CREATE JOURNAL ENTRIES TABLE
-- ========================================

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

CREATE TABLE goals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    is_completed BOOLEAN DEFAULT FALSE,
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

CREATE TABLE guided_questions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    question TEXT NOT NULL,
    category TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insert sample guided questions
INSERT INTO guided_questions (question, category, is_active) VALUES
    ('What are three things you''re grateful for today?', 'gratitude', TRUE),
    ('What was the most challenging part of your day?', 'reflection', TRUE),
    ('What did you learn about yourself today?', 'self-discovery', TRUE),
    ('How did you show kindness to others today?', 'kindness', TRUE),
    ('What are you looking forward to tomorrow?', 'future', TRUE);

-- Enable RLS for guided_questions (read-only for all authenticated users)
ALTER TABLE guided_questions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "All authenticated users can view guided questions" ON guided_questions
    FOR SELECT USING (auth.role() = 'authenticated');

-- ========================================
-- 5. CREATE HELPER FUNCTIONS
-- ========================================

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

-- Create triggers to automatically update updated_at
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
-- 7. VERIFICATION
-- ========================================

-- Verify the tables were created correctly
SELECT 'OTP Authentication schema setup completed successfully!' as status;

-- Show table counts
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
FROM guided_questio