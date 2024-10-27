import React from 'react';
import { KeywordStatesList } from '../components/KeywordStatesList';

export function KeywordStates() {
  return (
    <div className="container mx-auto px-4 py-8">
      <div className="mb-8">
        <h1 className="text-2xl font-bold mb-2">Vocabulary Progress</h1>
        <p className="text-gray-600">
          Track your learning progress and review status for all vocabulary words
        </p>
      </div>
      
      <KeywordStatesList />
    </div>
  );
}

export default KeywordStates;