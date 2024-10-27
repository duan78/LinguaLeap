export interface SmartFlashcard {
  id: string;
  front_text: string;
  back_text: string;
  example_sentence?: string;
  status: 'new' | 'learning' | 'known' | 'mastered' | 'long-term';
  mastery_level: number;
  correct_streak: number;
  review_count: number;
  next_review: string;
}

export interface LearningSetting {
  id: string;
  name: string;
  description: string;
  state: string;
  min_mastery_level: number;
  min_correct_streak: number;
  min_review_count: number;
  score_weight: number;
  next_review_delay: string;
}

export interface FetchError extends Error {
  details?: string;
}