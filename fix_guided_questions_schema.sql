-- Fix guided_questions table to add missing order_index column
-- This will resolve the "column guided_questions.order_index does not exist" error

-- Add the missing order_index column
ALTER TABLE guided_questions 
ADD COLUMN order_index INTEGER;

-- Update existing questions with order_index values
UPDATE guided_questions 
SET order_index = CASE 
    WHEN question_text LIKE '%gratitude%' THEN 1
    WHEN question_text LIKE '%challenge%' THEN 2
    WHEN question_text LIKE '%smile%' THEN 3
    WHEN question_text LIKE '%learn%' THEN 4
    WHEN question_text LIKE '%forward%' THEN 5
    ELSE 6
END;

-- Make order_index NOT NULL and add default value for future inserts
ALTER TABLE guided_questions 
ALTER COLUMN order_index SET NOT NULL,
ALTER COLUMN order_index SET DEFAULT 1;

-- Create index for better performance
CREATE INDEX idx_guided_questions_order_index ON guided_questions(order_index);

-- Success message
DO $$
BEGIN
    RAISE NOTICE 'Fixed guided_questions table - added order_index column';
    RAISE NOTICE 'Updated existing questions with order_index values';
    RAISE NOTICE 'Ready for app testing!';
END $$;
