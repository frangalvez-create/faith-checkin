-- Fix the goals table schema to match the restored Goal model
-- The Goal model expects: id, user_id, content, goals, created_at, updated_at

-- First, let's see what columns currently exist in the goals table
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'goals'
ORDER BY ordinal_position;

-- Add missing columns that the restored Goal model expects
ALTER TABLE goals ADD COLUMN IF NOT EXISTS user_id UUID;
ALTER TABLE goals ADD COLUMN IF NOT EXISTS content TEXT;
ALTER TABLE goals ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

-- Update existing entries to have default values for new columns
UPDATE goals
SET
    user_id = gen_random_uuid(),  -- Generate random UUID for existing entries
    content = '',                 -- Empty string for content
    updated_at = created_at       -- Set updated_at to created_at for existing entries
WHERE user_id IS NULL;

-- Make user_id NOT NULL after setting default values
ALTER TABLE goals ALTER COLUMN user_id SET NOT NULL;

-- Add updated_at trigger for goals table
CREATE OR REPLACE FUNCTION update_goals_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger for goals
DROP TRIGGER IF EXISTS update_goals_updated_at ON goals;
CREATE TRIGGER update_goals_updated_at
    BEFORE UPDATE ON goals
    FOR EACH ROW
    EXECUTE FUNCTION update_goals_updated_at_column();

SELECT 'Goals table schema updated successfully' as status;
