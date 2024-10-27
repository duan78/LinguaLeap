import { useMutation, useQueryClient } from '@tanstack/react-query';
import { useAuth } from '../context/AuthContext';
import { updateProgress } from '../services/progressService';
import { toast } from '../components/ui/Toast';
import { retrySupabaseOperation } from '../lib/supabase';

interface ProgressUpdate {
  flashcardId: string;
  correct: boolean;
  responseTime?: number;
}

export function useFlashcardProgress() {
  const { user } = useAuth();
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async ({ flashcardId, correct, responseTime }) => {
      if (!user) {
        throw new Error('Authentication required');
      }

      return retrySupabaseOperation(async () => {
        const result = await updateProgress({
          userId: user.id,
          flashcardId,
          correct,
          responseTime
        });

        // Invalidate all related queries to ensure UI updates
        await Promise.all([
          queryClient.invalidateQueries({ queryKey: ['progress'] }),
          queryClient.invalidateQueries({ queryKey: ['word-progress-stats'] }),
          queryClient.invalidateQueries({ queryKey: ['keyword-states'] }),
          queryClient.invalidateQueries({ queryKey: ['lessons'] }),
          queryClient.invalidateQueries({ queryKey: ['flashcards'] }),
          queryClient.invalidateQueries({ queryKey: ['smart-practice'] })
        ]);

        // Force refetch of keyword states
        await queryClient.refetchQueries({ queryKey: ['keyword-states'] });

        return result;
      });
    },
    onError: (error) => {
      console.error('Error updating flashcard progress:', error);
      toast.error('Failed to update progress. Please try again.');
    }
  });
}