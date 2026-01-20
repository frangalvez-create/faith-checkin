-- Add last_name field to user_profiles table
-- This script adds the last_name field needed for the Last Name functionality

-- ========================================
-- 1. ADD LAST_NAME COLUMN
-- ========================================

-- Add last_name column
ALTER TABLE public.user_profiles ADD COLUMN IF NOT EXISTS last_name TEXT;

-- ========================================
-- 2. VERIFICATION
-- ========================================

SELECT 'Last name field added successfully!' as status;

-- Show updated table structure
SELECT 'user_profiles table structure:' as table_name;
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'user_profiles' AND table_schema = 'public'
ORDER BY ordinal_position;

-- Show table record count
SELECT 'user_profiles' as table_name, COUNT(*) as record_count 
FROM public.user_profiles;
