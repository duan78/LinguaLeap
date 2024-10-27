import { create } from 'zustand';
import { supabase } from '../lib/supabase';

interface ProgressState {
  stats: {
    wordsMastered: number;
    currentStreak: number;
    reviewSuccess: number;
  } | null;
  isLoading: boolean;
  error: string | null;
  fetchProgress: () => Promise<void>;
  updateProgress: (flashcardId: string, correct: boolean) => Promise<void>;
}

export const useProgressStore = create<ProgressState>((set) => ({
  stats: null,
  isLoading: false,
  error: null,

  fetchProgress: async () => {
    try {
      set({ isLoading: true, error: null });
      const { data: { user } } = await supabase.auth.getUser();
      
      if (!user) throw new Error('Not authenticated');

      const { data, error } = await supabase
        .from('word_progress_stats')
        .select('*')
        .eq('user_id', user.id)
        .single();

      if (error) throw error;

      set({
        stats: {
          wordsMastered: data.words_mastered || 0,
          currentStreak: data.current_streak || 0,
          reviewSuccess: data.review_success || 0
        },
        isLoading: false
      });
    } catch (err) {
      console.error('Error fetching progress:', err);
      set({ error: 'Failed to fetch progress', isLoading: false });
    }
  },

  updateProgress: async (flashcardId: string, correct: boolean) => {
    try {
      set({ isLoading: true, error: null });
      const { data: { user } } = await supabase.auth.getUser();
      
      if (!user) throw new Error('Not authenticated');

      const now = new Date().toISOString();
      const { data: existingProgress, error: fetchError } = await supabase
        .from('word_progress')
        .select('mastery_level')
        .eq('user_id', user.id)
        .eq('flashcard_id', flashcardId)
        .single();

      const currentLevel = existingProgress?.mastery_level || 0;
      const newLevel = correct ? Math.min(currentLevel + 1, 5) : Math.max(currentLevel - 1, 0);

      const { error: upsertError } = await supabase
        .from('word_progress')
        .upsert({
          user_id: user.id,
          flashcard_id: flashcardId,
          mastery_level: newLevel,
          last_reviewed: now,
          next_review: now
        });

      if (upsertError) throw upsertError;

      await useProgressStore.getState().fetchProgress();
      set({ isLoading: false });
    } catch (err) {
      console.error('Error updating progress:', err);
      set({ error: 'Failed to update progress', isLoading: false });
    }
  }
}));