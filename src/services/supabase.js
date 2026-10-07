import { createClient } from '@supabase/supabase-js';

// Live Supabase project credentials
export const SUPABASE_URL = 'https://usgoulvpgayviixalmkd.supabase.co';
export const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVzZ291bHZwZ2F5dmlpeGFsbWtkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTExODcwMjgsImV4cCI6MjEwNjc2MzAyOH0.ARy4m7wlO37fEjQFGuWQQ3kRcePbZNXOaF-UW-Bq1kE';

// Create persistent client instance
export const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
  auth: { persistSession: false }
});

export const getSupabase = () => supabase;

export const getSupabaseConfig = () => ({
  url: localStorage.getItem('toppers_supabase_url') || SUPABASE_URL,
  key: localStorage.getItem('toppers_supabase_key') || SUPABASE_ANON_KEY,
  isConfigured: true
});

export const setSupabaseConfig = (url, key) => {
  if (url && key) {
    localStorage.setItem('toppers_supabase_url', url.trim());
    localStorage.setItem('toppers_supabase_key', key.trim());
  } else {
    localStorage.removeItem('toppers_supabase_url');
    localStorage.removeItem('toppers_supabase_key');
  }
};

/**
 * INSTANT FETCH: Fetch all existing responses from Supabase on page load/refresh
 */
export const fetchUserResponsesFromDb = async (attemptId) => {
  try {
    const { data, error } = await supabase
      .from('user_responses')
      .select('*')
      .eq('attempt_id', attemptId)
      .order('question_number', { ascending: true });

    if (error) {
      console.error('Error fetching user_responses from Supabase:', error);
      return {};
    }

    const responsesMap = {};
    if (data && Array.isArray(data)) {
      data.forEach((row) => {
        responsesMap[row.question_number] = {
          selectedOption: row.selected_option || null,
          timeSpentSeconds: Number(row.time_taken_seconds || 0),
          status: row.status || (row.selected_option ? 'ANSWERED' : 'NOT_ANSWERED')
        };
      });
      console.log(`⚡ Fetched ${data.length} saved responses from Supabase user_responses table!`, responsesMap);
    }
    return responsesMap;
  } catch (err) {
    console.error('Failed to load user_responses:', err);
    return {};
  }
};

/**
 * INSTANT SAVE: The exact moment user selects or changes any answer
 */
export const saveUserResponseInstant = async (resp) => {
  try {
    const payload = {
      attempt_id: String(resp.attempt_id),
      roll_number: String(resp.roll_number || '2201048291'),
      candidate_name: resp.candidate_name || 'ANKIT SHARMA',
      test_id: resp.test_id || 'ssc_cgl_tier1_mock_3',
      question_number: Number(resp.question_number),
      section_name: resp.section_name || '',
      selected_option: resp.selected_option || null,
      time_taken_seconds: Number(resp.time_taken_seconds || 0),
      correct_option: resp.correct_option || null,
      is_correct: Boolean(resp.is_correct),
      status: resp.status || (resp.selected_option ? 'ANSWERED' : 'NOT_ANSWERED'),
      recorded_at: new Date().toISOString()
    };

    const { data, error } = await supabase
      .from('user_responses')
      .upsert(payload, { onConflict: 'attempt_id,question_number' })
      .select();

    if (error) {
      console.error('❌ Supabase user_responses save error:', error.message);
      return { success: false, error: error.message };
    }

    console.log(`✓ [SUPABASE INSTANT SYNC] Q${resp.question_number} => Option "${resp.selected_option}" in ${resp.time_taken_seconds}s`, data);
    return { success: true, data };
  } catch (err) {
    console.error('Error in saveUserResponseInstant:', err);
    return { success: false, error: err.message };
  }
};

export const recordUserResponse = saveUserResponseInstant;
export const recordQuestionAnswer = saveUserResponseInstant;

/**
 * Save or Update In-Progress Session Metadata
 */
export const saveOrUpdateAttempt = async (attemptData) => {
  try {
    const payload = {
      id: attemptData.id,
      test_id: attemptData.test_id,
      test_title: attemptData.test_title,
      roll_number: attemptData.roll_number,
      candidate_name: attemptData.candidate_name,
      status: attemptData.status || 'in_progress',
      current_section_id: attemptData.current_section_id,
      current_question_number: attemptData.current_question_number,
      sectional_time_left: attemptData.sectional_time_left,
      completed_sections: attemptData.completed_sections,
      question_states: attemptData.question_states,
      total_questions: attemptData.total_questions || 100,
      total_attempted: attemptData.total_attempted || 0,
      time_taken_seconds: attemptData.time_taken_seconds || 0,
      last_synced_at: new Date().toISOString()
    };

    await supabase
      .from('test_attempts')
      .upsert(payload, { onConflict: 'id' });

    return { success: true };
  } catch (err) {
    console.warn('Attempt metadata sync warning:', err);
    return { success: false };
  }
};

/**
 * Check for in-progress session
 */
export const getInProgressAttempt = async (testId = 'ssc_cgl_tier1_mock_3', rollNumber = '2201048291') => {
  try {
    const { data, error } = await supabase
      .from('test_attempts')
      .select('*')
      .eq('test_id', testId)
      .eq('roll_number', rollNumber)
      .eq('status', 'in_progress')
      .order('updated_at', { ascending: false })
      .limit(1)
      .maybeSingle();

    if (!error && data) return data;
  } catch (e) {
    console.warn('getInProgressAttempt error:', e);
  }
  return null;
};

/**
 * Final Submit of Test Attempt
 */
export const submitFinalAttempt = async (attemptData, detailedAnswers = []) => {
  try {
    await supabase
      .from('test_attempts')
      .upsert({
        ...attemptData,
        status: 'submitted',
        submitted_at: new Date().toISOString(),
        updated_at: new Date().toISOString()
      }, { onConflict: 'id' });

    if (detailedAnswers.length > 0) {
      const responsesPayload = detailedAnswers.map(ans => ({
        attempt_id: String(attemptData.id),
        roll_number: attemptData.roll_number || '2201048291',
        candidate_name: attemptData.candidate_name || 'ANKIT SHARMA',
        test_id: attemptData.test_id || 'ssc_cgl_tier1_mock_3',
        question_number: Number(ans.question_number),
        section_name: ans.section_name,
        selected_option: ans.selected_option || null,
        time_taken_seconds: Number(ans.time_spent_seconds || 0),
        correct_option: ans.correct_option,
        is_correct: ans.is_correct,
        status: ans.status,
        recorded_at: new Date().toISOString()
      }));

      await supabase
        .from('user_responses')
        .upsert(responsesPayload, { onConflict: 'attempt_id,question_number' });
    }

    return { success: true };
  } catch (err) {
    console.error('Error submitting test to Supabase:', err);
    return { success: false };
  }
};
