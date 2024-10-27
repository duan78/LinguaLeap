import { useQuery } from '@tanstack/react-query';
import { supabase, retrySupabaseOperation } from '../lib/supabase';
import { useAuth } from '../context/AuthContext';

export interface KeywordState {
  flashcard_id: string;
  keyword: string;
  translation: string;
  example_sentence?: string;
  lesson_title: string;
  current_state: 'unknown' | 'learning' | 'known' | 'mastered' | 'long-term';
  base_score: number;
  actual_score: number;
  total_score: number;
  mastery_level: number;
  last_reviewed: string | null;
  next_review: string | null;
  needs_review: boolean;
}

export function useKeywordStates() {
  const { user } = useAuth();

  return useQuery<{ data: KeywordState[] }>({
    queryKey: ['keyword-states', user?.id],
    queryFn: async () => {
      if (!user) throw new Error('User not authenticated');

      return retrySupabaseOperation(async () => {
        // Fetch only flashcards that have been reviewed (have word_progress entries)
        const { data: flashcards, error: flashcardsError } = await supabase
          .from('flashcards')
          .select(`
            id,
            front_text,
            back_text,
            example_sentence,
            lessons!inner (
              title
            ),
            word_progress!inner (
              state,
              mastery_level,
              score,
              last_reviewed,
              next_review
            )
          `)
          .eq('word_progress.user_id', user.id)
          .order('front_text');

        if (flashcardsError) {
          throw new Error(`Failed to fetch keyword states: ${flashcardsError.message}`);
        }

        if (!flashcards) return { data: [] };

        // Map the results to the expected format
        const keywordStates = flashcards.map(card => ({
          flashcard_id: card.id,
          keyword: card.front_text,
          translation: card.back_text,
          example_sentence: card.example_sentence,
          lesson_title: card.lessons.title,
          current_state: (card.word_progress?.[0]?.state || 'unknown') as KeywordState['current_state'],
          base_score: getBaseScore(card.word_progress?.[0]?.state || 'unknown'),
          actual_score: card.word_progress?.[0]?.score || 0,
          total_score: (card.word_progress?.[0]?.score || 0) + getBaseScore(card.word_progress?.[0]?.state || 'unknown'),
          mastery_level: card.word_progress?.[0]?.mastery_level || 0,
          last_reviewed: card.word_progress?.[0]?.last_reviewed,
          next_review: card.word_progress?.[0]?.next_review,
          needs_review: isNeedingReview(card.word_progress?.[0]?.next_review)
        }));

        return { data: keywordStates };
      });
    },
    enabled: !!user,
    staleTime: 1000, // Reduce stale time to update more frequently
    cacheTime: 0, // Disable caching to ensure fresh data
    refetchOnMount: true,
    refetchOnWindowFocus: true,
    refetchOnReconnect: true,
    retry: 3,
    retryDelay: (attemptIndex) => Math.min(1000 * Math.pow(2, attemptIndex), 10000)
  });
}

function getBaseScore(state: KeywordState['current_state']): number {
  switch (state) {
    case 'learning': return 1;
    case 'known': return 2;
    case 'mastered': return 3;
    case 'long-term': return 4;
    default: return 0;
  }
}

function isNeedingReview(nextReview?: string | null): boolean {
  if (!nextReview) return true;
  return new Date(nextReview) <= new Date();
}