import React from 'react';
import { AlertTriangle, X, ArrowRight } from 'lucide-react';

export default function EarlySectionSubmitModal({
  isOpen,
  onClose,
  onConfirm,
  currentSection,
  nextSection
}) {
  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 backdrop-blur-xs p-4 animate-fade-in">
      <div className="bg-white rounded-lg shadow-2xl max-w-md w-full overflow-hidden border border-gray-300">
        <div className="bg-amber-600 text-white px-5 py-3.5 flex items-center justify-between">
          <div className="flex items-center space-x-2">
            <AlertTriangle className="w-5 h-5 text-yellow-200" />
            <h3 className="font-bold text-base">Submit Section Early?</h3>
          </div>
          <button
            onClick={onClose}
            className="text-white/80 hover:text-white p-1 rounded hover:bg-white/10 transition"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        <div className="p-5 space-y-3 text-xs sm:text-sm text-gray-700">
          <p>
            You are about to submit <strong className="text-gray-900">{currentSection?.title}</strong> before the 15 minutes allocation expires.
          </p>

          <div className="bg-amber-50 border border-amber-300 p-3 rounded text-amber-900 text-xs space-y-1">
            <strong className="block text-amber-950 font-bold">Important SSC Examination Rules:</strong>
            <p>1. Once submitted, this section will be permanently locked and you <strong>cannot return</strong> to change any answers.</p>
            <p>2. Unused time for this section does <strong>not</strong> get added to the next section.</p>
            {nextSection && (
              <p>3. You will immediately proceed to <strong>{nextSection.title}</strong> with a fresh 15-minute timer.</p>
            )}
          </div>
        </div>

        <div className="bg-gray-50 px-5 py-3 border-t border-gray-300 flex justify-between items-center">
          <button
            onClick={onClose}
            className="px-3.5 py-1.5 border border-gray-300 text-gray-700 hover:bg-gray-100 text-xs font-semibold rounded"
          >
            Cancel &amp; Continue Section
          </button>
          <button
            onClick={onConfirm}
            className="px-4 py-1.5 bg-amber-600 hover:bg-amber-700 text-white text-xs font-bold rounded shadow transition flex items-center space-x-1"
          >
            <span>Confirm &amp; Proceed</span>
            <ArrowRight className="w-3.5 h-3.5" />
          </button>
        </div>
      </div>
    </div>
  );
}
