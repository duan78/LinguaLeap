interface ProgressState {
  state: string;
  mastery_level: number;
  correct_streak: number;
  review_count: number;
}

interface StateResult {
  state: string;
  mastery_level: number;
}

export async function determineNextState(
  current: ProgressState,
  correct: boolean,
  response_time: number
): Promise<StateResult> {
  // Reset or increment mastery level based on correctness
  let newMasteryLevel = correct
    ? Math.min(current.mastery_level + 1, 5)
    : Math.max(current.mastery_level - 1, 0);

  // Determine new state based on mastery level and performance
  let newState: string;

  if (newMasteryLevel === 0) {
    newState = 'unknown';  // Changed from 'new' to 'unknown'
  } else if (newMasteryLevel >= 4 && current.correct_streak >= 5 && response_time < 3000) {
    newState = 'long-term';
  } else if (newMasteryLevel >= 3) {
    newState = 'mastered';
  } else if (newMasteryLevel >= 2) {
    newState = 'known';
  } else {
    newState = 'learning';
  }

  return {
    state: newState,
    mastery_level: newMasteryLevel
  };
}