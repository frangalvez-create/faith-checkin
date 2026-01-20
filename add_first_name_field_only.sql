-- Add only first_name field to user_profiles table
-- This script adds the minimal fields needed for the first name functionality

-- ========================================
-- 1. ADD FIRST_NAME COLUMN ONLY
-- ========================================

-- Add first_name column
ALTER TABLE public.user_profiles ADD COLUMN IF NOT EXISTS first_name TEXT;

-- ========================================
-- 2. VERIFY REQUIRED FIELDS EXIST
-- ========================================

-- Check if user_id field exists (required for auth linking)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'user_profiles' 
        AND column_name = 'user_id' 
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE public.user_profiles ADD COLUMN user_id UUID REFERENCES auth.users(id);
    END IF;
END $$;

-- Check if id field exists (primary key)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'user_profiles' 
        AND column_name = 'id' 
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE public.user_profiles ADD COLUMN id UUID DEFAULT gen_random_uuid() PRIMARY KEY;
    END IF;
END $$;

-- ========================================
-- 3. VERIFICATION
-- ========================================

SELECT 'First name field added successfully!' as status;

-- Show updated table structure
SELECT 'user_profiles table structure:' as table_name;
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'user_profiles' AND table_schema = 'public'
ORDER BY ordinal_position;

-- Show table record count
SELECT 'user_profiles' as table_name, COUNT(*) as record_count 
FROM public.user_profiles;
