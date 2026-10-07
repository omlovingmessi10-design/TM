const fs = require('fs');
const path = require('path');

const mock3Data = JSON.parse(fs.readFileSync(path.join(__dirname, '..', 'ssc_cgl_mock_test_3.json'), 'utf8'));

function escapeSql(str) {
  if (str === null || str === undefined) return 'NULL';
  return "'" + String(str).replace(/'/g, "''") + "'";
}

let sql = `-- ==============================================================================
-- All-In-One Setup & Seed: SSC CGL Tier-1 Mock Test 3 for Supabase
-- ==============================================================================
-- Safe for both NEW databases and EXISTING databases (automatically alters columns)
-- ==============================================================================

-- 1. Enable UUID Extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. Create Table: mock_tests
CREATE TABLE IF NOT EXISTS public.mock_tests (
    id VARCHAR(100) PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    total_questions INTEGER NOT NULL DEFAULT 100,
    total_time_minutes INTEGER NOT NULL DEFAULT 60,
    sectional_time_minutes INTEGER NOT NULL DEFAULT 15,
    has_sectional_timing BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- 3. Create Table: questions
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

-- 4. Create Table: test_attempts
CREATE TABLE IF NOT EXISTS public.test_attempts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    roll_number VARCHAR(50) NOT NULL DEFAULT 'ANONYMOUS',
    candidate_name VARCHAR(150) DEFAULT 'ANKIT SHARMA',
    candidate_email VARCHAR(255),
    test_id VARCHAR(100) NOT NULL DEFAULT 'ssc_cgl_tier1_mock_3',
    test_title VARCHAR(255) NOT NULL DEFAULT 'SSC CGL Tier-I Full Mock Test 3',
    status VARCHAR(30) NOT NULL DEFAULT 'in_progress',
    current_section_id VARCHAR(50) NOT NULL DEFAULT 'gi',
    current_question_number INTEGER NOT NULL DEFAULT 1,
    sectional_time_left JSONB NOT NULL DEFAULT '{"gi": 900, "ga": 900, "qa": 900, "ec": 900}'::jsonb,
    completed_sections JSONB NOT NULL DEFAULT '[]'::jsonb,
    question_states JSONB NOT NULL DEFAULT '{}'::jsonb,
    total_questions INTEGER NOT NULL DEFAULT 100,
    total_attempted INTEGER NOT NULL DEFAULT 0,
    total_correct INTEGER NOT NULL DEFAULT 0,
    total_incorrect INTEGER NOT NULL DEFAULT 0,
    total_unattempted INTEGER NOT NULL DEFAULT 100,
    total_score NUMERIC(6, 2) NOT NULL DEFAULT 0.00,
    accuracy_percentage NUMERIC(5, 2) NOT NULL DEFAULT 0.00,
    section_breakdown JSONB DEFAULT '[]'::jsonb,
    time_taken_seconds INTEGER NOT NULL DEFAULT 0,
    started_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    submitted_at TIMESTAMPTZ,
    last_synced_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    client_ip TEXT,
    user_agent TEXT
);

-- CRITICAL FIX: Ensure all columns exist even if test_attempts already existed previously
ALTER TABLE public.test_attempts ADD COLUMN IF NOT EXISTS status VARCHAR(30) DEFAULT 'in_progress';
ALTER TABLE public.test_attempts ADD COLUMN IF NOT EXISTS current_section_id VARCHAR(50) DEFAULT 'gi';
ALTER TABLE public.test_attempts ADD COLUMN IF NOT EXISTS current_question_number INTEGER DEFAULT 1;
ALTER TABLE public.test_attempts ADD COLUMN IF NOT EXISTS sectional_time_left JSONB DEFAULT '{"gi": 900, "ga": 900, "qa": 900, "ec": 900}'::jsonb;
ALTER TABLE public.test_attempts ADD COLUMN IF NOT EXISTS completed_sections JSONB DEFAULT '[]'::jsonb;
ALTER TABLE public.test_attempts ADD COLUMN IF NOT EXISTS question_states JSONB DEFAULT '{}'::jsonb;
ALTER TABLE public.test_attempts ADD COLUMN IF NOT EXISTS last_synced_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now());

-- 5. Create Table: test_attempt_answers
CREATE TABLE IF NOT EXISTS public.test_attempt_answers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    attempt_id UUID NOT NULL REFERENCES public.test_attempts(id) ON DELETE CASCADE,
    question_number INTEGER NOT NULL,
    section_name VARCHAR(100) NOT NULL,
    selected_option VARCHAR(10),
    correct_option VARCHAR(10) NOT NULL,
    is_correct BOOLEAN DEFAULT FALSE,
    marks_awarded NUMERIC(4, 2) DEFAULT 0.00,
    status VARCHAR(30) NOT NULL,
    time_spent_seconds INTEGER NOT NULL DEFAULT 0,
    timestamp TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    UNIQUE (attempt_id, question_number)
);

ALTER TABLE public.test_attempt_answers ADD COLUMN IF NOT EXISTS time_spent_seconds INTEGER DEFAULT 0;

-- 6. Enable Row Level Security (RLS)
ALTER TABLE public.mock_tests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.test_attempts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.test_attempt_answers ENABLE ROW LEVEL SECURITY;

-- 7. Configure RLS Policies
DROP POLICY IF EXISTS "Allow public read of mock tests" ON public.mock_tests;
CREATE POLICY "Allow public read of mock tests" ON public.mock_tests FOR SELECT TO public USING (true);

DROP POLICY IF EXISTS "Allow public read of questions" ON public.questions;
CREATE POLICY "Allow public read of questions" ON public.questions FOR SELECT TO public USING (true);

DROP POLICY IF EXISTS "Allow public insert of test attempts" ON public.test_attempts;
CREATE POLICY "Allow public insert of test attempts" ON public.test_attempts FOR INSERT TO public WITH CHECK (true);

DROP POLICY IF EXISTS "Allow public read of test attempts" ON public.test_attempts;
CREATE POLICY "Allow public read of test attempts" ON public.test_attempts FOR SELECT TO public USING (true);

DROP POLICY IF EXISTS "Allow public update of test attempts" ON public.test_attempts;
CREATE POLICY "Allow public update of test attempts" ON public.test_attempts FOR UPDATE TO public USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow public insert of answers" ON public.test_attempt_answers;
CREATE POLICY "Allow public insert of answers" ON public.test_attempt_answers FOR INSERT TO public WITH CHECK (true);

DROP POLICY IF EXISTS "Allow public read of answers" ON public.test_attempt_answers;
CREATE POLICY "Allow public read of answers" ON public.test_attempt_answers FOR SELECT TO public USING (true);

DROP POLICY IF EXISTS "Allow public update of answers" ON public.test_attempt_answers;
CREATE POLICY "Allow public update of answers" ON public.test_attempt_answers FOR UPDATE TO public USING (true) WITH CHECK (true);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_test_attempts_status_user ON public.test_attempts (status, roll_number);
CREATE INDEX IF NOT EXISTS idx_test_attempts_test_id ON public.test_attempts (test_id, status);
CREATE INDEX IF NOT EXISTS idx_test_attempt_answers_attempt_q ON public.test_attempt_answers (attempt_id, question_number);

-- ==============================================================================
-- 8. Seed Mock Test 3 Record
-- ==============================================================================
INSERT INTO public.mock_tests (id, title, total_questions, total_time_minutes, sectional_time_minutes, has_sectional_timing)
VALUES ('ssc_cgl_tier1_mock_3', 'SSC CGL Tier-I Full Mock Test 3 (TCS iON CBT Pattern)', 100, 60, 15, TRUE)
ON CONFLICT (id) DO UPDATE SET
  title = EXCLUDED.title,
  total_questions = EXCLUDED.total_questions,
  total_time_minutes = EXCLUDED.total_time_minutes,
  sectional_time_minutes = EXCLUDED.sectional_time_minutes,
  has_sectional_timing = EXCLUDED.has_sectional_timing;

-- Clear previous questions for this test to allow clean re-seeding
DELETE FROM public.questions WHERE test_id = 'ssc_cgl_tier1_mock_3';

-- ==============================================================================
-- 9. Insert All 100 Questions for Mock Test 3
-- ==============================================================================
INSERT INTO public.questions (
  test_id, question_number, part_number, section_name, section_title, 
  chapter_name, difficulty, question_text, question_text_hi, 
  options, options_hi, correct_option, solution_text, solution_text_hi
) VALUES
`;

const rows = mock3Data.map((q) => {
  const testId = "'ssc_cgl_tier1_mock_3'";
  const qNum = q.question_number;
  const partNum = q.part_number || (Math.floor((q.question_number - 1) / 25) + 1);
  const secName = escapeSql(q.section_name || `PART-${partNum}`);
  const secTitle = escapeSql(q.section_title);
  const chapterName = escapeSql(q.chapter_name || '');
  const difficulty = escapeSql(q.difficulty || 'Moderate');
  const qText = escapeSql(q.question_text);
  const qTextHi = escapeSql(q.question_text_hi || '');
  const optionsJson = escapeSql(JSON.stringify(q.options || {}));
  const optionsHiJson = escapeSql(JSON.stringify(q.options_hi || {}));
  const correctOpt = escapeSql(q.correct_option);
  const solText = escapeSql(q.solution_text || '');
  const solTextHi = escapeSql(q.solution_text_hi || '');

  return `  (${testId}, ${qNum}, ${partNum}, ${secName}, ${secTitle}, ${chapterName}, ${difficulty}, ${qText}, ${qTextHi}, ${optionsJson}::jsonb, ${optionsHiJson}::jsonb, ${correctOpt}, ${solText}, ${solTextHi})`;
});

sql += rows.join(',\n') + ';\n\n';
sql += `-- Verification
SELECT count(*) AS total_mock_3_questions_seeded FROM public.questions WHERE test_id = 'ssc_cgl_tier1_mock_3';
`;

fs.writeFileSync(path.join(__dirname, '..', 'mock_test_3_seed.sql'), sql, 'utf8');
console.log(`Generated mock_test_3_seed.sql with automatic column migrations and ${mock3Data.length} questions.`);
