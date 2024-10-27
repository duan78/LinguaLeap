import { useQuery } from '@tanstack/react-query';
import { useAuth } from '../context/AuthContext';
import { FetchError, SmartFlashcard } from '../types/smartPractice';
import { fetchSmartPracticeCards } from '../services/smartPracticeService';

const RETRY_ATTEMPTS = 3;
const STALE_TIME = 5 * 60 * 1000; // 5 minutes

export function useSmartFlashcards(enabled = true) {
  const { user } = useAuth();

  return useQuery<SmartFlashcard[], FetchError>({
    queryKey: ['smart-practice', user?.id],
    queryFn: async () => {
      if (!user) {
        const authError = new Error('Authentication required') as FetchError;
        authError.details = 'Please sign in to use Smart Practice';
        throw authError;
      }
      return fetchSmartPracticeCards(user.id);
    },
    enabled: !!user && enabled,
    retry: RETRY_ATTEMPTS,
    retryDelay: (attemptIndex) => Math.min(1000 * Math.pow(2, attemptIndex), 10000),
    staleTime: STALE_TIME,
    refetchOnWindowFocus: false,
    refetchOnMount: true,
    refetchOnReconnect: true
  });
}