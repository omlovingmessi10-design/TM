-- ==============================================================================
-- ToppersMock - Supabase Database Schema for SSC CGL Mock Test
-- ==============================================================================
-- This schema tracks candidate test attempts, timing, question responses, 
-- and automatic timestamps.
-- ==============================================================================

-- 1. Enable UUID Extension (built into PostgreSQL & Supabase)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ==============================================================================
-- Table: test_attempts
-- Records overall exam session, final scores, and timestamps
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.test_attempts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Candidate Identification
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL, -- Optional link to Supabase Auth
    roll_number VARCHAR(50) NOT NULL DEFAULT 'ANONYMOUS',
    candidate_name VARCHAR(150),
    candidate_email VARCHAR(255),
    
    -- Test Details
    test_id VARCHAR(100) NOT NULL DEFAULT 'ssc_cgl_tier1_mock_1',
    test_title VARCHAR(255) NOT NULL DEFAULT 'SSC CGL Tier-I (CBT) Full Mock Test 1',
    
    -- Performance Metrics
    total_questions INTEGER NOT NULL DEFAULT 100,
    total_attempted INTEGER NOT NULL DEFAULT 0,
    total_correct INTEGER NOT NULL DEFAULT 0,
    total_incorrect INTEGER NOT NULL DEFAULT 0,
    total_unattempted INTEGER NOT NULL DEFAULT 0,
    
    -- Scoring (+2 for correct, -0.50 for incorrect in SSC CGL)
    total_score NUMERIC(6, 2) NOT NULL DEFAULT 0.00,
    accuracy_percentage NUMERIC(5, 2) NOT NULL DEFAULT 0.00,
    
    -- Section-Wise Breakdown (JSONB for fast querying and flexibility)
    section_breakdown JSONB DEFAULT '[]'::jsonb,
    
    -- Timestamps
    time_taken_seconds INTEGER NOT NULL DEFAULT 0,
    timestamp TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    started_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    submitted_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    
    -- Client & Device Metadata
    client_ip TEXT,
    user_agent TEXT
);

-- Ensure timestamp column exists if table was created previously
ALTER TABLE public.test_attempts ADD COLUMN IF NOT EXISTS "timestamp" TIMESTAMPTZ DEFAULT timezone('utc'::text, now());

-- ==============================================================================
-- Table: test_attempt_answers (Optional Detailed Question Log)
-- Records response, status, and time spent per individual question
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
    
    status VARCHAR(30) NOT NULL,         -- 'answered', 'not_answered', 'marked', 'marked_answered', 'not_visited'
    time_spent_seconds INTEGER DEFAULT 0,
    
    timestamp TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
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
-- Indexes for Fast Analytics and Leaderboards
-- ==============================================================================
CREATE INDEX IF NOT EXISTS idx_test_attempts_submitted_at ON public.test_attempts (submitted_at DESC);
CREATE INDEX IF NOT EXISTS idx_test_attempts_test_id_score ON public.test_attempts (test_id, total_score DESC);
CREATE INDEX IF NOT EXISTS idx_test_attempts_roll_number ON public.test_attempts (roll_number);
CREATE INDEX IF NOT EXISTS idx_test_attempt_answers_attempt_id ON public.test_attempt_answers (attempt_id);

-- ==============================================================================
-- Row-Level Security (RLS) Configuration
-- ==============================================================================
ALTER TABLE public.test_attempts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.test_attempt_answers ENABLE ROW LEVEL SECURITY;

-- 1. Allow any user (public/anonymous or authenticated) to record (insert) test submissions
DROP POLICY IF EXISTS "Allow public insert of test attempts" ON public.test_attempts;
CREATE POLICY "Allow public insert of test attempts"
ON public.test_attempts
FOR INSERT
TO public
WITH CHECK (true);

-- 2. Allow reading of test attempts for leaderboard/results
DROP POLICY IF EXISTS "Allow public read of test attempts" ON public.test_attempts;
CREATE POLICY "Allow public read of test attempts"
ON public.test_attempts
FOR SELECT
TO public
USING (true);

-- 3. Detailed answers permissions
DROP POLICY IF EXISTS "Allow public insert of answers" ON public.test_attempt_answers;
CREATE POLICY "Allow public insert of answers"
ON public.test_attempt_answers
FOR INSERT
TO public
WITH CHECK (true);

DROP POLICY IF EXISTS "Allow public read of answers" ON public.test_attempt_answers;
CREATE POLICY "Allow public read of answers"
ON public.test_attempt_answers
FOR SELECT
TO public
USING (true);

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
    total_correct,
    total_incorrect,
    time_taken_seconds,
    submitted_at,
    RANK() OVER (PARTITION BY test_id ORDER BY total_score DESC, time_taken_seconds ASC) AS rank
FROM public.test_attempts
ORDER BY test_id, rank ASC;
