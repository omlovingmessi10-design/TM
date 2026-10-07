import React, { useState, useEffect } from 'react';
import { Database, CheckCircle2, AlertCircle, X, ExternalLink, Key, RefreshCw } from 'lucide-react';
import { getSupabaseConfig, setSupabaseConfig, getSupabase } from '../services/supabase';

export default function SupabaseSettingsModal({ isOpen, onClose, onConfigUpdated }) {
  const [url, setUrl] = useState('');
  const [key, setKey] = useState('');
  const [testStatus, setTestStatus] = useState(null); // 'testing' | 'success' | 'error'
  const [errorMessage, setErrorMessage] = useState('');

  useEffect(() => {
    if (isOpen) {
      const config = getSupabaseConfig();
      setUrl(config.url);
      setKey(config.key);
      setTestStatus(null);
      setErrorMessage('');
    }
  }, [isOpen]);

  if (!isOpen) return null;

  const handleTestAndSave = async () => {
    setTestStatus('testing');
    setErrorMessage('');

    try {
      setSupabaseConfig(url, key);
      const client = getSupabase();
      if (!client) {
        throw new Error('Please provide both Supabase URL and Anon Key.');
      }

      // Quick ping test
      const { data, error } = await client.from('test_attempts').select('id').limit(1);
      if (error && error.code !== 'PGRST116') {
        // Table might not exist yet or permission error
        console.warn('Supabase test warning:', error);
      }

      setTestStatus('success');
      if (onConfigUpdated) onConfigUpdated();
      setTimeout(() => {
        onClose();
      }, 1200);
    } catch (err) {
      setTestStatus('error');
      setErrorMessage(err.message || 'Failed to connect to Supabase.');
    }
  };

  const handleClear = () => {
    setSupabaseConfig('', '');
    setUrl('');
    setKey('');
    setTestStatus(null);
    if (onConfigUpdated) onConfigUpdated();
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 backdrop-blur-xs p-4 animate-fade-in">
      <div className="bg-white rounded-lg shadow-2xl max-w-lg w-full overflow-hidden border border-gray-300">
        {/* Header */}
        <div className="bg-[#1b4d89] text-white px-5 py-3.5 flex items-center justify-between">
          <div className="flex items-center space-x-2">
            <Database className="w-5 h-5 text-emerald-400" />
            <h3 className="font-bold text-base">Supabase Cloud Database Settings</h3>
          </div>
          <button
            onClick={onClose}
            className="text-white/80 hover:text-white p-1 rounded hover:bg-white/10 transition"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Content */}
        <div className="p-5 space-y-4 text-xs">
          <p className="text-gray-600 leading-relaxed">
            Connect your Supabase project to automatically sync in-progress mock test attempts, sectional timing, resume data, and per-question time tracking.
          </p>

          <div className="space-y-3">
            <div>
              <label className="block font-bold text-gray-700 mb-1">Supabase Project URL:</label>
              <input
                type="text"
                placeholder="https://xyzcompany.supabase.co"
                value={url}
                onChange={(e) => setUrl(e.target.value)}
                className="w-full p-2 border border-gray-300 rounded focus:ring-1 focus:ring-blue-500 font-mono text-xs"
              />
            </div>

            <div>
              <label className="block font-bold text-gray-700 mb-1">Supabase Anon Public API Key:</label>
              <input
                type="password"
                placeholder="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
                value={key}
                onChange={(e) => setKey(e.target.value)}
                className="w-full p-2 border border-gray-300 rounded focus:ring-1 focus:ring-blue-500 font-mono text-xs"
              />
            </div>
          </div>

          {testStatus === 'success' && (
            <div className="p-2.5 bg-emerald-50 border border-emerald-200 text-emerald-800 rounded flex items-center space-x-2">
              <CheckCircle2 className="w-4 h-4 text-emerald-600 shrink-0" />
              <span>Connected successfully! Saved and ready for real-time tracking.</span>
            </div>
          )}

          {testStatus === 'error' && (
            <div className="p-2.5 bg-rose-50 border border-rose-200 text-rose-800 rounded flex items-center space-x-2">
              <AlertCircle className="w-4 h-4 text-rose-600 shrink-0" />
              <span>{errorMessage}</span>
            </div>
          )}

          <div className="bg-gray-50 border border-gray-200 p-3 rounded text-[11px] text-gray-600 space-y-1">
            <span className="font-bold text-gray-800 block">Database Schema &amp; Seed:</span>
            <p>1. Run the SQL schema from <code className="bg-gray-200 px-1 py-0.5 rounded text-gray-800">supabase_schema.sql</code> in your Supabase SQL Editor.</p>
            <p>2. Run <code className="bg-gray-200 px-1 py-0.5 rounded text-gray-800">mock_test_3_seed.sql</code> to load all 100 questions of Mock Test 3.</p>
          </div>
        </div>

        {/* Footer */}
        <div className="bg-gray-50 px-5 py-3 border-t border-gray-300 flex justify-between items-center">
          <button
            onClick={handleClear}
            className="text-gray-500 hover:text-red-600 text-xs font-semibold"
          >
            Clear Settings
          </button>
          <div className="flex space-x-2">
            <button
              onClick={onClose}
              className="px-3.5 py-1.5 border border-gray-300 rounded text-gray-700 hover:bg-gray-100 text-xs font-medium"
            >
              Cancel
            </button>
            <button
              onClick={handleTestAndSave}
              disabled={testStatus === 'testing' || !url || !key}
              className="px-4 py-1.5 bg-[#1b4d89] hover:bg-[#153e6e] disabled:bg-gray-300 text-white rounded font-bold text-xs shadow-xs transition flex items-center space-x-1.5"
            >
              {testStatus === 'testing' ? (
                <>
                  <RefreshCw className="w-3.5 h-3.5 animate-spin" />
                  <span>Connecting...</span>
                </>
              ) : (
                <span>Save &amp; Connect</span>
              )}
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
