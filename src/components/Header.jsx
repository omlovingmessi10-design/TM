import React, { useState } from 'react';
import { Clock, Globe, User, Maximize2, Minimize2, Database, CloudCheck, Check } from 'lucide-react';

export default function Header({
  sectionTimeLeft,
  totalTimeLeft,
  language,
  setLanguage,
  candidate = {
    name: "ANKIT SHARMA",
    rollNo: "2201048291",
    systemNo: "C9-LAB3-042",
    photoUrl: null
  },
  activeSectionTitle,
  isSupabaseConfigured,
  isSynced,
  onOpenSupabaseModal,
  testTitle = "SSC CGL Tier 1 Mock Test 3"
}) {
  const [isFullscreen, setIsFullscreen] = useState(false);

  // Format time mm:ss
  const formatTime = (seconds) => {
    const mins = Math.floor(Math.max(0, seconds) / 60);
    const secs = Math.max(0, seconds) % 60;
    return `${String(mins).padStart(2, '0')}:${String(secs).padStart(2, '0')}`;
  };

  const toggleFullscreen = () => {
    if (!document.fullscreenElement) {
      document.documentElement.requestFullscreen().catch(() => {});
      setIsFullscreen(true);
    } else {
      if (document.exitFullscreen) {
        document.exitFullscreen().catch(() => {});
        setIsFullscreen(false);
      }
    }
  };

  const isLowSectionTime = sectionTimeLeft <= 120; // Under 2 minutes in section

  return (
    <header className="bg-[#1b4d89] text-white shadow-md select-none border-b border-[#0d3463] sticky top-0 z-40">
      <div className="px-3 sm:px-4 py-2 flex items-center justify-between gap-3">
        {/* Left: Exam Title & SSC Crest */}
        <div className="flex items-center space-x-2.5 min-w-0">
          <div className="w-9 h-9 rounded-full bg-white/10 border border-white/20 flex items-center justify-center shrink-0 shadow-inner">
            <svg className="w-5 h-5 text-yellow-300" viewBox="0 0 24 24" fill="currentColor">
              <path d="M12 2L15.09 8.26L22 9.27L17 14.14L18.18 21.02L12 17.77L5.82 21.02L7 14.14L2 9.27L8.91 8.26L12 2Z" />
            </svg>
          </div>
          <div className="truncate">
            <div className="flex items-center space-x-2">
              <h1 className="text-sm sm:text-base font-bold tracking-tight text-white leading-tight truncate">
                {testTitle}
              </h1>
              <span className="text-[10px] bg-amber-400 text-blue-950 px-1.5 py-0.2 rounded font-black tracking-wide hidden sm:inline">
                SECTIONAL TIMED
              </span>
            </div>
            <p className="text-[11px] text-blue-200 hidden sm:block truncate">
              Current: <span className="font-semibold text-white">{activeSectionTitle}</span> (Strict Section Locking)
            </p>
          </div>
        </div>

        {/* Right Controls */}
        <div className="flex items-center space-x-2 sm:space-x-4 shrink-0">
          {/* Supabase Sync Status Indicator & Trigger */}
          <button
            onClick={onOpenSupabaseModal}
            title={isSupabaseConfigured ? "Connected to Supabase (Auto-syncing attempts & question timing)" : "Click to connect Supabase Database"}
            className="flex items-center space-x-1.5 px-2 py-1 rounded bg-black/20 hover:bg-black/35 border border-white/15 transition text-xs"
          >
            <Database className={`w-3.5 h-3.5 ${isSupabaseConfigured ? 'text-emerald-400' : 'text-gray-300'}`} />
            <span className="text-[10px] hidden md:inline font-medium text-blue-100">
              {isSupabaseConfigured ? (isSynced ? 'Supabase Synced' : 'Syncing...') : 'Connect Supabase'}
            </span>
            {isSupabaseConfigured && isSynced && (
              <span className="w-1.5 h-1.5 rounded-full bg-emerald-400"></span>
            )}
          </button>

          {/* Section Time Left (Primary Countdown) */}
          <div className={`flex items-center px-2.5 sm:px-3 py-1 rounded border transition-colors ${
            isLowSectionTime 
              ? 'bg-red-600/90 border-red-400 animate-pulse text-white' 
              : 'bg-black/30 border-blue-300/30 text-amber-300'
          }`}>
            <Clock className={`w-4 h-4 mr-1.5 sm:mr-2 shrink-0 ${isLowSectionTime ? 'text-white' : 'text-amber-400'}`} />
            <div className="text-right">
              <span className="text-[9px] text-blue-200 block uppercase font-bold leading-none">Section Time</span>
              <span className="text-sm sm:text-base font-mono font-bold tracking-wider">
                {formatTime(sectionTimeLeft)}
              </span>
            </div>
          </div>

          {/* Total Exam Time (Secondary) */}
          <div className="hidden lg:flex items-center px-2.5 py-1 rounded bg-black/20 border border-white/10 text-gray-200">
            <div className="text-right">
              <span className="text-[9px] text-gray-300 block uppercase font-bold leading-none">Total Time</span>
              <span className="text-xs font-mono font-bold text-gray-100">
                {formatTime(totalTimeLeft)}
              </span>
            </div>
          </div>

          {/* Language Selector */}
          <div className="flex items-center space-x-1 bg-white/10 px-2 py-1 rounded border border-white/20">
            <Globe className="w-3.5 h-3.5 text-blue-200 shrink-0" />
            <select
              value={language}
              onChange={(e) => setLanguage(e.target.value)}
              className="bg-transparent text-xs font-semibold text-white focus:outline-none cursor-pointer pr-1"
              id="header-language-toggle"
            >
              <option value="en" className="text-gray-900 bg-white">English</option>
              <option value="hi" className="text-gray-900 bg-white">हिन्दी</option>
            </select>
          </div>

          {/* Fullscreen Button */}
          <button
            onClick={toggleFullscreen}
            title={isFullscreen ? "Exit Fullscreen" : "Enter Fullscreen"}
            className="p-1.5 hover:bg-white/15 rounded text-blue-100 hover:text-white transition hidden md:block"
          >
            {isFullscreen ? <Minimize2 className="w-4 h-4" /> : <Maximize2 className="w-4 h-4" />}
          </button>

          {/* Candidate Profile Snippet */}
          <div className="flex items-center space-x-2 pl-2 sm:pl-3 border-l border-white/20">
            <div className="w-8 h-8 rounded-full bg-white/90 border border-white/80 overflow-hidden flex items-center justify-center shrink-0 shadow">
              {candidate.photoUrl ? (
                <img src={candidate.photoUrl} alt="Candidate" className="w-full h-full object-cover" />
              ) : (
                <div className="w-full h-full bg-gradient-to-br from-blue-100 to-indigo-200 flex items-center justify-center text-blue-800 font-bold text-xs">
                  {candidate.name.split(' ').map(n => n[0]).join('')}
                </div>
              )}
            </div>
            <div className="text-left hidden xl:block leading-tight">
              <div className="text-xs font-bold text-white tracking-wide">{candidate.name}</div>
              <div className="text-[10px] text-blue-200">Roll: {candidate.rollNo}</div>
            </div>
          </div>
        </div>
      </div>
    </header>
  );
}
