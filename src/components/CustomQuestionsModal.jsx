import React, { useState } from 'react';
import { Upload, FileText, CheckCircle, AlertCircle, X, Sparkles } from 'lucide-react';

export default function CustomQuestionsModal({
  isOpen,
  onClose,
  onLoadQuestions
}) {
  const [jsonText, setJsonText] = useState('');
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');

  if (!isOpen) return null;

  const handleFileUpload = (e) => {
    const file = e.target.files?.[0];
    if (!file) return;

    const reader = new FileReader();
    reader.onload = (event) => {
      try {
        const content = event.target?.result;
        setJsonText(content);
        setError('');
      } catch (err) {
        setError('Failed to read file: ' + err.message);
      }
    };
    reader.readAsText(file);
  };

  const handleApply = () => {
    setError('');
    setSuccess('');
    try {
      const parsed = JSON.parse(jsonText);
      if (!Array.isArray(parsed) || parsed.length === 0) {
        throw new Error('JSON must be an array of questions.');
      }
      onLoadQuestions(parsed);
      setSuccess(`Successfully loaded ${parsed.length} questions!`);
      setTimeout(() => {
        onClose();
      }, 1000);
    } catch (err) {
      setError('Invalid JSON format: ' + err.message);
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 backdrop-blur-xs p-4 animate-fade-in">
      <div className="bg-white rounded-lg shadow-2xl max-w-xl w-full overflow-hidden border border-gray-300">
        <div className="bg-[#1b4d89] text-white px-5 py-3.5 flex items-center justify-between">
          <div className="flex items-center space-x-2">
            <Sparkles className="w-5 h-5 text-yellow-300" />
            <h3 className="font-bold text-base">Load Custom Questions (JSON)</h3>
          </div>
          <button
            onClick={onClose}
            className="text-white/80 hover:text-white p-1 rounded hover:bg-white/10 transition"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        <div className="p-5 space-y-4 text-xs">
          <p className="text-gray-600">
            You can paste your questions JSON directly below, or upload a JSON file. The test will immediately update with your questions.
          </p>

          <div>
            <label className="block font-bold text-gray-700 mb-1">Upload JSON File:</label>
            <input
              type="file"
              accept=".json"
              onChange={handleFileUpload}
              className="block w-full text-xs text-gray-500 file:mr-3 file:py-1.5 file:px-3 file:rounded file:border-0 file:text-xs file:font-semibold file:bg-blue-50 file:text-blue-700 hover:file:bg-blue-100 cursor-pointer"
            />
          </div>

          <div>
            <label className="block font-bold text-gray-700 mb-1">Or Paste JSON Content:</label>
            <textarea
              rows={8}
              value={jsonText}
              onChange={(e) => setJsonText(e.target.value)}
              placeholder='[ { "question_number": 1, "question_text": "...", "options": { "a": "...", "b": "...", "c": "...", "d": "..." } } ]'
              className="w-full font-mono text-[11px] p-2.5 border border-gray-300 rounded focus:ring-1 focus:ring-blue-500 focus:outline-none"
            />
          </div>

          {error && (
            <div className="p-2.5 bg-red-50 border border-red-200 text-red-700 rounded flex items-center space-x-2">
              <AlertCircle className="w-4 h-4 shrink-0" />
              <span>{error}</span>
            </div>
          )}

          {success && (
            <div className="p-2.5 bg-green-50 border border-green-200 text-green-700 rounded flex items-center space-x-2">
              <CheckCircle className="w-4 h-4 shrink-0" />
              <span>{success}</span>
            </div>
          )}
        </div>

        <div className="bg-gray-50 px-5 py-3 border-t border-gray-300 flex justify-between items-center">
          <button
            onClick={onClose}
            className="px-3.5 py-1.5 text-xs font-semibold text-gray-600 hover:text-gray-800"
          >
            Cancel
          </button>
          <button
            onClick={handleApply}
            disabled={!jsonText.trim()}
            className="px-4 py-2 bg-[#1b4d89] hover:bg-[#153e6e] disabled:bg-gray-300 text-white font-bold rounded shadow transition text-xs"
          >
            Load Questions
          </button>
        </div>
      </div>
    </div>
  );
}
