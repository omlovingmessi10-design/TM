const fs = require('fs');
const path = require('path');

const jsonPath = path.join(__dirname, 'ssc_cgl_mock_test_1.json');
const questions = JSON.parse(fs.readFileSync(jsonPath, 'utf8'));

console.log('Total questions loaded:', questions.length);

// 1. Build balanced target options: exactly 25 a, 25 b, 25 c, 25 d
// Each 25-question section has 6 of each plus 1 extra
const targetOptions = [];
for (let sec = 0; sec < 4; sec++) {
  const extraOpt = ['a', 'b', 'c', 'd'][sec];
  const secOpts = [];
  ['a', 'b', 'c', 'd'].forEach(opt => {
    const count = (opt === extraOpt) ? 7 : 6;
    for (let k = 0; k < count; k++) secOpts.push(opt);
  });
  
  // Shuffle within section
  for (let i = secOpts.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [secOpts[i], secOpts[j]] = [secOpts[j], secOpts[i]];
  }
  targetOptions.push(...secOpts);
}

// 2. Perform the swap for each question
questions.forEach((q, idx) => {
  const oldKey = q.correct_option.toLowerCase();
  const newKey = targetOptions[idx];

  if (oldKey !== newKey) {
    // Swap options in English
    const tempEn = q.options[newKey];
    q.options[newKey] = q.options[oldKey];
    q.options[oldKey] = tempEn;

    // Swap options in Hindi
    if (q.options_hi) {
      const tempHi = q.options_hi[newKey];
      q.options_hi[newKey] = q.options_hi[oldKey];
      q.options_hi[oldKey] = tempHi;
    }

    q.correct_option = newKey;
  }

  // Update Solution Text (English)
  q.solution_text = q.solution_text.replace(/Correct Option:\s*\([a-d]\)/gi, 'Correct Option: (' + newKey + ')');
  q.solution_text = q.solution_text.replace(/Correct Option:\s*([a-d])\b/gi, 'Correct Option: (' + newKey + ')');

  // Update Solution Text (Hindi)
  if (q.solution_text_hi) {
    q.solution_text_hi = q.solution_text_hi.replace(/(उत्तर\s*\()([a-d])(\))/gi, (m, p1, p2, p3) => p1 + newKey + p3);
    q.solution_text_hi = q.solution_text_hi.replace(/(विकल्प\s*\()([a-d])(\))/gi, (m, p1, p2, p3) => p1 + newKey + p3);
    q.solution_text_hi = q.solution_text_hi.replace(/(विकल्प\s+)([a-d])([)\s।,])/gi, (m, p1, p2, p3) => p1 + newKey + p3);
    q.solution_text_hi = q.solution_text_hi.replace(/उत्तर\s+([a-d])\b/gi, 'उत्तर (' + newKey + ')');
  }
});

// Verify distribution
const counts = {};
questions.forEach(q => counts[q.correct_option] = (counts[q.correct_option] || 0) + 1);
console.log('New Correct Option Distribution:', counts);

// Write back to JSON
fs.writeFileSync(jsonPath, JSON.stringify(questions, null, 2), 'utf8');
console.log('Saved updated questions to', jsonPath);
