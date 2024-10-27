import { supabase } from '../lib/supabase';
import type { SmartFlashcard } from '../types/smartPractice';

export async function fetchSmartPracticeCards(userId: string): Promise<SmartFlashcard[]> {
  try {
    // Get all flashcards with their progress
    const { data: flashcardsWithProgress, error: progressError } = await supabase
      .from('word_progress')
      .select(`
        flashcard_id,
        state,
        next_review,
        mastery_level,
        correct_streak,
        review_count,
        flashcards (
          id,
          front_text,
          back_text,
          example_sentence
        )
      `)
      .eq('user_id', userId)
      .order('next_review', { ascending: true });

    if (progressError) throw progressError;

    // Get new cards (cards without progress)
    const { data: existingIds } = await supabase
      .from('word_progress')
      .select('flashcard_id')
      .eq('user_id', userId);

    const existingFlashcardIds = existingIds?.map(p => p.flashcard_id) || [];

    // Get new cards if there are existing IDs to filter
    let newCards = [];
    if (existingFlashcardIds.length > 0) {
      const { data: newCardsData, error: newCardsError } = await supabase
        .from('flashcards')
        .select('*')
        .not('id', 'in', `(${existingFlashcardIds.join(',')})`);

      if (newCardsError) throw newCardsError;
      newCards = newCardsData || [];
    } else {
      // If no existing progress, get all flashcards
      const { data: allCards, error: allCardsError } = await supabase
        .from('flashcards')
        .select('*');

      if (allCardsError) throw allCardsError;
      newCards = allCards || [];
    }

    // Format cards with progress
    const cardsWithProgress: SmartFlashcard[] = (flashcardsWithProgress || [])
      .filter(card => card.flashcards)
      .map(card => ({
        id: card.flashcards.id,
        front_text: card.flashcards.front_text,
        back_text: card.flashcards.back_text,
        example_sentence: card.flashcards.example_sentence,
        status: card.state || 'new',
        mastery_level: card.mastery_level || 0,
        correct_streak: card.correct_streak || 0,
        review_count: card.review_count || 0,
        next_review: card.next_review || new Date().toISOString()
      }));

    // Format new cards
    const formattedNewCards: SmartFlashcard[] = newCards.map(card => ({
      id: card.id,
      front_text: card.front_text,
      back_text: card.back_text,
      example_sentence: card.example_sentence,
      status: 'new',
      mastery_level: 0,
      correct_streak: 0,
      review_count: 0,
      next_review: new Date().toISOString()
    }));

    // Combine and sort all cards
    // Due cards first, then new cards
    return [
      ...cardsWithProgress.filter(card => new Date(card.next_review) <= new Date()),
      ...formattedNewCards,
      ...cardsWithProgress.filter(card => new Date(card.next_review) > new Date())
    ];

  } catch (error) {
    console.error('Error fetching smart practice cards:', error);
    throw error;
  }
}

export async function updateCardProgress(params: {
  userId: string;
  flashcardId: string;
  correct: boolean;
  responseTime: number;
}): Promise<{
  status: string;
  mastery_level: number;
  correct_streak: number;
  review_count: number;
  next_review: string;
}> {
  const { userId, flashcardId, correct, responseTime } = params;
  const now = new Date().toISOString();

  try {
    // Get current progress and learning settings
    const [progressResult, settingsResult] = await Promise.all([
      supabase
        .from('word_progress')
        .select('*')
        .eq('user_id', userId)
        .eq('flashcard_id', flashcardId)
        .maybeSingle(),
      supabase
        .from('learning_settings')
        .select('*')
        .order('min_mastery_level')
    ]);

    if (progressResult.error) throw progressResult.error;
    if (settingsResult.error) throw settingsResult.error;

    const existingProgress = progressResult.data;
    const learningSettings = settingsResult.data || [];

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

    // Determine new status based on mastery level and settings
    let newStatus = 'new';
    for (const setting of learningSettings.reverse()) {
      if (newMasteryLevel >= setting.min_mastery_level && 
          newStreak >= setting.min_correct_streak && 
          reviewCount >= setting.min_review_count) {
        newStatus = setting.state;
        break;
      }
    }

    // Calculate next review date based on settings
    const currentSetting = learningSettings.find(s => s.state === newStatus);
    const nextReview = new Date();
    if (currentSetting?.next_review_delay) {
      const [value, unit] = currentSetting.next_review_delay.split(' ');
      const hours = unit.startsWith('hour') ? parseInt(value) :
                   unit.startsWith('day') ? parseInt(value) * 24 :
                   unit.startsWith('week') ? parseInt(value) * 24 * 7 : 1;
      nextReview.setHours(nextReview.getHours() + hours);
    }

    // Update progress
    const { data: updatedProgress, error: updateError } = await supabase
      .from('word_progress')
      .upsert({
        user_id: userId,
        flashcard_id: flashcardId,
        state: newStatus,
        mastery_level: newMasteryLevel,
        correct_streak: newStreak,
        review_count: reviewCount,
        response_time: responseTime,
        last_reviewed: now,
        next_review: nextReview.toISOString()
      }, {
        onConflict: 'user_id,flashcard_id'
      })
      .select()
      .single();

    if (updateError) throw updateError;

    return {
      status: newStatus,
      mastery_level: newMasteryLevel,
      correct_streak: newStreak,
      review_count: reviewCount,
      next_review: nextReview.toISOString()
    };

  } catch (error) {
    console.error('Error updating card progress:', error);
    throw error;
  }
}