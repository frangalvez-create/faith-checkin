-- Fix Supabase schema to match reverted code expectations
-- This script aligns the database schema with the "Refresh button and 2am refresh" commit

-- ========================================
-- 1. FIX GOALS TABLE
-- ========================================

-- First, check what columns exist in the goals table
SELECT 'Current goals table structure:' as info;
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'goals' AND table_schema = 'public'
ORDER BY ordinal_position;

-- Add missing columns that the Goal model expects
ALTER TABLE public.goals ADD COLUMN IF NOT EXISTS id UUID DEFAULT gen_random_uuid();
ALTER TABLE public.goals ADD COLUMN IF NOT EXISTS user_id UUID;
ALTER TABLE public.goals ADD COLUMN IF NOT EXISTS content TEXT;
ALTER TABLE public.goals ADD COLUMN IF NOT EXISTS goals TEXT;
ALTER TABLE public.goals ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW();
ALTER TABLE public.goals ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

-- Handle existing columns that might have different names
DO $$ 
BEGIN
    -- If goal_text exists, rename it to content
    IF EXISTS (SELECT 1 FROM information_schema.columns 
               WHERE table_name = 'goals' AND column_name = 'goal_text' AND table_schema = 'public') THEN
        ALTER TABLE public.goals RENAME COLUMN goal_text TO content;
    END IF;
    
    -- If goal_text doesn't exist but content is missing, create it
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'goals' AND column_name = 'content' AND table_schema = 'public') THEN
        ALTER TABLE public.goals ADD COLUMN content TEXT;
    END IF;
END $$;

-- Update existing records to have proper values
UPDATE public.goals 
SET 
    content = COALESCE(content, ''),
    goals = COALESCE(goals, ''),
    user_id = COALESCE(user_id, gen_random_uuid())
WHERE content IS NULL OR goals IS NULL OR user_id IS NULL;

-- Make required fields NOT NULL
ALTER TABLE public.goals ALTER COLUMN user_id SET NOT NULL;
ALTER TABLE public.goals ALTER COLUMN content SET NOT NULL;
ALTER TABLE public.goals ALTER COLUMN goals SET NOT NULL;

-- ========================================
-- 2. FIX GUIDED QUESTIONS TABLE
-- ========================================

-- Check current guided questions table structure
SELECT 'Current guided_questions table structure:' as info;
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'guided_questions' AND table_schema = 'public'
ORDER BY ordinal_position;

-- Handle column renaming safely
DO $$ 
BEGIN
    -- If 'question' column exists, rename it to 'question_text'
    IF EXISTS (SELECT 1 FROM information_schema.columns 
               WHERE table_name = 'guided_questions' AND column_name = 'question' AND table_schema = 'public') THEN
        ALTER TABLE public.guided_questions RENAME COLUMN question TO question_text;
    END IF;
    
    -- If 'question_text' doesn't exist, create it
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'guided_questions' AND column_name = 'question_text' AND table_schema = 'public') THEN
        ALTER TABLE public.guided_questions ADD COLUMN question_text TEXT;
    END IF;
END $$;

-- Add the missing 'order_index' column
ALTER TABLE public.guided_questions 
ADD COLUMN IF NOT EXISTS order_index INTEGER;

-- Set default order_index for existing questions using a CTE
WITH numbered_questions AS (
    SELECT id, row_number() OVER (ORDER BY created_at) as new_order
    FROM public.guided_questions 
    WHERE order_index IS NULL
)
UPDATE public.guided_questions 
SET order_index = numbered_questions.new_order
FROM numbered_questions
WHERE guided_questions.id = numbered_questions.id;

-- ========================================
-- 3. FIX JOURNAL ENTRIES TABLE
-- ========================================

-- Add missing 'entry_type' column
ALTER TABLE public.journal_entries 
ADD COLUMN IF NOT EXISTS entry_type TEXT DEFAULT 'guided';

-- Add missing 'tags' column
ALTER TABLE public.journal_entries 
ADD COLUMN IF NOT EXISTS tags TEXT[] DEFAULT '{}';

-- Update existing records to have proper entry_type
UPDATE public.journal_entries 
SET entry_type = 'guided' 
WHERE entry_type IS NULL;

-- Add constraint for entry_type values
ALTER TABLE public.journal_entries 
ADD CONSTRAINT check_entry_type 
CHECK (entry_type IN ('guided', 'open'));

-- ========================================
-- 4. FIX USER PROFILES TABLE
-- ========================================

-- Check current user_profiles table structure
SELECT 'Current user_profiles table structure:' as info;
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'user_profiles' AND table_schema = 'public'
ORDER BY ordinal_position;

-- Handle column renaming safely
DO $$ 
BEGIN
    -- If 'full_name' column exists, rename it to 'display_name'
    IF EXISTS (SELECT 1 FROM information_schema.columns 
               WHERE table_name = 'user_profiles' AND column_name = 'full_name' AND table_schema = 'public') THEN
        ALTER TABLE public.user_profiles RENAME COLUMN full_name TO display_name;
    END IF;
    
    -- If 'display_name' doesn't exist, create it
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'user_profiles' AND column_name = 'display_name' AND table_schema = 'public') THEN
        ALTER TABLE public.user_profiles ADD COLUMN display_name TEXT;
    END IF;
END $$;

-- ========================================
-- 5. INSERT DEFAULT GUIDED QUESTIONS
-- ========================================

-- Clear existing guided questions and insert the ones expected by the code
DELETE FROM public.guided_questions;

INSERT INTO public.guided_questions (id, question_text, is_active, order_index, created_at) VALUES
    (gen_random_uuid(), 'What thing, person or moment filled you with gratitude today?', true, 1, NOW()),
    (gen_random_uuid(), 'What went well today and why?', true, 2, NOW()),
    (gen_random_uuid(), 'How are you feeling today? Mind and body', true, 3, NOW()),
    (gen_random_uuid(), 'If you dream, what would you like to dream about tonight?', true, 4, NOW()),
    (gen_random_uuid(), 'How was your time management today? Anything to improve?', true, 5, NOW());

-- ========================================
-- 6. VERIFICATION
-- ========================================

-- Verify the schema matches the reverted code expectations
SELECT 'Schema fixes completed successfully!' as status;

-- Show updated table structures
SELECT 'Goals table structure:' as info;
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'goals' AND table_schema = 'public'
ORDER BY ordinal_position;

SELECT 'Guided Questions table structure:' as info;
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'guided_questions' AND table_schema = 'public'
ORDER BY ordinal_position;

SELECT 'Journal Entries table structure:' as info;
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'journal_entries' AND table_schema = 'public'
ORDER BY ordinal_position;

SELECT 'User Profiles table structure:' as info;
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'user_profiles' AND table_schema = 'public'
ORDER BY ordinal_position;
