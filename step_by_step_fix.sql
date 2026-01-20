-- Step-by-step authentication fix
-- Run each section separately in Supabase SQL Editor

-- STEP 1: Clean up (run this first)
DELETE FROM public.journal_entries;
DELETE FROM public.user_profiles;
