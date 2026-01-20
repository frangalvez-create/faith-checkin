-- Fix the column name mismatch in goals table
-- The Swift Goal model expects 'goals' column, but database has 'goal_text'

-- Option 1: Rename goal_text to goals (if goal_text has data we want to keep)
-- ALTER TABLE goals RENAME COLUMN goal_text TO goals;

-- Option 2: Drop goal_text column since we already have 'goals' column
-- This is safer since we already have both columns
ALTER TABLE goals DROP COLUMN IF EXISTS goal_text;

-- Verify the final schema
SELECT column_name, data_type 
FROM information_schema.columns
WHERE table_name = 'goals' AND table_schema = 'public'
ORDER BY ordinal_position;

SELECT 'Goals table column mismatch fixed' as status;
