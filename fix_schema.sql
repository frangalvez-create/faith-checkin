-- Fix database schema to match Swift models
-- Remove updated_at columns that are causing conflicts

-- Remove updated_at from journal_entries table
ALTER TABLE public.journal_entries DROP COLUMN IF EXISTS updated_at;

-- Add missing fields that Swift models expect
ALTER TABLE public.journal_entries ADD COLUMN IF NOT EXISTS guided_question_id UUID;
ALTER TABLE public.journal_entries ADD COLUMN IF NOT EXISTS contributes_to_streak BOOLEAN DEFAULT true;

-- Ensure the entry_type constraint is correct
ALTER TABLE public.journal_entries DROP CONSTRAINT IF EXISTS journal_entries_entry_type_check;
ALTER TABLE public.journal_entries ADD CONSTRAINT journal_entries_entry_type_check CHECK (entry_type IN ('guided', 'open'));

-- Update user_profiles to match what we need (keep updated_at here as it's used in the service)
-- No changes needed for user_profiles

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_journal_entries_user_id ON public.journal_entries(user_id);
CREATE INDEX IF NOT EXISTS idx_journal_entries_session_date ON public.journal_entries(session_date);
CREATE INDEX IF NOT EXISTS idx_journal_entries_entry_type ON public.journal_entries(entry_type);
