import { useCallback } from 'react';
import { useMutation, useQuery } from '@tanstack/react-query';
import { AppError } from '@/types';

interface ErrorOptions {
  showToast?: boolean;
  logToConsole?: boolean;
  reportToService?: boolean;
  customMessage?: string;
}

// Hook pour la gestion d'erreurs centralisée
export const useErrorHandler = () => {
  const handleError = useCallback((error: unknown, options: ErrorOptions = {}) => {
    const {
      showToast = true,
      logToConsole = true,
      reportToService = true,
      customMessage
    } = options;

    // Normaliser l'erreur
    let normalizedError: AppError;

    if (error instanceof Error) {
      normalizedError = {
        code: 'UNKNOWN_ERROR',
        message: customMessage || error.message,
        timestamp: new Date().toISOString(),
      };
    } else if (typeof error === 'string') {
      normalizedError = {
        code: 'STRING_ERROR',
        message: customMessage || error,
        timestamp: new Date().toISOString(),
      };
    } else if (error && typeof error === 'object' && 'message' in error) {
      normalizedError = {
        code: 'OBJECT_ERROR',
        message: customMessage || (error as any).message || 'Erreur inconnue',
        timestamp: new Date().toISOString(),
      };
    } else {
      normalizedError = {
        code: 'UNKNOWN_ERROR',
        message: customMessage || 'Une erreur inconnue est survenue',
        timestamp: new Date().toISOString(),
      };
    }

    // Logger dans la console
    if (logToConsole) {
      console.error('Application Error:', normalizedError, error);
    }

    // Reporter au service de monitoring
    if (reportToService) {
      // Integration avec des services comme Sentry, LogRocket, etc.
      // Sentry.captureException(error, { extra: { normalizedError } });
    }

    // Afficher une notification (à implémenter avec votre système de toast)
    if (showToast) {
      // showToast(normalizedError.message, { type: 'error' });
      console.warn('Toast notification:', normalizedError.message);
    }

    return normalizedError;
  }, []);

  // Hook pour les mutations avec gestion d'erreur
  const useMutationWithError = <TData, TError, TVariables>(
    mutationFn: (variables: TVariables) => Promise<TData>,
    options: ErrorOptions = {}
  ) => {
    return useMutation({
      mutationFn,
      onError: (error: TError, variables: TVariables) => {
        handleError(error, options);
      },
      retry: (failureCount, error: any) => {
        // Ne pas retry pour les erreurs 4xx
        if (error?.status >= 400 && error?.status < 500) {
          return false;
        }
        return failureCount < 2;
      },
    });
  };

  // Hook pour les queries avec gestion d'erreur
  const useQueryWithError = <TData>(
    queryKey: string[],
    queryFn: () => Promise<TData>,
    options: ErrorOptions & {
      enabled?: boolean;
      staleTime?: number;
      cacheTime?: number;
    } = {}
  ) => {
    const {
      onError,
      ...queryOptions
    } = options;

    return useQuery({
      queryKey,
      queryFn,
      onError: (error: unknown) => {
        handleError(error, options);
        onError?.(error);
      },
      ...queryOptions,
    });
  };

  return {
    handleError,
    useMutationWithError,
    useQueryWithError,
  };
};

// Utilitaire pour créer des messages d'erreur conviviaux
export const getErrorMessage = (error: unknown): string => {
  if (error instanceof Error) {
    return error.message;
  }

  if (typeof error === 'string') {
    return error;
  }

  if (error && typeof error === 'object' && 'message' in error) {
    return (error as any).message || 'Une erreur est survenue';
  }

  return 'Une erreur inconnue est survenue';
};

// Utilitaire pour les erreurs réseau
export const isNetworkError = (error: unknown): boolean => {
  if (error instanceof Error) {
    return (
      error.message.includes('Network Error') ||
      error.message.includes('fetch') ||
      error.message.includes('Failed to fetch')
    );
  }
  return false;
};

// Utilitaire pour les erreurs d'authentification
export const isAuthError = (error: unknown): boolean => {
  if (error && typeof error === 'object' && 'status' in error) {
    const status = (error as any).status;
    return status === 401 || status === 403;
  }
  return false;
};

// Types pour les erreurs Supabase
export interface SupabaseError {
  message: string;
  status: number;
  code?: string;
  details?: string;
}

export const isSupabaseError = (error: unknown): error is SupabaseError => {
  return (
    error &&
    typeof error === 'object' &&
    'message' in error &&
    'status' in error
  );
};

export default useErrorHandler;