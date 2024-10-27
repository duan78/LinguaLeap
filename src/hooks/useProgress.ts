import { useQuery, useQueryClient } from '@tanstack/react-query';
import { supabase, retrySupabaseOperation } from '../lib/supabase';
import { useAuth } from '../context/AuthContext';
import type { ProgressStats } from '../types/progress';

export function useProgress() {
  const { user } = useAuth();
  const queryClient = useQueryClient();

  return useQuery<ProgressStats>({
    queryKey: ['word-progress-stats', user?.id],
    queryFn: async () => {
      if (!user) throw new Error('User not authenticated');

      return retrySupabaseOperation(async () => {
        const { data, error } = await supabase
          .from('word_progress_stats')
          .select('*')
          .eq('user_id', user.id)
          .maybeSingle();

        if (error) {
          throw new Error(`Failed to fetch progress data: ${error.message}`);
        }

        if (!data) {
          return {
            total_words: 0,
            words_mastered: 0,
            current_streak: 0,
            review_success: 0,
            average_score: 0,
            unknown_count: 0,
            learning_count: 0,
            known_count: 0,
            mastered_count: 0,
            long_term_count: 0
          };
        }

        return data;
      });
    },
    enabled: !!user,
    staleTime: 1000, // Reduce stale time to update more frequently
    cacheTime: 0, // Disable caching to ensure fresh data
    refetchOnMount: true,
    refetchOnWindowFocus: true,
    refetchOnReconnect: true
  });
}