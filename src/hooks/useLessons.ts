import { useQuery } from '@tanstack/react-query';
import { supabase } from '../lib/supabase';
import { useAuth } from '../context/AuthContext';

export interface Lesson {
  id: string;
  title: string;
  description: string;
  order_index: number;
  flashcard_count: number;
  mastered_count: number;
}

export function useLessons() {
  const { user } = useAuth();

  return useQuery<Lesson[]>({
    queryKey: ['lessons', user?.id],
    queryFn: async () => {
      if (!user) throw new Error('User not authenticated');

      try {
        // Get all lessons
        const { data: lessons, error: lessonsError } = await supabase
          .from('lessons')
          .select('*')
          .order('order_index');

        if (lessonsError) throw lessonsError;

        // For each lesson, calculate completion using the database function
        const lessonsWithProgress = await Promise.all(
          lessons.map(async (lesson) => {
            const { data: completion, error: completionError } = await supabase
              .rpc('calculate_lesson_completion', {
                lesson_id: lesson.id,
                user_id: user.id
              });

            if (completionError) throw completionError;

            return {
              ...lesson,
              flashcard_count: completion?.[0]?.total_flashcards || 0,
              mastered_count: completion?.[0]?.mastered_flashcards || 0
            };
          })
        );

        return lessonsWithProgress;
      } catch (err) {
        const error = err instanceof Error ? err : new Error('Unknown error occurred');
        error.message = `Failed to load lessons: ${error.message}`;
        throw error;
      }
    },
    enabled: !!user,
    staleTime: 30000,
    retry: 3,
    retryDelay: 1000
  });
}