import React from 'react';
import { AlertTriangle, RefreshCw } from 'lucide-react';

interface ErrorFallbackProps {
  error?: Error;
  resetErrorBoundary?: () => void;
  message?: string;
  compact?: boolean;
}

export const ErrorFallback: React.FC<ErrorFallbackProps> = ({
  error,
  resetErrorBoundary,
  message = "Une erreur est survenue",
  compact = false
}) => {
  if (compact) {
    return (
      <div className="flex items-center gap-3 p-4 bg-red-50 border border-red-200 rounded-lg">
        <AlertTriangle className="w-5 h-5 text-red-600 flex-shrink-0" />
        <div className="flex-1">
          <p className="text-sm text-red-800 font-medium">{message}</p>
          {error && (
            <p className="text-xs text-red-600 mt-1">{error.message}</p>
          )}
        </div>
        {resetErrorBoundary && (
          <button
            onClick={resetErrorBoundary}
            className="p-2 text-red-600 hover:bg-red-100 rounded-lg transition-colors"
            title="Réessayer"
          >
            <RefreshCw className="w-4 h-4" />
          </button>
        )}
      </div>
    );
  }

  return (
    <div className="p-6 bg-red-50 border border-red-200 rounded-xl text-center">
      <div className="mx-auto w-12 h-12 bg-red-100 rounded-full flex items-center justify-center mb-4">
        <AlertTriangle className="w-6 h-6 text-red-600" />
      </div>
      <h3 className="text-lg font-semibold text-red-900 mb-2">{message}</h3>
      {error && (
        <p className="text-sm text-red-700 mb-4">{error.message}</p>
      )}
      {resetErrorBoundary && (
        <button
          onClick={resetErrorBoundary}
          className="inline-flex items-center gap-2 bg-red-600 text-white px-4 py-2 rounded-lg hover:bg-red-700 transition-colors"
        >
          <RefreshCw className="w-4 h-4" />
          Réessayer
        </button>
      )}
    </div>
  );
};