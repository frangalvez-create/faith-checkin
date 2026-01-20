-- Create all required tables for the Centered app
-- This script ensures all necessary tables exist with the correct schema

-- 1. Create journal_entries table
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

-- 2. Create goals table
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

-- 3. Create guided_questions table
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

-- Create triggers to update updated_at timestamps
CREATE TRIGGER update_journal_entries_updated_at
    BEFORE UPDATE ON journal_entries
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_goals_updated_at
    BEFORE UPDATE ON goals
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_guided_questions_updated_at
    BEFORE UPDATE ON guided_questions
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- Verify tables were created
SELECT 'All tables created successfully' as status;
