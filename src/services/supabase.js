import { createClient } from '@supabase/supabase-js';

// Default credentials from repo commits
const DEFAULT_SUPABASE_URL = 'https://usgoulvpgayviixalmkd.supabase.co';
const DEFAULT_SUPABASE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVzZ291bHZwZ2F5dmlpeGFsbWtkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTExODcwMjgsImV4cCI6MjEwNjc2MzAyOH0.ARy4m7wlO37fEjQFGuWQQ3kRcePbZNXOaF-UW-Bq1kE';

// Retrieve configuration
export const getSupabaseConfig = () => {
  const envUrl = import.meta.env.VITE_SUPABASE_URL;
  const envKey = import.meta.env.VITE_SUPABASE_ANON_KEY;
  
  const storedUrl = localStorage.getItem('toppers_supabase_url') || localStorage.getItem('toppersmock_supabase_url');
  const storedKey = localStorage.getItem('toppers_supabase_key') || localStorage.getItem('toppersmock_supabase_key');
  
  const url = storedUrl || envUrl || DEFAULT_SUPABASE_URL;
  const key = storedKey || envKey || DEFAULT_SUPABASE_KEY;

  return {
    url,
    key,
    isConfigured: Boolean(url && key)
  };
};

export const setSupabaseConfig = (url, key) => {
  if (url && key) {
    localStorage.setItem('toppers_supabase_url', url.trim());
    localStorage.setItem('toppers_supabase_key', key.trim());
  } else {
    localStorage.removeItem('toppers_supabase_url');
    localStorage.removeItem('toppers_supabase_key');
  }
};

let supabaseInstance = null;

export const getSupabase = () => {
  const { url, key, isConfigured } = getSupabaseConfig();
  if (!isConfigured) return null;

  if (!supabaseInstance || supabaseInstance.supabaseUrl !== url) {
    try {
      supabaseInstance = createClient(url, key);
    } catch (e) {
      console.error('Failed to initialize Supabase client:', e);
      return null;
    }
  }
  return supabaseInstance;
};

// ==============================================================================
// Database Operations
// ==============================================================================

/**
 * Fetch Mock Test questions from Supabase (or fallback to local file)
 */
export const fetchMockQuestionsFromDb = async (testId = 'ssc_cgl_tier1_mock_3') => {
  const client = getSupabase();
  if (!client) return null;

  try {
    const { data, error } = await client
      .from('questions')
      .select('*')
      .eq('test_id', testId)
      .order('question_number', { ascending: true });

    if (error) {
      console.warn('Could not fetch questions from Supabase, using local bundle:', error.message);
      return null;
    }

    if (data && data.length > 0) {
      return data;
    }
    return null;
  } catch (err) {
    console.error('Error fetching questions from Supabase:', err);
    return null;
  }
};

/**
 * Fetch In-Progress Attempt for Resume
 */
export const getInProgressAttempt = async (testId = 'ssc_cgl_tier1_mock_3', rollNumber = '2201048291') => {
  const client = getSupabase();
  if (client) {
    try {
      const { data, error } = await client
        .from('test_attempts')
        .select('*')
        .eq('test_id', testId)
        .eq('roll_number', rollNumber)
        .eq('status', 'in_progress')
        .order('updated_at', { ascending: false })
        .limit(1)
        .maybeSingle();

      if (!error && data) {
        return data;
      }
    } catch (err) {
      console.warn('Error reading attempt from Supabase:', err);
    }
  }

  // Fallback to localStorage
  try {
    const local = localStorage.getItem(`ssc_mock_attempt_${testId}_${rollNumber}`);
    if (local) {
      const parsed = JSON.parse(local);
      if (parsed.status === 'in_progress') {
        return parsed;
      }
    }
  } catch (e) {
    console.warn('Error reading local attempt backup:', e);
  }

  return null;
};

/**
 * Save or Update In-Progress Test Attempt
 */
export const saveOrUpdateAttempt = async (attemptData) => {
  const { test_id, roll_number } = attemptData;
  const storageKey = `ssc_mock_attempt_${test_id}_${roll_number}`;

  try {
    localStorage.setItem(storageKey, JSON.stringify({
      ...attemptData,
      updated_at: new Date().toISOString()
    }));
  } catch (e) {
    console.warn('Failed to write to localStorage:', e);
  }

  const client = getSupabase();
  if (!client) return { success: true, localOnly: true };

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

    const { data, error } = await client
      .from('test_attempts')
      .upsert(payload, { onConflict: 'id' })
      .select()
      .maybeSingle();

    if (error) {
      console.warn('Failed to upsert attempt in Supabase:', error.message);
      return { success: false, error: error.message };
    }
    return { success: true, data };
  } catch (err) {
    console.error('Error syncing attempt with Supabase:', err);
    return { success: false, error: err.message };
  }
};

/**
 * Record Option Chosen and Time Taken in dedicated `user_responses` table
 */
export const recordUserResponse = async (responseData) => {
  const client = getSupabase();
  if (!client) return;

  try {
    const payload = {
      attempt_id: String(responseData.attempt_id),
      roll_number: responseData.roll_number || '2201048291',
      candidate_name: responseData.candidate_name || 'ANKIT SHARMA',
      test_id: responseData.test_id || 'ssc_cgl_tier1_mock_3',
      question_number: Number(responseData.question_number),
      section_name: responseData.section_name || '',
      selected_option: responseData.selected_option || null,
      time_taken_seconds: Number(responseData.time_taken_seconds || 0),
      correct_option: responseData.correct_option || null,
      is_correct: responseData.is_correct || false,
      status: responseData.status || 'ANSWERED',
      recorded_at: new Date().toISOString()
    };

    const { error } = await client
      .from('user_responses')
      .upsert(payload, { onConflict: 'attempt_id,question_number' });

    if (error) {
      console.warn('Failed to record in user_responses table:', error.message);
    } else {
      console.log(`✓ Saved to user_responses: Q${responseData.question_number} -> Option ${responseData.selected_option} in ${responseData.time_taken_seconds}s`);
    }
  } catch (err) {
    console.error('Error saving to user_responses:', err);
  }
};

/**
 * Record or Update Individual Question Answer and Time Spent
 */
export const recordQuestionAnswer = async (attemptId, answerData) => {
  const client = getSupabase();
  if (!client || !attemptId) return;

  try {
    const payload = {
      attempt_id: attemptId,
      question_number: answerData.question_number,
      section_name: answerData.section_name,
      selected_option: answerData.selected_option || null,
      correct_option: answerData.correct_option,
      is_correct: answerData.is_correct || false,
      marks_awarded: answerData.marks_awarded || 0,
      status: answerData.status,
      time_spent_seconds: answerData.time_spent_seconds || 0,
      timestamp: new Date().toISOString()
    };

    const { error } = await client
      .from('test_attempt_answers')
      .upsert(payload, { onConflict: 'attempt_id,question_number' });

    if (error) {
      console.warn('Failed to record question answer in Supabase:', error.message);
    }

    // Also sync to user_responses table
    await recordUserResponse({
      attempt_id: attemptId,
      roll_number: answerData.roll_number,
      candidate_name: answerData.candidate_name,
      test_id: answerData.test_id,
      question_number: answerData.question_number,
      section_name: answerData.section_name,
      selected_option: answerData.selected_option,
      time_taken_seconds: answerData.time_spent_seconds,
      correct_option: answerData.correct_option,
      is_correct: answerData.is_correct,
      status: answerData.status
    });
  } catch (e) {
    console.error('Error recording answer:', e);
  }
};

/**
 * Final Submit of Test Attempt
 */
export const submitFinalAttempt = async (attemptData, detailedAnswers = []) => {
  const { test_id, roll_number } = attemptData;
  const storageKey = `ssc_mock_attempt_${test_id}_${roll_number}`;

  try {
    localStorage.removeItem(storageKey);
    localStorage.setItem(`ssc_mock_completed_${test_id}_${attemptData.id}`, JSON.stringify(attemptData));
  } catch (e) {}

  const client = getSupabase();
  if (!client) return { success: true, localOnly: true };

  try {
    const { error: attemptError } = await client
      .from('test_attempts')
      .upsert({
        ...attemptData,
        status: 'submitted',
        submitted_at: new Date().toISOString(),
        updated_at: new Date().toISOString()
      }, { onConflict: 'id' });

    if (attemptError) throw attemptError;

    if (detailedAnswers.length > 0) {
      const answersPayload = detailedAnswers.map(ans => ({
        attempt_id: attemptData.id,
        question_number: ans.question_number,
        section_name: ans.section_name,
        selected_option: ans.selected_option || null,
        correct_option: ans.correct_option,
        is_correct: ans.is_correct,
        marks_awarded: ans.marks_awarded,
        status: ans.status,
        time_spent_seconds: ans.time_spent_seconds || 0,
        timestamp: new Date().toISOString()
      }));

      const { error: ansError } = await client
        .from('test_attempt_answers')
        .upsert(answersPayload, { onConflict: 'attempt_id,question_number' });

      if (ansError) console.warn('Failed to batch save answers:', ansError.message);

      // Batch upsert to user_responses table
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

      const { error: respError } = await client
        .from('user_responses')
        .upsert(responsesPayload, { onConflict: 'attempt_id,question_number' });

      if (respError) console.warn('Failed to batch save user_responses:', respError.message);
    }

    return { success: true };
  } catch (err) {
    console.error('Error submitting final test to Supabase:', err);
    return { success: false, error: err.message };
  }
};
