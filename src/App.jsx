import React, { useState, useEffect, useRef } from 'react';
import Header from './components/Header';
import SectionTabs from './components/SectionTabs';
import QuestionArea from './components/QuestionArea';
import QuestionPalette from './components/QuestionPalette';
import SectionInfoModal from './components/SectionInfoModal';
import SubmitModal from './components/SubmitModal';
import ResultModal from './components/ResultModal';
import CustomQuestionsModal from './components/CustomQuestionsModal';
import ResumeModal from './components/ResumeModal';
import SectionTimeOverModal from './components/SectionTimeOverModal';
import EarlySectionSubmitModal from './components/EarlySectionSubmitModal';
import SupabaseSettingsModal from './components/SupabaseSettingsModal';

import { 
  SECTIONS, 
  STATUS, 
  SECTION_DURATION_SECONDS,
  TOTAL_EXAM_DURATION_SECONDS,
  getDefaultQuestions 
} from './data/questions';

import {
  getSupabaseConfig,
  getInProgressAttempt,
  saveOrUpdateAttempt,
  recordQuestionAnswer,
  submitFinalAttempt
} from './services/supabase';

export default function App() {
  const TEST_ID = 'ssc_cgl_tier1_mock_3';
  const TEST_TITLE = 'SSC CGL Tier-I Mock Test 3 (TCS iON CBT)';
  const candidate = {
    name: "ANKIT SHARMA",
    rollNo: "2201048291",
    systemNo: "C9-LAB3-042",
    photoUrl: null
  };

  // Questions (Mock Test 3 default)
  const [questions, setQuestions] = useState(() => getDefaultQuestions());

  // Attempt UUID
  const [attemptId, setAttemptId] = useState(() => {
    return 'attempt_' + Date.now() + '_' + Math.random().toString(36).substring(2, 8);
  });

  // Section Tracking (Strict Sectional Timing)
  const [activeSectionId, setActiveSectionId] = useState('gi');
  const [completedSections, setCompletedSections] = useState([]); // ['gi', 'ga', ...]

  // Active Question Number (1 to 100)
  const [activeQuestionNumber, setActiveQuestionNumber] = useState(1);

  // Sectional Time Left mapping in seconds: { gi: 900, ga: 900, qa: 900, ec: 900 }
  const [sectionalTimeLeft, setSectionalTimeLeft] = useState(() => ({
    gi: SECTION_DURATION_SECONDS,
    ga: SECTION_DURATION_SECONDS,
    qa: SECTION_DURATION_SECONDS,
    ec: SECTION_DURATION_SECONDS,
  }));

  const [isTimerRunning, setIsTimerRunning] = useState(true);
  const [language, setLanguage] = useState('en');

  // Question Statuses and Time Spent state map:
  // { [qNum]: { status, selectedOption, timeSpentSeconds } }
  const [questionStatuses, setQuestionStatuses] = useState(() => {
    const initial = {};
    const defaultQs = getDefaultQuestions();
    defaultQs.forEach((q, idx) => {
      initial[q.question_number] = {
        status: idx === 0 ? STATUS.NOT_ANSWERED : STATUS.NOT_VISITED,
        selectedOption: null,
        timeSpentSeconds: 0,
      };
    });
    return initial;
  });

  // Modals state
  const [isInfoModalOpen, setIsInfoModalOpen] = useState(false);
  const [isSubmitModalOpen, setIsSubmitModalOpen] = useState(false);
  const [isResultModalOpen, setIsResultModalOpen] = useState(false);
  const [isCustomQuestionsOpen, setIsCustomQuestionsOpen] = useState(false);
  const [isEarlySubmitOpen, setIsEarlySubmitOpen] = useState(false);
  const [isSectionTimeOverOpen, setIsSectionTimeOverOpen] = useState(false);
  const [isSupabaseModalOpen, setIsSupabaseModalOpen] = useState(false);
  const [pendingExpiredSection, setPendingExpiredSection] = useState(null);

  // Resume State
  const [detectedPastAttempt, setDetectedPastAttempt] = useState(null);
  const [isResumeModalOpen, setIsResumeModalOpen] = useState(false);

  // Supabase connection indicator
  const [isSupabaseConfigured, setIsSupabaseConfigured] = useState(() => getSupabaseConfig().isConfigured);
  const [isSynced, setIsSynced] = useState(true);

  // --------------------------------------------------------------------------
  // Check for In-Progress Attempt on Startup (Supabase or Local)
  // --------------------------------------------------------------------------
  useEffect(() => {
    let isMounted = true;
    const checkForAttempt = async () => {
      try {
        const attempt = await getInProgressAttempt(TEST_ID, candidate.rollNo);
        if (isMounted && attempt && attempt.status === 'in_progress') {
          setDetectedPastAttempt(attempt);
          setIsResumeModalOpen(true);
        }
      } catch (e) {
        console.warn('Check attempt error:', e);
      }
    };
    checkForAttempt();
    return () => { isMounted = false; };
  }, []);

  // Handler: Resume Past Attempt
  const handleResumePastAttempt = () => {
    if (!detectedPastAttempt) return;

    if (detectedPastAttempt.id) setAttemptId(detectedPastAttempt.id);
    if (detectedPastAttempt.current_section_id) setActiveSectionId(detectedPastAttempt.current_section_id);
    if (detectedPastAttempt.current_question_number) setActiveQuestionNumber(detectedPastAttempt.current_question_number);
    if (detectedPastAttempt.completed_sections) setCompletedSections(detectedPastAttempt.completed_sections);
    if (detectedPastAttempt.sectional_time_left) setSectionalTimeLeft(detectedPastAttempt.sectional_time_left);

    if (detectedPastAttempt.question_states) {
      setQuestionStatuses((prev) => {
        const merged = { ...prev };
        Object.entries(detectedPastAttempt.question_states).forEach(([qNum, state]) => {
          merged[Number(qNum)] = {
            status: state.status || STATUS.NOT_VISITED,
            selectedOption: state.selectedOption || null,
            timeSpentSeconds: state.timeSpentSeconds || 0,
          };
        });
        return merged;
      });
    }

    setIsResumeModalOpen(false);
    setIsTimerRunning(true);
  };

  // Handler: Start Fresh Attempt
  const handleStartFreshAttempt = () => {
    setIsResumeModalOpen(false);
    // Reset attempt key in storage
    localStorage.removeItem(`ssc_mock_attempt_${TEST_ID}_${candidate.rollNo}`);
    // Start fresh ID
    setAttemptId('attempt_' + Date.now() + '_' + Math.random().toString(36).substring(2, 8));
  };

  // --------------------------------------------------------------------------
  // Section Timing Countdown & Question Active Time Tracking (1s interval)
  // --------------------------------------------------------------------------
  useEffect(() => {
    if (!isTimerRunning) return;

    const interval = setInterval(() => {
      // 1. Increment time spent on CURRENT question
      setQuestionStatuses((prev) => {
        const currentQ = prev[activeQuestionNumber];
        if (!currentQ) return prev;
        return {
          ...prev,
          [activeQuestionNumber]: {
            ...currentQ,
            timeSpentSeconds: (currentQ.timeSpentSeconds || 0) + 1,
          }
        };
      });

      // 2. Decrement time left for CURRENT ACTIVE SECTION
      setSectionalTimeLeft((prev) => {
        const currentSecTime = prev[activeSectionId] ?? SECTION_DURATION_SECONDS;
        if (currentSecTime <= 1) {
          // SECTION TIME IS OVER!
          handleSectionTimeExpired(activeSectionId);
          return {
            ...prev,
            [activeSectionId]: 0,
          };
        }
        return {
          ...prev,
          [activeSectionId]: currentSecTime - 1,
        };
      });
    }, 1000);

    return () => clearInterval(interval);
  }, [isTimerRunning, activeSectionId, activeQuestionNumber]);

  // Total time left = sum of current active section time + remaining sections
  const totalTimeLeft = Object.entries(sectionalTimeLeft)
    .filter(([secId]) => !completedSections.includes(secId))
    .reduce((sum, [, secSecs]) => sum + secSecs, 0);

  const currentSection = SECTIONS.find((s) => s.id === activeSectionId) || SECTIONS[0];
  const currentQuestion = questions.find((q) => q.question_number === activeQuestionNumber) || questions[0];
  const currentOption = questionStatuses[activeQuestionNumber]?.selectedOption || null;
  const currentQTimeSpent = questionStatuses[activeQuestionNumber]?.timeSpentSeconds || 0;

  // --------------------------------------------------------------------------
  // Handling Section Expiration & Progression
  // --------------------------------------------------------------------------
  const handleSectionTimeExpired = (expiredSecId) => {
    const expiredSectionObj = SECTIONS.find(s => s.id === expiredSecId);
    setPendingExpiredSection(expiredSectionObj);
    setIsSectionTimeOverOpen(true);
  };

  const handleProceedAfterSectionOver = () => {
    setIsSectionTimeOverOpen(false);
    
    // Mark section as completed
    const newlyCompleted = [...new Set([...completedSections, activeSectionId])];
    setCompletedSections(newlyCompleted);

    // Find next section in order
    const currentIndex = SECTIONS.findIndex(s => s.id === activeSectionId);
    const nextSec = SECTIONS[currentIndex + 1];

    if (nextSec) {
      // Advance to next section
      setActiveSectionId(nextSec.id);
      const firstQOfNext = nextSec.startIndex + 1;
      
      setQuestionStatuses((prev) => {
        if (prev[firstQOfNext]?.status === STATUS.NOT_VISITED) {
          return {
            ...prev,
            [firstQOfNext]: { ...prev[firstQOfNext], status: STATUS.NOT_ANSWERED }
          };
        }
        return prev;
      });

      setActiveQuestionNumber(firstQOfNext);
      syncToBackend(newlyCompleted, nextSec.id, firstQOfNext);
    } else {
      // All 4 sections completed! Final test submission
      handleFinalSubmit();
    }
  };

  // Early Section Submit
  const handleConfirmEarlySectionSubmit = () => {
    setIsEarlySubmitOpen(false);
    // Mark current section time as finished
    setSectionalTimeLeft(prev => ({ ...prev, [activeSectionId]: 0 }));
    handleProceedAfterSectionOver();
  };

  // --------------------------------------------------------------------------
  // Auto-Save / Sync to Supabase & LocalStorage
  // --------------------------------------------------------------------------
  const syncToBackend = async (completed = completedSections, currentSec = activeSectionId, currentQ = activeQuestionNumber) => {
    setIsSynced(false);

    // Calculate total attempted
    let totalAttempted = 0;
    Object.values(questionStatuses).forEach((q) => {
      if (q.status === STATUS.ANSWERED || q.status === STATUS.ANSWERED_AND_MARKED) {
        totalAttempted++;
      }
    });

    const payload = {
      id: attemptId,
      test_id: TEST_ID,
      test_title: TEST_TITLE,
      roll_number: candidate.rollNo,
      candidate_name: candidate.name,
      status: 'in_progress',
      current_section_id: currentSec,
      current_question_number: currentQ,
      sectional_time_left: sectionalTimeLeft,
      completed_sections: completed,
      question_states: questionStatuses,
      total_questions: questions.length,
      total_attempted: totalAttempted,
      time_taken_seconds: TOTAL_EXAM_DURATION_SECONDS - totalTimeLeft,
    };

    await saveOrUpdateAttempt(payload);

    // Also record current question answer
    const currentQData = questions.find(q => q.question_number === currentQ);
    const stateObj = questionStatuses[currentQ];
    if (currentQData && stateObj) {
      await recordQuestionAnswer(attemptId, {
        question_number: currentQ,
        section_name: currentQData.section_title,
        selected_option: stateObj.selectedOption,
        correct_option: currentQData.correct_option,
        is_correct: stateObj.selectedOption?.toLowerCase() === currentQData.correct_option?.toLowerCase(),
        status: stateObj.status,
        time_spent_seconds: stateObj.timeSpentSeconds || 0,
      });
    }

    setIsSynced(true);
  };

  // Periodic Auto-save every 10 seconds
  useEffect(() => {
    if (!isTimerRunning) return;
    const saveInterval = setInterval(() => {
      syncToBackend();
    }, 10000);
    return () => clearInterval(saveInterval);
  }, [isTimerRunning, attemptId, activeSectionId, activeQuestionNumber, questionStatuses, sectionalTimeLeft, completedSections]);

  // --------------------------------------------------------------------------
  // Question Actions & State Updates
  // --------------------------------------------------------------------------
  const handleSelectOption = (optKey) => {
    setQuestionStatuses((prev) => ({
      ...prev,
      [activeQuestionNumber]: {
        ...prev[activeQuestionNumber],
        selectedOption: optKey
      }
    }));
  };

  // Save & Next
  const handleSaveAndNext = () => {
    const currentSelected = questionStatuses[activeQuestionNumber]?.selectedOption;

    setQuestionStatuses((prev) => {
      const newStatus = currentSelected ? STATUS.ANSWERED : STATUS.NOT_ANSWERED;
      return {
        ...prev,
        [activeQuestionNumber]: {
          ...prev[activeQuestionNumber],
          status: newStatus,
          selectedOption: currentSelected || null
        }
      };
    });

    // Navigation constrained to CURRENT SECTION
    const maxQInSection = currentSection.endIndex + 1;
    if (activeQuestionNumber < maxQInSection) {
      const nextQNum = activeQuestionNumber + 1;
      setQuestionStatuses((prev) => {
        if (prev[nextQNum]?.status === STATUS.NOT_VISITED) {
          return {
            ...prev,
            [nextQNum]: { ...prev[nextQNum], status: STATUS.NOT_ANSWERED }
          };
        }
        return prev;
      });
      setActiveQuestionNumber(nextQNum);
    } else {
      // Reached end of current section: prompt section submit
      setIsEarlySubmitOpen(true);
    }

    syncToBackend();
  };

  // Mark for Review & Next
  const handleMarkForReviewAndNext = () => {
    const currentSelected = questionStatuses[activeQuestionNumber]?.selectedOption;

    setQuestionStatuses((prev) => {
      const newStatus = currentSelected ? STATUS.ANSWERED_AND_MARKED : STATUS.MARKED_FOR_REVIEW;
      return {
        ...prev,
        [activeQuestionNumber]: {
          ...prev[activeQuestionNumber],
          status: newStatus,
          selectedOption: currentSelected || null
        }
      };
    });

    const maxQInSection = currentSection.endIndex + 1;
    if (activeQuestionNumber < maxQInSection) {
      const nextQNum = activeQuestionNumber + 1;
      setQuestionStatuses((prev) => {
        if (prev[nextQNum]?.status === STATUS.NOT_VISITED) {
          return {
            ...prev,
            [nextQNum]: { ...prev[nextQNum], status: STATUS.NOT_ANSWERED }
          };
        }
        return prev;
      });
      setActiveQuestionNumber(nextQNum);
    } else {
      setIsEarlySubmitOpen(true);
    }

    syncToBackend();
  };

  // Clear Response
  const handleClearResponse = () => {
    setQuestionStatuses((prev) => ({
      ...prev,
      [activeQuestionNumber]: {
        ...prev[activeQuestionNumber],
        status: STATUS.NOT_ANSWERED,
        selectedOption: null
      }
    }));
    syncToBackend();
  };

  // Previous Question (within section)
  const handlePreviousQuestion = () => {
    const minQInSection = currentSection.startIndex + 1;
    if (activeQuestionNumber > minQInSection) {
      setActiveQuestionNumber(activeQuestionNumber - 1);
    }
  };

  // Direct Navigate from Palette
  const handleNavigateToQuestion = (targetQNum) => {
    if (targetQNum === activeQuestionNumber) return;

    // Check if target is inside active section
    const minQInSection = currentSection.startIndex + 1;
    const maxQInSection = currentSection.endIndex + 1;
    if (targetQNum < minQInSection || targetQNum > maxQInSection) {
      return; // Locked!
    }

    // Mark current if left without answering
    setQuestionStatuses((prev) => {
      const curr = prev[activeQuestionNumber];
      if (curr && !curr.selectedOption && (curr.status === STATUS.NOT_VISITED || curr.status === STATUS.NOT_ANSWERED)) {
        return {
          ...prev,
          [activeQuestionNumber]: { ...curr, status: STATUS.NOT_ANSWERED },
          [targetQNum]: prev[targetQNum]?.status === STATUS.NOT_VISITED 
            ? { ...prev[targetQNum], status: STATUS.NOT_ANSWERED } 
            : prev[targetQNum]
        };
      }
      if (prev[targetQNum]?.status === STATUS.NOT_VISITED) {
        return {
          ...prev,
          [targetQNum]: { ...prev[targetQNum], status: STATUS.NOT_ANSWERED }
        };
      }
      return prev;
    });

    setActiveQuestionNumber(targetQNum);
  };

  // --------------------------------------------------------------------------
  // Final Test Submission
  // --------------------------------------------------------------------------
  const handleFinalSubmit = async () => {
    setIsSubmitModalOpen(false);
    setIsTimerRunning(false);

    // Compute evaluation
    let correct = 0;
    let incorrect = 0;
    let unattempted = 0;
    let score = 0;

    const detailedAnswers = questions.map((q) => {
      const s = questionStatuses[q.question_number];
      const userAns = s?.selectedOption;
      const isAttempted = s?.status === STATUS.ANSWERED || s?.status === STATUS.ANSWERED_AND_MARKED;
      const isCorrect = isAttempted && userAns && userAns.toLowerCase() === (q.correct_option || '').toLowerCase();
      
      let marks = 0;
      if (isAttempted && userAns) {
        if (isCorrect) {
          correct++;
          score += 2.0;
          marks = 2.0;
        } else {
          incorrect++;
          score -= 0.5;
          marks = -0.5;
        }
      } else {
        unattempted++;
      }

      return {
        question_number: q.question_number,
        section_name: q.section_title,
        selected_option: userAns || null,
        correct_option: q.correct_option,
        is_correct: isCorrect,
        marks_awarded: marks,
        status: s?.status || STATUS.NOT_VISITED,
        time_spent_seconds: s?.timeSpentSeconds || 0,
      };
    });

    const accuracy = (correct + incorrect > 0) ? Math.round((correct / (correct + incorrect)) * 100) : 0;
    const timeTaken = TOTAL_EXAM_DURATION_SECONDS - totalTimeLeft;

    const finalAttemptPayload = {
      id: attemptId,
      test_id: TEST_ID,
      test_title: TEST_TITLE,
      roll_number: candidate.rollNo,
      candidate_name: candidate.name,
      total_questions: questions.length,
      total_attempted: correct + incorrect,
      total_correct: correct,
      total_incorrect: incorrect,
      total_unattempted: unattempted,
      total_score: score,
      accuracy_percentage: accuracy,
      time_taken_seconds: timeTaken,
      status: 'submitted',
    };

    await submitFinalAttempt(finalAttemptPayload, detailedAnswers);
    setIsResultModalOpen(true);
  };

  const handleRestartTest = () => {
    localStorage.removeItem(`ssc_mock_attempt_${TEST_ID}_${candidate.rollNo}`);
    setAttemptId('attempt_' + Date.now() + '_' + Math.random().toString(36).substring(2, 8));
    setActiveSectionId('gi');
    setCompletedSections([]);
    setActiveQuestionNumber(1);
    setSectionalTimeLeft({
      gi: SECTION_DURATION_SECONDS,
      ga: SECTION_DURATION_SECONDS,
      qa: SECTION_DURATION_SECONDS,
      ec: SECTION_DURATION_SECONDS,
    });
    setIsTimerRunning(true);
    setIsResultModalOpen(false);

    const reset = {};
    questions.forEach((q, idx) => {
      reset[q.question_number] = {
        status: idx === 0 ? STATUS.NOT_ANSWERED : STATUS.NOT_VISITED,
        selectedOption: null,
        timeSpentSeconds: 0
      };
    });
    setQuestionStatuses(reset);
  };

  const isCurrentSectionLast = activeSectionId === SECTIONS[SECTIONS.length - 1].id;
  const currentSectionIndex = SECTIONS.findIndex(s => s.id === activeSectionId);
  const nextSectionObj = SECTIONS[currentSectionIndex + 1];

  return (
    <div className="min-h-screen flex flex-col bg-[#e9ecef] font-sans antialiased text-gray-900 select-none overflow-hidden">
      {/* 1. Top Header with Sectional Countdown & Supabase Status */}
      <Header
        sectionTimeLeft={sectionalTimeLeft[activeSectionId] ?? 0}
        totalTimeLeft={totalTimeLeft}
        language={language}
        setLanguage={setLanguage}
        candidate={candidate}
        activeSectionTitle={currentSection?.title}
        isSupabaseConfigured={isSupabaseConfigured}
        isSynced={isSynced}
        onOpenSupabaseModal={() => setIsSupabaseModalOpen(true)}
        testTitle={TEST_TITLE}
      />

      {/* CBT Status Bar */}
      <div className="bg-[#e2e8f0] border-b border-gray-300 px-3 sm:px-4 py-1 flex items-center justify-between text-xs text-gray-600">
        <div className="flex items-center space-x-2">
          <span className="inline-block w-2 h-2 rounded-full bg-emerald-500 animate-pulse"></span>
          <span className="font-semibold text-gray-800">SSC CGL Mock Test 3</span>
          <span className="text-gray-400">|</span>
          <span className="text-blue-900 font-medium">
            Section {currentSectionIndex + 1} of 4: <strong>{currentSection?.title}</strong>
          </span>
          <span className="hidden md:inline text-gray-500">
            (15 Mins / Section • Sections Locked Sequentially)
          </span>
        </div>
        <div className="flex items-center space-x-3">
          <button
            onClick={() => setIsSupabaseModalOpen(true)}
            className="text-[11px] font-bold text-[#1b4d89] hover:underline bg-white px-2 py-0.5 rounded border border-gray-300 shadow-2xs hover:bg-blue-50 transition"
          >
            ⚙️ Supabase Config
          </button>
          <button
            onClick={() => setIsCustomQuestionsOpen(true)}
            className="text-[11px] font-bold text-gray-700 hover:underline bg-white px-2 py-0.5 rounded border border-gray-300 shadow-2xs hover:bg-gray-50 transition"
          >
            📂 Load JSON
          </button>
        </div>
      </div>

      {/* 2. Main Content Area (Two-Column Layout) */}
      <main className="flex-1 flex flex-col md:flex-row overflow-hidden relative" style={{ height: 'calc(100vh - 85px)' }}>
        {/* Left Column (75% width) */}
        <section className="w-full md:w-[75%] flex flex-col h-full bg-white border-r border-gray-300 overflow-hidden">
          {/* Section Tabs with Strict Locking */}
          <SectionTabs
            activeSectionId={activeSectionId}
            completedSections={completedSections}
            onSelectSection={(secId) => {
              if (secId === activeSectionId) return;
            }}
            onOpenSectionInfo={() => setIsInfoModalOpen(true)}
            questionStatuses={questionStatuses}
            questions={questions}
          />

          {/* Question Display Area & Footer Controls */}
          <QuestionArea
            currentQuestion={currentQuestion}
            currentSection={currentSection}
            selectedOption={currentOption}
            onSelectOption={handleSelectOption}
            onSaveAndNext={handleSaveAndNext}
            onMarkForReviewAndNext={handleMarkForReviewAndNext}
            onClearResponse={handleClearResponse}
            onPreviousQuestion={handlePreviousQuestion}
            onSubmitSectionEarly={() => setIsEarlySubmitOpen(true)}
            hasNext={activeQuestionNumber < (currentSection.endIndex + 1)}
            hasPrevious={activeQuestionNumber > (currentSection.startIndex + 1)}
            language={language}
            setLanguage={setLanguage}
            activeQuestionNumber={activeQuestionNumber}
            questionTimeSpentSeconds={currentQTimeSpent}
          />
        </section>

        {/* Right Column (25% width - Question Palette restricted to Active Section) */}
        <aside className="w-full md:w-[25%] h-full bg-[#f0f4f8] flex flex-col overflow-hidden">
          <QuestionPalette
            questions={questions}
            currentSection={currentSection}
            activeQuestionNumber={activeQuestionNumber}
            questionStatuses={questionStatuses}
            onNavigateToQuestion={handleNavigateToQuestion}
            onSubmitTest={() => setIsSubmitModalOpen(true)}
            onSubmitSectionEarly={() => setIsEarlySubmitOpen(true)}
            sectionTimeLeft={sectionalTimeLeft[activeSectionId] ?? 0}
            candidate={candidate}
            isLastSection={isCurrentSectionLast}
          />
        </aside>
      </main>

      {/* Modals */}
      <SectionInfoModal
        isOpen={isInfoModalOpen}
        onClose={() => setIsInfoModalOpen(false)}
      />

      <SubmitModal
        isOpen={isSubmitModalOpen}
        onClose={() => setIsSubmitModalOpen(false)}
        onConfirmSubmit={handleFinalSubmit}
        questions={questions}
        questionStatuses={questionStatuses}
      />

      <ResultModal
        isOpen={isResultModalOpen}
        onRestart={handleRestartTest}
        questions={questions}
        questionStatuses={questionStatuses}
        timeTakenSeconds={TOTAL_EXAM_DURATION_SECONDS - totalTimeLeft}
        attemptId={attemptId}
        isSupabaseConfigured={isSupabaseConfigured}
      />

      <ResumeModal
        isOpen={isResumeModalOpen}
        attemptData={detectedPastAttempt}
        onResume={handleResumePastAttempt}
        onStartFresh={handleStartFreshAttempt}
      />

      <SectionTimeOverModal
        isOpen={isSectionTimeOverOpen}
        completedSection={pendingExpiredSection}
        nextSection={nextSectionObj}
        onProceed={handleProceedAfterSectionOver}
      />

      <EarlySectionSubmitModal
        isOpen={isEarlySubmitOpen}
        onClose={() => setIsEarlySubmitOpen(false)}
        onConfirm={handleConfirmEarlySectionSubmit}
        currentSection={currentSection}
        nextSection={nextSectionObj}
      />

      <SupabaseSettingsModal
        isOpen={isSupabaseModalOpen}
        onClose={() => setIsSupabaseModalOpen(false)}
        onConfigUpdated={() => setIsSupabaseConfigured(getSupabaseConfig().isConfigured)}
      />

      <CustomQuestionsModal
        isOpen={isCustomQuestionsOpen}
        onClose={() => setIsCustomQuestionsOpen(false)}
        onLoadQuestions={(newQs) => {
          setQuestions(newQs);
          setActiveQuestionNumber(1);
          const reset = {};
          newQs.forEach((q, idx) => {
            reset[q.question_number] = {
              status: idx === 0 ? STATUS.NOT_ANSWERED : STATUS.NOT_VISITED,
              selectedOption: null,
              timeSpentSeconds: 0
            };
          });
          setQuestionStatuses(reset);
        }}
      />
    </div>
  );
}
