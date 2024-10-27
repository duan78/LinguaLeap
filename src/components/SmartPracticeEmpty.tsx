import React from 'react';
import { Brain } from 'lucide-react';
import { useNavigate } from 'react-router-dom';

export function SmartPracticeEmpty() {
  const navigate = useNavigate();

  return (
    <div className="container mx-auto px-4 py-8 text-center">
      <div className="bg-white p-8 rounded-lg shadow-md inline-block">
        <Brain className="w-12 h-12 text-indigo-600 mx-auto mb-4" />
        <h2 className="text-xl font-semibold mb-4">All Caught Up!</h2>
        <p className="text-gray-600 mb-6">
          You've reviewed all your due cards. Come back later for more practice!
        </p>
        <button
          onClick={() => navigate('/dashboard')}
          className="px-4 py-2 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700 transition-colors"
        >
          Return to Dashboard
        </button>
      </div>
    </div>
  );
}