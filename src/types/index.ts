// Database entity types
export interface Lesson {
  id: string;
  title: string;
  description: string;
  level: number;
  category: string;
  image_url?: string | null;
  created_at: string;
  updated_at?: string;
}

export interface Flashcard {
  id: string;
  lesson_id: string;
  front: string;
  back: string;
  example_sentence?: string | null;
  audio_url?: string | null;
  created_at: string;
  updated_at?: string;
}

export interface UserProgress {
  user_id: string;
  words_learned: number;
  current_streak: number;
  review_success: number;
  last_practice: string | null;
  created_at: string;
  updated_at?: string;
}

export interface WordProgress {
  id: string;
  user_id: string;
  flashcard_id: string;
  mastery_level: number;
  correct_count: number;
  incorrect_count: number;
  last_reviewed: string;
  next_review: string;
  response_time_ms?: number;
  created_at: string;
  updated_at?: string;
}

// Learning algorithm types
export type MasteryLevel = 0 | 1 | 2 | 3 | 4;

export const MASTERY_LEVELS = {
  UNKNOWN: 0,
  LEARNING: 1,
  KNOWN: 2,
  MASTERED: 3,
  LONG_TERM: 4,
} as const;

export interface MasteryLevelConfig {
  level: MasteryLevel;
  name: string;
  description: string;
  color: string;
  icon: string;
  intervalHours: number;
  minCorrectAnswers: number;
  baseScore: number;
}

// Practice session types
export interface PracticeCard {
  flashcard: Flashcard;
  wordProgress?: WordProgress;
  isDue: boolean;
  priority: number;
}

export interface PracticeSession {
  id: string;
  userId: string;
  startedAt: string;
  endedAt?: string;
  cardsStudied: number;
  correctAnswers: number;
  averageResponseTime: number;
  masteryGains: Record<MasteryLevel, number>;
}

export interface ReviewResult {
  flashcardId: string;
  isCorrect: boolean;
  responseTime: number;
  previousMasteryLevel: MasteryLevel;
  newMasteryLevel: MasteryLevel;
  nextReviewDate: string;
}

// API Response types
export interface ApiResponse<T = unknown> {
  data?: T;
  error?: string;
  message?: string;
  status: number;
}

export interface PaginatedResponse<T> {
  data: T[];
  total: number;
  page: number;
  limit: number;
  hasMore: boolean;
}

// UI Component types
export interface BaseComponentProps {
  className?: string;
  children?: React.ReactNode;
}

export interface ButtonProps extends BaseComponentProps {
  variant?: 'primary' | 'secondary' | 'danger' | 'ghost';
  size?: 'sm' | 'md' | 'lg';
  disabled?: boolean;
  loading?: boolean;
  onClick?: () => void;
  type?: 'button' | 'submit' | 'reset';
}

// Form types
export interface FormField {
  name: string;
  label: string;
  type: 'text' | 'textarea' | 'select' | 'number';
  required?: boolean;
  placeholder?: string;
  options?: Array<{ value: string; label: string }>;
  validation?: {
    min?: number;
    max?: number;
    pattern?: RegExp;
    custom?: (value: any) => string | undefined;
  };
}

export interface FormState {
  values: Record<string, any>;
  errors: Record<string, string>;
  touched: Record<string, boolean>;
  isSubmitting: boolean;
  isValid: boolean;
}

// Utility types
export type Optional<T, K extends keyof T> = Omit<T, K> & Partial<Pick<T, K>>;
export type RequiredFields<T, K extends keyof T> = T & Required<Pick<T, K>>;
export type ID = string;
export type Timestamp = string;

// Error types
export interface AppError {
  code: string;
  message: string;
  details?: Record<string, any>;
  timestamp: string;
}

export interface ValidationError {
  field: string;
  message: string;
  code: string;
}

// Dashboard types
export interface DashboardStats {
  totalWords: number;
  masteredWords: number;
  currentStreak: number;
  reviewsToday: number;
  accuracyRate: number;
  averageResponseTime: number;
}

export interface ProgressChart {
  date: string;
  wordsLearned: number;
  reviewsCompleted: number;
  accuracyRate: number;
}

// Settings types
export interface LearningSettings {
  dailyGoal: number;
  reviewInterval: number;
  maxNewCardsPerDay: number;
  difficultyLevel: number;
  soundEnabled: boolean;
  notificationsEnabled: boolean;
}

// Admin types
export interface AdminStats {
  totalUsers: number;
  activeUsers: number;
  totalLessons: number;
  totalFlashcards: number;
  completionRate: number;
  averageAccuracy: number;
}

// Export all types for easy importing
export type {
  // Re-export commonly used types
  Lesson as LessonType,
  Flashcard as FlashcardType,
  UserProgress as UserProgressType,
  WordProgress as WordProgressType,
  PracticeCard as PracticeCardType,
  PracticeSession as PracticeSessionType,
};