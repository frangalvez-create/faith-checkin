-- Fix orphaned journal entries that reference non-existent guided questions
-- This script handles the foreign key constraint violation

-- ========================================
-- 1. CHECK FOR ORPHANED JOURNAL ENTRIES
-- ========================================

SELECT 'Checking for orphaned journal entries...' as status;

-- Show journal entries that reference non-existent guided questions
SELECT 
    je.id,
    je.guided_question_id,
    je.content,
    je.created_at
FROM public.journal_entries je
LEFT JOIN public.guided_questions gq ON je.guided_question_id = gq.id
WHERE je.guided_question_id IS NOT NULL 
AND gq.id IS NULL;

-- Count orphaned entries
SELECT COUNT(*) as orphaned_count
FROM public.journal_entries je
LEFT JOIN public.guided_questions gq ON je.guided_question_id = gq.id
WHERE je.guided_question_id IS NOT NULL 
AND gq.id IS NULL;

-- ========================================
-- 2. FIX ORPHANED JOURNAL ENTRIES
-- ========================================

-- Option 1: Set guided_question_id to NULL for orphaned entries
UPDATE public.journal_entries 
SET guided_question_id = NULL,
    entry_type = 'guided'  -- Keep as guided entry type
WHERE guided_question_id IS NOT NULL 
AND guided_question_id NOT IN (SELECT id FROM public.guided_questions);

-- ========================================
-- 3. VERIFICATION
-- ========================================

SELECT 'Orphaned journal entries fixed!' as status;

-- Verify no more orphaned entries exist
SELECT COUNT(*) as remaining_orphaned_count
FROM public.journal_entries je
LEFT JOIN public.guided_questions gq ON je.guided_question_id = gq.id
WHERE je.guided_question_id IS NOT NULL 
AND gq.id IS NULL;

-- Show summary of journal entries by type
SELECT 
    entry_type,
    COUNT(*) as count
FROM public.journal_entries 
GROUP BY entry_type;

-- Show journal entries with valid guided question references
SELECT 
    je.id,
    je.guided_question_id,
    gq.question_text,
    je.created_at
FROM public.journal_entries je
LEFT JOIN public.guided_questions gq ON je.guided_question_id = gq.id
WHERE je.guided_question_id IS NOT NULL 
AND gq.id IS NOT NULL
LIMIT 5;

SELECT 'Fix completed successfully!' as final_status;
