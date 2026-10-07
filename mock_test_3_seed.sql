-- ==============================================================================
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

-- Create Table: user_responses (Dedicated table for option chosen and time taken)
CREATE TABLE IF NOT EXISTS public.user_responses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    attempt_id TEXT NOT NULL,
    roll_number VARCHAR(50) NOT NULL DEFAULT '2201048291',
    candidate_name VARCHAR(150) DEFAULT 'ANKIT SHARMA',
    test_id VARCHAR(100) NOT NULL DEFAULT 'ssc_cgl_tier1_mock_3',
    question_number INTEGER NOT NULL,
    section_name VARCHAR(100) NOT NULL,
    selected_option VARCHAR(10),
    time_taken_seconds INTEGER NOT NULL DEFAULT 0,
    correct_option VARCHAR(10),
    is_correct BOOLEAN DEFAULT FALSE,
    status VARCHAR(30) NOT NULL DEFAULT 'ANSWERED',
    recorded_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    UNIQUE (attempt_id, question_number)
);

-- 6. Enable Row Level Security (RLS)
ALTER TABLE public.mock_tests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.test_attempts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.test_attempt_answers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_responses ENABLE ROW LEVEL SECURITY;

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

DROP POLICY IF EXISTS "Allow public insert of user_responses" ON public.user_responses;
CREATE POLICY "Allow public insert of user_responses" ON public.user_responses FOR INSERT TO public WITH CHECK (true);

DROP POLICY IF EXISTS "Allow public read of user_responses" ON public.user_responses;
CREATE POLICY "Allow public read of user_responses" ON public.user_responses FOR SELECT TO public USING (true);

DROP POLICY IF EXISTS "Allow public update of user_responses" ON public.user_responses;
CREATE POLICY "Allow public update of user_responses" ON public.user_responses FOR UPDATE TO public USING (true) WITH CHECK (true);

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
  ('ssc_cgl_tier1_mock_3', 1, 1, 'PART-1', 'General Intelligence & Reasoning', 'Number Series', 'Hard', 'Select the number that can replace the question mark (?) in the following series:
7, 19, 51, 121, 247, 447, ?', 'निम्नलिखित श्रृंखला में प्रश्न चिह्न (?) के स्थान पर आने वाली संख्या का चयन कीजिए:
7, 19, 51, 121, 247, 447, ?', '{"a":"721","b":"739","c":"753","d":"715"}'::jsonb, '{"a":"721","b":"739","c":"753","d":"715"}'::jsonb, 'b', 'Calculate the first level of differences between consecutive terms:
 19 - 7 = 12
 51 - 19 = 32
 121 - 51 = 70
 247 - 121 = 126
 447 - 247 = 200

Now, calculate the second level of differences:
 32 - 12 = 20
 70 - 32 = 38
 126 - 70 = 56
 200 - 126 = 74

Notice that the second differences increase by a constant +18:
 38 - 20 = 18
 56 - 38 = 18
 74 - 56 = 18

Following this constant difference of 18:
Next second difference = 74 + 18 = 92
Next first difference = 200 + 92 = 292
Next term in series = 447 + 292 = 739.

Correct Option: (b)', 'क्रमागत पदों के प्रथम स्तर का अंतर:
 19 - 7 = 12
 51 - 19 = 32
 121 - 51 = 70
 247 - 121 = 126
 447 - 247 = 200

अब, दूसरे स्तर का अंतर ज्ञात करें:
 32 - 12 = 20
 70 - 32 = 38
 126 - 70 = 56
 200 - 126 = 74

द्वितीय अंतर में +18 की स्थिर वृद्धि है:
 38 - 20 = 18
 56 - 38 = 18
 74 - 56 = 18

अतः अगला द्वितीय अंतर = 74 + 18 = 92
अगला प्रथम अंतर = 200 + 92 = 292
श्रृंखला का अगला पद = 447 + 292 = 739।

अतः सही उत्तर (b) है।'),
  ('ssc_cgl_tier1_mock_3', 2, 1, 'PART-1', 'General Intelligence & Reasoning', 'Letter Series', 'Easy', 'Which letter cluster will replace the question mark (?) in the following series?
BDF, CFI, DHL, EJO, ?', 'निम्नलिखित श्रृंखला में प्रश्न चिह्न (?) के स्थान पर कौन-सा अक्षर समूह आएगा?
BDF, CFI, DHL, EJO, ?', '{"a":"GMS","b":"FLR","c":"FKQ","d":"EMR"}'::jsonb, '{"a":"GMS","b":"FLR","c":"FKQ","d":"EMR"}'::jsonb, 'b', 'Pattern of letter positions across clusters:
- First letter: B(2) + 1 = C(3) + 1 = D(4) + 1 = E(5) + 1 = F(6)
- Second letter: D(4) + 2 = F(6) + 2 = H(8) + 2 = J(10) + 2 = L(12)
- Third letter: F(6) + 3 = I(9) + 3 = L(12) + 3 = O(15) + 3 = R(18)

Thus, the missing letter cluster is FLR.

Correct Option: (b)', 'प्रत्येक पद के अक्षरों का प्रतिरूप:
- पहला अक्षर: B(2) + 1 = C(3) + 1 = D(4) + 1 = E(5) + 1 = F(6)
- दूसरा अक्षर: D(4) + 2 = F(6) + 2 = H(8) + 2 = J(10) + 2 = L(12)
- तीसरा अक्षर: F(6) + 3 = I(9) + 3 = L(12) + 3 = O(15) + 3 = R(18)

अतः लुप्त अक्षर समूह FLR है।

अतः सही उत्तर (b) है।'),
  ('ssc_cgl_tier1_mock_3', 3, 1, 'PART-1', 'General Intelligence & Reasoning', 'Coding-Decoding', 'Moderate', 'In a certain code language, ''VICTORY'' is coded as ''CIVSYRO''. How will ''TRIUMPH'' be coded in that language?', 'एक निश्चित कूट भाषा में, ''VICTORY'' को ''CIVSYRO'' के रूप में कूटबद्ध किया जाता है। उसी भाषा में ''TRIUMPH'' को किस प्रकार कूटबद्ध किया जाएगा?', '{"a":"IRTTHMP","b":"IRTUGPM","c":"IRTTHPM","d":"RITHHPM"}'::jsonb, '{"a":"IRTTHMP","b":"IRTUGPM","c":"IRTTHPM","d":"RITHHPM"}'::jsonb, 'c', 'Pattern analysis for ''VICTORY'' (7 letters):
- The first 3 letters ''VIC'' are reversed to give ''CIV''.
- The middle letter ''T'' is decreased by 1: T - 1 = S.
- The last 3 letters ''ORY'' are reversed to give ''YRO''.
- Concatenating gives ''CIVSYRO''.

Applying the same rule to ''TRIUMPH'':
- First 3 letters ''TRI'' reversed → ''IRT''
- Middle letter ''U'' - 1 = ''T''
- Last 3 letters ''MPH'' reversed → ''HPM''

Combining these segments gives ''IRTTHPM''.

Correct Option: (c)', '''VICTORY'' के लिए कूटन विधि:
- पहले 3 अक्षर ''VIC'' को उलट कर लिखा गया है → ''CIV''
- मध्य अक्षर ''T'' में से 1 घटाया गया है: T - 1 = S
- अंतिम 3 अक्षर ''ORY'' को उलट कर लिखा गया है → ''YRO''
- मिलाकर बना: ''CIVSYRO''

यही नियम ''TRIUMPH'' पर लागू करने पर:
- प्रथम 3 अक्षर ''TRI'' का उल्टा → ''IRT''
- मध्य अक्षर ''U'' - 1 = ''T''
- अंतिम 3 अक्षर ''MPH'' का उल्टा → ''HPM''

अतः अभीष्ट कूट ''IRTTHPM'' है।

अतः सही उत्तर (c) है।'),
  ('ssc_cgl_tier1_mock_3', 4, 1, 'PART-1', 'General Intelligence & Reasoning', 'Blood Relations', 'Hard', 'Read the following information carefully:
''A + B'' means ''A is the father of B''
''A − B'' means ''A is the mother of B''
''A × B'' means ''A is the brother of B''
''A ÷ B'' means ''A is the sister of B''

If the expression is ''M + N − O × P ÷ Q'', how is M related to Q?', 'निम्नलिखित जानकारी को ध्यानपूर्वक पढ़िए:
''A + B'' का अर्थ है ''A, B का पिता है''
''A − B'' का अर्थ है ''A, B की माता है''
''A × B'' का अर्थ है ''A, B का भाई है''
''A ÷ B'' का अर्थ है ''A, B की बहन है''

यदि व्यंजक ''M + N − O × P ÷ Q'' है, तो M का Q से क्या संबंध है?', '{"a":"Father","b":"Paternal Grandfather","c":"Maternal Uncle","d":"Maternal Grandfather"}'::jsonb, '{"a":"पिता","b":"दादा (पितृ पक्षीय)","c":"मामा","d":"नाना (मातृ पक्षीय)"}'::jsonb, 'd', 'Decoding the relationship step-by-step from the expression ''M + N − O × P ÷ Q'':
1. ''P ÷ Q'' → P is the sister of Q.
2. ''O × P'' → O is the brother of P. (So O, P, and Q are siblings).
3. ''N − O'' → N is the mother of O. (Therefore, N is the mother of all three siblings: O, P, and Q).
4. ''M + N'' → M is the father of N.

Since N is Q''s mother and M is N''s father, M is Q''s mother''s father, which is Maternal Grandfather.

Correct Option: (d)', 'व्यंजक ''M + N − O × P ÷ Q'' का चरणबद्ध विश्लेषण:
1. ''P ÷ Q'' → P, Q की बहन है।
2. ''O × P'' → O, P का भाई है। (अतः O, P और Q सहोदर/भाई-बहन हैं)।
3. ''N − O'' → N, O की माता है। (अतः N, Q की भी माता है)।
4. ''M + N'' → M, N का पिता है।

M, Q की माता (N) का पिता है, अर्थात M, Q का नाना है।

अतः सही उत्तर (d) है।'),
  ('ssc_cgl_tier1_mock_3', 5, 1, 'PART-1', 'General Intelligence & Reasoning', 'Mathematical Operations', 'Moderate', 'Which two signs should be interchanged to make the given equation correct?
54 ÷ 6 × 8 + 4 − 15 = 26', 'दिए गए समीकरण को संतुलित करने के लिए किन दो चिन्हों को परस्पर बदलना चाहिए?
54 ÷ 6 × 8 + 4 − 15 = 26', '{"a":"÷ and +","b":"× and +","c":"÷ and ×","d":"+ and −"}'::jsonb, '{"a":"÷ और +","b":"× और +","c":"÷ और ×","d":"+ और −"}'::jsonb, 'b', 'Given Equation: 54 ÷ 6 × 8 + 4 − 15 = 26

Testing Option (b): Interchange ''×'' and ''+''
New Equation: 54 ÷ 6 + 8 × 4 − 15

Applying BODMAS:
Step 1 (Division): 54 ÷ 6 = 9
Equation becomes: 9 + 8 × 4 − 15

Step 2 (Multiplication): 8 × 4 = 32
Equation becomes: 9 + 32 − 15

Step 3 (Addition & Subtraction):
41 − 15 = 26

Since LHS = RHS (26 = 26), interchanging ''×'' and ''+'' balances the equation.

Correct Option: (b)', 'दिया गया समीकरण: 54 ÷ 6 × 8 + 4 − 15 = 26

विकल्प (b) के अनुसार ''×'' और ''+'' को परस्पर बदलने पर:
नया समीकरण: 54 ÷ 6 + 8 × 4 − 15

BODMAS नियम लागू करने पर:
चरण 1 (भाग): 54 ÷ 6 = 9
समीकरण: 9 + 8 × 4 − 15

चरण 2 (गुणा): 8 × 4 = 32
समीकरण: 9 + 32 − 15

चरण 3 (जोड़ व घटाव):
41 − 15 = 26

बायाँ पक्ष = दायाँ पक्ष (26 = 26)। अतः सही उत्तर (b) है।'),
  ('ssc_cgl_tier1_mock_3', 6, 1, 'PART-1', 'General Intelligence & Reasoning', 'Syllogism', 'Hard', 'Read the given statements and conclusions carefully. Assuming that the information in the statements is true, decide which of the given conclusions logically follow(s) from the statements.

Statements:
1. Only a few Desks are Tables.
2. All Tables are Chairs.
3. No Chair is a Bench.

Conclusions:
I. Some Desks are Chairs.
II. All Desks being Benches is a possibility.
III. No Table is a Bench.', 'दिए गए कथनों और निष्कर्षों को ध्यानपूर्वक पढ़िए। कथनों को सत्य मानते हुए निर्णय लीजिए कि कौन-सा/से निष्कर्ष तार्किक रूप से अनुसरण करता है/करते हैं।

कथन:
1. केवल कुछ डेस्क, टेबल हैं।
2. सभी टेबल, कुर्सियाँ हैं।
3. कोई कुर्सी, बेंच नहीं है।

निष्कर्ष:
I. कुछ डेस्क, कुर्सियाँ हैं।
II. सभी डेस्क के बेंच होने की संभावना है।
III. कोई टेबल, बेंच नहीं है।', '{"a":"Only Conclusions I and III follow","b":"Only Conclusion I follows","c":"Only Conclusions I and II follow","d":"All Conclusions I, II and III follow"}'::jsonb, '{"a":"केवल निष्कर्ष I और III अनुसरण करते हैं","b":"केवल निष्कर्ष I अनुसरण करता है","c":"केवल निष्कर्ष I और II अनुसरण करते हैं","d":"सभी निष्कर्ष I, II और III अनुसरण करते हैं"}'::jsonb, 'a', 'Logical analysis of the statements:
1. ''Only a few Desks are Tables'' means: Some Desks are Tables AND Some Desks are not Tables.
2. ''All Tables are Chairs'': The entire Table set is inside the Chair set.
3. ''No Chair is a Bench'': The Chair set and Bench set are disjoint.

Evaluation of conclusions:
- Conclusion I: ''Some Desks are Chairs''. Since some Desks are Tables and all Tables are Chairs, those Desks are definitely Chairs. Hence, Conclusion I is DEFINITELY TRUE.
- Conclusion II: ''All Desks being Benches is a possibility''. The portion of Desks that are Tables are also Chairs. Since no Chair can be a Bench, that common portion of Desks can NEVER be a Bench. Hence, all Desks can NEVER be Benches. Conclusion II is FALSE.
- Conclusion III: ''No Table is a Bench''. Since all Tables are inside Chairs and no Chair is a Bench, no Table can be a Bench. Hence, Conclusion III is DEFINITELY TRUE.

Therefore, only Conclusions I and III follow.

Correct Option: (a)', 'कथनों का तार्किक विश्लेषण:
1. ''केवल कुछ डेस्क, टेबल हैं'' का अर्थ है: कुछ डेस्क टेबल हैं तथा कुछ डेस्क टेबल नहीं हैं।
2. ''सभी टेबल, कुर्सियाँ हैं'': टेबल का पूरा हिस्सा कुर्सी के अंदर है।
3. ''कोई कुर्सी, बेंच नहीं है'': कुर्सी और बेंच में कोई संबंध नहीं हो सकता।

निष्कर्षों की जाँच:
- निष्कर्ष I: ''कुछ डेस्क, कुर्सियाँ हैं'' → चूँकि कुछ डेस्क टेबल हैं और सभी टेबल कुर्सियाँ हैं, इसलिए वे डेस्क कुर्सियाँ भी होंगी। अतः निष्कर्ष I सही है।
- निष्कर्ष II: ''सभी डेस्क के बेंच होने की संभावना है'' → डेस्क का जो भाग टेबल (कुर्सी) है, वह कभी बेंच नहीं हो सकता। अतः सभी डेस्क कभी बेंच नहीं हो सकते। यह संभावना गलत है।
- निष्कर्ष III: ''कोई टेबल, बेंच नहीं है'' → सभी टेबल कुर्सियों के भीतर हैं और कोई कुर्सी बेंच नहीं है, अतः कोई टेबल बेंच नहीं हो सकती। यह निष्कर्ष पूर्णतः सत्य है।

अतः केवल निष्कर्ष I और III अनुसरण करते हैं।

अतः सही उत्तर (a) है।'),
  ('ssc_cgl_tier1_mock_3', 7, 1, 'PART-1', 'General Intelligence & Reasoning', 'Seating Arrangement', 'Hard', 'Eight friends — P, Q, R, S, T, U, V, and W — are sitting in a straight line facing North.
- V sits at the extreme right end of the line.
- Exactly three people sit between V and T.
- R sits second to the left of T.
- P sits to the immediate right of R.
- W sits third to the right of P.
- S sits to the immediate left of W.
- Q sits at the extreme left end of the line.

Who sits third to the left of U?', 'आठ मित्र — P, Q, R, S, T, U, V और W — एक सीधी पंक्ति में उत्तर की ओर मुख करके बैठे हैं।
- V पंक्ति के दायें छोर पर बैठा है।
- V और T के बीच ठीक तीन व्यक्ति बैठे हैं।
- R, T के बायें से दूसरे स्थान पर बैठा है।
- P, R के ठीक दायें बैठा है।
- W, P के दायें से तीसरे स्थान पर बैठा है।
- S, W के ठीक बायें बैठा है।
- Q पंक्ति के बायें छोर पर बैठा है।

U के बायें से तीसरे स्थान पर कौन बैठा है?', '{"a":"T","b":"R","c":"S","d":"P"}'::jsonb, '{"a":"T","b":"R","c":"S","d":"P"}'::jsonb, 'a', 'Let positions from left to right be 1 to 8 (all facing North):
1. ''V sits at the extreme right end'' → Position 8 = V.
2. ''Three people sit between V and T'' → V is at 8, so T must be at Position 4 (leaving 5, 6, 7 in between).
3. ''R sits second to the left of T'' → T is at 4, so R is at Position 2.
4. ''P sits to the immediate right of R'' → R is at 2, so P is at Position 3.
5. ''W sits third to the right of P'' → P is at 3, so W is at 3 + 3 = Position 6.
6. ''S sits to the immediate left of W'' → W is at 6, so S is at Position 5.
7. ''Q sits at the extreme left end'' → Position 1 = Q.
8. The only remaining position is Position 7, which must be occupied by U.

Full arrangement from left to right (Positions 1 to 8):
1: Q, 2: R, 3: P, 4: T, 5: S, 6: W, 7: U, 8: V.

U is at Position 7. The person sitting third to the left of U is at Position 7 − 3 = 4, which is T.

Correct Option: (a)', 'बायें से दायें 1 से 8 तक के स्थान निर्धारित करते हैं (सभी उत्तर की ओर मुख किए हुए):
1. ''V दायें छोर पर है'' → स्थान 8 = V
2. ''V और T के मध्य तीन व्यक्ति हैं'' → स्थान 4 = T (मध्य में 5, 6, 7)
3. ''R, T के बायें दूसरा है'' → स्थान 2 = R
4. ''P, R के ठीक दायें है'' → स्थान 3 = P
5. ''W, P के दायें तीसरा है'' → स्थान 6 = W (3 + 3 = 6)
6. ''S, W के ठीक बायें है'' → स्थान 5 = S
7. ''Q बायें छोर पर है'' → स्थान 1 = Q
8. शेष बचा स्थान 7 स्वतः U का होगा।

पंक्ति का पूर्ण क्रम (बायें से दायें):
1: Q, 2: R, 3: P, 4: T, 5: S, 6: W, 7: U, 8: V

U स्थान 7 पर है। U के बायें तीसरा स्थान = 7 − 3 = स्थान 4, जिस पर T बैठा है।

अतः सही उत्तर (a) है।'),
  ('ssc_cgl_tier1_mock_3', 8, 1, 'PART-1', 'General Intelligence & Reasoning', 'Blood Relations', 'Easy', 'Pointing towards a woman, a man said, "Her mother is the only daughter of my mother." How is the man related to the woman?', 'एक महिला की ओर इशारा करते हुए एक पुरुष ने कहा, "उसकी माता, मेरी माता की इकलौती पुत्री है।" उस पुरुष का उस महिला से क्या संबंध है?', '{"a":"Maternal Uncle","b":"Brother","c":"Father","d":"Paternal Uncle"}'::jsonb, '{"a":"मामा","b":"भाई","c":"पिता","d":"चाचा"}'::jsonb, 'a', 'Breaking down the statement:
1. "The only daughter of my mother" = The man''s sister.
2. "Her mother is the only daughter of my mother" → The woman''s mother is the man''s sister.

Since the man is the brother of the woman''s mother, the man is her Maternal Uncle (मामा).

Correct Option: (a)', 'कथन का विश्लेषण:
1. "मेरी माता की इकलौती पुत्री" = उस पुरुष की बहन।
2. "उसकी माता मेरी माता की इकलौती पुत्री है" → उस महिला की माता, पुरुष की बहन है।

चूँकि पुरुष महिला की माँ का भाई है, अतः वह पुरुष उस महिला का मामा है।

अतः सही उत्तर (a) है।'),
  ('ssc_cgl_tier1_mock_3', 9, 1, 'PART-1', 'General Intelligence & Reasoning', 'Word Analogy', 'Easy', 'Select the option that is related to the third word in the same way as the second word is related to the first word:
Dermatologist : Skin :: Ophthalmologist : ?', 'उस विकल्प का चयन कीजिए जो तीसरे शब्द से उसी प्रकार संबंधित है जैसे दूसरा शब्द पहले शब्द से संबंधित है:
त्वचा विशेषज्ञ : त्वचा :: नेत्र विशेषज्ञ : ?', '{"a":"Eyes","b":"Bones","c":"Heart","d":"Brain"}'::jsonb, '{"a":"आँखें","b":"हड्डियाँ","c":"हृदय","d":"मस्तिष्क"}'::jsonb, 'a', 'A Dermatologist is a medical specialist who diagnoses and treats conditions of the skin.
Similarly, an Ophthalmologist is a medical specialist who diagnoses and treats conditions of the eyes.

Correct Option: (a)', 'त्वचा विशेषज्ञ (Dermatologist) त्वचा से संबंधित रोगों का चिकित्सक होता है।
उसी प्रकार, नेत्र विशेषज्ञ (Ophthalmologist) आँखों (Eyes) से संबंधित रोगों का विशेषज्ञ होता है।

अतः सही उत्तर (a) है।'),
  ('ssc_cgl_tier1_mock_3', 10, 1, 'PART-1', 'General Intelligence & Reasoning', 'Order & Ranking', 'Moderate', 'In a row of students facing North, Amit is 16th from the left end and Bharat is 18th from the right end. If they interchange their positions, Amit becomes 25th from the left end. What will be Bharat''s new position from the right end?', 'उत्तर की ओर मुख किए छात्रों की एक पंक्ति में, अमित बायें छोर से 16वें स्थान पर है तथा भरत दायें छोर से 18वें स्थान पर है। यदि वे परस्पर अपना स्थान बदल लेते हैं, तो अमित बायें छोर से 25वें स्थान पर आ जाता है। भरत का दायें छोर से नया स्थान क्या होगा?', '{"a":"25th","b":"27th","c":"26th","d":"28th"}'::jsonb, '{"a":"25वाँ","b":"27वाँ","c":"26वाँ","d":"28वाँ"}'::jsonb, 'b', 'Step 1: Calculate the total number of students in the row.
After interchanging, Amit takes Bharat''s former seat.
Thus, this seat is 25th from the left and 18th from the right.
Total students = (Left position + Right position) − 1 = 25 + 18 − 1 = 42 students.

Step 2: Determine Bharat''s new position from the right end.
Bharat now occupies Amit''s former seat, which was 16th from the left end.
Bharat''s new position from right = Total − (Left position) + 1 = 42 − 16 + 1 = 27th.

Correct Option: (b)', 'चरण 1: पंक्ति में कुल छात्रों की संख्या ज्ञात करना:
स्थान बदलने के बाद अमित भरत के पुराने स्थान पर बैठता है।
अतः यह स्थान बायें से 25वाँ तथा दायें से 18वाँ है।
कुल छात्र = (बायें से स्थान + दायें से स्थान) − 1 = 25 + 18 − 1 = 42 छात्र।

चरण 2: भरत का दायें छोर से नया स्थान:
भरत अब अमित के पुराने स्थान पर बैठा है, जो बायें से 16वाँ था।
भरत का दायें से स्थान = कुल छात्र − (बायें से स्थान) + 1 = 42 − 16 + 1 = 27वाँ।

अतः सही उत्तर (b) है।'),
  ('ssc_cgl_tier1_mock_3', 11, 1, 'PART-1', 'General Intelligence & Reasoning', 'Letter Analogy', 'Easy', 'Select the option that is related to the third letter-cluster in the same way as the second letter-cluster is related to the first letter-cluster:
PRT : KMO :: JLN : ?', 'उस विकल्प का चयन कीजिए जो तीसरे अक्षर-समूह से उसी प्रकार संबंधित है जैसे दूसरा अक्षर-समूह पहले अक्षर-समूह से संबंधित है:
PRT : KMO :: JLN : ?', '{"a":"DFH","b":"FHK","c":"EGI","d":"EHK"}'::jsonb, '{"a":"DFH","b":"FHK","c":"EGI","d":"EHK"}'::jsonb, 'c', 'Analyze the alphabetical shifts:
P (16) − 5 = K (11)
R (18) − 5 = M (13)
T (20) − 5 = O (15)

Applying the same −5 shift to ''JLN'':
J (10) − 5 = E (5)
L (12) − 5 = G (7)
N (14) − 5 = I (9)

Thus, the related letter-cluster is EGI.

Correct Option: (c)', 'अक्षरों के मान में परिवर्तन:
P (16) − 5 = K (11)
R (18) − 5 = M (13)
T (20) − 5 = O (15)

यही नियम ''JLN'' पर लागू करने पर:
J (10) − 5 = E (5)
L (12) − 5 = G (7)
N (14) − 5 = I (9)

अतः सही अक्षर-समूह EGI है।

अतः सही उत्तर (c) है।'),
  ('ssc_cgl_tier1_mock_3', 12, 1, 'PART-1', 'General Intelligence & Reasoning', 'Odd One Out', 'Easy', 'Four words have been given, out of which three are alike in some manner and one is different. Select the odd one out.', 'चार शब्द दिए गए हैं, जिनमें से तीन किसी प्रकार समान हैं और एक भिन्न है। उस भिन्न शब्द का चयन कीजिए।', '{"a":"Liver","b":"Pancreas","c":"Kidney","d":"Skin"}'::jsonb, '{"a":"यकृत (Liver)","b":"अग्न्याशय (Pancreas)","c":"वृक्क (Kidney)","d":"त्वचा (Skin)"}'::jsonb, 'd', 'Liver, Kidney, and Pancreas are all internal organs of the human body. In contrast, Skin is an external organ (the largest organ and outer covering of the body). Hence, Skin is the odd one out.

Correct Option: (d)', 'यकृत (Liver), वृक्क (Kidney) और अग्न्याशय (Pancreas) मानव शरीर के आंतरिक अंग (Internal organs) हैं, जबकि त्वचा (Skin) शरीर का बाहरी अंग (External organ) है। अतः त्वचा भिन्न है।

अतः सही उत्तर (d) है।'),
  ('ssc_cgl_tier1_mock_3', 13, 1, 'PART-1', 'General Intelligence & Reasoning', 'Clock', 'Moderate', 'At what time between 4 o''clock and 5 o''clock will the hands of a clock be at a right angle (90°) for the first time?', '4 बजे और 5 बजे के बीच किस समय पहली बार घड़ी की दोनों सुइयाँ समकोण (90°) बनाएंगी?', '{"a":"4 hours 38 2/11 minutes","b":"4 hours 5 5/11 minutes","c":"4 hours 15 3/11 minutes","d":"4 hours 10 10/11 minutes"}'::jsonb, '{"a":"4 बजकर 38 सही 2/11 मिनट","b":"4 बजकर 5 सही 5/11 मिनट","c":"4 बजकर 15 सही 3/11 मिनट","d":"4 बजकर 10 सही 10/11 मिनट"}'::jsonb, 'b', 'The angle θ between the hour hand and minute hand is given by:
θ = |30H − (11/2)M|

Here, H = 4 and θ = 90°.
For the first occurrence (minute hand behind the hour hand):
30(4) − (11/2)M = 90
120 − 90 = (11/2)M
30 = (11/2)M
M = 60 / 11 = 5 5/11 minutes.

Thus, the hands are at right angles for the first time at 4 hours 5 5/11 minutes.
(Note: The second occurrence is at 4 hours 38 2/11 minutes).

Correct Option: (b)', 'घड़ी की सुइयों के बीच का कोण:
θ = |30H − (11/2)M|

यहाँ, H = 4 तथा θ = 90° है।
पहली बार समकोण बनने के लिए (मिनट की सुई घंटे की सुई से पीछे):
30 × 4 − (11/2)M = 90
120 − 90 = (11/2)M
30 = (11/2)M
M = 60 / 11 = 5 सही 5/11 मिनट।

अतः पहली बार 90° का कोण 4 बजकर 5 सही 5/11 मिनट पर बनेगा।

अतः सही उत्तर (b) है।'),
  ('ssc_cgl_tier1_mock_3', 14, 1, 'PART-1', 'General Intelligence & Reasoning', 'Letter-Number Analogy', 'Moderate', 'Select the option that is related to the third term in the same way as the second term is related to the first term:
BCD : 24 :: EFG : ?', 'उस विकल्प का चयन कीजिए जो तीसरे पद से उसी प्रकार संबंधित है जैसे दूसरा पद पहले पद से संबंधित है:
BCD : 24 :: EFG : ?', '{"a":"195","b":"180","c":"240","d":"210"}'::jsonb, '{"a":"195","b":"180","c":"240","d":"210"}'::jsonb, 'd', 'Pattern: The number is the product of the alphabetical positional values of the letters.
For ''BCD'':
B = 2, C = 3, D = 4
Product = 2 × 3 × 4 = 24.

Applying the same rule to ''EFG'':
E = 5, F = 6, G = 7
Product = 5 × 6 × 7 = 210.

Correct Option: (d)', 'तर्क: संख्या अक्षरों के वर्णमाला क्रमांकों का गुणनफल है।
''BCD'' के लिए:
B = 2, C = 3, D = 4
गुणनफल = 2 × 3 × 4 = 24

''EFG'' के लिए:
E = 5, F = 6, G = 7
गुणनफल = 5 × 6 × 7 = 210।

अतः सही उत्तर (d) है।'),
  ('ssc_cgl_tier1_mock_3', 15, 1, 'PART-1', 'General Intelligence & Reasoning', 'Dictionary Order', 'Easy', 'Select the option that represents the correct order of the given words as they would appear in an English dictionary:
1. Radiant
2. Radical
3. Radiation
4. Radiative
5. Radiate', 'दिए गए शब्दों को अंग्रेजी शब्दकोश के अनुसार व्यवस्थित करने पर सही क्रम का चयन कीजिए:
1. Radiant
2. Radical
3. Radiation
4. Radiative
5. Radiate', '{"a":"1, 3, 5, 4, 2","b":"2, 1, 5, 3, 4","c":"1, 5, 4, 3, 2","d":"1, 5, 3, 4, 2"}'::jsonb, '{"a":"1, 3, 5, 4, 2","b":"2, 1, 5, 3, 4","c":"1, 5, 4, 3, 2","d":"1, 5, 3, 4, 2"}'::jsonb, 'd', 'Comparing letter-by-letter as per English alphabetical order:
1. Radiant → ''Radia-n''
2. Radiate → ''Radia-te''
3. Radiation → ''Radia-tio''
4. Radiative → ''Radia-tiv''
5. Radical → ''Radic''

Sorting in order:
1 (Radiant) comes first (''n'' before ''t'' and ''c'')
5 (Radiate) comes second (''te'' before ''ti'')
3 (Radiation) comes third (''tio'' before ''tiv'')
4 (Radiative) comes fourth
2 (Radical) comes last (''Radic'' comes after ''Radia'')

Correct sequence: 1, 5, 3, 4, 2.

Correct Option: (d)', 'अंग्रेजी शब्दकोश के अनुसार अक्षरों का मिलान:
1. Radiant → ''Radia-n''
5. Radiate → ''Radia-te''
3. Radiation → ''Radia-tio''
4. Radiative → ''Radia-tiv''
2. Radical → ''Radic''

अक्षरों की वर्णमाला स्थिति के आधार पर सही क्रम 1, 5, 3, 4, 2 है।

अतः सही उत्तर (d) है।'),
  ('ssc_cgl_tier1_mock_3', 16, 1, 'PART-1', 'General Intelligence & Reasoning', 'Calendar', 'Hard', 'If 26th January 1950 was a Thursday, what day of the week was 15th August 1947?', 'यदि 26 जनवरी 1950 को गुरुवार था, तो 15 अगस्त 1947 को सप्ताह का कौन-सा दिन था?', '{"a":"Sunday","b":"Thursday","c":"Friday","d":"Saturday"}'::jsonb, '{"a":"रविवार","b":"गुरुवार","c":"शुक्रवार","d":"शनिवार"}'::jsonb, 'c', 'Count the total number of odd days from 15th August 1947 to 26th January 1950:

1. Days remaining in 1947:
- August (31 − 15) = 16 days → 16 mod 7 = 2
- September = 30 days → 30 mod 7 = 2
- October = 31 days → 31 mod 7 = 3
- November = 30 days → 30 mod 7 = 2
- December = 31 days → 31 mod 7 = 3
Total for 1947 = 2 + 2 + 3 + 2 + 3 = 12 days → 12 mod 7 = 5 odd days.

2. Year 1948 (Leap Year) = 366 days → 366 mod 7 = 2 odd days.
3. Year 1949 (Ordinary Year) = 365 days → 365 mod 7 = 1 odd day.
4. Year 1950 (up to 26th January) = 26 days → 26 mod 7 = 5 odd days.

Total odd days = 5 + 2 + 1 + 5 = 13 days → 13 mod 7 = 6 odd days.

Going backwards from 26th January 1950 (Thursday):
Day on 15th August 1947 = Thursday − 6 days = Friday.

Correct Option: (c)', '15 अगस्त 1947 से 26 जनवरी 1950 तक विषम दिनों की गणना:

1. वर्ष 1947 के शेष दिन:
- अगस्त (31 − 15) = 16 दिन → 16 mod 7 = 2
- सितंबर = 30 दिन → 30 mod 7 = 2
- अक्टूबर = 31 दिन → 31 mod 7 = 3
- नवंबर = 30 दिन → 30 mod 7 = 2
- दिसंबर = 31 दिन → 31 mod 7 = 3
1947 के कुल विषम दिन = 12 mod 7 = 5 विषम दिन।

2. वर्ष 1948 (लीप वर्ष) = 366 दिन → 2 विषम दिन।
3. वर्ष 1949 (साधारण वर्ष) = 365 दिन → 1 विषम दिन।
4. वर्ष 1950 (26 जनवरी तक) = 26 दिन → 26 mod 7 = 5 विषम दिन।

कुल विषम दिन = 5 + 2 + 1 + 5 = 13 दिन → 13 mod 7 = 6 विषम दिन।

26 जनवरी 1950 (गुरुवार) से 6 दिन पीछे जाने पर:
गुरुवार − 6 दिन = शुक्रवार।

अतः सही उत्तर (c) है।'),
  ('ssc_cgl_tier1_mock_3', 17, 1, 'PART-1', 'General Intelligence & Reasoning', 'Number Set Analogy', 'Hard', 'Select the set in which the numbers are related in the same way as are the numbers of the following sets.
(NOTE: Operations should be performed on the whole numbers, without breaking down the numbers into its constituent digits. E.g. 13 – Operations on 13 such as adding/subtracting/multiplying etc. to 13 can be performed. Breaking down 13 into 1 and 3 and then performing mathematical operations on 1 and 3 is not allowed)

(12, 16, 124)
(14, 18, 158)', 'उस समुच्चय का चयन कीजिए जिसमें संख्याएँ उसी प्रकार संबंधित हैं जिस प्रकार निम्नलिखित समुच्चयों की संख्याएँ संबंधित हैं।
(नोट: संख्याओं को उनके घटक अंकों में तोड़े बिना, पूर्ण संख्याओं पर संक्रियाएँ की जानी चाहिए। उदाहरण के लिए 13 – 13 पर संक्रियाएँ जैसे जोड़ना/घटाना/गुणा करना आदि किया जा सकता है। 13 को 1 और 3 में तोड़ना और फिर 1 और 3 पर गणितीय संक्रियाएँ करने की अनुमति नहीं है)

(12, 16, 124)
(14, 18, 158)', '{"a":"10, 14, 98","b":"16, 20, 196","c":"15, 24, 205","d":"18, 22, 214"}'::jsonb, '{"a":"10, 14, 98","b":"16, 20, 196","c":"15, 24, 205","d":"18, 22, 214"}'::jsonb, 'b', 'Let the triad be (A, B, C).
Pattern analysis:
C = [(A × B) ÷ 2] + (A + B)

Verification for Set 1: (12, 16, 124)
- [(12 × 16) ÷ 2] + (12 + 16)
= [192 ÷ 2] + 28
= 96 + 28 = 124 (Matches)

Verification for Set 2: (14, 18, 158)
- [(14 × 18) ÷ 2] + (14 + 18)
= [252 ÷ 2] + 32
= 126 + 32 = 158 (Matches)

Checking Option (a): (16, 20, 196)
- [(16 × 20) ÷ 2] + (16 + 20)
= [320 ÷ 2] + 36
= 160 + 36 = 196 (Matches perfectly)

Correct Option: (b)', 'समुच्चय (A, B, C) का तार्किक संबंध:
C = [(A × B) ÷ 2] + (A + B)

प्रथम समुच्चय (12, 16, 124):
[(12 × 16) ÷ 2] + (12 + 16) = 96 + 28 = 124

द्वितीय समुच्चय (14, 18, 158):
[(14 × 18) ÷ 2] + (14 + 18) = 126 + 32 = 158

विकल्प (a) की जाँच: (16, 20, 196)
[(16 × 20) ÷ 2] + (16 + 20) = 160 + 36 = 196 (सटीक मेल खाता है)।

अतः सही उत्तर (b) है।'),
  ('ssc_cgl_tier1_mock_3', 18, 1, 'PART-1', 'General Intelligence & Reasoning', 'Logical Sequence of Words', 'Easy', 'Arrange the following words in a logical and meaningful order:
1. Cotton
2. Plant
3. Shirt
4. Yarn
5. Fabric', 'निम्नलिखित शब्दों को एक तार्किक और अर्थपूर्ण क्रम में व्यवस्थित कीजिए:
1. कपास (Cotton)
2. पौधा (Plant)
3. कमीज (Shirt)
4. धागा (Yarn)
5. कपड़ा (Fabric)', '{"a":"1, 2, 4, 5, 3","b":"2, 4, 1, 5, 3","c":"2, 1, 5, 4, 3","d":"2, 1, 4, 5, 3"}'::jsonb, '{"a":"1, 2, 4, 5, 3","b":"2, 4, 1, 5, 3","c":"2, 1, 5, 4, 3","d":"2, 1, 4, 5, 3"}'::jsonb, 'd', 'The logical lifecycle from raw material cultivation to finished garment:
1. First, we grow the Plant (2).
2. The plant yields Cotton (1).
3. Cotton is spun into Yarn (4).
4. Yarn is woven into Fabric (5).
5. Fabric is tailored into a Shirt (3).

Logical sequence: 2, 1, 4, 5, 3.

Correct Option: (d)', 'उत्पादन प्रक्रिया का तार्किक क्रम:
1. सबसे पहले पौधा (2) उगाया जाता है।
2. पौधे से कपास (1) प्राप्त होता है।
3. कपास से धागा (4) काता जाता है।
4. धागे से कपड़ा (5) बुना जाता है।
5. कपड़े से कमीज (3) सिली जाती है।

सही तार्किक क्रम: 2, 1, 4, 5, 3।

अतः सही उत्तर (d) है।'),
  ('ssc_cgl_tier1_mock_3', 19, 1, 'PART-1', 'General Intelligence & Reasoning', 'Coded Inequality', 'Moderate', 'In the following question, assuming the given statement to be true, find which of the conclusion(s) is/are definitely true.

Statement:
J ≥ K > L = M ≥ N > O

Conclusions:
I. J > M
II. L > O
III. K = N', 'निम्नलिखित प्रश्न में, दिए गए कथन को सत्य मानते हुए ज्ञात कीजिए कि कौन-सा/से निष्कर्ष निश्चित रूप से सत्य है/हैं।

कथन:
J ≥ K > L = M ≥ N > O

निष्कर्ष:
I. J > M
II. L > O
III. K = N', '{"a":"Only Conclusion I is true","b":"All Conclusions I, II and III are true","c":"Only Conclusions I and II are true","d":"Only Conclusions II and III are true"}'::jsonb, '{"a":"केवल निष्कर्ष I सत्य है","b":"सभी निष्कर्ष I, II और III सत्य हैं","c":"केवल निष्कर्ष I और II सत्य हैं","d":"केवल निष्कर्ष II और III सत्य हैं"}'::jsonb, 'c', 'Analyzing the given statement: J ≥ K > L = M ≥ N > O

1. Conclusion I: J > M
Path from J to M: J ≥ K > L = M.
Since there is a strict inequality symbol ''>'' between J and L, J > L holds. Since L = M, J > M is definitely TRUE.

2. Conclusion II: L > O
Path from L to O: L = M ≥ N > O.
Since there is a strict inequality symbol ''>'' between N and O, and L = M ≥ N, L > O is definitely TRUE.

3. Conclusion III: K = N
Path from K to N: K > L = M ≥ N → K > N.
Since K is strictly greater than N, K = N is FALSE.

Therefore, only Conclusions I and II are definitely true.

Correct Option: (c)', 'दिए गए कथन का विश्लेषण: J ≥ K > L = M ≥ N > O

1. निष्कर्ष I: J > M
J से M का संबंध: J ≥ K > L = M।
मार्ग में निश्चित बड़ा चिन्ह (>) मौजूद है, अतः J > M निश्चित रूप से सत्य है।

2. निष्कर्ष II: L > O
L से O का संबंध: L = M ≥ N > O।
मार्ग में निश्चित बड़ा चिन्ह (>) मौजूद है, अतः L > O निश्चित रूप से सत्य है।

3. निष्कर्ष III: K = N
K से N का संबंध: K > L = M ≥ N → K > N।
चूँकि K, N से बड़ा है, अतः K = N असत्य है।

अतः केवल निष्कर्ष I और II सत्य हैं।

अतः सही उत्तर (c) है।'),
  ('ssc_cgl_tier1_mock_3', 20, 1, 'PART-1', 'General Intelligence & Reasoning', 'Unit Analogy', 'Easy', 'Select the option that is related to the third term in the same way as the second term is related to the first term:
Resistance : Ohm :: Magnetic Field : ?', 'उस विकल्प का चयन कीजिए जो तीसरे पद से उसी प्रकार संबंधित है जैसे दूसरा पद पहले पद से संबंधित है:
प्रतिरोध : ओम :: चुंबकीय क्षेत्र : ?', '{"a":"Henry","b":"Joule","c":"Tesla","d":"Pascal"}'::jsonb, '{"a":"हेनरी","b":"जूल","c":"टेस्ला","d":"पास्कल"}'::jsonb, 'c', 'Ohm is the SI unit of Electrical Resistance.
Similarly, Tesla is the SI unit of Magnetic Field (magnetic flux density).

Correct Option: (c)', 'ओम (Ohm) विद्युत प्रतिरोध की SI इकाई है।
उसी प्रकार, टेस्ला (Tesla) चुंबकीय क्षेत्र की तीव्रता की SI इकाई है।

अतः सही उत्तर (c) है।'),
  ('ssc_cgl_tier1_mock_3', 21, 1, 'PART-1', 'General Intelligence & Reasoning', 'Circular Seating Arrangement', 'Hard', 'Eight executives — P, Q, R, S, T, U, V, and W — are seated around a circular conference table facing the center.
1. P sits third to the right of T.
2. W sits second to the left of P.
3. Only three executives sit between T and V.
4. Q sits second to the right of V.
5. S is an immediate neighbor of neither P nor T.
6. U sits to the immediate left of P.

Who sits opposite to W?', 'आठ अधिकारी — P, Q, R, S, T, U, V और W — एक वृत्ताकार सम्मेलन मेज के चारों ओर केंद्र की ओर मुख करके बैठे हैं।
1. P, T के दायें से तीसरे स्थान पर बैठा है।
2. W, P के बायें से दूसरे स्थान पर बैठा है।
3. T और V के बीच ठीक तीन अधिकारी बैठे हैं।
4. Q, V के दायें से दूसरे स्थान पर बैठा है।
5. S न तो P का और न ही T का निकटतम पड़ोसी है।
6. U, P के ठीक बायें बैठा है।

W के विपरीत कौन बैठा है?', '{"a":"R","b":"U","c":"S","d":"Q"}'::jsonb, '{"a":"R","b":"U","c":"S","d":"Q"}'::jsonb, 'c', 'Let positions 1 to 8 be arranged clockwise around the circular table (facing the center: Clockwise = Left, Counter-Clockwise = Right):
1. Place T at Position 1.
2. ''P sits third to the right of T'' (Counter-clockwise): Positions 8, 7, 6 → Position 6 = P.
3. ''W sits second to the left of P'' (Clockwise): From 6, clockwise is 7, 8 → Position 8 = W.
4. ''Only three executives sit between T and V'' → In an 8-person table, 3 people between two persons means they sit directly opposite to each other. Opposite of Position 1 (T) is Position 5 → Position 5 = V.
5. ''Q sits second to the right of V'' (Counter-clockwise): From 5, moving counter-clockwise (4, 3) → Position 3 = Q.
6. Current occupied positions: 1: T, 3: Q, 5: V, 6: P, 8: W. Empty positions: 2, 4, 7.
7. ''S is an immediate neighbor of neither P nor T'' → Neighbors of T(1) are 2 and 8; neighbors of P(6) are 5 and 7. Thus, S cannot be at 2 or 7. Therefore, S must be at Position 4.
8. ''U sits to the immediate left of P'' → P is at Position 6, so its immediate left (clockwise) is Position 7, which gives U = Position 7. Consequently, the only remaining position, Position 2, is occupied by R (Position 2 = R).
All 8 positions around the table are uniquely resolved:
Position 1 = T, Position 2 = R, Position 3 = Q, Position 4 = S, Position 5 = V, Position 6 = P, Position 7 = U, Position 8 = W.

Looking at W at Position 8: Directly opposite to Position 8 is Position (8 − 4) = 4, which is occupied by S.

Thus, S sits directly opposite to W.

Correct Option: (c)', 'वृत्ताकार मेज (केंद्र की ओर मुख, दक्षिणावर्त = बायाँ, वामावर्त = दायाँ):
1. T को स्थान 1 पर रखते हैं।
2. ''P, T के दायें तीसरा है'' → वामावर्त दिशा में स्थान 6 = P।
3. ''W, P के बायें दूसरा है'' → दक्षिणावर्त दिशा में स्थान 8 = W।
4. ''T और V के बीच ठीक तीन व्यक्ति हैं'' → T (स्थान 1) के ठीक विपरीत स्थान 5 = V।
5. ''Q, V के दायें दूसरा है'' → वामावर्त दिशा में स्थान 3 = Q।
6. वर्तमान स्थिति: स्थान 1(T), 3(Q), 5(V), 6(P), 8(W)। खाली स्थान: 2, 4, 7।
7. ''S न तो P का और न ही T का पड़ोसी है'' → S स्थान 2 और 7 पर नहीं हो सकता। अतः स्थान 4 = S।
8. ''U, P के ठीक बायें बैठा है'' → P (स्थान 6) के ठीक बायें (दक्षिणावर्त) स्थान 7 है, अतः स्थान 7 = U। अब एकमात्र शेष स्थान 2 पर R बैठेगा (स्थान 2 = R)।
सभी 8 अधिकारियों का निश्चित क्रम:
स्थान 1 = T, स्थान 2 = R, स्थान 3 = Q, स्थान 4 = S, स्थान 5 = V, स्थान 6 = P, स्थान 7 = U, स्थान 8 = W।

स्थान 8 पर W है, जिसके ठीक विपरीत स्थान 4 (8 − 4 = 4) पर S बैठा है।

अतः W के विपरीत S बैठा है।

अतः सही उत्तर (c) है।'),
  ('ssc_cgl_tier1_mock_3', 22, 1, 'PART-1', 'General Intelligence & Reasoning', 'Decision Making', 'Hard', 'Given below are the eligibility criteria for recruitment of a Senior Research Analyst in a premier think-tank:
The candidate must:
(i) Possess a Master''s degree in Economics or Statistics with at least 60% marks.
(ii) Be at least 25 years old and not more than 32 years old as on 01.01.2026.
(iii) Have at least 3 years of post-qualification work experience in data analytics.
(iv) Have scored at least 50% marks in the personal interview.

Exceptions:
(a) If a candidate fulfills all criteria except (i) above, but has at least 5 years of relevant work experience, the case is to be referred to the Director.
(b) If a candidate fulfills all criteria except (ii) above, but holds a Ph.D. degree, the case is to be referred to the Chairman.

Candidate''s Profile:
Ananya was born on 14th May 1998. She completed her M.Sc. in Statistics with 68% marks. She has been working as a data analyst for the past 4 years and secured 62% marks in the personal interview. What decision should be taken regarding her candidature?', 'एक प्रमुख थिंक-टैंक में ''वरिष्ठ अनुसंधान विश्लेषक'' के पद पर भर्ती के लिए पात्रता शर्तें नीचे दी गई हैं:
उम्मीदवार को:
(i) अर्थशास्त्र या सांख्यिकी में न्यूनतम 60% अंकों के साथ स्नातकोत्तर डिग्री धारक होना चाहिए।
(ii) 01.01.2026 को आयु कम से कम 25 वर्ष और 32 वर्ष से अधिक नहीं होनी चाहिए।
(iii) डेटा एनालिटिक्स में न्यूनतम 3 वर्ष का कार्यानुभव होना चाहिए।
(iv) व्यक्तिगत साक्षात्कार में न्यूनतम 50% अंक प्राप्त किए होने चाहिए।

अपवाद:
(a) यदि उम्मीदवार (i) को छोड़कर अन्य सभी शर्तें पूरी करता है, परंतु उसके पास 5 वर्ष का कार्यानुभव है, तो मामला ''निदेशक'' को भेजा जाएगा।
(b) यदि उम्मीदवार (ii) को छोड़कर अन्य सभी शर्तें पूरी करता है, परंतु उसके पास Ph.D. डिग्री है, तो मामला ''अध्यक्ष'' को भेजा जाएगा।

उम्मीदवार का विवरण:
अनन्या का जन्म 14 मई 1998 को हुआ था। उसने 68% अंकों के साथ सांख्यिकी में एम.एससी. (M.Sc.) उत्तीर्ण की है। वह पिछले 4 वर्षों से डेटा एनालिस्ट के रूप में कार्यरत है और उसने साक्षात्कार में 62% अंक प्राप्त किए हैं। उसकी उम्मीदवारी के संबंध में क्या निर्णय लिया जाना चाहिए?', '{"a":"The case is to be referred to the Chairman","b":"The case is to be referred to the Director","c":"The candidate is not to be selected","d":"The candidate is to be selected"}'::jsonb, '{"a":"मामला अध्यक्ष को भेजा जाएगा","b":"मामला निदेशक को भेजा जाएगा","c":"उम्मीदवार का चयन नहीं किया जाएगा","d":"उम्मीदवार का चयन किया जाएगा"}'::jsonb, 'd', 'Evaluate Ananya''s profile against each criterion:
1. Qualification: M.Sc. in Statistics with 68% marks (Meets criterion (i), as 68% ≥ 60%).
2. Age: Born on 14.05.1998. Age as of 01.01.2026 is 27 years 7 months (Meets criterion (ii), between 25 and 32 years).
3. Work Experience: 4 years in data analytics (Meets criterion (iii), as 4 years ≥ 3 years).
4. Interview Marks: 62% (Meets criterion (iv), as 62% ≥ 50%).

Since Ananya fulfills all four main criteria without needing any exceptions, she is to be selected directly.

Correct Option: (d)', 'अनन्या के विवरण का प्रत्येक शर्त के आधार पर परीक्षण:
1. योग्यता: सांख्यिकी में एम.एससी. (68% अंक) → शर्त (i) पूरी होती है (68% ≥ 60%)।
2. आयु: जन्म 14.05.1998। 01.01.2026 को आयु 27 वर्ष 7 माह है → शर्त (ii) पूरी होती है (25 से 32 वर्ष के मध्य)।
3. कार्यानुभव: 4 वर्ष का डेटा एनालिटिक्स अनुभव → शर्त (iii) पूरी होती है (4 वर्ष ≥ 3 वर्ष)।
4. साक्षात्कार: 62% अंक → शर्त (iv) पूरी होती है (62% ≥ 50%)।

चूँकि अनन्या सभी चार मूल शर्तों को पूर्ण करती है, अतः उसका सीधा चयन किया जाएगा।

अतः सही उत्तर (d) है।'),
  ('ssc_cgl_tier1_mock_3', 23, 1, 'PART-1', 'General Intelligence & Reasoning', 'Direction Sense & Distance', 'Hard', 'A cyclist starts from point A and rides 12 m North to reach point B. From B, he turns right and rides 8 m to reach point C. From C, he turns right and rides 6 m to reach point D. From D, he turns left and rides 7 m to reach point E. From E, he turns right and rides 6 m to reach point F. From F, he turns right and rides 7 m to reach point G. Finally, from G, he turns left and rides 6 m to reach point H.

What is the shortest distance and direction of point H with respect to starting point A?', 'एक साइकिल चालक बिंदु A से चलना शुरू करता है और बिंदु B तक पहुँचने के लिए उत्तर की ओर 12 मीटर जाता है। B से, वह दायें मुड़ता है और बिंदु C तक 8 मीटर जाता है। C से, वह दायें मुड़ता है और बिंदु D तक 6 मीटर जाता है। D से, वह बायें मुड़ता है और बिंदु E तक 7 मीटर जाता है। E से, वह दायें मुड़ता है और बिंदु F तक 6 मीटर जाता है। F से, वह दायें मुड़ता है और बिंदु G तक 7 मीटर जाता है। अंत में, G से वह बायें मुड़ता है और बिंदु H तक 6 मीटर जाता है।

प्रारंभिक बिंदु A के संदर्भ में बिंदु H की न्यूनतम दूरी और दिशा क्या है?', '{"a":"10 m, South-East","b":"12 m, South-East","c":"14 m, South","d":"10 m, North-East"}'::jsonb, '{"a":"10 मीटर, दक्षिण-पूर्व","b":"12 मीटर, दक्षिण-पूर्व","c":"14 मीटर, दक्षिण","d":"10 मीटर, उत्तर-पूर्व"}'::jsonb, 'a', 'Trace coordinates setting point A as the origin (0, 0):
- Point B: 12 m North → (0, 12)
- Point C: 8 m East → (8, 12)
- Point D: 6 m South → (8, 12 − 6) = (8, 6)
- Point E: 7 m East → (8 + 7, 6) = (15, 6)
- Point F: 6 m South → (15, 6 − 6) = (15, 0)
- Point G: 7 m West → (15 − 7, 0) = (8, 0)
- Point H: 6 m South → (8, 0 − 6) = (8, −6)

Position of H relative to A (0, 0):
- Δx = +8 m (East)
- Δy = −6 m (South)

Shortest distance AH = √(Δx² + Δy²) = √(8² + (−6)²) = √(64 + 36) = √100 = 10 meters.
Direction of H from A: East and South → South-East.

Correct Option: (a)', 'बिंदु A को मूल बिंदु (0, 0) मानकर निर्देशांक पद्धति से हल:
- बिंदु B: उत्तर में 12 मी → (0, 12)
- बिंदु C: पूर्व में 8 मी → (8, 12)
- बिंदु D: दक्षिण में 6 मी → (8, 6)
- बिंदु E: पूर्व में 7 मी → (15, 6)
- बिंदु F: दक्षिण में 6 मी → (15, 0)
- बिंदु G: पश्चिम में 7 मी → (8, 0)
- बिंदु H: दक्षिण में 6 मी → (8, −6)

प्रारंभिक बिंदु A (0, 0) के सापेक्ष H (8, −6) की स्थिति:
- पूर्व दिशा में दूरी (x) = 8 मीटर
- दक्षिण दिशा में दूरी (y) = 6 मीटर

न्यूनतम दूरी AH = √(8² + 6²) = √(64 + 36) = √100 = 10 मीटर।
दिशा: दक्षिण-पूर्व (South-East)।

अतः सही उत्तर (a) है।'),
  ('ssc_cgl_tier1_mock_3', 24, 1, 'PART-1', 'General Intelligence & Reasoning', 'Statement & Course of Action', 'Hard', 'Read the statement and courses of action carefully and decide which of the given courses of action logically follow(s).

Statement:
A severe fire broke out in a congested commercial market in the city center due to an electrical short circuit, revealing widespread absence of mandatory fire-safety clearances and hazardous unauthorized extensions in several buildings.

Courses of Action:
I. The municipal authorities should immediately conduct a comprehensive fire-safety audit of all commercial establishments and seal premises that fail to comply with mandatory norms.
II. The municipal administration should immediately demolish all commercial buildings in the city that were constructed before the year 2000.
III. Mandatory electrical safety inspections and firefighting drills should be organized regularly in coordination with local market trade associations.', 'कथन और कार्यवाहियों को ध्यानपूर्वक पढ़िए और निर्णय लीजिए कि कौन-सी कार्यवाही तार्किक रूप से अनुसरण करती है।

कथन:
शहर के केंद्र में स्थित एक संकरे व्यावसायिक बाजार में बिजली के शॉर्ट सर्किट के कारण भीषण आग लग गई, जिससे कई इमारतों में अनिवार्य अग्नि-सुरक्षा अनापत्ति का अभाव और खतरनाक अनधिकृत निर्माण उजागर हुआ।

कार्यवाहियाँ:
I. नगर निगम प्रशासन को सभी व्यावसायिक प्रतिष्ठानों का व्यापक अग्नि-सुरक्षा ऑडिट करना चाहिए और अनिवार्य मानकों का उल्लंघन करने वाले परिसरों को सील करना चाहिए।
II. नगर प्रशासन को शहर की वर्ष 2000 से पूर्व निर्मित सभी व्यावसायिक इमारतों को तुरंत ध्वस्त कर देना चाहिए।
III. स्थानीय व्यापार संघों के समन्वय से नियमित विद्युत सुरक्षा निरीक्षण और अग्निशमन मॉक ड्रिल आयोजित की जानी चाहिए।', '{"a":"Only Course of Action I follows","b":"Only Courses of Action II and III follow","c":"Only Courses of Action I and III follow","d":"All Courses of Action I, II and III follow"}'::jsonb, '{"a":"केवल कार्यवाही I अनुसरण करती है","b":"केवल कार्यवाहियाँ II और III अनुसरण करती हैं","c":"केवल कार्यवाहियाँ I और III अनुसरण करती हैं","d":"सभी कार्यवाहियाँ I, II और III अनुसरण करती हैं"}'::jsonb, 'c', 'Evaluating the proposed courses of action:
- Action I is directly remedial, practical, and addresses non-compliance by auditing and sealing violating commercial properties. Hence, Action I logically follows.
- Action II is an extreme, disproportionate, and irrational measure that demolishes all older structures regardless of their structural integrity or compliance. Hence, Action II does NOT follow.
- Action III is a preventive, proactive measure involving stakeholders to minimize future fire risks through routine inspections and drills. Hence, Action III logically follows.

Therefore, only Courses of Action I and III follow.

Correct Option: (c)', 'प्रस्तावित कार्यवाहियों का विश्लेषण:
- कार्यवाही I एक उचित, व्यावहारिक और सुधारात्मक कदम है जो सुरक्षा मानकों की जाँच कर उल्लंघनकर्ताओं के विरुद्ध कानूनी कार्यवाही सुनिश्चित करता है। अतः यह अनुसरण करती है।
- कार्यवाही II एक अत्यधिक कठोर, अव्यावहारिक और मनमाना कदम है जिसमें बिना किसी औचित्य के सभी पुरानी इमारतों को गिराने की बात कही गई है। अतः यह अनुसरण नहीं करती।
- कार्यवाही III भविष्य में ऐसी घटनाओं की पुनरावृत्ति रोकने के लिए एक सकारात्मक और निवारक उपाय है। अतः यह अनुसरण करती है।

अतः केवल कार्यवाहियाँ I और III अनुसरण करती हैं।

अतः सही उत्तर (c) है।'),
  ('ssc_cgl_tier1_mock_3', 25, 1, 'PART-1', 'General Intelligence & Reasoning', 'Statement & Assumptions', 'Moderate', 'In the question below, a statement is followed by three assumptions numbered I, II, and III. An assumption is something supposed or taken for granted. Consider the statement and decide which of the assumptions is/are implicit in the statement.

Statement:
"Passengers are requested to switch all portable electronic devices to airplane mode during takeoff and landing." — Announcement made by the cabin crew.

Assumptions:
I. Transmitting signals from mobile devices can potentially interfere with the aircraft''s communication and navigation systems.
II. Most passengers are willing to comply with safety announcements made by the airline crew.
III. Switching to airplane mode completely shuts down the device and makes it impossible to use.', 'नीचे दिए गए प्रश्न में एक कथन के बाद तीन पूर्वधारणाएँ I, II और III दी गई हैं। पूर्वधारणा वह बात होती है जिसे मान लिया गया हो। कथन पर विचार करते हुए निर्णय लीजिए कि कौन-सी पूर्वधारणा/पूर्वधारणाएँ अंतर्निहित है/हैं।

कथन:
"यात्रियों से अनुरोध है कि विमान के उड़ान भरने और उतरने के दौरान अपने सभी इलेक्ट्रॉनिक उपकरणों को एयरप्लेन मोड पर कर लें।" — केबिन क्रू द्वारा की गई उद्घोषणा।

पूर्वधारणाएँ:
I. मोबाइल उपकरणों से निकलने वाले सिग्नल विमान के संचार और नेविगेशन सिस्टम में बाधा डाल सकते हैं।
II. अधिकांश यात्री विमान कर्मियों द्वारा की गई सुरक्षा उद्घोषणाओं का पालन करने को तैयार रहते हैं।
III. एयरप्लेन मोड पर करने से उपकरण पूरी तरह बंद हो जाता है और उसका उपयोग करना असंभव हो जाता है।', '{"a":"Only Assumptions I and II are implicit","b":"Only Assumptions II and III are implicit","c":"Only Assumption I is implicit","d":"All Assumptions I, II and III are implicit"}'::jsonb, '{"a":"केवल पूर्वधारणाएँ I और II अंतर्निहित हैं","b":"केवल पूर्वधारणाएँ II और III अंतर्निहित हैं","c":"केवल पूर्वधारणा I अंतर्निहित है","d":"सभी पूर्वधारणाएँ I, II और III अंतर्निहित हैं"}'::jsonb, 'a', 'Evaluation of assumptions:
- Assumption I is implicit: The rationale behind requesting airplane mode is the premise that cellular/transmitting frequencies might cause electromagnetic interference with cockpit instrumentation during critical phases of flight.
- Assumption II is implicit: Whenever an authority makes a public request or safety announcement, it inherently assumes that passengers will listen and comply with the directive.
- Assumption III is not implicit: Airplane mode merely turns off cellular, Wi-Fi, and Bluetooth transmissions; it does not shut down the device or prevent offline usage (such as reading or playing pre-downloaded media).

Therefore, only Assumptions I and II are implicit.

Correct Option: (a)', 'पूर्वधारणाओं का तार्किक परीक्षण:
- पूर्वधारणा I अंतर्निहित है: यह घोषणा इस आधार पर की जाती है कि चालू सिग्नलों से विमान के नेविगेशन उपकरणों में व्यवधान उत्पन्न होने की आशंका रहती है।
- पूर्वधारणा II अंतर्निहित है: कोई भी सार्वजनिक उद्घोषणा या निर्देश इस विश्वास के साथ जारी किया जाता है कि यात्री उसका पालन करेंगे।
- पूर्वधारणा III अंतर्निहित नहीं है: एयरप्लेन मोड केवल वायरलेस सिग्नलों को बंद करता है, उपकरण पूरी तरह बंद नहीं होता और ऑफलाइन कार्य संभव रहता है।

अतः केवल पूर्वधारणाएँ I और II अंतर्निहित हैं।

अतः सही उत्तर (a) है।'),
  ('ssc_cgl_tier1_mock_3', 26, 2, 'PART-2', 'General Awareness', 'Current Affairs (Science & Technology 2025-26)', 'Hard', 'What is the primary operational orbit of the joint NASA-ISRO Synthetic Aperture Radar (NISAR) satellite mission launched from the Satish Dhawan Space Centre in Sriharikota?', 'सतीश धवन अंतरिक्ष केंद्र, श्रीहरिकोटा से प्रक्षेपित संयुक्त नासा-इसरो सिंथेटिक अपर्चर रडार (NISAR) उपग्रह मिशन की प्राथमिक परिचालन कक्षा कौन-सी है?', '{"a":"Geostationary Earth Orbit (GEO) at 35,786 km","b":"Sun-synchronous Low Earth Orbit (SSO) at approximately 747 km","c":"Lagrangian Point 1 (L1) Halo Orbit","d":"Medium Earth Orbit (MEO) at 20,200 km"}'::jsonb, '{"a":"35,786 किमी पर भूस्थैतिक कक्षा (GEO)","b":"लगभग 747 किमी पर सूर्य-तुल्यकालिक निम्न भू-कक्षा (SSO)","c":"लैग्रेंजियन बिंदु 1 (L1) हेलो कक्षा","d":"20,200 किमी पर मध्यम भू-कक्षा (MEO)"}'::jsonb, 'b', 'NISAR (NASA-ISRO Synthetic Aperture Radar) is a joint Earth-observing mission between NASA and ISRO. It operates in a Sun-synchronous Low Earth Orbit (SSO) at an altitude of approximately 747 km with an orbital inclination of 98.4°. It is the first satellite mission to utilize dual-frequency radar (L-band by NASA and S-band by ISRO) to observe Earth''s dynamic land and ice surfaces globally every 12 days with unprecedented resolution.

Correct Option: (b)', 'NISAR (नासा-इसरो सिंथेटिक अपर्चर रडार) नासा और इसरो का एक संयुक्त पृथ्वी-अवलोकन मिशन है। यह लगभग 747 किमी की ऊँचाई और 98.4° के झुकाव पर सूर्य-तुल्यकालिक निम्न भू-कक्षा (Sun-synchronous Low Earth Orbit - SSO) में संचालित होता है। यह पृथ्वी की गतिशील भूमि और बर्फ की सतहों का वैश्विक रूप से हर 12 दिन में अभूतपूर्व स्पष्टता के साथ मानचित्रण करने के लिए दोहरी आवृत्ति रडार (नासा द्वारा L-बैंड और इसरो द्वारा S-बैंड) का उपयोग करने वाला पहला उपग्रह है।

अतः सही उत्तर (b) है।'),
  ('ssc_cgl_tier1_mock_3', 27, 2, 'PART-2', 'General Awareness', 'Current Affairs (Economy & Budget 2025-26)', 'Hard', 'What target fiscal deficit (as a percentage of Gross Domestic Product) was projected in the Union Budget 2025–26, adhering to the government''s fiscal consolidation glide path?', 'सरकार के राजकोषीय सुदृढ़ीकरण मार्ग का पालन करते हुए, केंद्रीय बजट 2025-26 में राजकोषीय घाटा (सकल घरेलू उत्पाद के प्रतिशत के रूप में) कितना लक्षित किया गया?', '{"a":"5.1% of GDP","b":"3.8% of GDP","c":"4.4% of GDP","d":"4.9% of GDP"}'::jsonb, '{"a":"जीडीपी का 5.1%","b":"जीडीपी का 3.8%","c":"जीडीपी का 4.4%","d":"जीडीपी का 4.9%"}'::jsonb, 'c', 'In the Union Budget 2025–26 presented by Finance Minister Nirmala Sitharaman, the fiscal deficit for FY 2025–26 was projected at 4.4% of GDP, continuing the government''s fiscal consolidation glide path to bring the deficit below 4.5% of GDP by FY 2025–26 (down from 4.9% in the revised estimates of FY 2024–25).

Correct Option: (c)', 'वित्त मंत्री निर्मला सीतारमण द्वारा प्रस्तुत केंद्रीय बजट 2025-26 में, वित्त वर्ष 2025-26 के लिए राजकोषीय घाटा जीडीपी का 4.4% अनुमानित किया गया। यह सरकार के राजकोषीय सुदृढ़ीकरण के उस लक्ष्य के अनुरूप है जिसके तहत वित्त वर्ष 2025-26 तक राजकोषीय घाटे को जीडीपी के 4.5% से नीचे लाना निर्धारित था (जो वित्त वर्ष 2024-25 के संशोधित अनुमानों में 4.9% था)।

अतः सही उत्तर (c) है।'),
  ('ssc_cgl_tier1_mock_3', 28, 2, 'PART-2', 'General Awareness', 'Current Affairs (National Schemes 2025-26)', 'Hard', 'Consider the following statements regarding the ''PM-Surya Ghar: Muft Bijli Yojana'' launched by the Government of India:
1. The scheme aims to provide up to 300 units of free electricity per month to one crore households across India.
2. The Central Government provides a financial subsidy of up to 60% of the system cost for rooftop solar installations up to 2 kW capacity.
3. The total outlay allocated for the nationwide implementation of this initiative is over ₹75,000 crore.

Which of the statements given above are correct?', 'भारत सरकार द्वारा शुरू की गई ''पीएम-सूर्य घर: मुफ्त बिजली योजना'' के संबंध में निम्नलिखित कथनों पर विचार कीजिए:
1. इस योजना का उद्देश्य देश भर के 1 करोड़ घरों को प्रति माह 300 यूनिट तक मुफ्त बिजली प्रदान करना है।
2. केंद्र सरकार 2 किलोवाट क्षमता तक के रूफटॉप सोलर सिस्टम के लिए लागत का 60% तक वित्तीय अनुदान (सब्सिडी) प्रदान करती है।
3. इस पहल के देशव्यापी क्रियान्वयन के लिए ₹75,000 करोड़ से अधिक का कुल वित्तीय परिव्यय आवंटित किया गया है।

उपर्युक्त कथनों में से कौन-से सही हैं?', '{"a":"2 and 3 only","b":"1 and 3 only","c":"1, 2 and 3","d":"1 and 2 only"}'::jsonb, '{"a":"केवल 2 और 3","b":"केवल 1 और 3","c":"1, 2 और 3","d":"केवल 1 और 2"}'::jsonb, 'c', 'All three statements are correct regarding ''PM-Surya Ghar: Muft Bijli Yojana'':
- Statement 1 is correct: The scheme targets 1 crore beneficiary households to enable them to receive up to 300 units of free electricity every month through grid-connected rooftop solar systems.
- Statement 2 is correct: The subsidy structure provides 60% of the benchmark system cost for systems up to 2 kW capacity (₹30,000 per kW up to 2 kW = ₹60,000) and an additional ₹18,000 for the 3rd kW (capped at ₹78,000).
- Statement 3 is correct: The Union Cabinet approved the scheme with a total outlay of ₹75,021 crore.

Correct Option: (c)', '''पीएम-सूर्य घर: मुफ्त बिजली योजना'' के संबंध में तीनों कथन सत्य हैं:
- कथन 1 सही है: इस योजना का लक्ष्य 1 करोड़ परिवारों को ग्रिड से जुड़े रूफटॉप सोलर सिस्टम स्थापित करके प्रति माह 300 यूनिट तक मुफ्त बिजली उपलब्ध कराना है।
- कथन 2 सही है: सब्सिडी संरचना के अनुसार, 2 किलोवाट तक की प्रणालियों के लिए लागत का 60% अनुदान (₹30,000 प्रति किलोवाट, अधिकतम ₹60,000) तथा तीसरे किलोवाट के लिए ₹18,000 (अधिकतम ₹78,000 तक) प्रदान किया जाता है।
- कथन 3 सही है: केंद्रीय मंत्रिमंडल ने ₹75,021 करोड़ के कुल परिव्यय के साथ इस योजना को मंजूरी दी है।

अतः सही उत्तर (c) है।'),
  ('ssc_cgl_tier1_mock_3', 29, 2, 'PART-2', 'General Awareness', 'Current Affairs (National Initiatives 2025-26)', 'Hard', 'India''s first commercial semiconductor fabrication plant (fab) being constructed in Dholera, Gujarat, under the India Semiconductor Mission is a joint venture between Tata Electronics and which international semiconductor corporation?', 'भारत सेमीकंडक्टर मिशन के तहत गुजरात के धोलेरा में स्थापित किया जा रहा भारत का पहला वाणिज्यिक सेमीकंडक्टर फैब्रिकेशन प्लांट (Fab) टाटा इलेक्ट्रॉनिक्स और किस अंतरराष्ट्रीय सेमीकंडक्टर निगम का संयुक्त उद्यम है?', '{"a":"Intel Corporation","b":"Taiwan Semiconductor Manufacturing Company (TSMC)","c":"Powerchip Semiconductor Manufacturing Corporation (PSMC)","d":"Samsung Electronics"}'::jsonb, '{"a":"इंटेल कॉर्पोरेशन","b":"ताइवान सेमीकंडक्टर मैन्युफैक्चरिंग कंपनी (TSMC)","c":"पावरचिप सेमीकंडक्टर मैन्युफैक्चरिंग कॉर्पोरेशन (PSMC)","d":"सैमसंग इलेक्ट्रॉनिक्स"}'::jsonb, 'c', 'Tata Electronics has partnered with Taiwan''s Powerchip Semiconductor Manufacturing Corporation (PSMC) to build India''s first commercial semiconductor fabrication facility in Dholera Special Investment Region (SIR), Gujarat. With an investment of ₹91,000 crore ($11 billion), this fab has a planned manufacturing capacity of up to 50,000 wafers per month to produce chips for power management, electric vehicles, telecom, and consumer electronics.

Correct Option: (c)', 'टाटा इलेक्ट्रॉनिक्स ने गुजरात के धोलेरा विशेष निवेश क्षेत्र (SIR) में भारत का पहला वाणिज्यिक सेमीकंडक्टर फैब्रिकेशन प्लांट स्थापित करने के लिए ताइवान की पावरचिप सेमीकंडक्टर मैन्युफैक्चरिंग कॉर्पोरेशन (PSMC) के साथ साझेदारी की है। ₹91,000 करोड़ (लगभग 11 बिलियन डॉलर) के निवेश से बनने वाले इस संयंत्र की क्षमता प्रति माह 50,000 वेफर तक चिप निर्माण की होगी, जिससे ऑटोमोटिव, इलेक्ट्रिक वाहन, दूरसंचार और उपभोक्ता इलेक्ट्रॉनिक्स के लिए चिप्स बनाए जाएंगे।

अतः सही उत्तर (c) है।'),
  ('ssc_cgl_tier1_mock_3', 30, 2, 'PART-2', 'General Awareness', 'Current Affairs (International Summits 2025-26)', 'Hard', 'Under the theme ''Building a Just World and a Sustainable Planet'', which country hosted the 19th G20 Leaders'' Summit in November 2024, formally handing over the presidency to South Africa for 2025?', '''एक न्यायसंगत विश्व और एक सतत ग्रह का निर्माण'' विषय के तहत, किस देश ने नवंबर 2024 में 19वें G20 राष्ट्राध्यक्षों के शिखर सम्मेलन की मेजबानी की और वर्ष 2025 के लिए अध्यक्षता दक्षिण अफ्रीका को सौंपी?', '{"a":"Brazil","b":"Indonesia","c":"Argentina","d":"Saudi Arabia"}'::jsonb, '{"a":"ब्राजील","b":"इंडोनेशिया","c":"अर्जेंटीना","d":"सऊदी अरब"}'::jsonb, 'a', 'Brazil hosted the 19th G20 Leaders'' Summit on 18–19 November 2024 in Rio de Janeiro under the presidency of President Luiz Inácio Lula da Silva. The theme was ''Building a Just World and a Sustainable Planet'', focusing on social inclusion, the fight against hunger and poverty (launching the Global Alliance Against Hunger and Poverty), energy transitions, and reform of global governance institutions. Brazil transferred the G20 Presidency to South Africa for 2025.

Correct Option: (a)', 'ब्राजील ने 18-19 नवंबर 2024 को रियो डी जेनेरो में राष्ट्रपति लुइज़ इनासियो लूला डा सिल्वा की अध्यक्षता में 19वें G20 शिखर सम्मेलन की मेजबानी की। इसका विषय ''एक न्यायसंगत विश्व और एक सतत ग्रह का निर्माण'' (Building a Just World and a Sustainable Planet) था, जिसमें सामाजिक समावेशन, भूख और गरीबी के खिलाफ वैश्विक गठबंधन (Global Alliance Against Hunger and Poverty) तथा वैश्विक शासन संस्थानों के सुधार पर बल दिया गया। ब्राजील ने वर्ष 2025 के लिए G20 की अध्यक्षता दक्षिण अफ्रीका को सौंपी।

अतः सही उत्तर (a) है।'),
  ('ssc_cgl_tier1_mock_3', 31, 2, 'PART-2', 'General Awareness', 'Current Affairs (Sports & Games 2024-25)', 'Hard', 'Who became the first athlete from independent India to win two Olympic medals in a single edition of the Olympic Games at the Paris 2024 Olympics?', 'पेरिस 2024 ओलंपिक में ओलंपिक खेलों के एक ही संस्करण में दो ओलंपिक पदक जीतने वाले स्वतंत्र भारत के पहले एथलीट कौन बने?', '{"a":"Aman Sehrawat","b":"Sarabjot Singh","c":"Neeraj Chopra","d":"Manu Bhaker"}'::jsonb, '{"a":"अमन सहरावत","b":"सरबजोत सिंह","c":"नीरज चोपड़ा","d":"मनु भाकर"}'::jsonb, 'd', 'Indian pistol shooter Manu Bhaker scripted history at the Paris 2024 Olympic Games by winning two bronze medals: first in the Women''s 10m Air Pistol individual event, and second in the 10m Air Pistol Mixed Team event alongside Sarabjot Singh. She became the first Indian in post-independence history to win two medals at the same Olympic Games (Norman Pritchard had won two silver medals in athletics in 1900 during British India).

Correct Option: (d)', 'भारतीय निशानेबाज मनु भाकर ने पेरिस 2024 ओलंपिक खेलों में दो कांस्य पदक जीतकर इतिहास रचा: पहला महिलाओं की 10 मीटर एयर पिस्टल व्यक्तिगत स्पर्धा में और दूसरा सरबजोत सिंह के साथ 10 मीटर एयर पिस्टल मिश्रित टीम स्पर्धा में। वह स्वतंत्रता के बाद ओलंपिक के एक ही संस्करण में दो पदक जीतने वाली पहली भारतीय एथलीट बनीं (इससे पूर्व 1900 में ब्रिटिश भारत के नॉर्मन प्रिचर्ड ने दो रजत पदक जीते थे)।

अतः सही उत्तर (d) है।'),
  ('ssc_cgl_tier1_mock_3', 32, 2, 'PART-2', 'General Awareness', 'Indian Polity & Constitution', 'Hard', 'Which of the following constitutional provisions was/were newly inserted by the Constitution (One Hundred and Sixth Amendment) Act, 2023 (Nari Shakti Vandan Adhiniyam) to provide 33% reservation for women?
1. Article 330A (Reservation for women in Lok Sabha)
2. Article 332A (Reservation for women in State Legislative Assemblies)
3. Article 239AA amendment / Article 239AA(2)(b) (Reservation for women in Legislative Assembly of NCT of Delhi)
4. Article 334A (Sunset clause of 15 years from commencement)

Select the correct answer using the codes given below:', 'महिलाओं के लिए 33% आरक्षण प्रदान करने हेतु संविधान (एक सौ छहवाँ संशोधन) अधिनियम, 2023 (नारी शक्ति वंदन अधिनियम) द्वारा निम्नलिखित में से कौन-से संवैधानिक प्रावधान नए जोड़े गए?
1. अनुच्छेद 330A (लोकसभा में महिलाओं के लिए आरक्षण)
2. अनुच्छेद 332A (राज्य विधानसभाओं में महिलाओं के लिए आरक्षण)
3. अनुच्छेद 239AA संशोधन / अनुच्छेद 239AA(2)(b) (दिल्ली राष्ट्रीय राजधानी क्षेत्र की विधानसभा में महिलाओं के लिए आरक्षण)
4. अनुच्छेद 334A (आरक्षण की 15 वर्ष की अवधि का प्रावधान)

नीचे दिए गए कूट का प्रयोग कर सही उत्तर चुनिए:', '{"a":"1, 2, 3 and 4","b":"1 and 2 only","c":"1, 2 and 3 only","d":"2, 3 and 4 only"}'::jsonb, '{"a":"1, 2, 3 और 4","b":"केवल 1 और 2","c":"केवल 1, 2 और 3","d":"केवल 2, 3 और 4"}'::jsonb, 'a', 'The Constitution (106th Amendment) Act, 2023 reserved one-third (33%) of all seats for women in the Lok Sabha, the State Legislative Assemblies, and the Legislative Assembly of the National Capital Territory of Delhi.
Key articles introduced/amended:
- Article 330A: Reservation for women in the House of the People (Lok Sabha).
- Article 332A: Reservation for women in the Legislative Assemblies of States.
- Article 239AA(2)(b): Reservation for women in the Legislative Assembly of NCT of Delhi.
- Article 334A: Specifies that the reservation shall come into effect after delimitation following the first census conducted after the Act, and shall remain in force for a period of 15 years.
All 1, 2, 3, and 4 are correct.

Correct Option: (a)', 'संविधान (106वाँ संशोधन) अधिनियम, 2023 द्वारा लोकसभा, राज्य विधानसभाओं तथा दिल्ली राष्ट्रीय राजधानी क्षेत्र की विधानसभा में महिलाओं के लिए कुल सीटों की एक-तिहाई (33%) सीटें आरक्षित की गईं।
जोड़े गए प्रमुख अनुच्छेद:
- अनुच्छेद 330A: लोकसभा में महिलाओं के लिए सीटों का आरक्षण।
- अनुच्छेद 332A: राज्यों की विधानसभाओं में महिलाओं के लिए सीटों का आरक्षण।
- अनुच्छेद 239AA संशोधन: दिल्ली विधानसभा में महिलाओं के लिए आरक्षण।
- अनुच्छेद 334A: यह प्रावधान करता है कि यह आरक्षण परिसीमन के बाद लागू होगा तथा 15 वर्षों की अवधि तक प्रभावी रहेगा।
अतः 1, 2, 3 और 4 सभी सत्य हैं।

अतः सही उत्तर (a) है।'),
  ('ssc_cgl_tier1_mock_3', 33, 2, 'PART-2', 'General Awareness', 'Modern Indian History', 'Hard', 'Under which specific regulation did Governor-General Lord William Bentinck declare the practice of Sati illegal and punishable as culpable homicide in December 1829?', 'दिसंबर 1829 में गवर्नर-जनरल लॉर्ड विलियम बेंटिक ने किस विशिष्ट विनियमन के तहत सती प्रथा को अवैध और गैर-इरादतन हत्या के रूप में दंडनीय घोषित किया था?', '{"a":"Charter Act of 1833","b":"Bengal Regulation III of 1818","c":"Bengal Regulation XVII of 1829","d":"Religious Disabilities Act XXI of 1850"}'::jsonb, '{"a":"1833 का चार्टर एक्ट","b":"1818 का बंगाल विनियमन III","c":"1829 का बंगाल विनियमन XVII","d":"1850 का धार्मिक निर्योग्यता अधिनियम XXI"}'::jsonb, 'c', 'The Bengal Sati Regulation, officially known as Regulation XVII of 1829, was passed on 4th December 1829 by Governor-General Lord William Bentinck with crucial social advocacy from Raja Ram Mohan Roy. It declared the practice of burning or burying alive Hindu widows (Sati) illegal and punishable as culpable homicide. It was initially enforced in the Bengal Presidency and extended to Madras and Bombay Presidencies in 1830.

Correct Option: (c)', 'बंगाल सती विनियमन (विनियमन XVII, 1829) 4 दिसंबर 1829 को गवर्नर-जनरल लॉर्ड विलियम बेंटिक द्वारा राजा राममोहन राय के सामाजिक प्रयासों से पारित किया गया था। इसके तहत हिंदू विधवाओं को जीवित जलाने या दफनाने की सती प्रथा को अवैध तथा गैर-इरादतन मानव वध (Culpable homicide) के तहत दंडनीय घोषित किया गया। प्रारंभ में यह बंगाल प्रेसीडेंसी में लागू हुआ तथा 1830 में इसे मद्रास और बॉम्बे प्रेसीडेंसी में भी लागू किया गया।

अतः सही उत्तर (c) है।'),
  ('ssc_cgl_tier1_mock_3', 34, 2, 'PART-2', 'General Awareness', 'Indian Economy', 'Hard', 'Which uncollateralized monetary policy tool was introduced by the Reserve Bank of India in April 2022 to absorb excess liquidity from commercial banks without pledging government securities?', 'भारतीय रिज़र्व बैंक द्वारा सरकारी प्रतिभूतियों को गिरवी रखे बिना वाणिज्यिक बैंकों से अतिरिक्त तरलता को अवशोषित करने के लिए अप्रैल 2022 में कौन-सा संपार्श्विक-मुक्त (uncollateralized) मौद्रिक नीति साधन शुरू किया गया था?', '{"a":"Marginal Standing Facility (MSF)","b":"Cash Reserve Ratio (CRR)","c":"Market Stabilization Scheme (MSS)","d":"Standing Deposit Facility (SDF)"}'::jsonb, '{"a":"सीमांत स्थायी सुविधा (MSF)","b":"नकद आरक्षित अनुपात (CRR)","c":"बाजार स्थिरीकरण योजना (MSS)","d":"स्थायी जमा सुविधा (SDF)"}'::jsonb, 'd', 'The Standing Deposit Facility (SDF) was introduced by the RBI in April 2022 under the amended Section 17 of the RBI Act, 1934 (recommended by the Urjit Patel Committee). Unlike the Reverse Repo facility, the SDF allows the RBI to absorb overnight liquidity from commercial banks without providing any government securities as collateral, strengthening the operating framework of liquidity management.

Correct Option: (d)', 'भारतीय रिज़र्व बैंक ने अप्रैल 2022 में स्थायी जमा सुविधा (Standing Deposit Facility - SDF) को लागू किया (उर्जित पटेल समिति की सिफारिश पर RBI अधिनियम 1934 की धारा 17 में संशोधन करके)। रिवर्स रेपो सुविधा के विपरीत, SDF के तहत रिज़र्व बैंक को बैंकों से अतिरिक्त तरलता अवशोषित करने के लिए सरकारी प्रतिभूतियों को संपार्श्विक (Collateral) के रूप में गिरवी नहीं रखना पड़ता है।

अतः सही उत्तर (d) है।'),
  ('ssc_cgl_tier1_mock_3', 35, 2, 'PART-2', 'General Awareness', 'Physical Geography (Ocean Currents)', 'Hard', 'Which cold, low-salinity ocean current flows equatorward along the western coast of South America, contributing directly to the extreme aridity of the Atacama Desert?', 'कौन-सी ठंडी, कम लवणता वाली महासागरीय धारा दक्षिण अमेरिका के पश्चिमी तट के साथ भूमध्य रेखा की ओर बहती है और अटाकामा मरुस्थल की अत्यधिक शुष्कता में सीधा योगदान देती है?', '{"a":"Canary Current","b":"Humboldt (Peru) Current","c":"Benguela Current","d":"Falkland Current"}'::jsonb, '{"a":"कैनरी धारा","b":"हम्बोल्ट (पेरू) धारा","c":"बेंगुएला धारा","d":"फ़ॉकलैंड धारा"}'::jsonb, 'b', 'The Humboldt Current (also known as the Peru Current) is a cold ocean current flowing northward along the western coast of Chile and Peru in South America. The cold waters chill the overlying air masses, creating atmospheric stability and temperature inversions that suppress cloud formation and precipitation, directly causing the extreme hyper-aridity of the coastal Atacama Desert.

Correct Option: (b)', 'हम्बोल्ट धारा (या पेरू धारा) दक्षिण अमेरिका के चिली और पेरू के पश्चिमी तट के साथ उत्तर (भूमध्य रेखा) की ओर बहने वाली एक ठंडी महासागरीय धारा है। इसके ठंडे जल से तटीय वायु ठंडी होकर स्थिर हो जाती है और तापमान व्युत्क्रमण (Temperature inversion) के कारण संवहनीय वर्षा और बादलों का निर्माण रुक जाता है, जिससे अटाकामा मरुस्थल विश्व के सबसे शुष्क मरुस्थलों में परिणत हो जाता है।

अतः सही उत्तर (b) है।'),
  ('ssc_cgl_tier1_mock_3', 36, 2, 'PART-2', 'General Awareness', 'Chemistry in Medicine', 'Hard', 'The widely used anti-cancer chemotherapy drug ''Cisplatin'' [cis-diamminedichloroplatinum(II)] is a coordination complex containing which heavy metal?', 'कैंसर के उपचार में व्यापक रूप से उपयोग की जाने वाली कीमोथेरेपी दवा ''सिसप्लाटिन'' [cis-Pt(NH3)2Cl2] किस भारी धातु का एक समन्वय यौगिक (coordination complex) है?', '{"a":"Platinum","b":"Silver","c":"Cobalt","d":"Gold"}'::jsonb, '{"a":"प्लैटिनम (Platinum)","b":"चांदी (Silver)","c":"कोबाल्ट (Cobalt)","d":"सोना (Gold)"}'::jsonb, 'a', 'Cisplatin, chemically known as cis-diamminedichloroplatinum(II) with formula [cis-Pt(NH3)2Cl2], is a platinum-based coordination compound. It acts as an effective antineoplastic chemotherapy drug used to treat various types of cancers, including testicular, ovarian, lung, and bladder cancers, by crosslinking with purine bases on cellular DNA and inhibiting cancer cell division.

Correct Option: (a)', 'सिसप्लाटिन (Cisplatin), जिसका रासायनिक सूत्र [cis-Pt(NH3)2Cl2] है, प्लैटिनम धातु का एक महत्वपूर्ण उपसहसंयोजक यौगिक (coordination compound) है। यह एक प्रमुख कीमोथेरेपी कैंसर-रोधी दवा है जो डीएनए के प्यूरीन क्षारों के साथ बंध बनाकर कैंसर कोशिकाओं के विभाजन को रोकती है और वृषण, अंडाशय, फेफड़े आदि के ट्यूमर के उपचार में प्रयुक्त होती है।

अतः सही उत्तर (a) है।'),
  ('ssc_cgl_tier1_mock_3', 37, 2, 'PART-2', 'General Awareness', 'Cell Biology (Cell Division)', 'Hard', 'During which specific substage of Prophase-I in Meiosis does the critical genetic process of ''crossing over'' (recombination of non-sister chromatids) take place?', 'अर्धसूत्रीविभाजन (Meiosis) के प्रोफेज-I की किस विशिष्ट उप-अवस्था के दौरान ''क्रॉसिंग ओवर'' (जीन विनिमय / नॉन-सिस्टर क्रोमैटिड्स का पुनर्संयोजन) की महत्वपूर्ण आनुवंशिक प्रक्रिया घटित होती है?', '{"a":"Pachytene","b":"Diplotene","c":"Leptotene","d":"Zygotene"}'::jsonb, '{"a":"पैचीटीन (Pachytene)","b":"डिप्लोटीन (Diplotene)","c":"लेप्टोटीन (Leptotene)","d":"जाइगोटीन (Zygotene)"}'::jsonb, 'a', 'Prophase-I of Meiosis is divided into five successive substages:
1. Leptotene: Chromatin condenses into visible chromosomes.
2. Zygotene: Homologous chromosomes pair up along their length (Synapsis) to form synaptonemal complexes.
3. Pachytene: Crossing over occurs between non-sister chromatids of homologous chromosomes facilitated by the enzyme recombinase, leading to genetic variation.
4. Diplotene: Dissolution of synaptonemal complexes; chiasmata become visible.
5. Diakinesis: Terminalization of chiasmata.
Hence, crossing over occurs during Pachytene.

Correct Option: (a)', 'अर्धसूत्री विभाजन-I की पूर्वावस्था-I (Prophase-I) पाँच उप-अवस्थाओं में विभाजित होती है:
1. लेप्टोटीन: क्रोमैटिन संघनित होकर क्रोमोसोम बनाते हैं।
2. जाइगोटीन: समजात गुणसूत्र युग्मित होते हैं (सूत्रयुग्मन / Synapsis)।
3. पैचीटीन (Pachytene): समजात गुणसूत्रों के नॉन-सिस्टर क्रोमैटिड्स के बीच पुनर्संयोजन एंजाइम (Recombinase) की सहायता से आनुवंशिक पदार्थों का आदान-प्रदान यानी ''क्रॉसिंग ओवर'' (Crossing over) होता है।
4. डिप्लोटीन: काइऐज्मेटा (Chiasmata) का निर्माण होता है।
5. डायकाइनेसिस: काइऐज्मेटा का उपांतीभवन होता है।

अतः सही उत्तर (a) है।'),
  ('ssc_cgl_tier1_mock_3', 38, 2, 'PART-2', 'General Awareness', 'Indian Polity (Election Commission)', 'Moderate', 'Under Article 324 of the Indian Constitution, the Election Commission of India is NOT responsible for conducting elections to which of the following bodies?', 'भारतीय संविधान के अनुच्छेद 324 के तहत, भारत का निर्वाचन आयोग निम्नलिखित में से किस निकाय के चुनाव कराने के लिए जिम्मेदार नहीं है?', '{"a":"State Legislative Assemblies and Councils","b":"Panchayats and Municipalities in the States","c":"Parliament (Lok Sabha and Rajya Sabha)","d":"Offices of the President and Vice-President"}'::jsonb, '{"a":"राज्य विधानसभाएँ और विधान परिषदें","b":"राज्यों में पंचायतें और नगरपालिकाएँ","c":"संसद (लोकसभा और राज्यसभा)","d":"राष्ट्रपति और उपराष्ट्रपति के पद"}'::jsonb, 'b', 'Under Article 324 of the Constitution, the Election Commission of India (ECI) is vested with the superintendence, direction, and control of elections to Parliament, State Legislatures, and the offices of the President and Vice-President of India.
Elections to local rural and urban bodies (Panchayats and Municipalities) are conducted by the respective State Election Commissions under Articles 243K and 243ZA.

Correct Option: (b)', 'संविधान के अनुच्छेद 324 के तहत, भारत निर्वाचन आयोग (ECI) संसद (लोकसभा व राज्यसभा), राज्य विधानमंडलों (विधानसभा व विधान परिषद) तथा राष्ट्रपति एवं उपराष्ट्रपति के पदों के चुनावों के अधीक्षण, निर्देशन और नियंत्रण के लिए जिम्मेदार है।
राज्यों में पंचायतों और नगरपालिकाओं के चुनाव कराने की जिम्मेदारी संबंधित राज्य निर्वाचन आयोग (State Election Commission) की होती है (अनुच्छेद 243K और 243ZA के तहत)।

अतः सही उत्तर (b) है।'),
  ('ssc_cgl_tier1_mock_3', 39, 2, 'PART-2', 'General Awareness', 'Medieval Indian History', 'Moderate', 'The standardized silver coin called ''Rupiya'' (weighing 178 grains) and copper coin called ''Dam'' were originally introduced in India by which medieval ruler?', '''रुपिया'' नामक मानकीकृत चांदी का सिक्का (178 ग्रेन वजन) और ''दाम'' नामक तांबे का सिक्का मूल रूप से भारत में किस मध्यकालीन शासक द्वारा शुरू किया गया था?', '{"a":"Muhammad bin Tughlaq","b":"Alauddin Khalji","c":"Akbar","d":"Sher Shah Suri"}'::jsonb, '{"a":"मोहम्मद बिन तुगलक","b":"अलाउद्दीन खिलजी","c":"अकबर","d":"शेरशाह सूरी"}'::jsonb, 'd', 'Sher Shah Suri, the founder of the Suri Empire (reigned 1540–1545), reformed currency administration by introducing a tri-metallic coinage system. He introduced the standardized silver coin called ''Rupiya'' (178 grains), copper coin called ''Dam'', and gold coin called ''Mohur''. The Rupiya became the precursor of the modern Indian Rupee and was maintained throughout the Mughal Empire and British Raj.

Correct Option: (d)', 'सूर वंश के संस्थापक शेरशाह सूरी (शासनकाल 1540-1545 ई.) ने मुद्रा प्रणाली का मानकीकरण करते हुए त्रि-धातु सिक्का प्रणाली शुरू की। उसने 178 ग्रेन का शुद्ध चांदी का सिक्का ''रुपिया'', तांबे का सिक्का ''दाम'' (380 ग्रेन) और सोने का सिक्का ''मोहर'' चलाया। शेरशाह का यही ''रुपिया'' आधुनिक भारतीय मुद्रा का पूर्वगामी बना जिसे मुगलों और अंग्रेजों ने भी जारी रखा।

अतः सही उत्तर (d) है।'),
  ('ssc_cgl_tier1_mock_3', 40, 2, 'PART-2', 'General Awareness', 'Indian Geography (Drainage System)', 'Moderate', 'Majuli, officially recognized by Guinness World Records as the world''s largest inhabited river island, is located on which river in Assam?', 'गिनीज वर्ल्ड रिकॉर्ड्स द्वारा आधिकारिक रूप से दुनिया के सबसे बड़े बसे हुए नदी द्वीप के रूप में मान्यता प्राप्त ''माजुली'', असम में किस नदी पर स्थित है?', '{"a":"Godavari","b":"Ganga","c":"Brahmaputra","d":"Mahanadi"}'::jsonb, '{"a":"गोदावरी","b":"गंगा","c":"ब्रह्मपुत्र","d":"महानदी"}'::jsonb, 'c', 'Majuli is the largest inhabited river island in the world, formed by the Brahmaputra River in the south and the Kherkutia Xuti (an anabranch of Brahmaputra) joined by the Subansiri River in the north, in the state of Assam. In 2016, it became the first river island district in India.

Correct Option: (c)', 'माजुली विश्व का सबसे बड़ा आबाद नदी द्वीप है, जो असम में दक्षिण में ब्रह्मपुत्र नदी और उत्तर में सुबनसिरी नदी व खेरकुटिया सूती द्वारा निर्मित है। वर्ष 2016 में माजुली भारत का पहला ''नदी द्वीप जिला'' भी बना।

अतः सही उत्तर (c) है।'),
  ('ssc_cgl_tier1_mock_3', 41, 2, 'PART-2', 'General Awareness', 'Physics (Thermodynamics)', 'Moderate', 'Which fundamental law of physics establishes the concept of temperature by stating that if two systems are each in thermal equilibrium with a third system, they are also in thermal equilibrium with each other?', 'भौतिकी का कौन-सा मौलिक नियम तापमान की अवधारणा को स्थापित करता है, जिसके अनुसार यदि दो निकाय किसी तीसरे निकाय के साथ अलग-अलग तापीय संतुलन में हैं, तो वे परस्पर भी तापीय संतुलन में होंगे?', '{"a":"Third Law of Thermodynamics","b":"First Law of Thermodynamics","c":"Second Law of Thermodynamics","d":"Zeroth Law of Thermodynamics"}'::jsonb, '{"a":"ऊष्मागतिकी का तृतीय नियम","b":"ऊष्मागतिकी का प्रथम नियम","c":"ऊष्मागतिकी का द्वितीय नियम","d":"ऊष्मागतिकी का शून्यांकी नियम (Zeroth Law)"}'::jsonb, 'd', 'The Zeroth Law of Thermodynamics states that if body A is in thermal equilibrium with body B, and body B is in thermal equilibrium with body C, then body A is also in thermal equilibrium with body C. This law provides the formal physical basis for defining temperature as a measurable scalar property and enables the functioning of thermometers.

Correct Option: (d)', 'ऊष्मागतिकी का शून्यांकी नियम (Zeroth Law of Thermodynamics) यह प्रतिपादित करता है कि यदि दो निकाय (A और B) किसी तीसरे निकाय (C) के साथ अलग-अलग ऊष्मीय संतुलन में हैं, तो वे परस्पर भी ऊष्मीय संतुलन में होते हैं। यह नियम तापमान (Temperature) की वैज्ञानिक अवधारणा को परिभाषित करता है और थर्मामीटर के कार्य करने का आधार है।

अतः सही उत्तर (d) है।'),
  ('ssc_cgl_tier1_mock_3', 42, 2, 'PART-2', 'General Awareness', 'Indian Economy (Taxation & Fiscal Reforms)', 'Moderate', 'Which Constitutional Amendment Act paved the way for the introduction of the Goods and Services Tax (GST) in India with effect from 1st July 2017?', 'किस संविधान संशोधन अधिनियम ने 1 जुलाई 2017 से भारत में वस्तु एवं सेवा कर (GST) लागू करने का मार्ग प्रशस्त किया?', '{"a":"101st Constitutional Amendment Act","b":"99th Constitutional Amendment Act","c":"102nd Constitutional Amendment Act","d":"100th Constitutional Amendment Act"}'::jsonb, '{"a":"101वाँ संविधान संशोधन अधिनियम","b":"99वाँ संविधान संशोधन अधिनियम","c":"102वाँ संविधान संशोधन अधिनियम","d":"100वाँ संविधान संशोधन अधिनियम"}'::jsonb, 'a', 'The Constitution (101st Amendment) Act, 2016 enabled the introduction of the Goods and Services Tax (GST) in India, which came into effect on 1st July 2017. It inserted Article 246A (special provision with respect to goods and services tax), Article 269A (levy and collection of GST on inter-state commerce), and Article 279A (creation of the GST Council).

Correct Option: (a)', '101वें संविधान संशोधन अधिनियम, 2016 के द्वारा भारत में वस्तु एवं सेवा कर (GST) को 1 जुलाई 2017 से लागू किया गया। इसने संविधान में अनुच्छेद 246A (जीएसटी लगाने की विशेष शक्तियां), अनुच्छेद 269A (अंतर-राज्यीय व्यापार पर आईजीएसटी) और अनुच्छेद 279A (जीएसटी परिषद का गठन) को जोड़ा।

अतः सही उत्तर (a) है।'),
  ('ssc_cgl_tier1_mock_3', 43, 2, 'PART-2', 'General Awareness', 'Chemistry in Daily Life', 'Moderate', 'What is the chemical name and chemical formula of ''Plaster of Paris'' obtained by heating gypsum at 373 K (100°C)?', 'जिप्सम को 373 K (100°C) पर गर्म करने पर प्राप्त ''प्लास्टर ऑफ पेरिस'' का रासायनिक नाम और सूत्र क्या है?', '{"a":"Calcium Hydroxide, Ca(OH)2","b":"Calcium Carbonate, CaCO3","c":"Calcium Sulphate Dihydrate, CaSO4·2H2O","d":"Calcium Sulphate Hemihydrate, CaSO4·½H2O"}'::jsonb, '{"a":"कैल्शियम हाइड्रॉक्साइड, Ca(OH)2","b":"कैल्शियम कार्बोनेट, CaCO3","c":"कैल्शियम सल्फेट डाइहाइड्रेट, CaSO4·2H2O","d":"कैल्शियम सल्फेट हेमीहाइड्रेट, CaSO4·½H2O"}'::jsonb, 'd', 'Plaster of Paris is Calcium Sulphate Hemihydrate (CaSO4·½H2O or 2CaSO4·H2O). It is produced by carefully heating gypsum (CaSO4·2H2O) to 373 K:
CaSO4·2H2O ⎯⎯(373 K)⎯→ CaSO4·½H2O + 1½ H2O.
On mixing with water, it rehydrates to form hard solid gypsum, making it useful for setting fractured bones, making statues, and ceiling plastering.

Correct Option: (d)', 'प्लास्टर ऑफ पेरिस का रासायनिक नाम ''कैल्शियम सल्फेट हेमीहाइड्रेट'' (अर्धहाइड्रेट) है और इसका रासायनिक सूत्र CaSO4·½H2O है। यह जिप्सम (CaSO4·2H2O) को 373 K (100°C) पर गर्म करने से जल के अणु त्यागने पर बनता है। पानी मिलाने पर यह पुनः जमकर कठोर जिप्सम में बदल जाता है, इसलिए इसका उपयोग टूटी हड्डियों पर प्लास्टर चढ़ाने, खिलौने और मूर्तियाँ बनाने में होता है।

अतः सही उत्तर (d) है।'),
  ('ssc_cgl_tier1_mock_3', 44, 2, 'PART-2', 'General Awareness', 'Art & Culture (Classical Dances of India)', 'Moderate', 'Sattriya, officially recognized as one of India''s classical dance forms, was introduced and propagated in Assam in the 15th century by which great Bhakti saint and reformer?', 'भारत के शास्त्रीय नृत्यों में से एक के रूप में मान्यता प्राप्त ''सत्रीया'' नृत्य की उत्पत्ति 15वीं शताब्दी में असम में किस महान भक्ति संत और सुधारक द्वारा की गई थी?', '{"a":"Madhavacharya","b":"Srimanta Sankaradeva","c":"Chaitanya Mahaprabhu","d":"Kabir Das"}'::jsonb, '{"a":"माध्वाचार्य","b":"श्रीमंत शंकरदेव","c":"चैतन्य महाप्रभु","d":"कबीर दास"}'::jsonb, 'b', 'Sattriya dance was conceived and developed in the 15th century by the great Vaishnavite saint, poet, and scholar Mahapurusha Srimanta Sankaradeva in Assam as an accompaniment to the Ankiya Naat (traditional Assamese one-act plays) within monastic institutions called Satras. Sangeet Natak Akademi recognized Sattriya as a classical dance of India in the year 2000.

Correct Option: (b)', 'सत्रीया नृत्य का विकास 15वीं शताब्दी में असम के महान वैष्णव संत, समाज सुधारक और कवि महापुरुष श्रीमंत शंकरदेव द्वारा किया गया था। उन्होंने इसे ''सत्र'' (मठ) परंपरा और अंकिया नाट के माध्यम से भक्ति आंदोलन के प्रचार के लिए विकसित किया। वर्ष 2000 में संगीत नाटक अकादमी द्वारा सत्रीया को भारत के आठ शास्त्रीय नृत्यों में औपचारिक रूप से शामिल किया गया।

अतः सही उत्तर (b) है।'),
  ('ssc_cgl_tier1_mock_3', 45, 2, 'PART-2', 'General Awareness', 'Human Physiology (Digestive System)', 'Moderate', 'Which digestive enzyme present in human saliva initiates the chemical digestion of dietary carbohydrates by breaking down starch into maltose?', 'मानव लार में मौजूद कौन-सा पाचक एंजाइम स्टार्च को माल्टोज में तोड़कर आहार कार्बोहाइड्रेट के रासायनिक पाचन की शुरुआत करता है?', '{"a":"Pepsin","b":"Lipase","c":"Trypsin","d":"Salivary Amylase (Ptyalin)"}'::jsonb, '{"a":"पेप्सिन","b":"लाइपेज","c":"ट्रिप्सिन","d":"लार एमाइलेज (टायलिन)"}'::jsonb, 'd', 'Chemical digestion of carbohydrates begins in the oral cavity (mouth) through Salivary Amylase (also called Ptyalin), secreted by salivary glands. It hydrolyzes complex starch molecules at an optimum pH of around 6.8 into simpler disaccharides such as maltose and isomaltose.

Correct Option: (d)', 'मनुष्य में कार्बोहाइड्रेट का पाचन मुख गुहा से ही प्रारंभ हो जाता है। लार ग्रंथियों द्वारा स्रावित लार में ''लार एमाइलेज'' (टायलिन - Ptyalin) नामक एंजाइम पाया जाता है, जो लगभग 6.8 के पीएच पर जटिल स्टार्च (मंड) को सरल डाइसैकेराइड शर्करा ''माल्टोज'' में विघटित कर देता है।

अतः सही उत्तर (d) है।'),
  ('ssc_cgl_tier1_mock_3', 46, 2, 'PART-2', 'General Awareness', 'Indian Polity (Fundamental Rights)', 'Easy', 'How many Fundamental Rights are currently guaranteed to Indian citizens under Part III of the Constitution of India?', 'भारत के संविधान के भाग III के तहत भारतीय नागरिकों को वर्तमान में कितने मौलिक अधिकार प्रदान किए गए हैं?', '{"a":"Eight","b":"Six","c":"Five","d":"Seven"}'::jsonb, '{"a":"आठ","b":"छह","c":"पाँच","d":"सात"}'::jsonb, 'b', 'Originally, the Constitution of India provided seven Fundamental Rights under Part III. However, the Right to Property (Article 31) was deleted from the list of Fundamental Rights by the 44th Constitutional Amendment Act, 1978, and made a legal right under Article 300A in Part XII. Thus, there are currently six Fundamental Rights:
1. Right to Equality (Articles 14–18)
2. Right to Freedom (Articles 19–22)
3. Right against Exploitation (Articles 23–24)
4. Right to Freedom of Religion (Articles 25–28)
5. Cultural and Educational Rights (Articles 29–30)
6. Right to Constitutional Remedies (Article 32)

Correct Option: (b)', 'मूल रूप से भारतीय संविधान के भाग III में 7 मौलिक अधिकार थे। लेकिन 44वें संविधान संशोधन अधिनियम, 1978 द्वारा ''संपत्ति के अधिकार'' (अनुच्छेद 31) को मौलिक अधिकारों की सूची से हटाकर अनुच्छेद 300A के तहत एक कानूनी/संवैधानिक अधिकार बना दिया गया। वर्तमान में नागरिकों को 6 मौलिक अधिकार प्राप्त हैं:
1. समानता का अधिकार (अनुच्छेद 14-18)
2. स्वतंत्रता का अधिकार (अनुच्छेद 19-22)
3. शोषण के विरुद्ध अधिकार (अनुच्छेद 23-24)
4. धार्मिक स्वतंत्रता का अधिकार (अनुच्छेद 25-28)
5. संस्कृति और शिक्षा संबंधी अधिकार (अनुच्छेद 29-30)
6. संवैधानिक उपचारों का अधिकार (अनुच्छेद 32)

अतः सही उत्तर (b) है।'),
  ('ssc_cgl_tier1_mock_3', 47, 2, 'PART-2', 'General Awareness', 'Ancient Indian History (Indus Valley)', 'Easy', 'The ruins of Harappa, the first discovered site of the Indus Valley Civilization, were excavated in 1921 under the leadership of which Indian archaeologist?', 'सिंधु घाटी सभ्यता के सबसे पहले खोजे गए स्थल ''हड़प्पा'' के खंडहरों का उत्खनन 1921 में किस भारतीय पुरातत्वविद् के नेतृत्व में किया गया था?', '{"a":"Daya Ram Sahni","b":"Rakhaldas Banerjee","c":"John Marshall","d":"A. Ghosh"}'::jsonb, '{"a":"दयाराम साहनी","b":"राखालदास बनर्जी","c":"जॉन मार्शल","d":"ए. घोष"}'::jsonb, 'a', 'Rai Bahadur Daya Ram Sahni directed the initial excavations at Harappa (located on the banks of river Ravi in Montgomery district, present-day Punjab, Pakistan) in 1921 under the Director-Generalship of Sir John Marshall. In 1922, Rakhaldas Banerjee excavated Mohenjo-daro on the Indus River.

Correct Option: (a)', 'वर्ष 1921 में भारतीय पुरातत्व सर्वेक्षण (ASI) के महानिदेशक जॉन मार्शल के निर्देशन में रायबहादुर दयाराम साहनी ने रावी नदी के तट पर स्थित हड़प्पा (वर्तमान पाकिस्तान के पंजाब प्रांत के मोंटगोमरी जिले में) का उत्खनन कार्य प्रारंभ किया था। इसके अगले वर्ष (1922) राखालदास बनर्जी ने मोहनजोदड़ो की खोज की थी।

अतः सही उत्तर (a) है।'),
  ('ssc_cgl_tier1_mock_3', 48, 2, 'PART-2', 'General Awareness', 'Indian Geography (Physiography & Peaks)', 'Easy', 'Which mountain peak, standing at an elevation of 2,695 meters in Kerala, is the highest peak in Peninsular India and the Western Ghats?', 'केरल में 2,695 मीटर की ऊँचाई पर स्थित कौन-सी पर्वत चोटी प्रायद्वीपीय भारत और पश्चिमी घाट की सबसे ऊँची चोटी है?', '{"a":"Guru Shikhar","b":"Mahendragiri","c":"Anamudi","d":"Doddabetta"}'::jsonb, '{"a":"गुरु शिखर","b":"महेंद्रगिरि","c":"अनामुडी","d":"डोडाबेट्टा"}'::jsonb, 'c', 'Anamudi (elevation 2,695 meters / 8,842 ft) is located in the Idukki district of Kerala within the Eravikulam National Park. It is the highest mountain peak in Peninsular India, South India, and the Western Ghats range (often termed the ''Everest of South India''). Doddabetta (2,637 m) is the highest peak of the Nilgiri Hills.

Correct Option: (c)', 'अनामुडी (ऊँचाई 2,695 मीटर) केरल के इडुक्की जिले में इराविकुलम राष्ट्रीय उद्यान में स्थित है। यह प्रायद्वीपीय भारत और पश्चिमी घाट पर्वत श्रृंखला की सबसे ऊँची चोटी है (इसे ''दक्षिण भारत का एवरेस्ट'' भी कहा जाता है)। डोडाबेट्टा (2,637 मीटर) नीलगिरि की सबसे ऊँची चोटी है।

अतः सही उत्तर (c) है।'),
  ('ssc_cgl_tier1_mock_3', 49, 2, 'PART-2', 'General Awareness', 'Physics (Optics)', 'Easy', 'Which optical phenomenon is primarily responsible for the brilliant sparkling of properly cut diamonds and the propagation of light through optical fiber cables?', 'कौन-सी प्रकाशीय परिघटना कटे हुए हीरों की अत्यधिक चमक और ऑप्टिकल फाइबर केबलों के माध्यम से प्रकाश के संचरण के लिए मुख्य रूप से जिम्मेदार है?', '{"a":"Interference of Light","b":"Total Internal Reflection","c":"Scattering of Light","d":"Diffraction of Light"}'::jsonb, '{"a":"प्रकाश का व्यतिकरण","b":"पूर्ण आंतरिक परावर्तन (Total Internal Reflection)","c":"प्रकाश का प्रकीर्णन","d":"प्रकाश का विवर्तन"}'::jsonb, 'b', 'Total Internal Reflection (TIR) occurs when light travels from an optically denser medium to a rarer medium at an angle of incidence greater than the critical angle. Because diamond has an exceptionally high refractive index (2.42), its critical angle is very small (about 24.4°), trapping light through multiple internal reflections. Optical fibers also rely entirely on TIR to transmit high-speed data signals with negligible loss.

Correct Option: (b)', 'पूर्ण आंतरिक परावर्तन (Total Internal Reflection - TIR) तब घटित होता है जब प्रकाश सघन माध्यम से विरल माध्यम में प्रवेश करता है और आपतन कोण का मान क्रांतिक कोण (Critical angle) से अधिक होता है। हीरे का अपवर्तनांक बहुत अधिक (2.42) होने के कारण इसका क्रांतिक कोण बहुत कम (लगभग 24.4°) होता है, जिससे प्रकाश भीतर बार-बार परावर्तित होकर चमक उत्पन्न करता है। ऑप्टिकल फाइबर केबल भी पूर्ण आंतरिक परावर्तन के सिद्धांत पर ही कार्य करते हैं।

अतः सही उत्तर (b) है।'),
  ('ssc_cgl_tier1_mock_3', 50, 2, 'PART-2', 'General Awareness', 'Cell Biology', 'Easy', 'Which eukaryotic cell organelle is universally referred to as the ''Powerhouse of the Cell'' because it synthesizes cellular energy in the form of Adenosine Triphosphate (ATP)?', 'किस यूकैरियोटिक कोशिकांग को ''कोशिका का ऊर्जाघर'' (पावरहाउस) कहा जाता है क्योंकि यह एडेनोसिन ट्राइफॉस्फेट (ATP) के रूप में ऊर्जा का उत्पादन करता है?', '{"a":"Ribosome","b":"Lysosome","c":"Mitochondrion","d":"Golgi Apparatus"}'::jsonb, '{"a":"राइबोसोम","b":"लाइसोसोम","c":"माइटोकॉन्ड्रिया","d":"गॉल्जी उपकरण"}'::jsonb, 'c', 'The Mitochondrion (plural: Mitochondria) is a double-membrane bound organelle found in eukaryotic cells. It carries out cellular respiration, Krebs cycle, and oxidative phosphorylation to produce Adenosine Triphosphate (ATP), which acts as the chemical energy currency of the cell. Hence, it is known as the ''Powerhouse of the Cell''.

Correct Option: (c)', 'माइटोकॉन्ड्रिया (Mitochondria) दोहरी झिल्ली वाला कोशिकांग है जिसे ''कोशिका का पावरहाउस'' कहा जाता है। यह कोशिकीय श्वसन, क्रेब्स चक्र और ऑक्सीडेटिव फॉस्फारिलीकरण के माध्यम से एडेनोसिन ट्राइफॉस्फेट (ATP) के रूप में ऊर्जा का संश्लेषण करता है, जो कोशिका की ऊर्जा मुद्रा (Energy currency) के रूप में कार्य करती है।

अतः सही उत्तर (c) है।'),
  ('ssc_cgl_tier1_mock_3', 51, 3, 'PART-3', 'Quantitative Aptitude', 'Number System (Divisibility)', 'Easy', 'If the 8-digit number 785x367y is completely divisible by 72, then what is the value of (x + 2y)?', 'यदि 8-अंकीय संख्या 785x367y, 72 से पूर्णतः विभाज्य है, तो (x + 2y) का मान क्या होगा?', '{"a":"9","b":"15","c":"13","d":"11"}'::jsonb, '{"a":"9","b":"15","c":"13","d":"11"}'::jsonb, 'd', 'A number is divisible by 72 if it is divisible by both 8 and 9 (since 8 and 9 are co-prime).

Step 1: Divisibility by 8 (Last 3 digits ''67y'' must be divisible by 8):
67y ÷ 8 → 670 ÷ 8 = 83 with a remainder of 6.
For (60 + y) to be divisible by 8, y must be 2 (since 64 ÷ 8 = 8).
Thus, y = 2.

Step 2: Divisibility by 9 (Sum of digits must be a multiple of 9):
Sum of digits = 7 + 8 + 5 + x + 3 + 6 + 7 + 2 = 38 + x.
The nearest multiple of 9 greater than 38 is 45.
38 + x = 45 ⇒ x = 7.

Step 3: Calculate (x + 2y):
x + 2y = 7 + 2(2) = 7 + 4 = 11.

Correct Option: (d)', '72 से विभाज्यता के लिए संख्या का 8 और 9 दोनों से विभाज्य होना आवश्यक है (क्योंकि 8 और 9 सह-अभाज्य हैं)।

चरण 1: 8 से विभाज्यता (अंतिम तीन अंक ''67y'' 8 से विभाज्य होने चाहिए):
67y ÷ 8 → 670 में 8 का भाग देने पर शेषफल 6 बचता है।
अतः (60 + y) को 8 से विभाज्य होने के लिए y = 2 होना चाहिए (चूँकि 64, 8 से विभाज्य है)।
अतः y = 2।

चरण 2: 9 से विभाज्यता (अंकों का योग 9 का गुणज होना चाहिए):
अंकों का योग = 7 + 8 + 5 + x + 3 + 6 + 7 + 2 = 38 + x
38 से बड़ा 9 का निकटतम गुणज 45 है।
38 + x = 45 ⇒ x = 7।

चरण 3: (x + 2y) का मान:
x + 2y = 7 + 2(2) = 7 + 4 = 11।

अतः सही उत्तर (d) है।'),
  ('ssc_cgl_tier1_mock_3', 52, 3, 'PART-3', 'Quantitative Aptitude', 'Percentages', 'Easy', 'The price of petrol increased by 20%. By what percentage should a driver reduce the consumption of petrol so that the expenditure on petrol increases by only 8%?', 'पेट्रोल के मूल्य में 20% की वृद्धि होती है। एक चालक को पेट्रोल की खपत में कितने प्रतिशत की कमी करनी चाहिए ताकि पेट्रोल पर होने वाले व्यय में केवल 8% की वृद्धि हो?', '{"a":"15%","b":"8%","c":"12%","d":"10%"}'::jsonb, '{"a":"15%","b":"8%","c":"12%","d":"10%"}'::jsonb, 'd', 'Let initial price = ₹100 per unit and initial consumption = 100 units.
Initial Expenditure = 100 × 100 = ₹10,000.

New price after 20% increase = ₹120.
Target expenditure after 8% increase = ₹10,000 × 1.08 = ₹10,800.

New Consumption = New Expenditure ÷ New Price
= 10,800 ÷ 120 = 90 units.

Reduction in consumption = 100 − 90 = 10 units.
Percentage reduction = (10 / 100) × 100 = 10%.

Correct Option: (d)', 'माना प्रारंभिक मूल्य = ₹100 प्रति इकाई तथा प्रारंभिक खपत = 100 इकाई।
प्रारंभिक व्यय = 100 × 100 = ₹10,000।

20% वृद्धि के बाद नया मूल्य = ₹120।
8% वृद्धि के बाद नया व्यय = ₹10,000 × 1.08 = ₹10,800।

नई खपत = नया व्यय ÷ नया मूल्य
= 10,800 ÷ 120 = 90 इकाई।

खपत में कमी = 100 − 90 = 10 इकाई (अर्थात 10%)।

अतः सही उत्तर (d) है।'),
  ('ssc_cgl_tier1_mock_3', 53, 3, 'PART-3', 'Quantitative Aptitude', 'Ratio & Proportion', 'Easy', 'What is the ratio of the mean proportional between 14.4 and 3.6 to the third proportional of 5 and 15?', '14.4 और 3.6 के मध्यानुपाती तथा 5 और 15 के तृतीयानुपाती का अनुपात क्या है?', '{"a":"4 : 25","b":"6 : 25","c":"2 : 15","d":"3 : 20"}'::jsonb, '{"a":"4 : 25","b":"6 : 25","c":"2 : 15","d":"3 : 20"}'::jsonb, 'a', 'Step 1: Calculate the Mean Proportional between 14.4 and 3.6:
Mean Proportional = √(a × b) = √(14.4 × 3.6) = √[(144 × 36) / 100] = (12 × 6) / 10 = 7.2.

Step 2: Calculate the Third Proportional to 5 and 15:
Third Proportional c = b² / a = 15² / 5 = 225 / 5 = 45.

Step 3: Ratio of Mean Proportional to Third Proportional:
Ratio = 7.2 : 45 = 72 : 450 = 4 : 25 (dividing both by 18).

Correct Option: (a)', 'चरण 1: 14.4 और 3.6 का मध्यानुपाती ज्ञात करना:
मध्यानुपाती = √(a × b) = √(14.4 × 3.6) = √[(144 × 36) / 100] = (12 × 6) / 10 = 7.2।

चरण 2: 5 और 15 का तृतीयानुपाती ज्ञात करना:
तृतीयानुपाती c = b² / a = 15² / 5 = 225 / 5 = 45।

चरण 3: दोनों का अनुपात:
7.2 : 45 = 72 : 450 = 4 : 25 (18 से विभाजित करने पर)।

अतः सही उत्तर (a) है।'),
  ('ssc_cgl_tier1_mock_3', 54, 3, 'PART-3', 'Quantitative Aptitude', 'Averages', 'Easy', 'The average weight of 24 students in a class is 45 kg. When the weight of the teacher is included, the average weight increases by 800 grams. What is the weight of the teacher?', 'एक कक्षा के 24 विद्यार्थियों का औसत वजन 45 किग्रा है। जब शिक्षक का वजन शामिल कर लिया जाता है, तो औसत वजन में 800 ग्राम की वृद्धि हो जाती है। शिक्षक का वजन कितना है?', '{"a":"65 kg","b":"66.5 kg","c":"63 kg","d":"64.2 kg"}'::jsonb, '{"a":"65 किग्रा","b":"66.5 किग्रा","c":"63 किग्रा","d":"64.2 किग्रा"}'::jsonb, 'a', 'Method 1 (Direct Shortcut):
Teacher''s weight = Old Average + (Total new number of people × Increase in average)
= 45 kg + (25 × 0.8 kg)
= 45 + 20 = 65 kg.

Method 2 (Standard Calculation):
Total weight of 24 students = 24 × 45 = 1,080 kg.
New average of 25 persons = 45 + 0.8 = 45.8 kg.
Total weight of 25 persons = 25 × 45.8 = 1,145 kg.
Weight of teacher = 1,145 − 1,080 = 65 kg.

Correct Option: (a)', 'संक्षिप्त विधि:
शिक्षक का वजन = पुराना औसत + (व्यक्तियों की कुल नई संख्या × औसत में वृद्धि)
= 45 किग्रा + (25 × 0.8 किग्रा)
= 45 + 20 = 65 किग्रा।

विस्तृत विधि:
24 विद्यार्थियों का कुल वजन = 24 × 45 = 1,080 किग्रा।
शिक्षक सहित 25 व्यक्तियों का नया औसत = 45 + 0.8 = 45.8 किग्रा।
25 व्यक्तियों का कुल वजन = 25 × 45.8 = 1,145 किग्रा।
शिक्षक का वजन = 1,145 − 1,080 = 65 किग्रा।

अतः सही उत्तर (a) है।'),
  ('ssc_cgl_tier1_mock_3', 55, 3, 'PART-3', 'Quantitative Aptitude', 'Time & Work', 'Easy', 'A can complete a piece of work alone in 18 days, B in 24 days, and C in 36 days. If all three work together, in how many days will the entire work be completed?', 'A अकेला किसी कार्य को 18 दिनों में, B 24 दिनों में तथा C 36 दिनों में पूरा कर सकता है। यदि तीनों एक साथ कार्य करते हैं, तो पूरा कार्य कितने दिनों में समाप्त होगा?', '{"a":"9 days","b":"7.5 days","c":"8 days","d":"10 days"}'::jsonb, '{"a":"9 दिन","b":"7.5 दिन","c":"8 दिन","d":"10 दिन"}'::jsonb, 'c', 'Total work = LCM of (18, 24, 36) = 72 units.

Individual daily work (efficiencies):
- Efficiency of A = 72 ÷ 18 = 4 units/day
- Efficiency of B = 72 ÷ 24 = 3 units/day
- Efficiency of C = 72 ÷ 36 = 2 units/day

Combined efficiency of (A + B + C) = 4 + 3 + 2 = 9 units/day.
Time taken together = Total work ÷ Combined efficiency = 72 ÷ 9 = 8 days.

Correct Option: (c)', 'कुल कार्य = (18, 24, 36) का ल.स.प. (LCM) = 72 इकाई।

कार्यकुशलता (प्रतिदिन कार्य):
- A की कार्यकुशलता = 72 ÷ 18 = 4 इकाई/दिन
- B की कार्यकुशलता = 72 ÷ 24 = 3 इकाई/दिन
- C की कार्यकुशलता = 72 ÷ 36 = 2 इकाई/दिन

तीनों की संयुक्त कार्यकुशलता = 4 + 3 + 2 = 9 इकाई/दिन।
एक साथ कार्य समाप्त करने में लगा समय = 72 ÷ 9 = 8 दिन।

अतः सही उत्तर (c) है।'),
  ('ssc_cgl_tier1_mock_3', 56, 3, 'PART-3', 'Quantitative Aptitude', 'Simplification & Surds', 'Easy', 'Find the value of the following expression:
[(√7 + √5) / (√7 − √5)] + [(√7 − √5) / (√7 + √5)]', 'निम्नलिखित व्यंजक का मान ज्ञात कीजिए:
[(√7 + √5) / (√7 − √5)] + [(√7 − √5) / (√7 + √5)]', '{"a":"10","b":"2√35","c":"12","d":"14"}'::jsonb, '{"a":"10","b":"2√35","c":"12","d":"14"}'::jsonb, 'c', 'Standard algebraic identity for conjugate surds:
[(√a + √b) / (√a − √b)] + [(√a − √b) / (√a + √b)] = [ (√a + √b)² + (√a − √b)² ] / [ (√a)² − (√b)² ]
= 2(a + b) / (a − b)

Here, a = 7 and b = 5:
Value = 2(7 + 5) / (7 − 5) = 2(12) / 2 = 12.

Correct Option: (c)', 'संयुग्मी करणी के लिए बीजगणितीय सर्वसमिका:
[(√a + √b) / (√a − √b)] + [(√a − √b) / (√a + √b)] = 2(a + b) / (a − b)

यहाँ a = 7 और b = 5 रखने पर:
मान = 2(7 + 5) / (7 − 5) = 2(12) / 2 = 12।

अतः सही उत्तर (c) है।'),
  ('ssc_cgl_tier1_mock_3', 57, 3, 'PART-3', 'Quantitative Aptitude', 'Trigonometry', 'Easy', 'Find the value of: 4 cot² 45° − sec² 60° + sin² 30°', '4 cot² 45° − sec² 60° + sin² 30° का मान ज्ञात कीजिए:', '{"a":"1/4","b":"3/4","c":"1/2","d":"1"}'::jsonb, '{"a":"1/4","b":"3/4","c":"1/2","d":"1"}'::jsonb, 'a', 'Substitute standard trigonometric values:
- cot 45° = 1 ⇒ 4 cot² 45° = 4(1)² = 4
- sec 60° = 2 ⇒ sec² 60° = (2)² = 4
- sin 30° = 1/2 ⇒ sin² 30° = (1/2)² = 1/4

Expression = 4 − 4 + 1/4 = 1/4.

Correct Option: (a)', 'मानक त्रिकोणमितीय मान रखने पर:
- cot 45° = 1 ⇒ 4 cot² 45° = 4(1)² = 4
- sec 60° = 2 ⇒ sec² 60° = (2)² = 4
- sin 30° = 1/2 ⇒ sin² 30° = (1/2)² = 1/4

व्यंजक = 4 − 4 + 1/4 = 1/4।

अतः सही उत्तर (a) है।'),
  ('ssc_cgl_tier1_mock_3', 58, 3, 'PART-3', 'Quantitative Aptitude', 'Profit, Loss & Discount', 'Moderate', 'A shopkeeper marks an article 50% above its cost price and sells it after offering two successive discounts of 20% and 10%. If he earns a profit of ₹256 on the transaction, what is the cost price of the article?', 'एक दुकानदार किसी वस्तु का मूल्य उसके क्रय मूल्य से 50% अधिक अंकित करता है और 20% तथा 10% की दो क्रमिक छूट देकर उसे बेचता है। यदि वह इस सौदे में ₹256 का लाभ अर्जित करता है, तो वस्तु का क्रय मूल्य क्या है?', '{"a":"₹2,800","b":"₹3,000","c":"₹3,200","d":"₹3,400"}'::jsonb, '{"a":"₹2,800","b":"₹3,000","c":"₹3,200","d":"₹3,400"}'::jsonb, 'c', 'Let the Cost Price (CP) = 100x.
Marked Price (MP) = 100x + 50% of 100x = 150x.

Selling Price (SP) after successive discounts of 20% and 10%:
SP = MP × (1 − 20/100) × (1 − 10/100)
= 150x × 0.80 × 0.90
= 150x × 0.72 = 108x.

Profit = SP − CP = 108x − 100x = 8x.
Given, Profit = ₹256:
8x = 256 ⇒ x = 32.

Cost Price (CP) = 100x = 100 × 32 = ₹3,200.

Correct Option: (c)', 'माना वस्तु का क्रय मूल्य (CP) = 100x।
अंकित मूल्य (MP) = 100x + 50% = 150x।

20% और 10% की दो क्रमिक छूट के बाद विक्रय मूल्य (SP):
SP = 150x × (80/100) × (90/100)
= 150x × 0.72 = 108x।

लाभ = SP − CP = 108x − 100x = 8x।
दिया गया लाभ = ₹256:
8x = 256 ⇒ x = 32।

वस्तु का क्रय मूल्य = 100x = 100 × 32 = ₹3,200।

अतः सही उत्तर (c) है।'),
  ('ssc_cgl_tier1_mock_3', 59, 3, 'PART-3', 'Quantitative Aptitude', 'Simple & Compound Interest', 'Moderate', 'The difference between the compound interest (compounded annually) and simple interest on a certain sum of money for 3 years at 10% per annum is ₹930. What is the sum of money?', 'किसी निश्चित धनराशि पर 10% वार्षिक ब्याज दर से 3 वर्षों के चक्रवृद्धि ब्याज (वार्षिक रूप से संयोजित) और साधारण ब्याज के बीच का अंतर ₹930 है। वह धनराशि क्या है?', '{"a":"₹28,000","b":"₹30,000","c":"₹25,000","d":"₹32,000"}'::jsonb, '{"a":"₹28,000","b":"₹30,000","c":"₹25,000","d":"₹32,000"}'::jsonb, 'b', 'Formula for the difference between CI and SI for 3 years:
Difference = P × (r / 100)² × [3 + (r / 100)]

Given, r = 10% and Difference = ₹930:
930 = P × (10 / 100)² × [3 + (10 / 100)]
930 = P × (1 / 100) × (31 / 10)
930 = 31P / 1000
P = (930 × 1000) / 31 = 30 × 1000 = ₹30,000.

Correct Option: (b)', '3 वर्षों के लिए CI और SI के अंतर का सूत्र:
अंतर = P × (r / 100)² × [3 + (r / 100)]

यहाँ r = 10% तथा अंतर = ₹930:
930 = P × (10 / 100)² × [3 + 0.1]
930 = P × (1 / 100) × 3.1
930 = 31P / 1000
P = (930 × 1000) / 31 = ₹30,000।

अतः सही उत्तर (b) है।'),
  ('ssc_cgl_tier1_mock_3', 60, 3, 'PART-3', 'Quantitative Aptitude', 'Mixture & Alligation', 'Moderate', 'A container contains 80 litres of pure milk. From this container, 8 litres of milk was taken out and replaced with water. This process was repeated two more times. How much milk is left in the container now?', 'एक बर्तन में 80 लीटर शुद्ध दूध है। इस बर्तन से 8 लीटर दूध निकालकर उतना ही पानी मिला दिया जाता है। इस प्रक्रिया को दो बार और दोहराया जाता है। अब बर्तन में कितना दूध शेष है?', '{"a":"56.40 litres","b":"57.84 litres","c":"60.25 litres","d":"58.32 litres"}'::jsonb, '{"a":"56.40 लीटर","b":"57.84 लीटर","c":"60.25 लीटर","d":"58.32 लीटर"}'::jsonb, 'd', 'Formula for repeated dilution:
Remaining quantity of pure liquid = Initial Quantity × [1 − (x / V)]ⁿ
Where:
- Initial Volume V = 80 litres
- Quantity withdrawn x = 8 litres
- Number of operations n = 1 + 2 = 3 times

Remaining Milk = 80 × [1 − (8 / 80)]³
= 80 × (9 / 10)³
= 80 × (729 / 1000)
= 58,320 / 1000 = 58.32 litres.

Correct Option: (d)', 'क्रमानुगत प्रतिस्थापन का सूत्र:
शेष शुद्ध द्रव की मात्रा = प्रारंभिक मात्रा × [1 − (x / V)]ⁿ
जहाँ V = 80 लीटर, x = 8 लीटर, तथा n = 3 बार।

शेष दूध = 80 × [1 − (8 / 80)]³
= 80 × (9 / 10)³
= 80 × (729 / 1000)
= 58.32 लीटर।

अतः सही उत्तर (d) है।'),
  ('ssc_cgl_tier1_mock_3', 61, 3, 'PART-3', 'Quantitative Aptitude', 'Speed, Time & Distance (Trains)', 'Moderate', 'A train 300 meters long crosses a platform of length 200 meters in 25 seconds. How much time (in seconds) will the same train take to cross a person running at a speed of 18 km/h in the direction opposite to that of the train?', '300 मीटर लंबी एक ट्रेन 200 मीटर लंबे प्लेटफॉर्म को 25 सेकंड में पार करती है। वही ट्रेन अपनी विपरीत दिशा में 18 किमी/घंटा की चाल से दौड़ रहे एक व्यक्ति को कितने समय (सेकंड में) पार करेगी?', '{"a":"14 seconds","b":"15 seconds","c":"12 seconds","d":"10 seconds"}'::jsonb, '{"a":"14 सेकंड","b":"15 सेकंड","c":"12 सेकंड","d":"10 सेकंड"}'::jsonb, 'c', 'Step 1: Calculate speed of the train.
Total distance to cross platform = Length of train + Length of platform = 300 + 200 = 500 meters.
Speed of train = Distance / Time = 500 / 25 = 20 m/s.

Step 2: Speed of the person.
Speed of person = 18 km/h = 18 × (5 / 18) = 5 m/s.

Step 3: Relative speed when moving in opposite directions:
Relative speed = Speed of train + Speed of person = 20 + 5 = 25 m/s.

Step 4: Time taken to cross the person:
Distance = Length of train = 300 meters.
Time = 300 / 25 = 12 seconds.

Correct Option: (c)', 'चरण 1: ट्रेन की चाल ज्ञात करना:
प्लेटफॉर्म पार करने में कुल दूरी = ट्रेन की लंबाई + प्लेटफॉर्म की लंबाई = 300 + 200 = 500 मीटर।
ट्रेन की चाल = 500 / 25 = 20 मीटर/सेकंड।

चरण 2: व्यक्ति की चाल:
18 किमी/घंटा = 18 × (5 / 18) = 5 मीटर/सेकंड।

चरण 3: विपरीत दिशा में सापेक्ष चाल:
सापेक्ष चाल = 20 + 5 = 25 मीटर/सेकंड।

चरण 4: व्यक्ति को पार करने में लगा समय:
दूरी = ट्रेन की लंबाई = 300 मीटर।
समय = 300 / 25 = 12 सेकंड।

अतः सही उत्तर (c) है।'),
  ('ssc_cgl_tier1_mock_3', 62, 3, 'PART-3', 'Quantitative Aptitude', 'Boats & Streams', 'Moderate', 'A motorboat travels 36 km downstream and 24 km upstream in a total of 6 hours. If the speed of the stream is 2 km/h, what is the speed of the motorboat in still water?', 'एक मोटरबोट धारा के अनुकूल 36 किमी और धारा के प्रतिकूल 24 किमी की दूरी कुल 6 घंटे में तय करती है। यदि धारा की चाल 2 किमी/घंटा है, तो शांत जल में मोटरबोट की चाल क्या है?', '{"a":"8 km/h","b":"10 km/h","c":"12 km/h","d":"9 km/h"}'::jsonb, '{"a":"8 किमी/घंटा","b":"10 किमी/घंटा","c":"12 किमी/घंटा","d":"9 किमी/घंटा"}'::jsonb, 'b', 'Let the speed of the motorboat in still water be x km/h.
Speed of stream = 2 km/h.
- Downstream speed = (x + 2) km/h
- Upstream speed = (x − 2) km/h

Total time equation:
[36 / (x + 2)] + [24 / (x − 2)] = 6

Dividing the entire equation by 6:
[6 / (x + 2)] + [4 / (x − 2)] = 1

Testing x = 10 km/h:
[6 / (10 + 2)] + [4 / (10 − 2)] = (6 / 12) + (4 / 8) = 0.5 + 0.5 = 1 (LHS = RHS).

Hence, the speed of the motorboat in still water is 10 km/h.

Correct Option: (b)', 'माना शांत जल में नाव की चाल = x किमी/घंटा।
धारा की चाल = 2 किमी/घंटा।
- धारा के अनुकूल चाल = (x + 2) किमी/घंटा
- धारा के प्रतिकूल चाल = (x − 2) किमी/घंटा

कुल समय = 6 घंटे:
[36 / (x + 2)] + [24 / (x − 2)] = 6

पूरे समीकरण को 6 से विभाजित करने पर:
[6 / (x + 2)] + [4 / (x − 2)] = 1

x = 10 किमी/घंटा रखने पर:
(6 / 12) + (4 / 8) = 0.5 + 0.5 = 1 (संतुष्ट होता है)।

अतः शांत जल में मोटरबोट की चाल 10 किमी/घंटा है।

अतः सही उत्तर (b) है।'),
  ('ssc_cgl_tier1_mock_3', 63, 3, 'PART-3', 'Quantitative Aptitude', 'Algebra', 'Moderate', 'If x + (1/x) = 3, what is the value of [x⁵ + (1/x⁵)]?', 'यदि x + (1/x) = 3 है, तो [x⁵ + (1/x⁵)] का मान क्या होगा?', '{"a":"126","b":"123","c":"120","d":"129"}'::jsonb, '{"a":"126","b":"123","c":"120","d":"129"}'::jsonb, 'b', 'Given: x + (1/x) = 3

Step 1: Find x² + (1/x²):
x² + (1/x²) = [x + (1/x)]² − 2 = 3² − 2 = 9 − 2 = 7.

Step 2: Find x³ + (1/x³):
x³ + (1/x³) = [x + (1/x)]³ − 3[x + (1/x)] = 3³ − 3(3) = 27 − 9 = 18.

Step 3: Multiply the two results:
[x² + (1/x²)] × [x³ + (1/x³)] = [x⁵ + (1/x⁵)] + [x + (1/x)]
7 × 18 = [x⁵ + (1/x⁵)] + 3
126 = [x⁵ + (1/x⁵)] + 3
[x⁵ + (1/x⁵)] = 126 − 3 = 123.

Correct Option: (b)', 'दिया गया है: x + (1/x) = 3

चरण 1: x² + (1/x²) का मान:
x² + (1/x²) = 3² − 2 = 7

चरण 2: x³ + (1/x³) का मान:
x³ + (1/x³) = 3³ − 3(3) = 27 − 9 = 18

चरण 3: दोनों का गुणा करने पर:
[x² + (1/x²)] × [x³ + (1/x³)] = [x⁵ + (1/x⁵)] + [x + (1/x)]
7 × 18 = [x⁵ + (1/x⁵)] + 3
126 = [x⁵ + (1/x⁵)] + 3
[x⁵ + (1/x⁵)] = 126 − 3 = 123।

अतः सही उत्तर (b) है।'),
  ('ssc_cgl_tier1_mock_3', 64, 3, 'PART-3', 'Quantitative Aptitude', 'Geometry (Right-Angled Triangle)', 'Moderate', 'In a right-angled triangle ABC right-angled at B, AB = 15 cm and BC = 20 cm. If R and r denote the circumradius and inradius of the triangle respectively, what is the value of (R − r)?', 'B पर समकोण वाले एक समकोण त्रिभुज ABC में, AB = 15 सेमी और BC = 20 सेमी है। यदि R और r क्रमशः त्रिभुज की परित्रिज्या और अंतःत्रिज्या को दर्शाते हैं, तो (R − r) का मान क्या होगा?', '{"a":"8 cm","b":"6 cm","c":"7.5 cm","d":"7 cm"}'::jsonb, '{"a":"8 सेमी","b":"6 सेमी","c":"7.5 सेमी","d":"7 सेमी"}'::jsonb, 'c', 'In right-angled triangle ABC with legs AB = 15 cm and BC = 20 cm:
By Pythagoras Theorem, Hypotenuse AC = √(15² + 20²) = √(225 + 400) = √625 = 25 cm.

1. Circumradius (R) of a right-angled triangle:
R = Hypotenuse / 2 = 25 / 2 = 12.5 cm.

2. Inradius (r) of a right-angled triangle:
r = (AB + BC − AC) / 2 = (15 + 20 − 25) / 2 = 10 / 2 = 5 cm.

3. Value of (R − r):
R − r = 12.5 − 5 = 7.5 cm.

Correct Option: (c)', 'समकोण त्रिभुज ABC में, भुजाएँ AB = 15 सेमी और BC = 20 सेमी हैं:
पाइथागोरस प्रमेय से, कर्ण AC = √(15² + 20²) = √625 = 25 सेमी।

1. समकोण त्रिभुज की परित्रिज्या (R):
R = कर्ण / 2 = 25 / 2 = 12.5 सेमी।

2. समकोण त्रिभुज की अंतःत्रिज्या (r):
r = (लंब + आधार − कर्ण) / 2 = (15 + 20 − 25) / 2 = 10 / 2 = 5 सेमी।

3. (R − r) का मान:
R − r = 12.5 − 5 = 7.5 सेमी।

अतः सही उत्तर (c) है।'),
  ('ssc_cgl_tier1_mock_3', 65, 3, 'PART-3', 'Quantitative Aptitude', 'Geometry (Circles & Tangents)', 'Moderate', 'Two circles have radii 9 cm and 4 cm. The distance between their centers is 13 cm. What is the length of their direct common tangent?', 'दो वृत्तों की त्रिज्याएँ 9 सेमी और 4 सेमी हैं। उनके केंद्रों के बीच की दूरी 13 सेमी है। उनकी उभयनिष्ठ अनुस्पर्श रेखा (Direct Common Tangent) की लंबाई क्या है?', '{"a":"12 cm","b":"11 cm","c":"10 cm","d":"12.5 cm"}'::jsonb, '{"a":"12 सेमी","b":"11 सेमी","c":"10 सेमी","d":"12.5 सेमी"}'::jsonb, 'a', 'Formula for the length of Direct Common Tangent (DCT):
Length = √[ d² − (r₁ − r₂)² ]

Where:
- Distance between centers d = 13 cm
- Radii r₁ = 9 cm, r₂ = 4 cm
- (r₁ − r₂) = 9 − 4 = 5 cm

Length of DCT = √[ 13² − 5² ] = √(169 − 25) = √144 = 12 cm.

Correct Option: (a)', 'उभयनिष्ठ अनुस्पर्श रेखा (DCT) की लंबाई का सूत्र:
लंबाई = √[ d² − (r₁ − r₂)² ]

जहाँ d = 13 सेमी, r₁ = 9 सेमी, r₂ = 4 सेमी:
लंबाई = √[ 13² − (9 − 4)² ]
= √[ 169 − 25 ] = √144 = 12 सेमी।

अतः सही उत्तर (a) है।'),
  ('ssc_cgl_tier1_mock_3', 66, 3, 'PART-3', 'Quantitative Aptitude', 'Mensuration 2D', 'Moderate', 'The area of an equilateral triangle is 49√3 cm². What is the area (in cm²) of the circle inscribed in this triangle? (Take π = 22/7)', 'एक समबाहु त्रिभुज का क्षेत्रफल 49√3 सेमी² है। इस त्रिभुज के अंतःवृत्त (inscribed circle) का क्षेत्रफल (सेमी² में) क्या होगा? (π = 22/7 मानिए)', '{"a":"46⅔ cm²","b":"48 cm²","c":"54 cm²","d":"51⅓ cm² (154/3 cm²)"}'::jsonb, '{"a":"46⅔ सेमी²","b":"48 सेमी²","c":"54 सेमी²","d":"51⅓ सेमी² (154/3 सेमी²)"}'::jsonb, 'd', 'Step 1: Find side ''a'' of the equilateral triangle.
Area = (√3 / 4) × a²
49√3 = (√3 / 4) × a²
a² = 49 × 4 = 196 ⇒ a = 14 cm.

Step 2: Find the inradius (r) of the equilateral triangle.
r = a / (2√3) = 14 / (2√3) = 7 / √3 cm.

Step 3: Area of the inscribed circle:
Area = π × r² = (22 / 7) × (7 / √3)²
= (22 / 7) × (49 / 3)
= (22 × 7) / 3 = 154 / 3 = 51⅓ cm².

Correct Option: (d)', 'चरण 1: समबाहु त्रिभुज की भुजा (a) ज्ञात करना:
क्षेत्रफल = (√3 / 4) × a²
49√3 = (√3 / 4) × a²
a² = 196 ⇒ a = 14 सेमी।

चरण 2: समबाहु त्रिभुज की अंतःत्रिज्या (r):
r = a / (2√3) = 14 / (2√3) = 7 / √3 सेमी।

चरण 3: अंतःवृत्त का क्षेत्रफल:
क्षेत्रफल = πr² = (22 / 7) × (7 / √3)²
= (22 / 7) × (49 / 3) = 154 / 3 = 51⅓ सेमी²।

अतः सही उत्तर (d) है।'),
  ('ssc_cgl_tier1_mock_3', 67, 3, 'PART-3', 'Quantitative Aptitude', 'Mensuration 3D', 'Moderate', 'A solid metallic sphere of radius 6 cm is melted and recast into a solid right circular cone having a base radius of 6 cm. What is the height of the recast cone?', '6 सेमी त्रिज्या वाले एक ठोस धात्विक गोले को पिघलाकर 6 सेमी आधार त्रिज्या वाले एक ठोस लंब वृत्तीय शंकु में ढाला जाता है। पुनर्गठित शंकु की ऊँचाई क्या होगी?', '{"a":"20 cm","b":"28 cm","c":"24 cm","d":"18 cm"}'::jsonb, '{"a":"20 सेमी","b":"28 सेमी","c":"24 सेमी","d":"18 सेमी"}'::jsonb, 'c', 'Since the sphere is melted and recast into a cone, the volume remains conserved:
Volume of Sphere = Volume of Cone

(4/3) × π × R³ = (1/3) × π × r² × h

Substitute R = 6 cm and r = 6 cm:
(4/3) × π × (6)³ = (1/3) × π × (6)² × h
4 × 216 = 36 × h
864 = 36h
h = 864 / 36 = 24 cm.

Correct Option: (c)', 'धातु को पिघलाने पर आयतन समान रहता है:
गोले का आयतन = शंकु का आयतन

(4/3) × π × R³ = (1/3) × π × r² × h

R = 6 सेमी तथा r = 6 सेमी रखने पर:
4 × 6³ = 6² × h
4 × 216 = 36 × h
h = 864 / 36 = 24 सेमी।

अतः सही उत्तर (c) है।'),
  ('ssc_cgl_tier1_mock_3', 68, 3, 'PART-3', 'Quantitative Aptitude', 'Time, Work & Wages', 'Hard', 'A, B, and C can complete a piece of work individually in 20 days, 30 days, and 60 days respectively. A works alone on the first two days, and is assisted by both B and C on every third day. In how many days will the work be completed, and if the total wage for the work is ₹18,000, what will be A''s share?', 'A, B और C अलग-अलग एक कार्य को क्रमशः 20 दिन, 30 दिन और 60 दिन में पूरा कर सकते हैं। A पहले दो दिन अकेले कार्य करता है तथा प्रत्येक तीसरे दिन B और C उसकी सहायता करते हैं। कार्य कितने दिनों में समाप्त होगा, और यदि कार्य की कुल मजदूरी ₹18,000 है, तो A का हिस्सा कितना होगा?', '{"a":"18 days, ₹13,500","b":"15 days, ₹12,000","c":"16 days, ₹14,000","d":"15 days, ₹13,500"}'::jsonb, '{"a":"18 दिन, ₹13,500","b":"15 दिन, ₹12,000","c":"16 दिन, ₹14,000","d":"15 दिन, ₹13,500"}'::jsonb, 'd', 'Total Work = LCM(20, 30, 60) = 60 units.
Efficiencies:
- A = 60 / 20 = 3 units/day
- B = 60 / 30 = 2 units/day
- C = 60 / 60 = 1 unit/day

Work done in a 3-day cycle:
- Day 1: A alone = 3 units
- Day 2: A alone = 3 units
- Day 3: A + B + C together = 3 + 2 + 1 = 6 units
Total work in 3 days = 3 + 3 + 6 = 12 units.

Number of 3-day cycles to complete 60 units = 60 ÷ 12 = 5 cycles.
Total time = 5 × 3 = 15 days.

Work done by A:
A worked on all 15 days = 15 × 3 = 45 units out of 60 units.
A''s share of wages = (45 / 60) × ₹18,000 = (3 / 4) × ₹18,000 = ₹13,500.

Correct Option: (d)', 'कुल कार्य = LCM(20, 30, 60) = 60 इकाई।
कार्यकुशलता:
- A = 60 / 20 = 3 इकाई/दिन
- B = 60 / 30 = 2 इकाई/दिन
- C = 60 / 60 = 1 इकाई/दिन

3 दिन के चक्र में कार्य:
- पहला दिन: A = 3 इकाई
- दूसरा दिन: A = 3 इकाई
- तीसरा दिन: A + B + C = 3 + 2 + 1 = 6 इकाई
3 दिनों में किया गया कार्य = 12 इकाई।

60 इकाई पूरा करने में चक्र = 60 ÷ 12 = 5 चक्र।
कुल दिन = 5 × 3 = 15 दिन।

A द्वारा किया गया कुल कार्य = 15 × 3 = 45 इकाई।
A की मजदूरी = (45 / 60) × 18,000 = (3/4) × 18,000 = ₹13,500।

अतः सही उत्तर (d) है।'),
  ('ssc_cgl_tier1_mock_3', 69, 3, 'PART-3', 'Quantitative Aptitude', 'Speed, Time & Distance (Races)', 'Hard', 'In a 1000-meter race, runner A beats runner B by 100 meters, and runner B beats runner C by 100 meters. In the same 1000-meter race, by how many meters does A beat C?', '1000 मीटर की दौड़ में, धावक A धावक B को 100 मीटर से हराता है, और धावक B धावक C को 100 मीटर से हराता है। उसी 1000 मीटर की दौड़ में A, C को कितने मीटर से हराएगा?', '{"a":"190 m","b":"180 m","c":"200 m","d":"195 m"}'::jsonb, '{"a":"190 मीटर","b":"180 मीटर","c":"200 मीटर","d":"195 मीटर"}'::jsonb, 'a', 'Step 1: Set up the ratio of distances covered in the same time.
- When A runs 1000 m, B runs (1000 − 100) = 900 m.
Ratio A : B = 1000 : 900 = 10 : 9.

- When B runs 1000 m, C runs (1000 − 100) = 900 m.
Ratio B : C = 1000 : 900 = 10 : 9.

Step 2: Combine the ratios to find A : C:
A / C = (A / B) × (B / C) = (10 / 9) × (10 / 9) = 100 / 81.

Step 3: Distance covered by C when A completes the 1000 m race:
When A runs 1000 m:
Distance covered by C = 1000 × (81 / 100) = 810 meters.

Distance by which A beats C = 1000 − 810 = 190 meters.

Correct Option: (a)', 'चरण 1: समान समय में तय की गई दूरियों का अनुपात:
- जब A 1000 मीटर दौड़ता है, तब B (1000 − 100) = 900 मीटर दौड़ता है।
A : B = 10 : 9

- जब B 1000 मीटर दौड़ता है, तब C (1000 − 100) = 900 मीटर दौड़ता है।
B : C = 10 : 9

चरण 2: A और C का अनुपात:
A / C = (A / B) × (B / C) = (10 / 9) × (10 / 9) = 100 / 81

चरण 3: जब A 1000 मीटर पूरा करता है, तब C द्वारा तय दूरी:
C की दूरी = 1000 × (81 / 100) = 810 मीटर।

A द्वारा C को हराया गया अंतर = 1000 − 810 = 190 मीटर।

अतः सही उत्तर (a) है।'),
  ('ssc_cgl_tier1_mock_3', 70, 3, 'PART-3', 'Quantitative Aptitude', 'Compound Interest (Non-Annual Compounding)', 'Hard', 'What is the compound interest on a sum of ₹15,625 for 2 years at 12% per annum, when the interest is compounded 8-monthly?', '₹15,625 की धनराशि पर 12% वार्षिक दर से 2 वर्षों के लिए चक्रवृद्धि ब्याज कितना होगा, यदि ब्याज की गणना 8-मासिक चक्रवृद्धि आधार पर की जाती है?', '{"a":"₹3,950","b":"₹4,058","c":"₹4,120","d":"₹4,258"}'::jsonb, '{"a":"₹3,950","b":"₹4,058","c":"₹4,120","d":"₹4,258"}'::jsonb, 'b', 'Parameters for 8-monthly compounding:
- Principal P = ₹15,625
- Annual rate R = 12% per annum → Rate per 8-month period r = 12% × (8 / 12) = 8%
- Total time = 2 years = 24 months → Number of 8-month periods n = 24 / 8 = 3 periods.

Amount A = P × [1 + (r / 100)]ⁿ
A = 15,625 × [1 + (8 / 100)]³
= 15,625 × (108 / 100)³
= 15,625 × (27 / 25)³
= 15,625 × (19,683 / 15,625)
= ₹19,683.

Compound Interest = Amount − Principal
CI = 19,683 − 15,625 = ₹4,058.

Correct Option: (b)', '8-मासिक चक्रवृद्धि के लिए:
- मूलधन (P) = ₹15,625
- 8-माह की दर (r) = 12% × (8 / 12) = 8%
- अवधियों की संख्या (n) = 24 माह ÷ 8 माह = 3 अवधियाँ

मिश्रधन A = P × [1 + (8 / 100)]³
= 15,625 × (27 / 25)³
= 15,625 × (19,683 / 15,625) = ₹19,683।

चक्रवृद्धि ब्याज = मिश्रधन − मूलधन
CI = 19,683 − 15,625 = ₹4,058।

अतः सही उत्तर (b) है।'),
  ('ssc_cgl_tier1_mock_3', 71, 3, 'PART-3', 'Quantitative Aptitude', 'Advanced Algebra', 'Hard', 'If a + b + c = 6, a² + b² + c² = 20, and a³ + b³ + c³ = 66, then what is the value of abc?', 'यदि a + b + c = 6, a² + b² + c² = 20, तथा a³ + b³ + c³ = 66 है, तो abc का मान क्या होगा?', '{"a":"−2","b":"2","c":"−4","d":"4"}'::jsonb, '{"a":"−2","b":"2","c":"−4","d":"4"}'::jsonb, 'a', 'Step 1: Use the expansion identity:
(a + b + c)² = a² + b² + c² + 2(ab + bc + ca)
6² = 20 + 2(ab + bc + ca)
36 − 20 = 2(ab + bc + ca)
16 = 2(ab + bc + ca) ⇒ ab + bc + ca = 8.

Step 2: Use the cubic identity:
a³ + b³ + c³ − 3abc = (a + b + c) [ (a² + b² + c²) − (ab + bc + ca) ]
Substitute given values:
66 − 3abc = 6 × (20 − 8)
66 − 3abc = 6 × 12
66 − 3abc = 72
−3abc = 72 − 66
−3abc = 6 ⇒ abc = −2.

Correct Option: (a)', 'चरण 1: सर्वसमिका (a + b + c)² का प्रयोग:
(a + b + c)² = a² + b² + c² + 2(ab + bc + ca)
6² = 20 + 2(ab + bc + ca)
36 − 20 = 2(ab + bc + ca) ⇒ ab + bc + ca = 8।

चरण 2: त्रिघातीय सर्वसमिका का प्रयोग:
a³ + b³ + c³ − 3abc = (a + b + c) [ (a² + b² + c²) − (ab + bc + ca) ]
मान रखने पर:
66 − 3abc = 6 × (20 − 8)
66 − 3abc = 6 × 12 = 72
−3abc = 72 − 66 = 6
abc = 6 / (−3) = −2।

अतः सही उत्तर (a) है।'),
  ('ssc_cgl_tier1_mock_3', 72, 3, 'PART-3', 'Quantitative Aptitude', 'Trigonometry (Identities)', 'Hard', 'If sec θ + tan θ = 5 (where 0° < θ < 90°), what is the value of sin θ?', 'यदि sec θ + tan θ = 5 है (जहाँ 0° < θ < 90°), तो sin θ का मान क्या होगा?', '{"a":"5/13","b":"7/25","c":"11/13","d":"12/13"}'::jsonb, '{"a":"5/13","b":"7/25","c":"11/13","d":"12/13"}'::jsonb, 'd', 'Identity: sec² θ − tan² θ = 1
⇒ (sec θ + tan θ)(sec θ − tan θ) = 1
Given: sec θ + tan θ = 5
⇒ sec θ − tan θ = 1 / 5 = 0.2

Adding the two equations:
2 sec θ = 5 + 0.2 = 5.2
⇒ sec θ = 2.6 = 13 / 5.

Therefore, cos θ = 1 / sec θ = 5 / 13.
Since sin θ = √(1 − cos² θ):
sin θ = √[1 − (5/13)²] = √[1 − 25/169] = √(144/169) = 12 / 13.

Correct Option: (d)', 'सर्वसमिका: sec² θ − tan² θ = 1
(sec θ + tan θ)(sec θ − tan θ) = 1
दिया है: sec θ + tan θ = 5
⇒ sec θ − tan θ = 1 / 5

दोनों समीकरणों को जोड़ने पर:
2 sec θ = 5 + 0.2 = 5.2
sec θ = 2.6 = 13 / 5

अतः cos θ = 5 / 13।
sin θ = √(1 − cos² θ) = √[1 − (5/13)²] = √[144 / 169] = 12 / 13।

अतः सही उत्तर (d) है।'),
  ('ssc_cgl_tier1_mock_3', 73, 3, 'PART-3', 'Quantitative Aptitude', 'Geometry (Secant-Tangent Theorem)', 'Hard', 'From an external point P, a tangent line segment PT is drawn to a circle touching it at T, and a secant line PAB intersects the circle at points A and B (with A lying between P and B). If PT = 12 cm and PA = 8 cm, what is the length of chord AB?', 'एक बाह्य बिंदु P से एक वृत्त पर स्पर्श रेखाखंड PT खींचा जाता है जो वृत्त को T पर स्पर्श करता है, और एक छेदक रेखा PAB वृत्त को बिंदुओं A और B पर प्रतिच्छेद करती है (जहाँ A, P और B के बीच स्थित है)। यदि PT = 12 सेमी और PA = 8 सेमी है, तो जीवा AB की लंबाई क्या है?', '{"a":"11 cm","b":"10 cm","c":"8.5 cm","d":"9 cm"}'::jsonb, '{"a":"11 सेमी","b":"10 सेमी","c":"8.5 सेमी","d":"9 सेमी"}'::jsonb, 'b', 'By the Tangent-Secant Theorem for circles:
PT² = PA × PB

Given, PT = 12 cm and PA = 8 cm:
12² = 8 × PB
144 = 8 × PB
PB = 144 / 8 = 18 cm.

Since point A lies between P and B:
PB = PA + AB
18 = 8 + AB
AB = 18 − 8 = 10 cm.

Correct Option: (b)', 'वृत्त के स्पर्श रेखा-छेदक रेखा प्रमेय के अनुसार:
PT² = PA × PB

दिया है, PT = 12 सेमी तथा PA = 8 सेमी:
12² = 8 × PB
144 = 8 × PB ⇒ PB = 18 सेमी।

चूँकि बिंदु A, P और B के मध्य है:
PB = PA + AB
18 = 8 + AB ⇒ AB = 10 सेमी।

अतः सही उत्तर (b) है।'),
  ('ssc_cgl_tier1_mock_3', 74, 3, 'PART-3', 'Quantitative Aptitude', 'Coordinate Geometry', 'Hard', 'What is the area (in square units) of the triangle formed by the vertices A(1, 2), B(−4, −3), and C(4, 1) in the Cartesian coordinate plane?', 'कार्तीय निर्देशांक तल में शीर्ष A(1, 2), B(−4, −3) और C(4, 1) द्वारा निर्मित त्रिभुज का क्षेत्रफल (वर्ग इकाई में) क्या है?', '{"a":"14 square units","b":"10 square units","c":"8 square units","d":"12 square units"}'::jsonb, '{"a":"14 वर्ग इकाई","b":"10 वर्ग इकाई","c":"8 वर्ग इकाई","d":"12 वर्ग इकाई"}'::jsonb, 'b', 'Formula for the area of a triangle with vertices (x₁, y₁), (x₂, y₂), and (x₃, y₃):
Area = (1/2) | x₁(y₂ − y₃) + x₂(y₃ − y₁) + x₃(y₁ − y₂) |

Here, (x₁, y₁) = (1, 2); (x₂, y₂) = (−4, −3); (x₃, y₃) = (4, 1):
Area = (1/2) | 1(−3 − 1) + (−4)(1 − 2) + 4(2 − (−3)) |
= (1/2) | 1(−4) + (−4)(−1) + 4(5) |
= (1/2) | −4 + 4 + 20 |
= (1/2) | 20 | = 10 square units.

Correct Option: (b)', 'निर्देशांक ज्यामिति में त्रिभुज के क्षेत्रफल का सूत्र:
क्षेत्रफल = (1/2) | x₁(y₂ − y₃) + x₂(y₃ − y₁) + x₃(y₁ − y₂) |

दिए गए शीर्ष: (1, 2), (−4, −3), (4, 1):
क्षेत्रफल = (1/2) | 1(−3 − 1) + (−4)(1 − 2) + 4(2 − (−3)) |
= (1/2) | −4 + 4 + 20 |
= (1/2) × 20 = 10 वर्ग इकाई।

अतः सही उत्तर (b) है।'),
  ('ssc_cgl_tier1_mock_3', 75, 3, 'PART-3', 'Quantitative Aptitude', 'Data Interpretation (Table)', 'Hard', 'Study the given table carefully and answer the following question.
The table shows the production of electrical units (in thousands) manufactured by four companies (P, Q, R, and S) over three consecutive years:

Year | Company P | Company Q | Company R | Company S
----------------------------------------------------
2022 |    45     |    60     |    50     |    75    
2023 |    55     |    70     |    65     |    80    
2024 |    60     |    85     |    75     |    90    

What is the ratio of the total production of companies P and Q together in the year 2023 to the total production of companies R and S together in the year 2024?', 'दी गई तालिका का ध्यानपूर्वक अध्ययन कीजिए और नीचे दिए गए प्रश्न का उत्तर दीजिए।
तालिका तीन क्रमागत वर्षों में चार कंपनियों (P, Q, R और S) द्वारा उत्पादित विद्युत इकाइयों (हजारों में) को दर्शाती है:

वर्ष  | कंपनी P | कंपनी Q | कंपनी R | कंपनी S
--------------------------------------------
2022 |   45    |   60    |   50    |   75   
2023 |   55    |   70    |   65    |   80   
2024 |   60    |   85    |   75    |   90   

वर्ष 2023 में कंपनियों P और Q के कुल उत्पादन का वर्ष 2024 में कंपनियों R और S के कुल उत्पादन से अनुपात क्या है?', '{"a":"20 : 27","b":"24 : 31","c":"25 : 33","d":"15 : 22"}'::jsonb, '{"a":"20 : 27","b":"24 : 31","c":"25 : 33","d":"15 : 22"}'::jsonb, 'c', 'From the table:
1. Total production of Company P and Company Q together in 2023:
= Production of P (2023) + Production of Q (2023)
= 55 + 70 = 125 thousand units.

2. Total production of Company R and Company S together in 2024:
= Production of R (2024) + Production of S (2024)
= 75 + 90 = 165 thousand units.

3. Required Ratio:
Ratio = 125 : 165
Dividing both terms by 5:
= 25 : 33.

Correct Option: (c)', 'तालिका से:
1. वर्ष 2023 में कंपनी P और कंपनी Q का कुल उत्पादन:
= 55 + 70 = 125 हजार इकाई।

2. वर्ष 2024 में कंपनी R और कंपनी S का कुल उत्पादन:
= 75 + 90 = 165 हजार इकाई।

3. अभीष्ट अनुपात:
= 125 : 165
दोनों पदों को 5 से विभाजित करने पर:
= 25 : 33।

अतः सही उत्तर (c) है।'),
  ('ssc_cgl_tier1_mock_3', 76, 4, 'PART-4', 'English Comprehension', 'Spotting the Error (Subject-Verb Agreement)', 'Easy', 'The following sentence has been split into four segments. Identify the segment that contains a grammatical error:

Not only the principal (A) / but also the teachers (B) / was enthusiastically participating (C) / in the annual sports day. (D)', 'निम्नलिखित वाक्य को चार खंडों में विभाजित किया गया है। उस खंड की पहचान करें जिसमें व्याकरणिक त्रुटि है:

Not only the principal (A) / but also the teachers (B) / was enthusiastically participating (C) / in the annual sports day. (D)', '{"a":"but also the teachers","b":"Not only the principal","c":"in the annual sports day","d":"was enthusiastically participating"}'::jsonb, '{"a":"but also the teachers","b":"Not only the principal","c":"in the annual sports day","d":"was enthusiastically participating"}'::jsonb, 'd', 'Grammar Rule - Correlative Conjunctions and Rule of Proximity:
1. When two subjects are joined by correlative conjunctions like ''not only... but also'', ''either... or'', or ''neither... nor'', the verb must agree in number and person with the NEARER subject (the subject closest to the verb).
2. Here, the nearer subject is ''the teachers'', which is plural.
3. Therefore, the singular auxiliary verb ''was'' must be replaced by the plural auxiliary verb ''were''.
4. Correct sentence: ''Not only the principal but also the teachers were enthusiastically participating in the annual sports day.''

Hence, segment (C) corresponding to option (d) contains the error. Correct Option: (d)', 'व्याकरण नियम - सहसंबंधित समुच्चयबोधक (Correlative Conjunctions) तथा समीपता का नियम:
1. जब दो कर्ता ''not only... but also'', ''either... or'', या ''neither... nor'' से जुड़े होते हैं, तो क्रिया सदैव अपने सबसे निकटतम कर्ता (nearer subject) के अनुसार प्रयुक्त होती है।
2. यहाँ क्रिया के सबसे निकटतम कर्ता ''the teachers'' (बहुवचन) है।
3. अतः एकवचन सहायक क्रिया ''was'' के स्थान पर बहुवचन क्रिया ''were'' का प्रयोग होना चाहिए।
4. शुद्ध वाक्य: ''Not only the principal but also the teachers were enthusiastically participating...''

अतः सही उत्तर (d) है।'),
  ('ssc_cgl_tier1_mock_3', 77, 4, 'PART-4', 'English Comprehension', 'Spotting the Error (Conditional Sentences)', 'Moderate', 'The following sentence has been split into four segments. Identify the segment that contains a grammatical error:

Had the railway authorities (A) / took prompt safety measures (B) / the catastrophic collision (C) / would certainly have been averted. (D)', 'निम्नलिखित वाक्य को चार खंडों में विभाजित किया गया है। उस खंड की पहचान करें जिसमें व्याकरणिक त्रुटि है:

Had the railway authorities (A) / took prompt safety measures (B) / the catastrophic collision (C) / would certainly have been averted. (D)', '{"a":"the catastrophic collision","b":"took prompt safety measures","c":"Had the railway authorities","d":"would certainly have been averted"}'::jsonb, '{"a":"the catastrophic collision","b":"took prompt safety measures","c":"Had the railway authorities","d":"would certainly have been averted"}'::jsonb, 'b', 'Grammar Rule - Third Conditional with Inversion:
1. Inverted third conditional sentences follow the structure: ''Had + Subject + Past Participle (V3)..., Subject + would have + V3...''.
2. The auxiliary verb ''Had'' must be followed by the third form of the verb (V3). The past participle of ''take'' is ''taken'', not the simple past ''took'' (V2).
3. Correct phrasing: ''Had the railway authorities taken prompt safety measures...''

Therefore, segment (B) corresponding to option (b) contains the grammatical error. Correct Option: (b)', 'व्याकरण नियम - तृतीय शर्त वाक्य और व्युत्क्रमण (Third Conditional with Inversion):
1. तृतीय शर्त वाले वाक्यों में जब ''If'' को हटाकर व्युत्क्रमण (Inversion) किया जाता है, तो संरचना ''Had + Subject + V3 (भूतकालिक कृदंत)..., Subject + would have + V3...'' होती है।
2. ''Had'' के साथ क्रिया का तीसरा रूप (V3) ''taken'' आना चाहिए, न कि दूसरा रूप (V2) ''took''।
3. शुद्ध रूप: ''Had the railway authorities taken prompt safety measures...''

अतः सही उत्तर (b) है।'),
  ('ssc_cgl_tier1_mock_3', 78, 4, 'PART-4', 'English Comprehension', 'Sentence Improvement (Correlative Conjunctions)', 'Easy', 'Select the most appropriate option to substitute the underlined segment in the given sentence. If no substitution is required, select ''No substitution required'':

Scarcely had the flight <u>taken off than one of the engines</u> developed a critical technical snag.', 'दिए गए वाक्य में रेखांकित खंड को प्रतिस्थापित करने के लिए सबसे उपयुक्त विकल्प का चयन करें:

Scarcely had the flight <u>taken off than one of the engines</u> developed a critical technical snag.', '{"a":"took off when one of the engines","b":"taken off than one of the engine","c":"No substitution required","d":"taken off when one of the engines"}'::jsonb, '{"a":"took off when one of the engines","b":"taken off than one of the engine","c":"No substitution required (किसी प्रतिस्थापन की आवश्यकता नहीं है)","d":"taken off when one of the engines"}'::jsonb, 'd', 'Grammar Rule - Conjunction Pairs (Hardly/Scarcely... When):
1. ''Scarcely'' and ''Hardly'' are always followed by the correlative conjunction ''when'' (or ''before''), NEVER by ''than'' (which is paired with ''No sooner'').
2. Furthermore, after auxiliary ''had'', the past participle ''taken'' (V3) is required.
3. The phrase ''one of the'' must be followed by a plural noun (''engines'').
4. Therefore, the correct replacement is: ''taken off when one of the engines''.

Correct Option: (d)', 'व्याकरण नियम - समुच्चयबोधक युग्म (Hardly/Scarcely... When):
1. ''Scarcely'' और ''Hardly'' के साथ सदैव ''when'' या ''before'' का युग्म बनता है, ''than'' का नहीं (''than'' का प्रयोग ''No sooner'' के साथ होता है)।
2. ''Had'' के साथ मुख्य क्रिया की तीसरी अवस्था ''taken'' (V3) आती है और ''one of the'' के बाद बहुवचन संज्ञा (''engines'') आती है।
3. अतः शुद्ध खंड ''taken off when one of the engines'' होगा।

अतः सही उत्तर (d) है।'),
  ('ssc_cgl_tier1_mock_3', 79, 4, 'PART-4', 'English Comprehension', 'Sentence Improvement (Parallel Structure)', 'Moderate', 'Select the option that will improve the underlined segment of the given sentence. If no improvement is needed, select ''No improvement'':

The research scholar spent the entire semester collecting archival data, analyzing statistical trends, and <u>to draft comprehensive reports</u>.', 'दिए गए वाक्य में रेखांकित खंड में सुधार करने वाले सबसे उपयुक्त विकल्प का चयन करें:

The research scholar spent the entire semester collecting archival data, analyzing statistical trends, and <u>to draft comprehensive reports</u>.', '{"a":"drafting comprehensive reports","b":"drafted comprehensive reports","c":"for drafting comprehensive reports","d":"No improvement"}'::jsonb, '{"a":"drafting comprehensive reports","b":"drafted comprehensive reports","c":"for drafting comprehensive reports","d":"No improvement (किसी सुधार की आवश्यकता नहीं है)"}'::jsonb, 'a', 'Grammar Rule - Parallelism / Parallel Structure:
1. Items in a series linked by coordinating conjunctions (like ''and'') must share the same grammatical form.
2. The series begins with two gerund phrases: ''collecting archival data'' and ''analyzing statistical trends''.
3. To maintain parallel structure, the third element must also be a gerund (''drafting comprehensive reports'') rather than an infinitive (''to draft'').

Hence, option (a) provides the correct parallel form. Correct Option: (a)', 'व्याकरण नियम - समानांतरता (Parallelism):
1. जब दो या दो से अधिक क्रियाएं या पदबंध किसी संयोजक (जैसे ''and'') से जुड़े हों, तो उनका व्याकरणिक रूप समान होना चाहिए।
2. वाक्य में पहले दो पदबंध ''collecting...'' और ''analyzing...'' (gerunds - क्रियावाचक संज्ञा) के रूप में हैं।
3. अतः समानांतर संरचना बनाए रखने के लिए तीसरा पदबंध भी gerund ''drafting comprehensive reports'' होना चाहिए, न कि infinitive (''to draft'')।

अतः सही उत्तर (a) है।'),
  ('ssc_cgl_tier1_mock_3', 80, 4, 'PART-4', 'English Comprehension', 'Fill in the Blanks (Prepositional Phrases)', 'Easy', 'Select the most appropriate preposition to fill in the blank:

The new environmental regulations introduced by the ministry are strictly congruent _______ the United Nations climate directives.', 'रिक्त स्थान की पूर्ति के लिए सबसे उपयुक्त पूर्वसर्ग (preposition) का चयन करें:

The new environmental regulations introduced by the ministry are strictly congruent _______ the United Nations climate directives.', '{"a":"for","b":"to","c":"against","d":"with"}'::jsonb, '{"a":"for (के लिए)","b":"to (की ओर)","c":"against (के विरुद्ध)","d":"with (के अनुरूप / के साथ)"}'::jsonb, 'd', 'Prepositional Usage:
1. The adjective ''congruent'' means in agreement, harmonious, or corresponding with something.
2. In English usage, ''congruent'' is appropriately paired with the preposition ''with'' when denoting harmony or accordance (e.g., ''actions congruent with one''s beliefs'').
3. Note: While ''congruent to'' is occasionally seen in specific geometric contexts (congruent triangles), in standard administrative, ethical, and general English context, ''congruent with'' is the established standard idiom.

Hence, option (d) ''with'' is the correct answer. Correct Option: (d)', 'पूर्वसर्ग (Preposition) का नियम:
1. ''Congruent'' का अर्थ ''अनुरूप'', ''संगत'' या ''सामंजस्यपूर्ण'' होता है।
2. सामान्य तथा प्रशासनिक संदर्भ में ''congruent'' के साथ निश्चित पूर्वसर्ग ''with'' का प्रयोग किया जाता है (congruent with rules/standards)।

अतः सही उत्तर (d) है।'),
  ('ssc_cgl_tier1_mock_3', 81, 4, 'PART-4', 'English Comprehension', 'Fill in the Blanks (Phrasal Verbs)', 'Moderate', 'Select the most appropriate phrasal verb to fill in the blank:

After several rounds of protracted negotiations, the diplomats finally managed to _______ a comprehensive ceasefire agreement.', 'रिक्त स्थान की पूर्ति के लिए सबसे उपयुक्त phrasal verb का चयन करें:

After several rounds of protracted negotiations, the diplomats finally managed to _______ a comprehensive ceasefire agreement.', '{"a":"fall out","b":"phase out","c":"hammer out","d":"back out"}'::jsonb, '{"a":"fall out (झगड़ा करना / अलग होना)","b":"phase out (क्रमशः समाप्त करना)","c":"hammer out (कठिन वार्ता के बाद सहमति बनाना / तैयार करना)","d":"back out (मुकर जाना / पीछे हटना)"}'::jsonb, 'c', 'Phrasal Verb Meanings and Context:
1. ''Hammer out'': To reach an agreement or solution after extensive discussion or difficult negotiations.
2. ''Fall out'': To quarrel or disagree with someone.
3. ''Back out'': To withdraw from a commitment or promise.
4. ''Phase out'': To gradually stop using or providing something over time.

In the context of diplomats concluding lengthy negotiations on a ceasefire, ''hammer out'' fits precisely.

Correct Option: (c)', 'Phrasal Verb का अर्थ और संदर्भ:
1. ''Hammer out'': लंबी व गहन बातचीत के बाद किसी समझौते पर पहुँचना।
2. ''Fall out'': झगड़ा होना या मतभेद होना।
3. ''Back out'': अपने वादे या समझौते से पीछे हटना।
4. ''Phase out'': किसी चीज़ को धीरे-धीरे बंद करना।

वाक्य के संदर्भ में राजनयिकों द्वारा युद्धविराम समझौते को अंतिम रूप देने हेतु ''hammer out'' सर्वाधिक उपयुक्त है।

अतः सही उत्तर (c) है।'),
  ('ssc_cgl_tier1_mock_3', 82, 4, 'PART-4', 'English Comprehension', 'Active and Passive Voice', 'Moderate', 'Select the option that expresses the given sentence in passive voice:

The Archaeological Survey of India has recently excavated three rare terracotta figurines from the historical mound.', 'दिए गए वाक्य को कर्मवाच्य (passive voice) में व्यक्त करने वाले सही विकल्प का चयन करें:

The Archaeological Survey of India has recently excavated three rare terracotta figurines from the historical mound.', '{"a":"Three rare terracotta figurines were recently excavated from the historical mound by the Archaeological Survey of India.","b":"Three rare terracotta figurines has recently been excavated from the historical mound by the Archaeological Survey of India.","c":"Three rare terracotta figurines have recently been excavated from the historical mound by the Archaeological Survey of India.","d":"Three rare terracotta figurines had recently been excavated from the historical mound by the Archaeological Survey of India."}'::jsonb, '{"a":"Three rare terracotta figurines were recently excavated from the historical mound by the Archaeological Survey of India.","b":"Three rare terracotta figurines has recently been excavated from the historical mound by the Archaeological Survey of India.","c":"Three rare terracotta figurines have recently been excavated from the historical mound by the Archaeological Survey of India.","d":"Three rare terracotta figurines had recently been excavated from the historical mound by the Archaeological Survey of India."}'::jsonb, 'c', 'Voice Conversion Rules - Present Perfect Tense:
1. Active Voice Structure: Subject + has/have + V3 + Object
2. Passive Voice Structure: Object + has/have + been + V3 + by + Subject
3. Here, the object is ''Three rare terracotta figurines'' (plural noun), which takes the plural auxiliary ''have''.
4. Hence: ''Three rare terracotta figurines have recently been excavated from the historical mound by the Archaeological Survey of India.''
5. Option (b) changes tense to Simple Past (''were''), option (c) uses Past Perfect (''had''), and option (d) uses incorrect singular verb ''has'' for a plural subject.

Correct Option: (c)', 'वाच्य परिवर्तन (Voice Conversion) - Present Perfect Tense:
1. Active Voice: Subject + has/have + V3 + Object
2. Passive Voice: Object + has/have + been + V3 + by + Subject
3. यहाँ कर्म (Object) ''Three rare terracotta figurines'' बहुवचन है, अतः इसके साथ ''have been excavated'' आएगा।
4. विकल्प (b) में Simple Past (''were'') है, (c) में Past Perfect (''had been'') है, और (d) में बहुवचन के साथ गलत रूप ''has'' लगाया गया है।

अतः सही उत्तर (c) है।'),
  ('ssc_cgl_tier1_mock_3', 83, 4, 'PART-4', 'English Comprehension', 'Direct and Indirect Speech', 'Moderate', 'Select the correct indirect form of the given sentence:

The detective said to the witness, "Did you observe any suspicious movement before the alarm was sounded?"', 'दिए गए वाक्य का सही अप्रत्यक्ष कथन (indirect form) चुनें:

The detective said to the witness, "Did you observe any suspicious movement before the alarm was sounded?"', '{"a":"The detective asked to the witness whether he has observed any suspicious movement before the alarm was sounded.","b":"The detective inquired of the witness whether he had observed any suspicious movement before the alarm was sounded.","c":"The detective asked the witness if he observed any suspicious movement before the alarm was sounded.","d":"The detective told the witness whether he had observed any suspicious movement before the alarm is sounded."}'::jsonb, '{"a":"The detective asked to the witness whether he has observed any suspicious movement before the alarm was sounded.","b":"The detective inquired of the witness whether he had observed any suspicious movement before the alarm was sounded.","c":"The detective asked the witness if he observed any suspicious movement before the alarm was sounded.","d":"The detective told the witness whether he had observed any suspicious movement before the alarm is sounded."}'::jsonb, 'b', 'Narration Rules - Interrogative Sentences (Simple Past to Past Perfect):
1. Reporting verb ''said to'' changes to ''asked'' or ''inquired of''.
2. Conjunction ''if'' or ''whether'' is used for yes/no questions.
3. Simple Past tense (''Did you observe'') changes into Past Perfect tense (''had observed'').
4. The interrogative structure is converted into an assertive sentence (subject before auxiliary verb).
5. Option (b) accurately executes all these transformations: ''The detective inquired of the witness whether he had observed any suspicious movement before the alarm was sounded.''

Correct Option: (b)', 'प्रत्यक्ष से अप्रत्यक्ष कथन (Narration) के नियम:
1. प्रश्नवाचक वाक्य (Interrogative) में रिपोर्टिंग वर्ब ''said to'' बदलकर ''inquired of'' या ''asked'' हो जाती है।
2. ''Yes/No'' प्रकार के प्रश्नों में संयोजक ''if'' या ''whether'' का प्रयोग होता है।
3. Simple Past Tense (''Did you observe'') बदलकर Past Perfect Tense (''had observed'') में परिवर्तित होता है।
4. वाक्य प्रश्नवाचक से साधारण (assertive) बन जाता है।

अतः सही उत्तर (b) है।'),
  ('ssc_cgl_tier1_mock_3', 84, 4, 'PART-4', 'English Comprehension', 'Synonyms', 'Easy', 'Select the most appropriate SYNONYM of the given word:

EPHEMERAL', 'दिए गए शब्द का सबसे उपयुक्त समानार्थी (SYNONYM) चुनें:

EPHEMERAL', '{"a":"Transient","b":"Perpetual","c":"Monolithic","d":"Enduring"}'::jsonb, '{"a":"Transient (क्षणभंगुर / अल्पकालिक)","b":"Perpetual (सदा रहने वाला)","c":"Monolithic (विशालकाय / अखंड)","d":"Enduring (चिरस्थायी)"}'::jsonb, 'a', 'Word Meaning and Synonyms:
1. ''EPHEMERAL'' (adjective): Lasting for a very short time; fleeting, transitory.
2. ''Transient'' (adjective): Lasting only for a short time; impermanent. This is an exact synonym.
3. ''Enduring'' and ''Perpetual'' are direct antonyms meaning long-lasting or permanent.
4. ''Monolithic'' means massive, solid, and uniform.

Therefore, ''Transient'' is the closest synonym. Correct Option: (a)', 'शब्दार्थ एवं पर्यायवाची:
1. ''EPHEMERAL'': अल्पकालिक, क्षणभंगुर (जो बहुत कम समय तक रहे)।
2. ''Transient'': क्षणिक, अल्पकालिक। यह इसका सटीक पर्यायवाची है।
3. ''Enduring'' और ''Perpetual'' इसके विलोम शब्द हैं जिनका अर्थ स्थायी या निरंतर होता है।
4. ''Monolithic'' का अर्थ विशाल और अखंड होता है।

अतः सही उत्तर (a) है।'),
  ('ssc_cgl_tier1_mock_3', 85, 4, 'PART-4', 'English Comprehension', 'Synonyms', 'Hard', 'Select the most appropriate SYNONYM of the highlighted word in the sentence:

The prime minister consulted several <b>sagacious</b> advisors before implementing the monetary policy reforms.', 'वाक्य में रेखांकित/बोल्ड शब्द का सबसे उपयुक्त समानार्थी (SYNONYM) चुनें:

The prime minister consulted several <b>sagacious</b> advisors before implementing the monetary policy reforms.', '{"a":"Fallacious","b":"Credulous","c":"Discerning","d":"Impetuous"}'::jsonb, '{"a":"Fallacious (भ्रामक / तर्कहीन)","b":"Credulous (भोला-भाला / सहज विश्वासी)","c":"Discerning (बुद्धिमान / विवेकी / दूरदर्शी)","d":"Impetuous (अविवेकपूर्ण / उतावला)"}'::jsonb, 'c', 'Word Meaning and Synonyms:
1. ''SAGACIOUS'' (adjective): Having or showing keen mental discernment, good judgment, and practical wisdom; wise, astute, judicious.
2. ''Discerning'' (adjective): Having or showing good judgment; astute, perceptive. This is the closest synonym.
3. ''Credulous'': Too ready to believe things; gullible.
4. ''Impetuous'': Acting or done quickly and without thought or care; rash.
5. ''Fallacious'': Based on a mistaken belief or unsound reasoning.

Correct Option: (c)', 'शब्दार्थ एवं विश्लेषण:
1. ''SAGACIOUS'': बुद्धिमान, दूरदर्शी, विवेकी (जिसमें अच्छी निर्णय क्षमता हो)।
2. ''Discerning'': सूक्ष्मदर्शी, विवेकी, गुणदोष-परखने वाला। यह ''sagacious'' का सटीक समानार्थी है।
3. ''Credulous'' का अर्थ भोला-भाला (जो आसानी से विश्वास कर ले), ''Impetuous'' का अर्थ उतावला/जल्दबाज, और ''Fallacious'' का अर्थ भ्रामक होता है।

अतः सही उत्तर (c) है।'),
  ('ssc_cgl_tier1_mock_3', 86, 4, 'PART-4', 'English Comprehension', 'Antonyms', 'Easy', 'Select the most appropriate ANTONYM of the given word:

METICULOUS', 'दिए गए शब्द का सबसे उपयुक्त विलोम शब्द (ANTONYM) चुनें:

METICULOUS', '{"a":"Diligent","b":"Careless","c":"Scrupulous","d":"Punctilious"}'::jsonb, '{"a":"Diligent (परिश्रमी / कर्मठ)","b":"Careless (लापरवाह / असावधान)","c":"Scrupulous (कर्तव्यनिष्ठ / सूक्ष्म)","d":"Punctilious (अति-सावधान / शिष्टाचार-प्रिय)"}'::jsonb, 'b', 'Word Meaning and Antonyms:
1. ''METICULOUS'' (adjective): Showing great attention to detail; very careful and precise.
2. ''Careless'' (adjective): Not giving sufficient attention or thought to avoiding harm or errors; negligent. This is the exact antonym.
3. ''Diligent'', ''Scrupulous'', and ''Punctilious'' are synonyms of meticulous.

Correct Option: (b)', 'शब्दार्थ एवं विलोम:
1. ''METICULOUS'': अति-सावधान, बारीकियों पर ध्यान देने वाला, सतर्क।
2. ''Careless'': लापरवाह, असावधान। यह ''meticulous'' का सीधा विलोम शब्द है।
3. ''Diligent'', ''Scrupulous'' और ''Punctilious'' इसके समानार्थी (synonyms) हैं।

अतः सही उत्तर (b) है।'),
  ('ssc_cgl_tier1_mock_3', 87, 4, 'PART-4', 'English Comprehension', 'Antonyms', 'Hard', 'Select the most appropriate ANTONYM of the underlined word in the sentence:

The provocative statements made by the union leader served only to <u>exacerbate</u> the existing tensions.', 'वाक्य में रेखांकित शब्द का सबसे उपयुक्त विलोम शब्द (ANTONYM) चुनें:

The provocative statements made by the union leader served only to <u>exacerbate</u> the existing tensions.', '{"a":"Intensify","b":"Perpetuate","c":"Alleviate","d":"Aggravate"}'::jsonb, '{"a":"Intensify (तीव्र करना)","b":"Perpetuate (स्थिर रखना / जारी रखना)","c":"Alleviate (कम करना / शांत करना / राहत देना)","d":"Aggravate (और गंभीर या बदतर बनाना)"}'::jsonb, 'c', 'Word Meaning and Antonyms:
1. ''EXACERBATE'' (verb): To make a problem, bad situation, or negative feeling worse or more severe; aggravate, worsen.
2. ''Alleviate'' (verb): To make suffering, deficiency, or a problem less severe; relieve, mitigate. This is the exact antonym.
3. ''Aggravate'' and ''Intensify'' are synonyms of exacerbate.
4. ''Perpetuate'' means to make something continue indefinitely.

Correct Option: (c)', 'शब्दार्थ एवं विलोम:
1. ''EXACERBATE'': किसी बुरी स्थिति, समस्या या तनाव को और अधिक बिगाड़ना या बदतर बनाना।
2. ''Alleviate'': कम करना, शांत करना, पीड़ा या तनाव में राहत देना। यह ''exacerbate'' का सटीक विलोम शब्द है।
3. ''Aggravate'' और ''Intensify'' इसके समानार्थी हैं।

अतः सही उत्तर (c) है।'),
  ('ssc_cgl_tier1_mock_3', 88, 4, 'PART-4', 'English Comprehension', 'One Word Substitution', 'Easy', 'Select the option that can be used as a one-word substitute for the given group of words:

A person who remains calm, unaffected, and indifferent to pain, pleasure, grief, or joy', 'दिए गए वाक्यांश के लिए एक शब्द (One Word Substitute) का चयन करें:

A person who remains calm, unaffected, and indifferent to pain, pleasure, grief, or joy (सुख-दुःख में समान रहने वाला व्यक्ति)', '{"a":"Hedonist","b":"Epicurean","c":"Stoic","d":"Cynic"}'::jsonb, '{"a":"Hedonist (सुखवादी)","b":"Epicurean (स्वादलोलुप / भोग-विलासी)","c":"Stoic (वैरागी / सुख-दुःख में समभाव रखने वाला)","d":"Cynic (दोषदर्शी / निंदक)"}'::jsonb, 'c', 'One Word Substitution Analysis:
1. ''Stoic'': A person who can endure pain or hardship without showing their feelings or complaining, indifferent to pleasure and pain.
2. ''Epicurean'': A person devoted to sensual enjoyment, especially that derived from fine food and drink.
3. ''Cynic'': A person who believes that people are motivated purely by self-interest rather than acting for honorable reasons.
4. ''Hedonist'': A person who believes that the pursuit of pleasure is the most important thing in life.

Correct Option: (c)', 'वाक्यांश के लिए एक शब्द विश्लेषण:
1. ''Stoic'': वह व्यक्ति जो सुख, दुःख, हर्ष या विषाद से अप्रभावित रहता है (स्थितप्रज्ञ/तटस्थ)।
2. ''Epicurean'': उत्तम खान-पान और विलासिता का प्रेमी।
3. ''Cynic'': मानव व्यवहार में केवल स्वार्थ देखने वाला (दोषदर्शी)।
4. ''Hedonist'': जीवन में केवल शारीरिक व इंद्रिय सुख को सर्वोपरि मानने वाला (सुखवादी)।

अतः सही उत्तर (c) है।'),
  ('ssc_cgl_tier1_mock_3', 89, 4, 'PART-4', 'English Comprehension', 'One Word Substitution', 'Moderate', 'Select the option that can be used as a one-word substitute for the given group of words:

A person who has an obsessive, abnormal, and unwarranted anxiety about having a serious illness', 'दिए गए वाक्यांश के लिए एक शब्द (One Word Substitute) का चयन करें:

A person who has an obsessive, abnormal, and unwarranted anxiety about having a serious illness (काल्पनिक बीमारी से ग्रस्त रहने वाला व्यक्ति)', '{"a":"Kleptomaniac","b":"Valetudinarian","c":"Convalescent","d":"Hypochondriac"}'::jsonb, '{"a":"Kleptomaniac (चोरी करने की अदम्य बीमारी से ग्रस्त व्यक्ति)","b":"Valetudinarian (दुर्बल व बीमारू व्यक्ति)","c":"Convalescent (रोगमुक्त हो रहा व्यक्ति / स्वास्थ्य-लाभ करने वाला)","d":"Hypochondriac (रोगभ्रमी / अपनी सेहत को लेकर निरंतर चिंतित रहने वाला)"}'::jsonb, 'd', 'One Word Substitution Analysis:
1. ''Hypochondriac'': A person who is abnormally anxious about their health, constantly imagining that they are ill.
2. ''Convalescent'': A person who is recovering from an illness or medical treatment.
3. ''Valetudinarian'': A person who is unduly anxious about their health, but primarily one who is chronically in poor health or living an invalid life.
4. ''Kleptomaniac'': A person suffering from an irresistible urge to steal items.

In standard examinations, ''Hypochondriac'' is the precise term for unwarranted anxiety about illnesses.

Correct Option: (d)', 'वाक्यांश के लिए एक शब्द:
1. ''Hypochondriac'': वह व्यक्ति जो यह वहम पाले रहता है कि वह किसी गंभीर बीमारी से पीड़ित है (रोगभ्रमी)।
2. ''Convalescent'': बीमारी के बाद स्वास्थ्य लाभ कर रहा व्यक्ति।
3. ''Kleptomaniac'': चोरी करने की मानसिक बीमारी से पीड़ित।

अतः सही उत्तर (d) है।'),
  ('ssc_cgl_tier1_mock_3', 90, 4, 'PART-4', 'English Comprehension', 'Idioms and Phrases', 'Easy', 'Select the most appropriate meaning of the given idiom:

To bite the bullet', 'दिए गए मुहावरे का सबसे उपयुक्त अर्थ चुनें:

To bite the bullet', '{"a":"To face a grim and unavoidable situation with courage and fortitude","b":"To express severe anger in an explosive manner","c":"To waste ammunition during a military operation","d":"To act recklessly without considering the consequences"}'::jsonb, '{"a":"To face a grim and unavoidable situation with courage and fortitude (किसी कठिन व अप्रिय परिस्थिति का साहसपूर्वक सामना करना)","b":"To express severe anger in an explosive manner (क्रोध व्यक्त करना)","c":"To waste ammunition during a military operation (गोला-बारूद बर्बाद करना)","d":"To act recklessly without considering the consequences (परिणामों की चिंता किए बिना लापरवाही से कार्य करना)"}'::jsonb, 'a', 'Idiom Explanation:
1. ''To bite the bullet'' originates from historical battlefield surgery before anesthesia, when wounded soldiers were given a lead bullet to clench in their teeth to endure the agonizing pain.
2. Meaning: To force oneself to do something difficult, unpleasant, or painful; to accept inevitable hardship with fortitude.

Hence, option (a) provides the precise meaning. Correct Option: (a)', 'मुहावरे का अर्थ एवं उत्पत्ति:
1. ''To bite the bullet'': किसी कठिन, अप्रिय लेकिन अनिवार्य परिस्थिति को साहस और धैर्य के साथ स्वीकार करना (कड़वा घूंट पीना / सीना तानकर कष्ट झेलना)।
2. यह मुहावरा पुराने समय में युद्ध क्षेत्र में बिना एनेस्थीसिया के ऑपरेशन के दौरान सैनिकों को दांतों तले गोली दबाने दिए जाने से उत्पन्न हुआ है।

अतः सही उत्तर (a) है।'),
  ('ssc_cgl_tier1_mock_3', 91, 4, 'PART-4', 'English Comprehension', 'Idioms and Phrases', 'Hard', 'Select the most appropriate meaning of the underlined idiom in the sentence:

Whether capital punishment acts as an effective deterrent against violent crimes remains <u>a moot point</u> among legal luminaries.', 'वाक्य में रेखांकित मुहावरे का सबसे उपयुक्त अर्थ चुनें:

Whether capital punishment acts as an effective deterrent against violent crimes remains <u>a moot point</u> among legal luminaries.', '{"a":"An issue that is open to argument, unresolved, or debatable","b":"A clandestine agreement signed in secrecy","c":"A settled matter that requires no further deliberation","d":"A trivial issue that has been completely dismissed"}'::jsonb, '{"a":"An issue that is open to argument, unresolved, or debatable (विवादस्पद या अनसुलझा मुद्दा जिस पर बहस जारी हो)","b":"A clandestine agreement signed in secrecy (गुप्त समझौता)","c":"A settled matter that requires no further deliberation (सुलझा हुआ मामला)","d":"A trivial issue that has been completely dismissed (तुच्छ विषय जिसे खारिज कर दिया गया हो)"}'::jsonb, 'a', 'Idiom Explanation:
1. ''A moot point'': A subject or issue that is open to debate, uncertain, or undecided; also an issue that has no practical significance because the outcome cannot be decided.
2. In formal legal and academic contexts, it specifically denotes a question that remains contentious and open to intellectual argument without universal consensus.

Correct Option: (a)', 'मुहावरे का अर्थ:
1. ''A moot point'': ऐसा विषय या मुद्दा जो अनिर्णीत हो और जिस पर विवाद या बहस की पूरी गुंजाइश हो (विवादास्पद या विचारणीय प्रश्न)।
2. अतः विकल्प (a) ''An issue that is open to argument, unresolved, or debatable'' इसका सही अर्थ है।

अतः सही उत्तर (a) है।'),
  ('ssc_cgl_tier1_mock_3', 92, 4, 'PART-4', 'English Comprehension', 'Spelling Test (Incorrectly Spelt Word)', 'Easy', 'Select the INCORRECTLY spelt word from the following options:', 'निम्नलिखित विकल्पों में से अशुद्ध वर्तनी (INCORRECTLY spelt word) वाले शब्द का चयन करें:', '{"a":"Millennium","b":"Bureaucracy","c":"Accomodation","d":"Surveillance"}'::jsonb, '{"a":"Millennium (शुद्ध वर्तनी - सहस्राब्दी)","b":"Bureaucracy (शुद्ध वर्तनी - नौकरशाही)","c":"Accomodation (अशुद्ध वर्तनी - सही: Accommodation)","d":"Surveillance (शुद्ध वर्तनी - निगरानी)"}'::jsonb, 'c', 'Spelling Correction:
1. ''Accomodation'' is INCORRECTLY spelt. It must have double ''c'' and double ''m''.
   - Correct spelling: ''Accommodation''.
2. ''Surveillance'', ''Millennium'', and ''Bureaucracy'' are all correctly spelt.

Correct Option: (c)', 'वर्तनी विश्लेषण:
1. ''Accomodation'' की वर्तनी अशुद्ध है। इसमें ''c'' और ''m'' दोनों दोहरे (double) होते हैं।
   - सही वर्तनी: ''Accommodation'' (आवास/सुविधा)।
2. अन्य सभी शब्द (''Surveillance'', ''Millennium'', ''Bureaucracy'') सही लिखे गए हैं।

अतः सही उत्तर (c) है।'),
  ('ssc_cgl_tier1_mock_3', 93, 4, 'PART-4', 'English Comprehension', 'Spelling Test (Correctly Spelt Word)', 'Moderate', 'Select the CORRECTLY spelt word from the given options:', 'दिए गए विकल्पों में से शुद्ध वर्तनी (CORRECTLY spelt word) वाले शब्द का चयन करें:', '{"a":"Conscensious","b":"Consciencious","c":"Conscientious","d":"Concientious"}'::jsonb, '{"a":"Conscensious (अशुद्ध वर्तनी)","b":"Consciencious (अशुद्ध वर्तनी)","c":"Conscientious (शुद्ध वर्तनी - कर्तव्यनिष्ठ / ईमानदार)","d":"Concientious (अशुद्ध वर्तनी)"}'::jsonb, 'c', 'Spelling Analysis:
1. ''Conscientious'' (adjective): Wishing to do one''s work or duty well and thoroughly; diligent, scrupulous.
2. Correct spelling: C - O - N - S - C - I - E - N - T - I - O - U - S.
3. The other options are erroneous permutations.

Correct Option: (c)', 'वर्तनी विश्लेषण:
1. ''Conscientious'' (कर्तव्यनिष्ठ/सत्यनिष्ठ) की सही वर्तनी ''C-O-N-S-C-I-E-N-T-I-O-U-S'' है।
2. अन्य तीनों विकल्प वर्तनी की दृष्टि से अशुद्ध हैं।

अतः सही उत्तर (c) है।'),
  ('ssc_cgl_tier1_mock_3', 94, 4, 'PART-4', 'English Comprehension', 'Para Jumbles (Sentence Rearrangement)', 'Moderate', 'Sentences of a paragraph are given below in jumbled order. Arrange the sentences in the correct order to form a meaningful and coherent paragraph:

P. Over the last decade, solar power has witnessed exponential technological efficiency gains.
Q. Consequently, clean renewable energy is transitioning from a subsidized alternative to a commercially competitive powerhouse.
R. The global push for decarbonization has intensified efforts to harness renewable energy sources.
S. Concurrently, manufacturing economies of scale have driven down photovoltaic panel costs by more than eighty percent.', 'दिए गए वाक्यों को एक अर्थपूर्ण और सुसंगत अनुच्छेद बनाने के लिए सही क्रम में व्यवस्थित करें:

P. Over the last decade, solar power has witnessed exponential technological efficiency gains.
Q. Consequently, clean renewable energy is transitioning from a subsidized alternative to a commercially competitive powerhouse.
R. The global push for decarbonization has intensified efforts to harness renewable energy sources.
S. Concurrently, manufacturing economies of scale have driven down photovoltaic panel costs by more than eighty percent.', '{"a":"S-P-R-Q","b":"R-Q-P-S","c":"P-S-Q-R","d":"R-P-S-Q"}'::jsonb, '{"a":"S-P-R-Q","b":"R-Q-P-S","c":"P-S-Q-R","d":"R-P-S-Q"}'::jsonb, 'd', 'Para Jumble Logical Sequence Analysis:
1. Sentence R introduces the broad thematic premise: the global imperative for decarbonization driving renewable energy efforts. Thus, R is the natural opening sentence.
2. Sentence P narrows down to the primary renewable sector (solar power) and its technological efficiency gains.
3. Sentence S begins with the transitional adverb ''Concurrently'' (at the same time), introducing the complementary economic factor: drastic drops in panel manufacturing costs.
4. Sentence Q begins with the causal concluding marker ''Consequently'', summarizing the combined outcome of efficiency (P) and affordability (S): clean energy becoming a commercially viable powerhouse.

Thus, the coherent sequence is R-P-S-Q.

Correct Option: (d)', 'वाक्य पुनर्व्यवस्था (Para Jumble) का तार्किक क्रम:
1. वाक्य R वैश्विक स्तर पर डीकार्बोनाइजेशन और नवीकरणीय ऊर्जा की आवश्यकता का सामान्य परिचय देता है, अतः यह प्रारंभिक वाक्य है।
2. वाक्य P सौर ऊर्जा की दक्षता में आए तकनीकी सुधारों का उल्लेख करता है।
3. वाक्य S ''Concurrently'' (साथ ही साथ) से जुड़कर पैनल उत्पादन की लागत में आई भारी गिरावट को दर्शाता है।
4. वाक्य Q ''Consequently'' (परिणामस्वरूप) से निष्कर्ष प्रस्तुत करता है कि इन दोनों कारणों से स्वच्छ ऊर्जा प्रतिस्पर्धी शक्ति बन गई है।

अतः सही क्रम R-P-S-Q है। अतः सही उत्तर (d) है।'),
  ('ssc_cgl_tier1_mock_3', 95, 4, 'PART-4', 'English Comprehension', 'Para Jumbles (Sentence Rearrangement)', 'Hard', 'Sentences of a paragraph are given below in jumbled order. Arrange the sentences in the correct order to form a meaningful and coherent paragraph:

P. These ancient structures, carved with intricate friezes, narrate epic mythologies and reflect extraordinary sculptural sophistication.
Q. Across the Indian subcontinent, monolithic rock-cut temples represent one of the most remarkable achievements of civilizational craftsmanship.
R. However, escalating environmental weathering and unregulated tourism now pose an unprecedented threat to their architectural integrity.
S. To safeguard these invaluable heritage treasures for posterity, conservationists are deploying advanced non-invasive laser cleaning and restoration technologies.', 'दिए गए वाक्यों को एक अर्थपूर्ण और सुसंगत अनुच्छेद बनाने के लिए सही क्रम में व्यवस्थित करें:

P. These ancient structures, carved with intricate friezes, narrate epic mythologies and reflect extraordinary sculptural sophistication.
Q. Across the Indian subcontinent, monolithic rock-cut temples represent one of the most remarkable achievements of civilizational craftsmanship.
R. However, escalating environmental weathering and unregulated tourism now pose an unprecedented threat to their architectural integrity.
S. To safeguard these invaluable heritage treasures for posterity, conservationists are deploying advanced non-invasive laser cleaning and restoration technologies.', '{"a":"Q-P-R-S","b":"P-Q-R-S","c":"Q-R-P-S","d":"R-Q-P-S"}'::jsonb, '{"a":"Q-P-R-S","b":"P-Q-R-S","c":"Q-R-P-S","d":"R-Q-P-S"}'::jsonb, 'a', 'Para Jumble Logical Progression Analysis:
1. Sentence Q introduces the core subject: monolithic rock-cut temples across the subcontinent as civilizational masterpieces. This is the introductory sentence.
2. Sentence P begins with the demonstrative pronoun phrase ''These ancient structures'', directly referencing the temples mentioned in Q, and describes their intricate carvings.
3. Sentence R introduces the contrasting dilemma with ''However'', highlighting the dual threats of environmental degradation and unchecked tourism.
4. Sentence S offers the corrective solution: conservationists utilizing laser technology to preserve the structures mentioned.

Therefore, the logical progression is Introduction (Q) -> Elaboration (P) -> Problem/Threat (R) -> Resolution (S), giving Q-P-R-S.

Correct Option: (a)', 'तार्किक संरचना:
1. वाक्य Q उपमहाद्वीप के एकाश्म शैलकृत मंदिरों का मुख्य परिचय देता है (प्रारंभिक वाक्य)।
2. वाक्य P ''These ancient structures'' द्वारा सीधे वाक्य Q के मंदिरों की नक्काशी और कलात्मकता का वर्णन करता है।
3. वाक्य R ''However'' के माध्यम से इन स्मारकों पर मौसम और अनियंत्रित पर्यटन से उत्पन्न खतरे को उजागर करता है।
4. वाक्य S संरक्षणवादियों द्वारा लेजर तकनीक के माध्यम से इनके संरक्षण के समाधान का उल्लेख करता है।

अतः सही तार्किक क्रम Q-P-R-S है। अतः सही उत्तर (a) है।'),
  ('ssc_cgl_tier1_mock_3', 96, 4, 'PART-4', 'English Comprehension', 'Cloze Test (Comprehension)', 'Easy', 'Read the passage carefully and select the most appropriate option to fill in blank (1):

Passage:
Sustainable urban mobility has emerged as a cornerstone of modern ecological planning. In contemporary metropolises, the unchecked expansion of private vehicular traffic has led to catastrophic congestion and alarming levels of air pollution. To counteract this escalating crisis, municipal authorities are undertaking concerted measures to (1) _______ public transit infrastructure. Transitioning towards integrated mass transit networks not only reduces carbon emissions, but also diminishes the citizen''s chronic (2) _______ fossil fuels. Nevertheless, civil engineers emphasize that electric mobility alone cannot resolve urban bottlenecks unless supported by (3) _______ last-mile connectivity. Urban planners must simultaneously design dedicated pedestrian corridors and bicycle lanes, thereby (4) _______ commuters to adopt non-motorized alternatives for short distances. Ultimately, building liveable, climate-resilient cities is no longer a utopian aspiration, but an ecological (5) _______ that demands decisive political will.

Select the most appropriate option for blank (1):', 'गद्यांश को ध्यानपूर्वक पढ़ें और रिक्त स्थान (1) के लिए सबसे उपयुक्त विकल्प का चयन करें:

To counteract this escalating crisis, municipal authorities are undertaking concerted measures to (1) _______ public transit infrastructure...

रिक्त स्थान (1) के लिए सही विकल्प चुनें:', '{"a":"disband","b":"overhaul","c":"neglect","d":"deteriorate"}'::jsonb, '{"a":"disband (भंग करना)","b":"overhaul (कायाकल्प करना / पुनर्गठन एवं सुधार करना)","c":"neglect (उपेक्षा करना)","d":"deteriorate (बदतर करना)"}'::jsonb, 'b', 'Cloze Test Analysis for Blank (1):
1. Context: Municipal authorities are taking active measures to address the crisis of congestion and pollution.
2. The infinitive verb needed after ''measures to'' must express positive modernization, improvement, or renovation of public transit infrastructure.
3. ''Overhaul'' means to thoroughly examine, repair, renovate, and modernize a system or structure.
4. Negative verbs such as ''deteriorate'' (worsen), ''neglect'' (ignore), and ''disband'' (dissolve) completely contradict the positive intent of taking ''concerted measures to counteract the crisis''.

Correct Option: (b)', 'रिक्त स्थान (1) का संदर्भ एवं विश्लेषण:
1. वाक्य में संकट से निपटने के लिए नगरपालिका अधिकारियों द्वारा सार्वजनिक परिवहन ढांचे के सुधार के लिए किए जा रहे सकारात्मक प्रयासों का वर्णन है।
2. ''Overhaul'' का अर्थ पूरी तरह से मरम्मत करना, आधुनिकीकरण करना या कायाकल्प करना होता है।
3. ''Deteriorate'' (बिगाड़ना), ''neglect'' (उपेक्षा करना), और ''disband'' (भंग करना) नकारात्मक अर्थ देते हैं जो संदर्भ के सर्वथा विपरीत हैं।

अतः सही उत्तर (b) है।'),
  ('ssc_cgl_tier1_mock_3', 97, 4, 'PART-4', 'English Comprehension', 'Cloze Test (Comprehension)', 'Moderate', 'Select the most appropriate option to fill in blank (2):

...Transitioning towards integrated mass transit networks not only reduces carbon emissions, but also diminishes the citizen''s chronic (2) _______ fossil fuels...', 'रिक्त स्थान (2) की पूर्ति के लिए सबसे उपयुक्त विकल्प का चयन करें:

...Transitioning towards integrated mass transit networks not only reduces carbon emissions, but also diminishes the citizen''s chronic (2) _______ fossil fuels...', '{"a":"indifference to","b":"resistance against","c":"antipathy towards","d":"reliance on"}'::jsonb, '{"a":"indifference to (के प्रति उदासीनता)","b":"resistance against (के विरुद्ध प्रतिरोध)","c":"antipathy towards (के प्रति दुर्भावना/घृणा)","d":"reliance on (पर निर्भरता)"}'::jsonb, 'd', 'Cloze Test Analysis for Blank (2):
1. The sentence discusses how moving to mass transit reduces carbon emissions and citizen''s excessive and persistent (''chronic'') dependence on fossil fuels.
2. The noun ''reliance'' naturally collocates with the preposition ''on'' (''reliance on something'' = dependence on something).
3. ''Antipathy towards'' (hostility), ''indifference to'' (apathy), and ''resistance against'' (opposition) do not fit logically, as people currently depend heavily on fossil fuels rather than resisting them.

Correct Option: (d)', 'रिक्त स्थान (2) का विश्लेषण:
1. वाक्य का भाव यह है कि सार्वजनिक परिवहन अपनाने से नागरिकों की जीवाश्म ईंधन पर दीर्घकालिक ''निर्भरता'' (reliance on) कम होती है।
2. ''Reliance'' के साथ निश्चित पूर्वसर्ग ''on'' आता है।
3. अन्य विकल्प (''antipathy'' - घृणा, ''indifference'' - उदासीनता, ''resistance'' - विरोध) यहाँ अतार्किक हैं।

अतः सही उत्तर (d) है।'),
  ('ssc_cgl_tier1_mock_3', 98, 4, 'PART-4', 'English Comprehension', 'Cloze Test (Comprehension)', 'Moderate', 'Select the most appropriate option to fill in blank (3):

...Nevertheless, civil engineers emphasize that electric mobility alone cannot resolve urban bottlenecks unless supported by (3) _______ last-mile connectivity...', 'रिक्त स्थान (3) की पूर्ति के लिए सबसे उपयुक्त विकल्प का चयन करें:

...Nevertheless, civil engineers emphasize that electric mobility alone cannot resolve urban bottlenecks unless supported by (3) _______ last-mile connectivity...', '{"a":"redundant","b":"seamless","c":"sporadic","d":"impeded"}'::jsonb, '{"a":"redundant (अनावश्यक / व्यर्थ)","b":"seamless (निर्बाध / सुगम / बिना रुकावट के)","c":"sporadic (छिटपुट / कभी-कभार होने वाला)","d":"impeded (बाधित / अवरुद्ध)"}'::jsonb, 'b', 'Cloze Test Analysis for Blank (3):
1. The engineers caution that electric mobility needs smooth, uninterrupted, and integrated last-mile connectivity to be genuinely effective.
2. ''Seamless'' means smooth, continuous, and without any awkward transitions or interruptions (e.g., ''seamless connectivity''). This is the ideal collocation.
3. ''Sporadic'' (occasional/irregular), ''redundant'' (superfluous), and ''impeded'' (hindered/blocked) represent flawed connectivity, which engineers would not advocate as a prerequisite.

Correct Option: (b)', 'रिक्त स्थान (3) का विश्लेषण:
1. संदर्भ में इंजीनियरों का कहना है कि इलेक्ट्रिक मोबिलिटी तभी सफल हो सकती है जब अंतिम छोर तक ''निर्बाध'' (seamless) कनेक्टिविटी उपलब्ध हो।
2. ''Seamless connectivity'' एक मानक व उपयुक्त कोलोकेशन है जिसका अर्थ बिना किसी रुकावट या झंझट के सुगम जुड़ाव होता है।
3. ''Sporadic'' (अनियमित), ''redundant'' (व्यर्थ) और ''impeded'' (बाधित) नकारात्मक शब्द हैं।

अतः सही उत्तर (b) है।'),
  ('ssc_cgl_tier1_mock_3', 99, 4, 'PART-4', 'English Comprehension', 'Cloze Test (Comprehension)', 'Hard', 'Select the most appropriate option to fill in blank (4):

...Urban planners must simultaneously design dedicated pedestrian corridors and bicycle lanes, thereby (4) _______ commuters to adopt non-motorized alternatives for short distances...', 'रिक्त स्थान (4) की पूर्ति के लिए सबसे उपयुक्त विकल्प का चयन करें:

...Urban planners must simultaneously design dedicated pedestrian corridors and bicycle lanes, thereby (4) _______ commuters to adopt non-motorized alternatives for short distances...', '{"a":"incentivizing","b":"alienating","c":"dissuading","d":"compelling"}'::jsonb, '{"a":"incentivizing (प्रोत्साहित करना / प्रेरक लाभ देना)","b":"alienating (अलग-थलग करना / विरक्त करना)","c":"dissuading (हतोत्साहित करना / विमुख करना)","d":"compelling (मजबूर करना / बाध्य करना)"}'::jsonb, 'a', 'Cloze Test Analysis for Blank (4):
1. Context: Dedicated pedestrian walkways and bike lanes encourage commuters by making non-motorized transport safe, convenient, and attractive.
2. ''Incentivizing'' means motivating or encouraging someone to undertake a particular action by offering an incentive or creating favorable conditions.
3. ''Dissuading'' means persuading someone NOT to take an action (opposite of the goal).
4. ''Compelling'' implies force or coercion, which is neither democratic nor accurate for urban corridor design.
5. ''Alienating'' means estranging or making hostile.

Correct Option: (a)', 'रिक्त स्थान (4) का विश्लेषण:
1. पैदल पथ और साइकिल लेन बनाने का उद्देश्य नागरिकों को गैर-मोटर चालित साधनों को अपनाने हेतु ''प्रोत्साहित'' (incentivize) करना है।
2. ''Incentivizing'' का अर्थ अनुकूल परिस्थितियाँ या लाभ प्रदान कर प्रेरित करना है।
3. ''Dissuading'' (रोकना/हतोत्साहित करना), ''compelling'' (मजबूर करना) तथा ''alienating'' (अलग-थलग करना) असंगत हैं।

अतः सही उत्तर (a) है।'),
  ('ssc_cgl_tier1_mock_3', 100, 4, 'PART-4', 'English Comprehension', 'Cloze Test (Comprehension)', 'Moderate', 'Select the most appropriate option to fill in blank (5):

...Ultimately, building liveable, climate-resilient cities is no longer a utopian aspiration, but an ecological (5) _______ that demands decisive political will.

Select the most appropriate option for blank (5):', 'रिक्त स्थान (5) की पूर्ति के लिए सबसे उपयुक्त विकल्प का चयन करें:

...Ultimately, building liveable, climate-resilient cities is no longer a utopian aspiration, but an ecological (5) _______ that demands decisive political will.

रिक्त स्थान (5) के लिए सबसे उपयुक्त विकल्प चुनें:', '{"a":"contingency","b":"imperative","c":"distraction","d":"triviality"}'::jsonb, '{"a":"contingency (आकस्मिकता / संभावित घटना)","b":"imperative (अनिवार्यता / परम आवश्यक कर्तव्य)","c":"distraction (भटकाव / व्याकुलता)","d":"triviality (तुच्छता / महत्वहीन बात)"}'::jsonb, 'b', 'Cloze Test Analysis for Blank (5):
1. The sentence contrasts ''utopian aspiration'' (an idealistic, optional dream) with an essential, unavoidable necessity: ''an ecological imperative''.
2. ''Imperative'' as a noun denotes an essential, urgent, and unavoidable obligation or requirement that demands immediate action.
3. ''Triviality'' (unimportant matter), ''contingency'' (unforeseen possibility), and ''distraction'' (diversion) do not align with the gravity of demanding ''decisive political will''.

Correct Option: (b)', 'रिक्त स्थान (5) का विश्लेषण:
1. वाक्य में यह स्पष्ट किया गया है कि जलवायु-अनुकूल शहरों का निर्माण केवल एक काल्पनिक सपना (utopian aspiration) नहीं है, बल्कि यह एक पारिस्थितिकीय ''अनिवार्यता'' (ecological imperative) है जिसके लिए दृढ़ राजनीतिक इच्छाशक्ति की आवश्यकता है।
2. ''Imperative'' (संज्ञा के रूप में) का अर्थ अत्यंत महत्वपूर्ण व अपरिहार्य आवश्यकता या कर्तव्य होता है।
3. ''Triviality'' (तुच्छता), ''contingency'' (आकस्मिकता) और ''distraction'' (भटकाव) इसके विपरीत हैं।

अतः सही उत्तर (b) है।');

-- Verification
SELECT count(*) AS total_mock_3_questions_seeded FROM public.questions WHERE test_id = 'ssc_cgl_tier1_mock_3';
