import { supabase, retrySupabaseOperation } from '../lib/supabase';

export interface ProgressUpdate {
  userId: string;
  flashcardId: string;
  correct: boolean;
  responseTime?: number;
}

export interface ProgressResult {
  flashcard_id: string;
  state: string;
  mastery_level: number;
  correct_streak: number;
  review_count: number;
  score: number;
  next_review: string;
}

export async function ensureWordProgress(userId: string): Promise<void> {
  return retrySupabaseOperation(async () => {
    const { error } = await supabase
      .rpc('ensure_word_progress_exists', { user_id: userId });

    if (error) throw error;
  });
}

export async function updateProgress({
  userId,
  flashcardId,
  correct,
  responseTime = 5000
}: ProgressUpdate): Promise<ProgressResult> {
  return retrySupabaseOperation(async () => {
    // Ensure progress exists for this flashcard
    await ensureWordProgress(userId);

    const now = new Date();

    // Get current progress
    const { data: existingProgress, error: fetchError } = await supabase
      .from('word_progress')
      .select('*')
      .eq('user_id', userId)
      .eq('flashcard_id', flashcardId)
      .maybeSingle();

    if (fetchError) throw fetchError;

    // Calculate new values
    const currentStreak = existingProgress?.correct_streak || 0;
    const newStreak = correct ? currentStreak + 1 : 0;
    const reviewCount = (existingProgress?.review_count || 0) + 1;
    const currentMasteryLevel = existingProgress?.mastery_level || 0;

    // Calculate new mastery level
    let newMasteryLevel = currentMasteryLevel;
    if (correct) {
      newMasteryLevel = Math.min(currentMasteryLevel + 1, 5);
    } else {
      newMasteryLevel = Math.max(currentMasteryLevel - 1, 0);
    }

    // Calculate score
    const baseScore = newMasteryLevel;
    const streakBonus = Math.min(newStreak / 5, 1);
    const timeBonus = Math.max(0, Math.min(1, (5000 - responseTime) / 5000));
    const score = Number((baseScore + streakBonus + timeBonus).toFixed(2));

    // Calculate next review date
    const nextReview = new Date(now);
    if (newMasteryLevel >= 4 && newStreak >= 5) {
      nextReview.setDate(nextReview.getDate() + 7); // long-term
    } else if (newMasteryLevel >= 3) {
      nextReview.setDate(nextReview.getDate() + 3); // mastered
    } else if (newMasteryLevel >= 2) {
      nextReview.setDate(nextReview.getDate() + 1); // known
    } else if (newMasteryLevel >= 1) {
      nextReview.setHours(nextReview.getHours() + 4); // learning
    } else {
      nextReview.setHours(nextReview.getHours() + 1); // unknown
    }

    // Update progress
    const { data: updatedProgress, error: updateError } = await supabase
      .from('word_progress')
      .upsert({
        user_id: userId,
        flashcard_id: flashcardId,
        mastery_level: newMasteryLevel,
        correct_streak: newStreak,
        review_count: reviewCount,
        score: score,
        response_time: responseTime,
        last_reviewed: now.toISOString(),
        next_review: nextReview.toISOString()
      }, {
        onConflict: 'user_id,flashcard_id'
      })
      .select()
      .single();

    if (updateError) throw updateError;

    return updatedProgress;
  });
}