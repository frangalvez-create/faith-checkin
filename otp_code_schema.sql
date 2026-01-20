-- OTP Code Authentication Schema for Centered App
-- This script sets up the database for OTP code authentication (not Magic Links)

-- First, clean up any existing schema
DO $$ 
BEGIN
    -- Drop existing triggers and functions
    DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
    DROP FUNCTION IF EXISTS handle_new_user();
    
    -- Drop existing tables (in reverse dependency order)
    DROP TABLE IF EXISTS journal_entries CASCADE;
    DROP TABLE IF EXISTS goals CASCADE;
    DROP TABLE IF EXISTS guided_questions CASCADE;
    DROP TABLE IF EXISTS user_profiles CASCADE;
    
    RAISE NOTICE 'Cleaned up existing schema';
END $$;

-- Create the core application tables
-- Note: We don't need a separate user_profiles table for OTP auth
-- We'll use auth.users directly

-- Journal Entries Table
CREATE TABLE journal_entries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    ai_response TEXT,
    entry_type TEXT NOT NULL CHECK (entry_type IN ('guided', 'open')),
    question_id UUID, -- References guided_questions.id for guided entries
    is_favorite BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Goals Table
CREATE TABLE goals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    goals TEXT, -- JSON string for multiple goals
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Guided Questions Table
CREATE TABLE guided_questions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    question_text TEXT NOT NULL,
    category TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Insert some sample guided questions
INSERT INTO guided_questions (question_text, category) VALUES
('What is one thing you''re grateful for today?', 'gratitude'),
('What challenge did you overcome today?', 'growth'),
('What made you smile today?', 'joy'),
('What did you learn about yourself today?', 'self-reflection'),
('What are you looking forward to tomorrow?', 'future');

-- Enable Row Level Security (RLS)
ALTER TABLE journal_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE goals ENABLE ROW LEVEL SECURITY;
ALTER TABLE guided_questions ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
-- Journal entries: users can only see their own entries
CREATE POLICY "Users can view their own journal entries" ON journal_entries
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own journal entries" ON journal_entries
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own journal entries" ON journal_entries
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own journal entries" ON journal_entries
    FOR DELETE USING (auth.uid() = user_id);

-- Goals: users can only see their own goals
CREATE POLICY "Users can view their own goals" ON goals
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own goals" ON goals
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own goals" ON goals
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own goals" ON goals
    FOR DELETE USING (auth.uid() = user_id);

-- Guided questions: everyone can read, but only authenticated users
CREATE POLICY "Anyone can view active guided questions" ON guided_questions
    FOR SELECT USING (is_active = TRUE);

-- Create indexes for better performance
CREATE INDEX idx_journal_entries_user_id ON journal_entries(user_id);
CREATE INDEX idx_journal_entries_created_at ON journal_entries(created_at DESC);
CREATE INDEX idx_journal_entries_entry_type ON journal_entries(entry_type);
CREATE INDEX idx_journal_entries_is_favorite ON journal_entries(is_favorite);

CREATE INDEX idx_goals_user_id ON goals(user_id);
CREATE INDEX idx_goals_created_at ON goals(created_at DESC);

CREATE INDEX idx_guided_questions_is_active ON guided_questions(is_active);

-- Create updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply updated_at triggers
CREATE TRIGGER update_journal_entries_updated_at 
    BEFORE UPDATE ON journal_entries 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_goals_updated_at 
    BEFORE UPDATE ON goals 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_guided_questions_updated_at 
    BEFORE UPDATE ON guided_questions 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Grant necessary permissions
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated;

-- Success message
DO $$
BEGIN
    RAISE NOTICE 'OTP Code Authentication Schema created successfully!';
    RAISE NOTICE 'Tables created: journal_entries, goals, guided_questions';
    RAISE NOTICE 'RLS policies enabled for user data isolation';
    RAISE NOTICE 'Sample guided questions inserted';
    RAISE NOTICE 'Ready for OTP authentication testing';
END $$;
