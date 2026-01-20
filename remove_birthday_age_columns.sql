-- Remove birthday and age columns from user_profiles table
-- This script removes the birthday and age fields that are no longer needed

-- Drop the birthday column
ALTER TABLE user_profiles DROP COLUMN IF EXISTS birthday;

-- Drop the age column  
ALTER TABLE user_profiles DROP COLUMN IF EXISTS age;

-- Verify the table structure
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'user_profiles' 
ORDER BY ordinal_position;
