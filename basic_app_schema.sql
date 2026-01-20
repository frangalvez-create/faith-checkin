-- Basic App Schema - No Authentication
-- This matches the "Nav Tab completed" commit state

-- Drop all existing tables to start fresh
DROP TABLE IF EXISTS journal_entries CASCADE;
DROP TABLE IF EXISTS goals CASCADE;
DROP TABLE IF EXISTS guided_questions CASCADE;
DROP TABLE IF EXISTS user_profiles CASCADE;

-- Create guided_questions table
CREATE TABLE public.guided_questions (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    question_text text NOT NULL,
    is_active bool NOT NULL DEFAULT true,
    order_index int4 NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT guided_questions_pkey PRIMARY KEY (id)
);

-- Insert default guided questions
INSERT INTO public.guided_questions (question_text, is_active, order_index) VALUES
('What thing, person or moment filled you with gratitude today?', true, 1),
('What went well today and why?', true, 2),
('How are you feeling today? Mind and body', true, 3),
('If you dream, what would you like to dream about tonight?', true, 4),
('How was your time management today? Anything to improve?', true, 5);

-- Create goals table
CREATE TABLE public.goals (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    content text NOT NULL,
    goals text[] NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT goals_pkey PRIMARY KEY (id)
);

-- Create journal_entries table
CREATE TABLE public.journal_entries (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    guided_question_id uuid NULL,
    content text NOT NULL,
    ai_prompt text NULL,
    ai_response text NULL,
    tags text[] NULL,
    is_favorite bool NOT NULL DEFAULT false,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT journal_entries_pkey PRIMARY KEY (id),
    CONSTRAINT journal_entries_guided_question_id_fkey FOREIGN KEY (guided_question_id) REFERENCES public.guided_questions(id) ON DELETE SET NULL
);

-- Enable RLS
ALTER TABLE public.guided_questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.goals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.journal_entries ENABLE ROW LEVEL SECURITY;

-- Create RLS policies (allow all for now since no auth)
CREATE POLICY "Enable read access for all users" ON public.guided_questions FOR SELECT USING (true);
CREATE POLICY "Enable all access for all users" ON public.goals FOR ALL USING (true);
CREATE POLICY "Enable all access for all users" ON public.journal_entries FOR ALL USING (true);

-- Verify the setup
SELECT 'Basic app schema created successfully - no authentication required' as status;
