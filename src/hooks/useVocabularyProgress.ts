import { useEffect } from 'react';
import { useProgressStore } from '../store/progressStore';

export function useVocabularyProgress() {
  const { fetchProgress, updateProgress, isLoading, error } = useProgressStore();

  useEffect(() => {
    fetchProgress();
  }, [fetchProgress]);

  const handleCardResult = async (correct: boolean) => {
    if (correct) {
      await updateProgress({
        words_learned: useProgressStore.getState().wordsLearned + 1,
        review_success: Math.min(100, useProgressStore.getState().reviewSuccess + 5),
      });
    } else {
      await updateProgress({
        review_success: Math.max(0, useProgressStore.getState().reviewSuccess - 3),
      });
    }
  };

  return {
    handleCardResult,
    isLoading,
    error,
  };
}