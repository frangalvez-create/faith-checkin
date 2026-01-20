-- Check and fix the goals table
-- First, let's see if the goals table exists and what columns it has

-- Check if goals table exists
SELECT EXISTS (
    SELECT FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_name = 'goals'
) as table_exists;

-- If table exists, show its columns
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'goals' AND table_schema = 'public'
ORDER BY ordinal_position;

-- If table doesn't exist, create it with the correct schema
CREATE TABLE IF NOT EXISTS goals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    content TEXT NOT NULL,
    goals TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add any missing columns if table exists but is missing columns
ALTER TABLE goals ADD COLUMN IF NOT EXISTS id UUID DEFAULT gen_random_uuid();
ALTER TABLE goals ADD COLUMN IF NOT EXISTS user_id UUID;
ALTER TABLE goals ADD COLUMN IF NOT EXISTS content TEXT;
ALTER TABLE goals ADD COLUMN IF NOT EXISTS goals TEXT;
ALTER TABLE goals ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW();
ALTER TABLE goals ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

-- Set primary key if not set
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints 
                   WHERE constraint_name = 'goals_pkey' AND table_name = 'goals') THEN
        ALTER TABLE goals ADD PRIMARY KEY (id);
    END IF;
END $$;

-- Make user_id NOT NULL if it has values
UPDATE goals SET user_id = gen_random_uuid() WHERE user_id IS NULL;
ALTER TABLE goals ALTER COLUMN user_id SET NOT NULL;

-- Add updated_at trigger
CREATE OR REPLACE FUNCTION update_goals_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

DROP TRIGGER IF EXISTS update_goals_updated_at ON goals;
CREATE TRIGGER update_goals_updated_at
    BEFORE UPDATE ON goals
    FOR EACH ROW
    EXECUTE FUNCTION update_goals_updated_at_column();

-- Final verification
SELECT 'Goals table setup completed' as status;
SELECT column_name, data_type 
FROM information_schema.columns
WHERE table_name = 'goals' AND table_schema = 'public'
ORDER BY ordinal_position;
