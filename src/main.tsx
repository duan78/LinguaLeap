import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import App from './App';
import './index.css';
import { ErrorBoundary } from '@/components/ui/ErrorBoundary';
import { getQueryClient } from '@/lib/queryClient';

// Create query client instance
const queryClient = getQueryClient();

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <ErrorBoundary
      onError={(error, errorInfo) => {
        // Log error to monitoring service
        console.error('Application error:', error, errorInfo);

        // You could integrate with error tracking services here
        // Sentry.captureException(error, { contexts: { react: { componentStack: errorInfo.componentStack } } });
      }}
    >
      <QueryClientProvider client={queryClient}>
        <App />
      </QueryClientProvider>
    </ErrorBoundary>
  </StrictMode>
);