export type LearningState = 'new' | 'learning' | 'known' | 'mastered' | 'long-term';

export const REVIEW_INTERVALS = {
  new: 1,
  learning: 2,
  known: 4,
  mastered: 10,
  'long-term': 30
} as const;

export const STATE_REQUIREMENTS = {
  learning: { consecutiveCorrect: 1 },
  known: { consecutiveCorrect: 3 },
  mastered: { consecutiveCorrect: 5 },
  'long-term': { consecutiveCorrect: 10, maxResponseTime: 5000 }
} as const;

export interface CardProgress {
  state: LearningState;
  score: number;
  consecutiveCorrect: number;
  totalReviews: number;
  correctReviews: number;
  responseTime?: number;
  lastReviewDate: Date;
  nextReviewDate: Date;
}