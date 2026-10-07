import mockTest3Data from './mockTest3.json';
import mockTest1Data from './defaultQuestions.json';

export const SECTION_DURATION_SECONDS = 15 * 60; // 15 minutes per section (strict SSC CBT rule)
export const TOTAL_EXAM_DURATION_SECONDS = 60 * 60; // 60 minutes total (100 Qs, 200 Marks)

export const SECTIONS = [
  {
    id: 'gi',
    part: 'PART - 1',
    title: 'General Intelligence & Reasoning',
    shortTitle: 'General Intelligence',
    totalQuestions: 25,
    maxMarks: 50,
    positiveMarks: 2.0,
    negativeMarks: 0.5,
    startIndex: 0,
    endIndex: 24,
    order: 0,
  },
  {
    id: 'ga',
    part: 'PART - 2',
    title: 'General Awareness',
    shortTitle: 'General Awareness',
    totalQuestions: 25,
    maxMarks: 50,
    positiveMarks: 2.0,
    negativeMarks: 0.5,
    startIndex: 25,
    endIndex: 49,
    order: 1,
  },
  {
    id: 'qa',
    part: 'PART - 3',
    title: 'Quantitative Aptitude',
    shortTitle: 'Quantitative Aptitude',
    totalQuestions: 25,
    maxMarks: 50,
    positiveMarks: 2.0,
    negativeMarks: 0.5,
    startIndex: 50,
    endIndex: 74,
    order: 2,
  },
  {
    id: 'ec',
    part: 'PART - 4',
    title: 'English Comprehension',
    shortTitle: 'English Comprehension',
    totalQuestions: 25,
    maxMarks: 50,
    positiveMarks: 2.0,
    negativeMarks: 0.5,
    startIndex: 75,
    endIndex: 99,
    order: 3,
  },
];

export const STATUS = {
  NOT_VISITED: 'NOT_VISITED', // Silver / White
  NOT_ANSWERED: 'NOT_ANSWERED', // Red
  ANSWERED: 'ANSWERED', // Green
  MARKED_FOR_REVIEW: 'MARKED_FOR_REVIEW', // Purple
  ANSWERED_AND_MARKED: 'ANSWERED_AND_MARKED', // Purple with a Green Tick
};

// Default loads Mock Test 3 as requested
export const getDefaultQuestions = () => {
  return mockTest3Data;
};

export const getMockTest1Questions = () => {
  return mockTest1Data;
};
