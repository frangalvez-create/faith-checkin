-- Update user_profiles table to support firstName field
-- This script adds the missing fields needed for the "from scratch" approach

-- ========================================
-- 1. ADD MISSING COLUMNS TO USER_PROFILES TABLE
-- ========================================

-- Add first_name column
ALTER TABLE public.user_profiles ADD COLUMN IF NOT EXISTS first_name TEXT;

-- Add last_name column  
ALTER TABLE public.user_profiles ADD COLUMN IF NOT EXISTS last_name TEXT;

-- Add notification_frequency column
ALTER TABLE public.user_profiles ADD COLUMN IF NOT EXISTS notification_frequency TEXT;

-- Add streak_ending_notification column
ALTER TABLE public.user_profiles ADD COLUMN IF NOT EXISTS streak_ending_notification BOOLEAN DEFAULT TRUE;

-- ========================================
-- 2. UPDATE EXISTING RECORDS
-- ========================================

-- Set default values for existing records
UPDATE public.user_profiles 
SET 
    first_name = COALESCE(first_name, ''),
    last_name = COALESCE(last_name, ''),
    notification_frequency = COALESCE(notification_frequency, 'Weekly'),
    streak_ending_notification = COALESCE(streak_ending_notification, TRUE)
WHERE first_name IS NULL OR last_name IS NULL OR notification_frequency IS NULL OR streak_ending_notification IS NULL;

-- ========================================
-- 3. VERIFICATION
-- ========================================

SELECT 'Schema update completed successfully!' as status;

-- Show updated table structure
SELECT 'Updated user_profiles table structure:' as table_name;
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'user_profiles' AND table_schema = 'public'
ORDER BY ordinal_position;

-- Show table record count
SELECT 'user_profiles' as table_name, COUNT(*) as record_count 
FROM public.user_profiles;
