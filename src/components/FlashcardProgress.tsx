import React from 'react';
import { useFlashcardProgress } from '../hooks/useFlashcardProgress';
import LoadingSpinner from './LoadingSpinner';

interface FlashcardProgressProps {
  flashcardId: string;
  onProgressUpdate: (result: { correct: boolean }) => void;
  isUpdating?: boolean;
}

export function FlashcardProgress({ 
  flashcardId, 
  onProgressUpdate,
  isUpdating 
}: FlashcardProgressProps) {
  const { mutate: updateProgress } = useFlashcardProgress();

  const handleAnswer = async (correct: boolean) => {
    const startTime = performance.now();
    try {
      await updateProgress({
        flashcardId,
        correct,
        responseTime: Math.round(performance.now() - startTime)
      });
      onProgressUpdate({ correct });
    } catch (error) {
      console.error('Failed to update progress:', error);
    }
  };

  return (
    <div className="mt-4 flex justify-center gap-4">
      {isUpdating ? (
        <div className="text-center">
          <LoadingSpinner />
          <p className="mt-2 text-gray-600">Saving progress...</p>
        </div>
      ) : (
        <>
          <button
            onClick={() => handleAnswer(false)}
            className="px-6 py-3 bg-red-500 text-white rounded-lg hover:bg-red-600 transition-colors"
            disabled={isUpdating}
          >
            Still Learning
          </button>
          <button
            onClick={() => handleAnswer(true)}
            className="px-6 py-3 bg-green-500 text-white rounded-lg hover:bg-green-600 transition-colors"
            disabled={isUpdating}
          >
            Got It!
          </button>
        </>
      )}
    </div>
  );
}