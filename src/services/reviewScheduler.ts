export async function calculateNextReview(state: string, lastReview: Date): Promise<Date> {
  const nextReview = new Date(lastReview);

  switch (state) {
    case 'unknown':  // Changed from 'new' to 'unknown'
      nextReview.setHours(nextReview.getHours() + 1);
      break;
    case 'learning':
      nextReview.setHours(nextReview.getHours() + 4);
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
      nextReview.setHours(nextReview.getHours() + 2);
  }

  return nextReview;
}