export interface Lesson {
  id: string;
  title: string;
  description: string;
  level: number;
  category: string;
  image_url?: string;
  created_at: string;
}

export interface Flashcard {
  id: string;
  lesson_id: string;
  front: string;
  back: string;
  example_sentence?: string;
  audio_url?: string;
  created_at: string;
}

export interface UserProgress {
  user_id: string;
  words_learned: number;
  current_streak: number;
  review_success: number;
  last_practice: string;
  created_at: string;
}