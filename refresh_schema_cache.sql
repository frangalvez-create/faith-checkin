-- Refresh Supabase Schema Cache
-- This script forces Supabase to refresh its schema cache
-- Run this AFTER the complete_database_cleanup.sql script

-- Force schema cache refresh by querying the schema
SELECT 
    schemaname,
    tablename,
    ic.column_name,
    ic.data_type
FROM pg_catalog.pg_tables pt
JOIN information_schema.columns ic ON pt.tablename = ic.table_name
WHERE schemaname = 'public'
AND tablename IN ('user_profiles', 'journal_entries', 'goals', 'guided_questions')
ORDER BY tablename, ic.column_name;

-- Verify no subscription columns exist
SELECT 
    table_name,
    column_name
FROM information_schema.columns 
WHERE table_name = 'user_profiles' 
AND column_name LIKE '%subscription%'
OR column_name LIKE '%tier%'
OR column_name LIKE '%premium%';

-- Show final clean schema
SELECT 
    'user_profiles' as table_name,
    column_name,
    data_type
FROM information_schema.columns 
WHERE table_name = 'user_profiles'
UNION ALL
SELECT 
    'journal_entries' as table_name,
    column_name,
    data_type
FROM information_schema.columns 
WHERE table_name = 'journal_entries'
UNION ALL
SELECT 
    'goals' as table_name,
    column_name,
    data_type
FROM information_schema.columns 
WHERE table_name = 'goals'
ORDER BY table_name, column_name;
