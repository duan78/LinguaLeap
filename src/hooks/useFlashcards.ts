import { useQuery } from '@tanstack/react-query';
import { supabase } from '../lib/supabase';
import { useAuth } from '../context/AuthContext';
import { retrySupabaseOperation } from '../lib/supabase';

interface Flashcard {
  id: string;
  front_text: string;
  back_text: string;
  example_sentence?: string;
  state: string;
  mastery_level: number;
}

export function useFlashcards(lessonId: string) {
  const { user } = useAuth();

  return useQuery<Flashcard[]>({
    queryKey: ['flashcards', lessonId, user?.id],
    queryFn: async () => {
      if (!user) throw new Error('User not authenticated');

      return retrySupabaseOperation(async () => {
        // First get all flashcards for the lesson
        const { data: flashcards, error: flashcardsError } = await supabase
          .from('flashcards')
          .select(`
            id,
            front_text,
            back_text,
            example_sentence,
            word_progress (
              state,
              mastery_level
            )
          `)
          .eq('lesson_id', lessonId)
          .order('created_at');

        if (flashcardsError) {
          throw new Error(`Failed to fetch flashcards: ${flashcardsError.message}`);
        }

        if (!flashcards) {
          return [];
        }

        // Get progress for these flashcards
        const { data: progress, error: progressError } = await supabase
          .from('word_progress')
          .select('*')
          .eq('user_id', user.id)
          .in('flashcard_id', flashcards.map(f => f.id));

        if (progressError) {
          throw new Error(`Failed to fetch progress: ${progressError.message}`);
        }

        // Create a map of progress by flashcard ID
        const progressMap = new Map(
          (progress || []).map(p => [p.flashcard_id, p])
        );

        // Map the results to include progress information
        return flashcards.map(card => ({
          id: card.id,
          front_text: card.front_text,
          back_text: card.back_text,
          example_sentence: card.example_sentence,
          state: progressMap.get(card.id)?.state || 'unknown',
          mastery_level: progressMap.get(card.id)?.mastery_level || 0
        }));
      });
    },
    enabled: !!user && !!lessonId,
    staleTime: 30000, // 30 seconds
    retry: 3,
    retryDelay: (attemptIndex) => Math.min(1000 * Math.pow(2, attemptIndex), 10000),
    refetchOnWindowFocus: false
  });
}