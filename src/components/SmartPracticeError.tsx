import React from 'react';
import { AlertCircle } from 'lucide-react';
import { FetchError } from '../types/smartPractice';

interface SmartPracticeErrorProps {
  error: FetchError;
  onRetry: () => void;
}

export function SmartPracticeError({ error, onRetry }: SmartPracticeErrorProps) {
  return (
    <div className="container mx-auto px-4 py-8">
      <div className="bg-red-50 border border-red-200 rounded-lg p-6 max-w-xl mx-auto text-center">
        <AlertCircle className="w-12 h-12 text-red-500 mx-auto mb-4" />
        <div className="text-red-600 font-semibold mb-2">
          {error.message}
        </div>
        {error.details && (
          <div className="text-red-500 text-sm mb-4">
            {error.details}
          </div>
        )}
        <button
          onClick={onRetry}
          className="px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 transition-colors"
        >
          Try Again
        </button>
      </div>
    </div>
  );
}