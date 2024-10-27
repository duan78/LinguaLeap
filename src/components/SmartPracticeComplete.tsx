import React from 'react';
import { useNavigate } from 'react-router-dom';
import { Brain } from 'lucide-react';

export function SmartPracticeComplete() {
  const navigate = useNavigate();

  return (
    <div className="text-center py-8">
      <div className="bg-green-50 p-8 rounded-lg inline-block">
        <Brain className="w-12 h-12 text-green-500 mx-auto mb-4" />
        <h2 className="text-xl font-semibold mb-2">All Caught Up!</h2>
        <p className="text-gray-600 mb-4">
          You've reviewed all the cards that are due. Come back later for more practice!
        </p>
        <button
          onClick={() => navigate('/dashboard')}
          className="px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700"
        >
          Return to Dashboard
        </button>
      </div>
    </div>
  );
}