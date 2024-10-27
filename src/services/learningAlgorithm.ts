import { supabase } from '../lib/supabase';

interface LearningState {
  status: string;
  mastery_level: number;
  correct_streak: number;
  review_count: number;
}

export async function determineNextState(
  currentState: LearningState,
  correct: boolean,
  responseTime: number
): Promise<LearningState> {
  try {
    // Get learning settings
    const { data: settings, error: settingsError } = await supabase
      .from('learning_settings')
      .select('*')
      .order('min_mastery_level', { ascending: true });

    if (settingsError) throw settingsError;

    let newState = { ...currentState };
    
    // Update streak
    newState.correct_streak = correct ? currentState.correct_streak + 1 : 0;
    
    // Find the highest matching state based on requirements
    const matchingState = settings?.reverse().find(setting => 
      newState.correct_streak >= setting.min_correct_streak &&
      newState.review_count >= setting.min_review_count &&
      (responseTime <= setting.max_response_time || !setting.max_response_time)
    );

    if (matchingState) {
      newState.status = matchingState.state;
      newState.mastery_level = matchingState.min_mastery_level;
    } else {
      // Fallback to basic progression
      if (!correct) {
        newState.status = 'new';
        newState.mastery_level = Math.max(0, currentState.mastery_level - 1);
      } else if (newState.correct_streak >= 5) {
        newState.status = 'long-term';
        newState.mastery_level = 5;
      } else if (newState.correct_streak >= 3) {
        newState.status = 'mastered';
        newState.mastery_level = 4;
      } else if (newState.correct_streak >= 2) {
        newState.status = 'known';
        newState.mastery_level = 3;
      } else {
        newState.status = 'learning';
        newState.mastery_level = Math.min(2, currentState.mastery_level + 1);
      }
    }

    return newState;
  } catch (error) {
    console.error('Error determining next state:', error);
    throw error;
  }
}

export async function calculateNextReview(status: string, now: Date): Promise<Date> {
  try {
    // Get review interval for the status
    const { data: setting, error: settingError } = await supabase
      .from('learning_settings')
      .select('next_review_delay')
      .eq('state', status)
      .single();

    if (settingError) throw settingError;

    const nextReview = new Date(now);
    
    if (setting?.next_review_delay) {
      const [value, unit] = setting.next_review_delay.split(' ');
      const hours = unit.startsWith('hour') ? parseInt(value) :
                   unit.startsWith('day') ? parseInt(value) * 24 :
                   unit.startsWith('week') ? parseInt(value) * 24 * 7 : 1;
      nextReview.setHours(nextReview.getHours() + hours);
    } else {
      // Fallback intervals if settings not found
      switch (status) {
        case 'new':
          nextReview.setHours(nextReview.getHours() + 1);
          break;
        case 'learning':
          nextReview.setHours(nextReview.getHours() + 6);
          break;
        case 'known':
          nextReview.setDate(nextReview.getDate() + 1);
          break;
        case 'mastered':
          nextReview.setDate(nextReview.getDate() + 3);
          break;
        case 'long-term':
          nextReview.setDate(nextReview.getDate() + 7);
          break;
        default:
          nextReview.setHours(nextReview.getHours() + 1);
      }
    }

    return nextReview;
  } catch (error) {
    console.error('Error calculating next review:', error);
    throw error;
  }
}

export function calculateScore(
  mastery_level: number,
  correct_streak: number,
  response_time: number
): number {
  // Base score from mastery level (0-5)
  let score = mastery_level;
  
  // Bonus from correct streak (up to 1 point)
  score += Math.min(correct_streak / 5, 1);
  
  // Time bonus (up to 1 point)
  // Perfect score for responses under 2 seconds
  // No bonus for responses over 10 seconds
  if (response_time < 10000) {
    const timeBonus = Math.max(0, (10000 - response_time) / 8000);
    score += timeBonus;
  }
  
  return Math.round(score * 100) / 100; // Round to 2 decimal places
}