-- Add age field to user_profiles table
-- This script adds the age column if it does not already exist.

-- ========================================
-- 1. ADD AGE COLUMN ONLY
-- ========================================

-- Add age column
ALTER TABLE public.user_profiles ADD COLUMN IF NOT EXISTS age DATE;

-- ========================================
-- 2. VERIFICATION
-- ========================================

SELECT 'Age field added successfully!' as status;

-- Show updated table structure
SELECT 'user_profiles table structure:' as table_name;
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'user_profiles' AND table_schema = 'public'
ORDER BY ordinal_position;

-- Show table record count
SELECT 'user_profiles' as table_name, COUNT(*) as record_count 
FROM public.user_profiles;
