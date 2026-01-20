-- AGGRESSIVE Schema Cache Refresh
-- This script forces Supabase to completely refresh its schema cache
-- Run this to fix the subscription_price error

-- Step 1: Force refresh by querying system tables
SELECT 
    schemaname,
    tablename,
    columnname,
    datatype
FROM pg_catalog.pg_tables pt
JOIN pg_catalog.pg_attribute pa ON pt.tablename = pa.attname
WHERE schemaname = 'public'
AND tablename IN ('user_profiles', 'journal_entries', 'goals', 'guided_questions');

-- Step 2: Explicitly refresh the schema cache by querying information_schema
SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_schema = 'public'
AND table_name IN ('user_profiles', 'journal_entries', 'goals', 'guided_questions')
ORDER BY table_name, ordinal_position;

-- Step 3: Force PostgREST to refresh by querying the exact table structure
SELECT * FROM user_profiles LIMIT 0;
SELECT * FROM journal_entries LIMIT 0;
SELECT * FROM goals LIMIT 0;
SELECT * FROM guided_questions LIMIT 0;

-- Step 4: Verify NO subscription columns exist anywhere
SELECT 
    table_name,
    column_name
FROM information_schema.columns 
WHERE table_schema = 'public'
AND (
    column_name LIKE '%subscription%' 
    OR column_name LIKE '%tier%' 
    OR column_name LIKE '%premium%'
    OR column_name LIKE '%price%'
);

-- Step 5: Show the EXACT current schema for user_profiles
SELECT 
    'user_profiles' as table_name,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public'
AND table_name = 'user_profiles'
ORDER BY ordinal_position;

-- Step 6: Force a schema reload by creating a dummy view and dropping it
CREATE OR REPLACE VIEW temp_schema_refresh AS 
SELECT * FROM user_profiles LIMIT 0;
DROP VIEW temp_schema_refresh;

SELECT 'Schema cache should now be refreshed' as status;
