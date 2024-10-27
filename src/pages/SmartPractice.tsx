import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { fetchSmartPracticeCards, updateCardProgress } from '../services/smartPracticeService';
import { SwipeableCard } from '../components/SwipeableCard';
import LoadingSpinner from '../components/LoadingSpinner';
import { SmartPracticeEmpty } from '../components/SmartPracticeEmpty';
import { SmartPracticeError } from '../components/SmartPracticeError';
import { Brain, Book, Star, GraduationCap } from 'lucide-react';

const statusIcons = {
  new: Book,
  learning: Brain,
  known: Star,
  mastered: GraduationCap,
  'long-term': GraduationCap
};

const statusColors = {
  new: 'text-gray-500',
  learning: 'text-blue-500',
  known: 'text-green-500',
  mastered: 'text-purple-500',
  'long-term': 'text-yellow-500'
};

const statusLabels = {
  new: 'Unknown',
  learning: 'Learning',
  known: 'Known',
  mastered: 'Mastered',
  'long-term': 'Long-term'
};

export function SmartPractice() {
  const { user } = useAuth();
  const queryClient = useQueryClient();
  const [currentIndex, setCurrentIndex] = useState(0);
  const [direction, setDirection] = useState<string | null>(null);
  const [processedCards, setProcessedCards] = useState<Set<string>>(new Set());

  const { data: cards, isLoading, error, refetch } = useQuery({
    queryKey: ['smart-practice', user?.id],
    queryFn: () => user ? fetchSmartPracticeCards(user.id) : Promise.reject('No user'),
    enabled: !!user,
    staleTime: 30000,
    retry: 2,
    refetchOnWindowFocus: false
  });

  const updateProgress = useMutation({
    mutationFn: async ({ flashcardId, correct, responseTime }: { 
      flashcardId: string;
      correct: boolean;
      responseTime: number;
    }) => {
      if (!user) throw new Error('User not authenticated');
      return updateCardProgress({
        userId: user.id,
        flashcardId,
        correct,
        responseTime
      });
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['smart-practice'] });
      queryClient.invalidateQueries({ queryKey: ['progress'] });
    }
  });

  const handleSwipe = async (swipeDirection: 'left' | 'right') => {
    if (!cards || currentIndex >= cards.length || !cards[currentIndex]) return;

    const startTime = performance.now();
    setDirection(swipeDirection);

    try {
      await updateProgress.mutateAsync({
        flashcardId: cards[currentIndex].id,
        correct: swipeDirection === 'right',
        responseTime: Math.round(performance.now() - startTime)
      });

      setProcessedCards(prev => new Set([...prev, cards[currentIndex].id]));

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

  if (error) {
    return (
      <SmartPracticeError 
        error={error as any} 
        onRetry={() => refetch()} 
      />
    );
  }

  if (!cards || cards.length === 0 || currentIndex >= cards.length) {
    return <SmartPracticeEmpty />;
  }

  const currentCard = cards[currentIndex];
  const StatusIcon = statusIcons[currentCard.status as keyof typeof statusIcons] || Book;
  const statusColor = statusColors[currentCard.status as keyof typeof statusColors] || 'text-gray-500';
  const statusLabel = statusLabels[currentCard.status as keyof typeof statusLabels] || 'Unknown';

  return (
    <div className="container mx-auto px-4 py-8">
      <div className="max-w-2xl mx-auto">
        <div className="mb-6 flex justify-between items-center">
          <div className="flex items-center gap-2">
            <StatusIcon className={`h-5 w-5 ${statusColor}`} />
            <span className="text-sm font-medium text-gray-600">
              Status: {statusLabel}
            </span>
          </div>
          <span className="text-sm text-gray-600">
            {currentIndex + 1} / {cards.length}
          </span>
        </div>

        <SwipeableCard
          front={currentCard.front_text}
          back={currentCard.back_text}
          example={currentCard.example_sentence}
          onSwipe={handleSwipe}
          direction={direction}
        />

        {updateProgress.isLoading && (
          <div className="mt-4 text-center text-gray-600">
            <LoadingSpinner />
            <p className="mt-2">Saving progress...</p>
          </div>
        )}
      </div>
    </div>
  );
}

export default SmartPractice;