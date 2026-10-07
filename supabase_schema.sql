-- ==============================================================================
-- ToppersMock - Supabase Database Schema for SSC CGL Mock Test (TCS iON CBT)
-- ==============================================================================
-- Features:
-- 1. Mock Tests and Questions catalog (supports Mock Test 3)
-- 2. Sectional Timing & Section Locking enforcement
-- 3. In-progress test session persistence (Resume anytime with past state)
-- 4. Question-level time tracking (time_spent_seconds recorded per question)
-- ==============================================================================

-- 1. Enable UUID Extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ==============================================================================
-- Table: mock_tests
-- Stores mock test metadata, total time, and sectional timing settings
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.mock_tests (
    id VARCHAR(100) PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    total_questions INTEGER NOT NULL DEFAULT 100,
    total_time_minutes INTEGER NOT NULL DEFAULT 60,
    sectional_time_minutes INTEGER NOT NULL DEFAULT 15,
    has_sectional_timing BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- ==============================================================================
-- Table: questions
-- Stores catalog of questions for each mock test
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.questions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    test_id VARCHAR(100) NOT NULL REFERENCES public.mock_tests(id) ON DELETE CASCADE,
    question_number INTEGER NOT NULL,
    part_number INTEGER NOT NULL DEFAULT 1,
    section_name VARCHAR(100) NOT NULL,
    section_title VARCHAR(150) NOT NULL,
    chapter_name VARCHAR(150),
    difficulty VARCHAR(50) DEFAULT 'Moderate',
    question_text TEXT NOT NULL,
    question_text_hi TEXT,
    options JSONB NOT NULL,
    options_hi JSONB,
    correct_option VARCHAR(10) NOT NULL,
    solution_text TEXT,
    solution_text_hi TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    UNIQUE (test_id, question_number)
);

-- ==============================================================================
-- Table: test_attempts
-- Records exam session, in-progress state (for resume), final scores & timing
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.test_attempts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Candidate Identification
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    roll_number VARCHAR(50) NOT NULL DEFAULT 'ANONYMOUS',
    candidate_name VARCHAR(150) DEFAULT 'ANKIT SHARMA',
    candidate_email VARCHAR(255),
    
    -- Test Details
    test_id VARCHAR(100) NOT NULL DEFAULT 'ssc_cgl_tier1_mock_3',
    test_title VARCHAR(255) NOT NULL DEFAULT 'SSC CGL Tier-I Full Mock Test 3',
    
    -- Session State (Allows resuming anytime)
    status VARCHAR(30) NOT NULL DEFAULT 'in_progress', -- 'in_progress' | 'submitted' | 'expired'
    current_section_id VARCHAR(50) NOT NULL DEFAULT 'gi',
    current_question_number INTEGER NOT NULL DEFAULT 1,
    sectional_time_left JSONB NOT NULL DEFAULT '{"gi": 900, "ga": 900, "qa": 900, "ec": 900}'::jsonb,
    completed_sections JSONB NOT NULL DEFAULT '[]'::jsonb,
    
    -- Full snapshot of question responses and time spent per question
    -- Format: { "1": { "status": "ANSWERED", "selectedOption": "b", "timeSpentSeconds": 45 }, ... }
    question_states JSONB NOT NULL DEFAULT '{}'::jsonb,
    
    -- Performance Metrics
    total_questions INTEGER NOT NULL DEFAULT 100,
    total_attempted INTEGER NOT NULL DEFAULT 0,
    total_correct INTEGER NOT NULL DEFAULT 0,
    total_incorrect INTEGER NOT NULL DEFAULT 0,
    total_unattempted INTEGER NOT NULL DEFAULT 100,
    
    -- Scoring (+2 for correct, -0.50 for incorrect in SSC CGL)
    total_score NUMERIC(6, 2) NOT NULL DEFAULT 0.00,
    accuracy_percentage NUMERIC(5, 2) NOT NULL DEFAULT 0.00,
    
    -- Section-Wise Breakdown
    section_breakdown JSONB DEFAULT '[]'::jsonb,
    
    -- Timestamps
    time_taken_seconds INTEGER NOT NULL DEFAULT 0,
    started_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    submitted_at TIMESTAMPTZ,
    last_synced_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    
    client_ip TEXT,
    user_agent TEXT
);

-- Ensure all columns exist even if test_attempts already existed previously
ALTER TABLE public.test_attempts ADD COLUMN IF NOT EXISTS status VARCHAR(30) DEFAULT 'in_progress';
ALTER TABLE public.test_attempts ADD COLUMN IF NOT EXISTS current_section_id VARCHAR(50) DEFAULT 'gi';
ALTER TABLE public.test_attempts ADD COLUMN IF NOT EXISTS current_question_number INTEGER DEFAULT 1;
ALTER TABLE public.test_attempts ADD COLUMN IF NOT EXISTS sectional_time_left JSONB DEFAULT '{"gi": 900, "ga": 900, "qa": 900, "ec": 900}'::jsonb;
ALTER TABLE public.test_attempts ADD COLUMN IF NOT EXISTS completed_sections JSONB DEFAULT '[]'::jsonb;
ALTER TABLE public.test_attempts ADD COLUMN IF NOT EXISTS question_states JSONB DEFAULT '{}'::jsonb;
ALTER TABLE public.test_attempts ADD COLUMN IF NOT EXISTS last_synced_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now());


-- ==============================================================================
-- Table: test_attempt_answers
-- Records detailed response, status, and precise time spent per individual question
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.test_attempt_answers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    attempt_id UUID NOT NULL REFERENCES public.test_attempts(id) ON DELETE CASCADE,
    
    question_number INTEGER NOT NULL,
    section_name VARCHAR(100) NOT NULL,
    
    selected_option VARCHAR(10),        -- 'a', 'b', 'c', 'd' or NULL
    correct_option VARCHAR(10) NOT NULL, -- 'a', 'b', 'c', 'd'
    is_correct BOOLEAN DEFAULT FALSE,
    marks_awarded NUMERIC(4, 2) DEFAULT 0.00,
    
    status VARCHAR(30) NOT NULL,         -- 'ANSWERED', 'NOT_ANSWERED', 'MARKED_FOR_REVIEW', 'ANSWERED_AND_MARKED', 'NOT_VISITED'
    time_spent_seconds INTEGER NOT NULL DEFAULT 0, -- Exact seconds spent by candidate on this question
    
    timestamp TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    UNIQUE (attempt_id, question_number)
);

-- ==============================================================================
-- Table: user_responses
-- Dedicated table to store option chosen and exact time taken per question
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.user_responses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    attempt_id TEXT NOT NULL,
    roll_number VARCHAR(50) NOT NULL DEFAULT '2201048291',
    candidate_name VARCHAR(150) DEFAULT 'ANKIT SHARMA',
    test_id VARCHAR(100) NOT NULL DEFAULT 'ssc_cgl_tier1_mock_3',
    question_number INTEGER NOT NULL,
    section_name VARCHAR(100) NOT NULL,
    selected_option VARCHAR(10),            -- Option chosen ('a', 'b', 'c', 'd')
    time_taken_seconds INTEGER NOT NULL DEFAULT 0, -- Time taken to choose option in seconds
    correct_option VARCHAR(10),
    is_correct BOOLEAN DEFAULT FALSE,
    status VARCHAR(30) NOT NULL DEFAULT 'ANSWERED',
    recorded_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    UNIQUE (attempt_id, question_number)
);

-- ==============================================================================
-- Automatic updated_at Trigger
-- ==============================================================================
CREATE OR REPLACE FUNCTION public.set_current_timestamp_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = timezone('utc'::text, now());
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_set_test_attempts_updated_at ON public.test_attempts;
CREATE TRIGGER trigger_set_test_attempts_updated_at
BEFORE UPDATE ON public.test_attempts
FOR EACH ROW
EXECUTE FUNCTION public.set_current_timestamp_updated_at();

-- ==============================================================================
-- Indexes for Fast Analytics, Resume, and Leaderboard
-- ==============================================================================
CREATE INDEX IF NOT EXISTS idx_test_attempts_status_user ON public.test_attempts (status, roll_number);
CREATE INDEX IF NOT EXISTS idx_test_attempts_test_id ON public.test_attempts (test_id, status);
CREATE INDEX IF NOT EXISTS idx_test_attempt_answers_attempt_q ON public.test_attempt_answers (attempt_id, question_number);
CREATE INDEX IF NOT EXISTS idx_questions_test_qnum ON public.questions (test_id, question_number);

-- ==============================================================================
-- Row-Level Security (RLS) Configuration
-- ==============================================================================
ALTER TABLE public.mock_tests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.test_attempts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.test_attempt_answers ENABLE ROW LEVEL SECURITY;

-- 1. Mock Tests and Questions: Public Select
DROP POLICY IF EXISTS "Allow public read of mock tests" ON public.mock_tests;
CREATE POLICY "Allow public read of mock tests" ON public.mock_tests FOR SELECT TO public USING (true);

DROP POLICY IF EXISTS "Allow public read of questions" ON public.questions;
CREATE POLICY "Allow public read of questions" ON public.questions FOR SELECT TO public USING (true);

-- 2. Test Attempts: Insert, Select, and Update (for resuming and updating in-progress state)
DROP POLICY IF EXISTS "Allow public insert of test attempts" ON public.test_attempts;
CREATE POLICY "Allow public insert of test attempts" ON public.test_attempts FOR INSERT TO public WITH CHECK (true);

DROP POLICY IF EXISTS "Allow public read of test attempts" ON public.test_attempts;
CREATE POLICY "Allow public read of test attempts" ON public.test_attempts FOR SELECT TO public USING (true);

DROP POLICY IF EXISTS "Allow public update of test attempts" ON public.test_attempts;
CREATE POLICY "Allow public update of test attempts" ON public.test_attempts FOR UPDATE TO public USING (true) WITH CHECK (true);

-- 3. Test Attempt Answers: Insert, Select, and Update
DROP POLICY IF EXISTS "Allow public insert of answers" ON public.test_attempt_answers;
CREATE POLICY "Allow public insert of answers" ON public.test_attempt_answers FOR INSERT TO public WITH CHECK (true);

DROP POLICY IF EXISTS "Allow public read of answers" ON public.test_attempt_answers;
CREATE POLICY "Allow public read of answers" ON public.test_attempt_answers FOR SELECT TO public USING (true);

DROP POLICY IF EXISTS "Allow public update of answers" ON public.test_attempt_answers;
CREATE POLICY "Allow public update of answers" ON public.test_attempt_answers FOR UPDATE TO public USING (true) WITH CHECK (true);

-- 4. User Responses: Insert, Select, and Update (Option chosen & time taken)
ALTER TABLE public.user_responses ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow public insert of user_responses" ON public.user_responses;
CREATE POLICY "Allow public insert of user_responses" ON public.user_responses FOR INSERT TO public WITH CHECK (true);

DROP POLICY IF EXISTS "Allow public select of user_responses" ON public.user_responses;
CREATE POLICY "Allow public select of user_responses" ON public.user_responses FOR SELECT TO public USING (true);

DROP POLICY IF EXISTS "Allow public update of user_responses" ON public.user_responses;
CREATE POLICY "Allow public update of user_responses" ON public.user_responses FOR UPDATE TO public USING (true) WITH CHECK (true);

-- ==============================================================================
-- Leaderboard View
-- ==============================================================================
CREATE OR REPLACE VIEW public.mock_leaderboard AS
SELECT 
    id,
    roll_number,
    candidate_name,
    test_id,
    total_score,
    accuracy_percentage,
    time_taken_seconds,
    total_correct,
    total_incorrect,
    submitted_at,
    RANK() OVER (PARTITION BY test_id ORDER BY total_score DESC, time_taken_seconds ASC) as rank
FROM public.test_attempts
WHERE status = 'submitted'
ORDER BY test_id, rank;
