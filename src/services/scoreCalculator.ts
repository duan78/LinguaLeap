export function calculateScore(
  mastery_level: number,
  correct_streak: number,
  response_time: number
): number {
  // Base score from mastery level (0-5)
  const baseScore = mastery_level;

  // Bonus from correct streak (up to 1 point)
  const streakBonus = Math.min(correct_streak / 5, 1);

  // Time bonus (up to 1 point)
  // Faster responses (< 3s) get more bonus
  const timeBonus = Math.max(0, Math.min(1, (5000 - response_time) / 5000));

  // Calculate total score
  const totalScore = baseScore + streakBonus + timeBonus;

  // Round to 2 decimal places
  return Number(totalScore.toFixed(2));
}