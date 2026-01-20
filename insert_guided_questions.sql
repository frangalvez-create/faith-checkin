-- Insert guided questions for the Centered app
-- This script inserts the complete set of guided questions

-- First, clear existing guided questions
DELETE FROM public.guided_questions;

-- Insert the guided questions with proper order_index values
INSERT INTO public.guided_questions (id, question_text, is_active, order_index, created_at) VALUES
    (gen_random_uuid(), 'What thing, person or moment filled you with gratitude today?', true, 1, NOW()),
    (gen_random_uuid(), 'What went well today and why?', true, 2, NOW()),
    (gen_random_uuid(), 'How are you feeling today? Mind and body', true, 3, NOW()),
    (gen_random_uuid(), 'If you dream, what would you like to dream about tonight?', true, 4, NOW()),
    (gen_random_uuid(), 'How was your time management today? Anything to improve?', true, 5, NOW()),
    (gen_random_uuid(), 'Were you satisfied with what you accomplished today?', true, 6, NOW()),
    (gen_random_uuid(), 'What are you looking forward to tomorrow?', true, 7, NOW()),
    (gen_random_uuid(), 'What purchase, under $100, gave you the most joy this month?', true, 8, NOW()),
    (gen_random_uuid(), 'What is your "go-to" book, movie or show? Why?', true, 9, NOW()),
    (gen_random_uuid(), 'What''s your top goal for the next month?', true, 10, NOW()),
    (gen_random_uuid(), 'Relationshipwise, which is going well or which needs more attention?', true, 11, NOW()),
    (gen_random_uuid(), 'Name an obstacle to your goals… Why is it hindering you?', true, 12, NOW()),
    (gen_random_uuid(), 'Who is a person in your life you are grateful for? Why?', true, 13, NOW()),
    (gen_random_uuid(), 'How have you handled criticism recently? Positively or Negatively?', true, 14, NOW()),
    (gen_random_uuid(), 'What progress have you made recently towards your health?', true, 15, NOW()),
    (gen_random_uuid(), 'How has your mindset been recently? Fixed or Growth minded?', true, 16, NOW()),
    (gen_random_uuid(), 'Are you tracking your progress towards your goals? How''s it going?', true, 17, NOW()),
    (gen_random_uuid(), 'When was your last meditative/spiritual moment? How did you feel?', true, 18, NOW()),
    (gen_random_uuid(), 'What is something you feel lucky to have in your life?', true, 19, NOW()),
    (gen_random_uuid(), 'Are you feeling overall stagnant or are you progressing towards a goal?', true, 20, NOW()),
    (gen_random_uuid(), 'When was the last time you were outdoors? What was enjoyable about it?', true, 21, NOW()),
    (gen_random_uuid(), 'What was your most recent failure? Where you able to bounce back?', true, 22, NOW()),
    (gen_random_uuid(), 'What is something new you learned today?', true, 23, NOW()),
    (gen_random_uuid(), 'What is a consistent and reliable source of joy for you?', true, 24, NOW());

-- Verify the insertion
SELECT 'Guided questions inserted successfully!' as status;
SELECT COUNT(*) as total_questions FROM public.guided_questions;
SELECT question_text, order_index FROM public.guided_questions ORDER BY order_index;
