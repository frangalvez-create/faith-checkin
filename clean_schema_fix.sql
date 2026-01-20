-- Complete schema fix for reverted code
-- This script creates missing tables and fixes existing ones to match the reverted code

-- ========================================
-- 1. CHECK WHAT TABLES EXIST
-- ========================================

SELECT 'Checking existing tables...' as status;
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
ORDER BY table_name;

-- ========================================
-- 2. CREATE USER PROFILES TABLE IF MISSING
-- ========================================

CREATE TABLE IF NOT EXISTS public.user_profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL,
    display_name TEXT,
    current_streak INTEGER DEFAULT 0,
    longest_streak INTEGER DEFAULT 0,
    total_journal_entries INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS for user_profiles
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for user_profiles
DROP POLICY IF EXISTS "Users can view own profile" ON public.user_profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON public.user_profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON public.user_profiles;

CREATE POLICY "Users can view own profile" ON public.user_profiles
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON public.user_profiles
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" ON public.user_profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

-- ========================================
-- 3. CREATE GOALS TABLE IF MISSING
-- ========================================

CREATE TABLE IF NOT EXISTS public.goals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    goals TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS for goals
ALTER TABLE public.goals ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for goals
DROP POLICY IF EXISTS "Users can manage own goals" ON public.goals;
CREATE POLICY "Users can manage own goals" ON public.goals
    FOR ALL USING (auth.uid() = user_id);

-- ========================================
-- 4. CREATE GUIDED QUESTIONS TABLE IF MISSING
-- ========================================

CREATE TABLE IF NOT EXISTS public.guided_questions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    question_text TEXT NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    order_index INTEGER,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS for guided_questions
ALTER TABLE public.guided_questions ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for guided_questions
DROP POLICY IF EXISTS "Authenticated users can view guided questions" ON public.guided_questions;
CREATE POLICY "Authenticated users can view guided questions" ON public.guided_questions
    FOR SELECT TO authenticated USING (true);

-- ========================================
-- 5. CREATE JOURNAL ENTRIES TABLE IF MISSING
-- ========================================

CREATE TABLE IF NOT EXISTS public.journal_entries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    guided_question_id UUID REFERENCES public.guided_questions(id),
    content TEXT NOT NULL,
    ai_prompt TEXT,
    ai_response TEXT,
    tags TEXT[] DEFAULT '{}',
    is_favorite BOOLEAN DEFAULT FALSE,
    entry_type TEXT NOT NULL DEFAULT 'guided',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS for journal_entries
ALTER TABLE public.journal_entries ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for journal_entries
DROP POLICY IF EXISTS "Users can view own journal entries" ON public.journal_entries;
DROP POLICY IF EXISTS "Users can create own journal entries" ON public.journal_entries;
DROP POLICY IF EXISTS "Users can update own journal entries" ON public.journal_entries;
DROP POLICY IF EXISTS "Users can delete own journal entries" ON public.journal_entries;

CREATE POLICY "Users can view own journal entries" ON public.journal_entries
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create own journal entries" ON public.journal_entries
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own journal entries" ON public.journal_entries
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own journal entries" ON public.journal_entries
    FOR DELETE USING (auth.uid() = user_id);

-- ========================================
-- 6. FIX EXISTING TABLES
-- ========================================

-- Fix goals table if it exists but has wrong structure
DO $$ 
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'goals' AND table_schema = 'public') THEN
        ALTER TABLE public.goals ADD COLUMN IF NOT EXISTS id UUID DEFAULT gen_random_uuid();
        ALTER TABLE public.goals ADD COLUMN IF NOT EXISTS user_id UUID;
        ALTER TABLE public.goals ADD COLUMN IF NOT EXISTS content TEXT;
        ALTER TABLE public.goals ADD COLUMN IF NOT EXISTS goals TEXT;
        ALTER TABLE public.goals ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW();
        ALTER TABLE public.goals ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();
        
        IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'goals' AND column_name = 'goal_text' AND table_schema = 'public') THEN
            ALTER TABLE public.goals RENAME COLUMN goal_text TO content;
        END IF;
        
        UPDATE public.goals 
        SET 
            content = COALESCE(content, ''),
            goals = COALESCE(goals, ''),
            user_id = COALESCE(user_id, gen_random_uuid())
        WHERE content IS NULL OR goals IS NULL OR user_id IS NULL;
        
        ALTER TABLE public.goals ALTER COLUMN user_id SET NOT NULL;
        ALTER TABLE public.goals ALTER COLUMN content SET NOT NULL;
        ALTER TABLE public.goals ALTER COLUMN goals SET NOT NULL;
    END IF;
END $$;

-- Fix guided_questions table if it exists but has wrong structure
DO $$ 
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'guided_questions' AND table_schema = 'public') THEN
        IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'guided_questions' AND column_name = 'question' AND table_schema = 'public') THEN
            ALTER TABLE public.guided_questions RENAME COLUMN question TO question_text;
        END IF;
        
        ALTER TABLE public.guided_questions ADD COLUMN IF NOT EXISTS question_text TEXT;
        ALTER TABLE public.guided_questions ADD COLUMN IF NOT EXISTS order_index INTEGER;
        ALTER TABLE public.guided_questions ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT TRUE;
        ALTER TABLE public.guided_questions ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW();
        
        WITH numbered_questions AS (
            SELECT id, row_number() OVER (ORDER BY created_at) as new_order
            FROM public.guided_questions 
            WHERE order_index IS NULL
        )
        UPDATE public.guided_questions 
        SET order_index = numbered_questions.new_order
        FROM numbered_questions
        WHERE guided_questions.id = numbered_questions.id;
    END IF;
END $$;

-- Fix journal_entries table if it exists but is missing columns
DO $$ 
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'journal_entries' AND table_schema = 'public') THEN
        ALTER TABLE public.journal_entries ADD COLUMN IF NOT EXISTS entry_type TEXT DEFAULT 'guided';
        ALTER TABLE public.journal_entries ADD COLUMN IF NOT EXISTS tags TEXT[] DEFAULT '{}';
        ALTER TABLE public.journal_entries ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();
        
        UPDATE public.journal_entries 
        SET entry_type = 'guided' 
        WHERE entry_type IS NULL;
        
        IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints 
                       WHERE constraint_name = 'check_entry_type' AND table_name = 'journal_entries') THEN
            ALTER TABLE public.journal_entries 
            ADD CONSTRAINT check_entry_type 
            CHECK (entry_type IN ('guided', 'open'));
        END IF;
    END IF;
END $$;

-- Fix user_profiles table if it exists but has wrong structure
DO $$ 
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'user_profiles' AND table_schema = 'public') THEN
        IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_profiles' AND column_name = 'full_name' AND table_schema = 'public') THEN
            ALTER TABLE public.user_profiles RENAME COLUMN full_name TO display_name;
        END IF;
        
        ALTER TABLE public.user_profiles ADD COLUMN IF NOT EXISTS display_name TEXT;
        ALTER TABLE public.user_profiles ADD COLUMN IF NOT EXISTS current_streak INTEGER DEFAULT 0;
        ALTER TABLE public.user_profiles ADD COLUMN IF NOT EXISTS longest_streak INTEGER DEFAULT 0;
        ALTER TABLE public.user_profiles ADD COLUMN IF NOT EXISTS total_journal_entries INTEGER DEFAULT 0;
        ALTER TABLE public.user_profiles ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW();
        ALTER TABLE public.user_profiles ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();
    END IF;
END $$;

-- ========================================
-- 7. INSERT DEFAULT GUIDED QUESTIONS
-- ========================================

-- Temporarily disable the foreign key constraint
ALTER TABLE public.journal_entries 
DROP CONSTRAINT IF EXISTS journal_entries_guided_question_id_fkey;

-- Clear existing guided questions (now safe without constraint)
DELETE FROM public.guided_questions;

INSERT INTO public.guided_questions (id, question_text, is_active, order_index, created_at) VALUES
    (gen_random_uuid(), 'What thing, person or moment filled you with gratitude today?', true, 1, NOW()),
    (gen_random_uuid(), 'What went well today and why?', true, 2, NOW()),
    (gen_random_uuid(), 'How are you feeling today? Mind and body', true, 3, NOW()),
    (gen_random_uuid(), 'If you dream, what would you like to dream about tonight?', true, 4, NOW()),
    (gen_random_uuid(), 'How was your time management today? Anything to improve?', true, 5, NOW());

-- Re-add the foreign key constraint
ALTER TABLE public.journal_entries 
ADD CONSTRAINT journal_entries_guided_question_id_fkey 
FOREIGN KEY (guided_question_id) REFERENCES public.guided_questions(id);

-- ========================================
-- 8. CREATE TRIGGERS FOR UPDATED_AT
-- ========================================

-- Create function for updating updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers for updated_at
DROP TRIGGER IF EXISTS update_user_profiles_updated_at ON public.user_profiles;
CREATE TRIGGER update_user_profiles_updated_at 
    BEFORE UPDATE ON public.user_profiles 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_goals_updated_at ON public.goals;
CREATE TRIGGER update_goals_updated_at 
    BEFORE UPDATE ON public.goals 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_journal_entries_updated_at ON public.journal_entries;
CREATE TRIGGER update_journal_entries_updated_at 
    BEFORE UPDATE ON public.journal_entries 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ========================================
-- 9. VERIFICATION
-- ========================================

SELECT 'Schema setup completed successfully!' as status;

-- Show final table structures
SELECT 'Final table structures:' as info;

SELECT 'Goals table structure:' as table_name;
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'goals' AND table_schema = 'public'
ORDER BY ordinal_position;

SELECT 'Guided Questions table structure:' as table_name;
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'guided_questions' AND table_schema = 'public'
ORDER BY ordinal_position;

SELECT 'Journal Entries table structure:' as table_name;
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'journal_entries' AND table_schema = 'public'
ORDER BY ordinal_position;

SELECT 'User Profiles table structure:' as table_name;
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'user_profiles' AND table_schema = 'public'
ORDER BY ordinal_position;

-- Show table counts
SELECT 'Table record counts:' as info;
SELECT 
    'user_profiles' as table_name, 
    COUNT(*) as record_count 
FROM public.user_profiles
UNION ALL
SELECT 
    'journal_entries' as table_name, 
    COUNT(*) as record_count 
FROM public.journal_entries
UNION ALL
SELECT 
    'goals' as table_name, 
    COUNT(*) as record_count 
FROM public.goals
UNION ALL
SELECT 
    'guided_questions' as table_name, 
    COUNT(*) as record_count 
FROM public.guided_questions;
