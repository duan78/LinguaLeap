import React, { useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { supabase } from '../lib/supabase';
import { useAuth } from '../context/AuthContext';
import LoadingSpinner from '../components/LoadingSpinner';
import { SwipeableCard } from '../components/SwipeableCard';
import { useFlashcardProgress } from '../hooks/useFlashcardProgress';
import { ErrorBoundary } from '../components/ErrorBoundary';
import { retrySupabaseOperation } from '../lib/supabase';

interface Flashcard {
  id: string;
  front_text: string;
  back_text: string;
  example_sentence?: string;
}

export function VocabularyPractice() {
  const { lessonId } = useParams();
  const navigate = useNavigate();
  const { user } = useAuth();
  const [flashcards, setFlashcards] = useState<Flashcard[]>([]);
  const [currentIndex, setCurrentIndex] = useState(0);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [direction, setDirection] = useState<string | null>(null);
  const { mutate: updateProgress, isLoading: isUpdating } = useFlashcardProgress();

  React.useEffect(() => {
    const fetchFlashcards = async () => {
      if (!lessonId || !user) return;

      try {
        const { data, error } = await retrySupabaseOperation(() => 
          supabase
            .from('flashcards')
            .select('*')
            .eq('lesson_id', lessonId)
            .order('created_at')
        );

        if (error) throw error;
        setFlashcards(data || []);
      } catch (err) {
        console.error('Error fetching flashcards:', err);
        setError('Failed to load flashcards. Please try again.');
      } finally {
        setIsLoading(false);
      }
    };

    fetchFlashcards();
  }, [lessonId, user]);

  const handleSwipe = async (direction: 'left' | 'right') => {
    if (!flashcards[currentIndex] || !user || isUpdating) return;

    setDirection(direction);
    const startTime = performance.now();

    try {
      await updateProgress({
        flashcardId: flashcards[currentIndex].id,
        correct: direction === 'right',
        responseTime: Math.round(performance.now() - startTime)
      });

      // Wait for the card animation
      setTimeout(() => {
        if (currentIndex < flashcards.length - 1) {
          setCurrentIndex(prev => prev + 1);
          setDirection(null);
        } else {
          navigate('/lessons/vocabulary');
        }
      }, 300);
    } catch (err) {
      console.error('Error updating progress:', err);
      setError('Failed to save progress. Please try again.');
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

  if (error) {
    return (
      <div className="text-center py-8">
        <div className="text-red-500 bg-red-50 p-4 rounded-lg inline-block">
          {error}
          <button
            onClick={() => window.location.reload()}
            className="ml-4 underline hover:text-red-700"
          >
            Retry
          </button>
        </div>
      </div>
    );
  }

  if (!flashcards.length) {
    return (
      <div className="text-center py-8">
        <p className="text-gray-600">No flashcards available for this lesson.</p>
        <button
          onClick={() => navigate('/lessons/vocabulary')}
          className="mt-4 px-4 py-2 bg-blue-500 text-white rounded hover:bg-blue-600"
        >
          Back to Lessons
        </button>
      </div>
    );
  }

  return (
    <ErrorBoundary>
      <div className="container mx-auto px-4 py-8">
        <div className="max-w-2xl mx-auto">
          <div className="mb-4 text-right">
            <span className="text-gray-600">
              {currentIndex + 1} / {flashcards.length}
            </span>
          </div>
          <SwipeableCard
            front={flashcards[currentIndex].front_text}
            back={flashcards[currentIndex].back_text}
            example={flashcards[currentIndex].example_sentence}
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
    </ErrorBoundary>
  );
}