import { create } from 'zustand';
import { supabase } from '../lib/supabase';

interface Word {
  id: string;
  front_text: string;
  back_text: string;
  example_sentence?: string;
  audio_url?: string;
  lesson_id: string;
}

interface Lesson {
  id: string;
  title: string;
  description: string;
  level: string;
  type: string;
  order_index: number;
}

interface LessonState {
  lessons: Lesson[];
  words: Word[];
  currentLesson: Lesson | null;
  loading: boolean;
  error: string | null;
  fetchLessons: (type: string) => Promise<void>;
  fetchWords: (lessonId: string) => Promise<void>;
  setCurrentLesson: (lesson: Lesson | null) => void;
}

export const useLessonStore = create<LessonState>((set) => ({
  lessons: [],
  words: [],
  currentLesson: null,
  loading: false,
  error: null,

  fetchLessons: async (type: string) => {
    try {
      set({ loading: true, error: null });
      
      const { data, error } = await supabase
        .from('lessons')
        .select('*')
        .eq('type', type)
        .order('order_index', { ascending: true });

      if (error) throw error;

      set({ lessons: data || [], loading: false });
    } catch (error) {
      console.error('Error fetching lessons:', error);
      set({ error: 'Failed to fetch lessons', loading: false });
    }
  },

  fetchWords: async (lessonId: string) => {
    try {
      set({ loading: true, error: null });
      
      const { data: lessonData, error: lessonError } = await supabase
        .from('lessons')
        .select('*')
        .eq('id', lessonId)
        .single();

      if (lessonError) throw lessonError;

      const { data: wordsData, error: wordsError } = await supabase
        .from('words')
        .select('*')
        .eq('lesson_id', lessonId);

      if (wordsError) throw wordsError;

      set({ 
        words: wordsData || [], 
        currentLesson: lessonData,
        loading: false 
      });
    } catch (error) {
      console.error('Error fetching words:', error);
      set({ error: 'Failed to fetch words', loading: false });
    }
  },

  setCurrentLesson: (lesson: Lesson | null) => {
    set({ currentLesson: lesson });
  },
}));