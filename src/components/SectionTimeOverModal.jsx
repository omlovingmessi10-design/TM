import React, { useEffect, useState } from 'react';
import { Clock, ArrowRight, CheckCircle2 } from 'lucide-react';

export default function SectionTimeOverModal({
  isOpen,
  completedSection,
  nextSection,
  onProceed
}) {
  const [countdown, setCountdown] = useState(4);

  useEffect(() => {
    if (!isOpen) {
      setCountdown(4);
      return;
    }

    const timer = setInterval(() => {
      setCountdown((prev) => {
        if (prev <= 1) {
          clearInterval(timer);
          onProceed();
          return 0;
        }
        return prev - 1;
      });
    }, 1000);

    return () => clearInterval(timer);
  }, [isOpen, onProceed]);

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/80 backdrop-blur-xs p-4 animate-fade-in">
      <div className="bg-white rounded-xl shadow-2xl max-w-md w-full overflow-hidden border border-gray-300 text-center">
        {/* Top bar */}
        <div className="bg-rose-600 text-white p-4 flex flex-col items-center">
          <div className="w-12 h-12 rounded-full bg-white/20 flex items-center justify-center mb-2">
            <Clock className="w-7 h-7 text-white animate-pulse" />
          </div>
          <h3 className="text-base font-bold">Sectional Time Expired!</h3>
          <p className="text-xs text-rose-100">15 Minutes Allocation Complete</p>
        </div>

        {/* Content */}
        <div className="p-6 space-y-4 text-xs sm:text-sm text-gray-700">
          <div className="bg-gray-50 border border-gray-200 p-3 rounded-lg text-left space-y-1">
            <div className="flex items-center text-gray-600 text-xs">
              <CheckCircle2 className="w-4 h-4 text-emerald-600 mr-1.5 shrink-0" />
              <span>Section finalized: <strong className="text-gray-900">{completedSection?.title}</strong></span>
            </div>
            {nextSection ? (
              <div className="flex items-center text-blue-900 text-xs font-semibold pt-1 border-t border-gray-200">
                <ArrowRight className="w-4 h-4 text-blue-600 mr-1.5 shrink-0" />
                <span>Next section: <strong className="text-[#1b4d89]">{nextSection.title}</strong></span>
              </div>
            ) : (
              <div className="text-emerald-700 font-bold pt-1 border-t border-gray-200">
                All 4 sections have completed. Proceeding to final test submission.
              </div>
            )}
          </div>

          <p className="text-xs text-gray-500">
            As per SSC examination regulations, you cannot return to completed sections.
          </p>

          <div className="text-xs font-semibold text-gray-600">
            Automatically transitioning in <span className="font-bold text-rose-600 text-sm">{countdown}s</span>...
          </div>
        </div>

        {/* Footer */}
        <div className="bg-gray-50 p-4 border-t border-gray-200">
          <button
            onClick={onProceed}
            className="w-full py-2.5 px-4 bg-[#1b4d89] hover:bg-[#153e6e] text-white text-xs font-bold rounded shadow transition flex items-center justify-center space-x-2"
          >
            <span>{nextSection ? 'Proceed to Next Section Now' : 'Submit Final Test'}</span>
            <ArrowRight className="w-4 h-4" />
          </button>
        </div>
      </div>
    </div>
  );
}
