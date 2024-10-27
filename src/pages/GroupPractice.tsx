import React, { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { useKeywordStates } from '../hooks/useKeywordStates';
import { SwipeableCard } from '../components/SwipeableCard';
import { useFlashcardProgress } from '../hooks/useFlashcardProgress';
import LoadingSpinner from '../components/LoadingSpinner';
import { AlertCircle } from 'lucide-react';

export function GroupPractice() {
  const { group } = useParams<{ group: string }>();
  const navigate = useNavigate();
  const { keywords, isLoading, error, refetch } = useKeywordStates();
  const { mutate: updateProgress, isLoading: isUpdating, error: updateError } = useFlashcardProgress();
  const [processedCards, setProcessedCards] = useState<Set<string>>(new Set());
  const [currentIndex, setCurrentIndex] = useState(0);
  const [direction, setDirection] = useState<string | null>(null);

  // Map URL parameter to state name
  const stateMap: Record<string, string> = {
    'unknown': 'unknown',  // Changed from 'new' to 'unknown'
    'learning': 'learning',
    'known': 'known',
    'memorized': 'mastered',
    'longTerm': 'long-term'
  };

  const currentState = stateMap[group || ''] || 'unknown';  // Changed default from 'new' to 'unknown'

  // Get available cards for the current group
  const availableCards = keywords?.data?.filter(
    card => card.current_state === currentState && !processedCards.has(card.flashcard_id)
  ) || [];

  // Reset state when group changes
  useEffect(() => {
    setProcessedCards(new Set());
    setCurrentIndex(0);
    setDirection(null);
  }, [group]);

  const handleSwipe = async (swipeDirection: 'left' | 'right') => {
    if (isUpdating || direction || !availableCards[currentIndex]) return;

    const currentCard = availableCards[currentIndex];
    const startTime = performance.now();
    setDirection(swipeDirection);

    try {
      await updateProgress({
        flashcardId: currentCard.flashcard_id,
        correct: swipeDirection === 'right',
        responseTime: Math.round(performance.now() - startTime)
      });

      // Mark card as processed
      setProcessedCards(prev => new Set([...prev, currentCard.flashcard_id]));

      // Wait for animation
      setTimeout(() => {
        setDirection(null);
        setCurrentIndex(prev => prev + 1);
      }, 300);

    } catch (err) {
      console.error('Error updating progress:', err);
      setDirection(null);
    }
  };

  if (isLoading) {
    return (
      <div className="flex justify-center items-center min-h-[50vh]">
        <LoadingSpinner />
      </div>
    );
  }

  if (error || updateError) {
    return (
      <div className="container mx-auto px-4 py-8">
        <div className="bg-red-50 border border-red-200 rounded-lg p-6 max-w-xl mx-auto text-center">
          <AlertCircle className="w-12 h-12 text-red-500 mx-auto mb-4" />
          <div className="text-red-600 font-semibold mb-2">
            {error?.message || updateError?.message || 'Failed to load flashcards'}
          </div>
          <button
            onClick={() => refetch()}
            className="px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 transition-colors"
          >
            Try Again
          </button>
        </div>
      </div>
    );
  }

  if (availableCards.length === 0) {
    return (
      <div className="text-center py-8">
        <p className="text-gray-600">
          {processedCards.size > 0 
            ? 'All cards in this group have been reviewed!'
            : 'No flashcards available in this group.'}
        </p>
        <button
          onClick={() => navigate('/progress')}
          className="mt-4 px-4 py-2 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700"
        >
          Return to Progress
        </button>
      </div>
    );
  }

  if (currentIndex >= availableCards.length) {
    return (
      <div className="text-center py-8">
        <p className="text-gray-600">Session complete! You've reviewed all cards.</p>
        <div className="mt-2 text-sm text-gray-500">
          Total cards reviewed: {processedCards.size}
        </div>
        <button
          onClick={() => navigate('/progress')}
          className="mt-4 px-4 py-2 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700"
        >
          Return to Progress
        </button>
      </div>
    );
  }

  const currentCard = availableCards[currentIndex];
  const remainingCount = availableCards.length - currentIndex;

  return (
    <div className="container mx-auto px-4 py-8">
      <div className="max-w-2xl mx-auto">
        <div className="mb-4 flex justify-between items-center">
          <span className="text-gray-600">
            Group: {currentState.charAt(0).toUpperCase() + currentState.slice(1).replace('-', ' ')}
          </span>
          <span className="text-gray-600">
            Remaining: {remainingCount}
          </span>
        </div>
        <SwipeableCard
          front={currentCard.keyword}
          back={currentCard.translation}
          example={currentCard.example_sentence}
          onSwipe={handleSwipe}
          direction={direction}
        />
        {isUpdating && (
          <div className="mt-4 text-center text-gray-600">
            <LoadingSpinner />
            <p className="mt-2">Saving progress...</p>
          </div>
        )}
      </div>
    </div>
  );
}