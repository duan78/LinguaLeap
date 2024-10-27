import { useMutation, useQueryClient } from '@tanstack/react-query';
import { supabase } from '../lib/supabase';
import { useAuth } from '../context/AuthContext';
import { LearningState, REVIEW_INTERVALS, STATE_REQUIREMENTS } from '../types/srs';

interface ReviewResult {
  flashcardId: string;
  result: {
    correct: boolean;
    responseTime: number;
  };
}

export function useSRS() {
  const { user } = useAuth();
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async ({ flashcardId, result }: ReviewResult) => {
      if (!user) throw new Error('User not authenticated');

      const now = new Date();

      // Get current progress
      const { data: existingProgress, error: fetchError } = await supabase
        .from('word_progress')
        .select('*')
        .eq('user_id', user.id)
        .eq('flashcard_id', flashcardId)
        .maybeSingle();

      if (fetchError) throw fetchError;

      // Initialize or update progress values
      const currentState = existingProgress?.state || 'new';
      const consecutiveCorrect = result.correct 
        ? (existingProgress?.consecutive_correct || 0) + 1 
        : 0;
      const totalReviews = (existingProgress?.total_reviews || 0) + 1;
      const correctReviews = (existingProgress?.correct_reviews || 0) + (result.correct ? 1 : 0);
      const currentScore = existingProgress?.score || 0;

      // Calculate new score with time bonus
      let newScore = currentScore;
      if (result.correct) {
        newScore += 1;
        if (result.responseTime < 5000) {
          const timeBonus = 0.1 * ((5000 - result.responseTime) / 1000);
          newScore += Math.min(timeBonus, 1);
        }
      } else {
        newScore = Math.max(0, newScore - 1);
      }

      // Determine new state based on performance
      let newState: LearningState = currentState;
      
      if (!result.correct && consecutiveCorrect === 0) {
        newState = 'new';
      } else if (consecutiveCorrect >= STATE_REQUIREMENTS['long-term'].consecutiveCorrect && 
                 result.responseTime <= STATE_REQUIREMENTS['long-term'].maxResponseTime) {
        newState = 'long-term';
      } else if (consecutiveCorrect >= STATE_REQUIREMENTS.mastered.consecutiveCorrect) {
        newState = 'mastered';
      } else if (consecutiveCorrect >= STATE_REQUIREMENTS.known.consecutiveCorrect) {
        newState = 'known';
      } else if (consecutiveCorrect >= STATE_REQUIREMENTS.learning.consecutiveCorrect) {
        newState = 'learning';
      }

      // Calculate next review date based on state
      const nextReview = new Date(now);
      nextReview.setDate(nextReview.getDate() + REVIEW_INTERVALS[newState]);

      // Update progress
      const { error: updateError } = await supabase
        .from('word_progress')
        .upsert({
          user_id: user.id,
          flashcard_id: flashcardId,
          state: newState,
          score: Number(newScore.toFixed(2)),
          consecutive_correct: consecutiveCorrect,
          total_reviews: totalReviews,
          correct_reviews: correctReviews,
          response_time: result.responseTime,
          last_reviewed: now.toISOString(),
          next_review: nextReview.toISOString()
        });

      if (updateError) throw updateError;

      return {
        state: newState,
        score: newScore,
        consecutiveCorrect,
        nextReview
      };
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['progress'] });
      queryClient.invalidateQueries({ queryKey: ['lessons'] });
      queryClient.invalidateQueries({ queryKey: ['flashcards'] });
    }
  });
}