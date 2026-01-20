-- Follow-Up Question Pre-Generation System Schema (Safe to Run Multiple Times)
-- This file creates the new follow_up_generation table and adds the follow_up_question column to journal_entries
-- Safe to run even if some parts already exist

-- 1. Create follow_up_generation table (one row per user, stores pre-generated follow-up questions)
CREATE TABLE IF NOT EXISTS public.follow_up_generation (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    fuq_ai_prompt TEXT NOT NULL,
    fuq_ai_response TEXT NOT NULL,
    source_entry_id UUID REFERENCES public.journal_entries(id) ON DELETE SET NULL, -- The past journal entry used to generate this question
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add UNIQUE constraint on user_id if it doesn't exist
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'unique_user_follow_up_generation' 
        AND conrelid = 'public.follow_up_generation'::regclass
    ) THEN
        ALTER TABLE public.follow_up_generation 
        ADD CONSTRAINT unique_user_follow_up_generation UNIQUE(user_id);
    END IF;
END $$;

-- 2. Add follow_up_question column to journal_entries (stores the question that was used when user responded)
ALTER TABLE public.journal_entries 
ADD COLUMN IF NOT EXISTS follow_up_question TEXT;

-- 3. Add trigger to update updated_at on follow_up_generation table
CREATE OR REPLACE FUNCTION update_follow_up_generation_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Drop trigger if exists, then create it (to ensure it's set up correctly)
DROP TRIGGER IF EXISTS update_follow_up_generation_updated_at ON public.follow_up_generation;
CREATE TRIGGER update_follow_up_generation_updated_at 
    BEFORE UPDATE ON public.follow_up_generation 
    FOR EACH ROW EXECUTE FUNCTION update_follow_up_generation_updated_at();

-- 4. Create index on user_id for faster lookups
CREATE INDEX IF NOT EXISTS idx_follow_up_generation_user_id ON public.follow_up_generation(user_id);

-- 5. Create index on source_entry_id for faster lookups
CREATE INDEX IF NOT EXISTS idx_follow_up_generation_source_entry_id ON public.follow_up_generation(source_entry_id);

-- 6. Enable Row Level Security (RLS) on follow_up_generation table
ALTER TABLE public.follow_up_generation ENABLE ROW LEVEL SECURITY;

-- 7. Create RLS policies for follow_up_generation table (drop and recreate to ensure they're correct)
-- Users can view their own follow-up generation entries
DROP POLICY IF EXISTS "Users can view their own follow_up_generation entries." ON public.follow_up_generation;
CREATE POLICY "Users can view their own follow_up_generation entries." ON public.follow_up_generation
    FOR SELECT USING (auth.uid() = user_id);

-- Users can insert their own follow-up generation entries
DROP POLICY IF EXISTS "Users can insert their own follow_up_generation entries." ON public.follow_up_generation;
CREATE POLICY "Users can insert their own follow_up_generation entries." ON public.follow_up_generation
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Users can update their own follow-up generation entries
DROP POLICY IF EXISTS "Users can update their own follow_up_generation entries." ON public.follow_up_generation;
CREATE POLICY "Users can update their own follow_up_generation entries." ON public.follow_up_generation
    FOR UPDATE USING (auth.uid() = user_id);

-- Users can delete their own follow-up generation entries
DROP POLICY IF EXISTS "Users can delete their own follow_up_generation entries." ON public.follow_up_generation;
CREATE POLICY "Users can delete their own follow_up_generation entries." ON public.follow_up_generation
    FOR DELETE USING (auth.uid() = user_id);

-- Note: The old columns fuq_ai_prompt and fuq_ai_response will be removed from journal_entries
-- after this migration is complete and verified. They are not removed here to allow for
-- gradual migration if needed.



