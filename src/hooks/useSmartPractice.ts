import { useQuery } from '@tanstack/react-query';
import { useAuth } from '../context/AuthContext';
import { SmartFlashcard, FetchError } from '../types/smartPractice';
import { fetchSmartPracticeCards } from '../services/smartPracticeService';
import { checkSupabaseConnection } from '../lib/supabase';

export function useSmartPractice() {
  const { user } = useAuth();

  return useQuery<SmartFlashcard[], FetchError>({
    queryKey: ['smart-practice', user?.id],
    queryFn: async () => {
      if (!user) {
        const error = new Error('Authentication required') as FetchError;
        error.details = 'Please sign in to use Smart Practice';
        throw error;
      }

      // Check connection before attempting to fetch
      const isConnected = await checkSupabaseConnection();
      if (!isConnected) {
        const error = new Error('Database connection error') as FetchError;
        error.details = 'Unable to connect to the database. Please check your internet connection and try again.';
        throw error;
      }

      return fetchSmartPracticeCards(user.id);
    },
    enabled: !!user,
    staleTime: 30000, // 30 seconds
    retry: 3,
    retryDelay: (attemptIndex) => Math.min(1000 * Math.pow(2, attemptIndex), 10000),
    refetchOnWindowFocus: false,
    refetchOnMount: true,
    refetchOnReconnect: true
  });
}