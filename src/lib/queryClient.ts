import { QueryClient } from '@tanstack/react-query';

// Configuration optimisée pour React Query
export const createQueryClient = () => {
  return new QueryClient({
    defaultOptions: {
      queries: {
        // Temps de stale par défaut (5 minutes)
        staleTime: 5 * 60 * 1000,

        // Temps avant de considérer la query comme ancienne (10 minutes)
        cacheTime: 10 * 60 * 1000,

        // Retry configuration
        retry: (failureCount, error: any) => {
          // Ne pas retry pour les erreurs 4xx (client errors)
          if (error?.status >= 400 && error?.status < 500) {
            return false;
          }

          // Max 3 retries pour les autres erreurs
          return failureCount < 3;
        },

        // Retry delay avec backoff exponentiel
        retryDelay: (attemptIndex) => Math.min(1000 * 2 ** attemptIndex, 30000),

        // Refetch on window focus (optimisé pour le mobile)
        refetchOnWindowFocus: false,

        // Refetch on reconnect
        refetchOnReconnect: true,

        // Refetch interval pour les données en temps réel
        refetchInterval: false,

        // Erreur retry
        throwOnError: false,

        // Placeholder data
        placeholderData: undefined,
      },

      mutations: {
        // Retry pour les mutations
        retry: 1,

        // Mutation timeout
        mutationTimeout: 30000,

        // Throw on error
        throwOnError: false,

        // Mutation delay
        useErrorBoundary: false,
      },
    },
  });
};

// Instance singleton
let queryClient: QueryClient | null = null;

export const getQueryClient = () => {
  if (!queryClient) {
    queryClient = createQueryClient();
  }
  return queryClient;
};

// Clés de query standardisées
export const queryKeys = {
  // User related
  user: ['user'] as const,
  userProgress: (userId: string) => ['user', userId, 'progress'] as const,
  userSettings: (userId: string) => ['user', userId, 'settings'] as const,

  // Lessons
  lessons: ['lessons'] as const,
  lesson: (id: string) => ['lessons', id] as const,
  lessonFlashcards: (lessonId: string) => ['lessons', lessonId, 'flashcards'] as const,
  lessonProgress: (lessonId: string, userId: string) =>
    ['lessons', lessonId, 'progress', userId] as const,

  // Flashcards
  flashcards: ['flashcards'] as const,
  flashcard: (id: string) => ['flashcards', id] as const,
  flashcardProgress: (flashcardId: string, userId: string) =>
    ['flashcards', flashcardId, 'progress', userId] as const,

  // Practice
  practiceCards: (userId: string) => ['practice', 'cards', userId] as const,
  practiceStats: (userId: string) => ['practice', 'stats', userId] as const,

  // Dashboard
  dashboardStats: (userId: string) => ['dashboard', 'stats', userId] as const,
  recentProgress: (userId: string) => ['dashboard', 'recent', userId] as const,

  // Admin
  adminLessons: ['admin', 'lessons'] as const,
  adminFlashcards: ['admin', 'flashcards'] as const,
  adminUsers: ['admin', 'users'] as const,
  adminStats: ['admin', 'stats'] as const,
} as const;

// Types pour les mutations
export interface MutationOptions<TData = unknown, TError = Error, TVariables = void> {
  onSuccess?: (data: TData, variables: TVariables) => void;
  onError?: (error: TError, variables: TVariables) => void;
  onSettled?: (data: TData | undefined, error: TError | null, variables: TVariables) => void;
}

// Utilitaires pour les mutations optimistiques
export const createOptimisticMutation = <TData, TError, TVariables>(
  queryKey: string[],
  updateFn: (oldData: unknown, variables: TVariables) => TData
) => ({
  onMutate: async (variables: TVariables) => {
    // Cancel any outgoing refetches
    await getQueryClient().cancelQueries({ queryKey });

    // Snapshot the previous value
    const previousData = getQueryClient().getQueryData(queryKey);

    // Optimistically update to the new value
    getQueryClient().setQueryData(queryKey, (old: unknown) =>
      updateFn(old, variables)
    );

    return { previousData };
  },
  onError: (err: TError, variables: TVariables, context: any) => {
    // If the mutation fails, use the context returned from onMutate to roll back
    if (context?.previousData) {
      getQueryClient().setQueryData(queryKey, context.previousData);
    }
  },
  onSettled: () => {
    // Always refetch after error or success
    getQueryClient().invalidateQueries({ queryKey });
  },
});

export default queryClient;