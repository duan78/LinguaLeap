export interface ProgressStats {
  words_mastered: number;
  total_words: number;
  current_streak: number;
  review_success: number;
  average_score: number;
  unknown_count?: number;
  learning_count?: number;
  known_count?: number;
  mastered_count?: number;
  long_term_count?: number;
}