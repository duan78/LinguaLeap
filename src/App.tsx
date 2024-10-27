import React from 'react';
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { AuthProvider, useAuth } from './context/AuthContext';
import { Layout } from './components/Layout';
import { Home } from './pages/Home';
import { Auth } from './pages/Auth';
import { Dashboard } from './pages/Dashboard';
import LessonList from './pages/LessonList';
import { VocabularyPractice } from './pages/VocabularyPractice';
import { SmartPractice } from './pages/SmartPractice';
import { Admin } from './pages/Admin';
import { KeywordStates } from './pages/KeywordStates';
import { GroupPractice } from './pages/GroupPractice';
import { LearningSettings } from './pages/admin/LearningSettings';
import { ErrorBoundary } from './components/ErrorBoundary';

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      retry: 1,
      refetchOnWindowFocus: false,
    },
  },
});

function ProtectedRoute({ children }: { children: React.ReactNode }) {
  const { user } = useAuth();
  return user ? children : <Navigate to="/auth" />;
}

export default function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <AuthProvider>
        <BrowserRouter>
          <Routes>
            <Route path="/" element={<Layout />}>
              <Route index element={<Home />} />
              <Route path="auth" element={<Auth />} />
              <Route
                path="dashboard"
                element={
                  <ProtectedRoute>
                    <ErrorBoundary>
                      <Dashboard />
                    </ErrorBoundary>
                  </ProtectedRoute>
                }
              />
              <Route
                path="lessons/vocabulary"
                element={
                  <ProtectedRoute>
                    <ErrorBoundary>
                      <LessonList />
                    </ErrorBoundary>
                  </ProtectedRoute>
                }
              />
              <Route
                path="practice/vocabulary/:lessonId"
                element={
                  <ProtectedRoute>
                    <ErrorBoundary>
                      <VocabularyPractice />
                    </ErrorBoundary>
                  </ProtectedRoute>
                }
              />
              <Route
                path="practice/group/:group"
                element={
                  <ProtectedRoute>
                    <ErrorBoundary>
                      <GroupPractice />
                    </ErrorBoundary>
                  </ProtectedRoute>
                }
              />
              <Route
                path="practice/smart"
                element={
                  <ProtectedRoute>
                    <ErrorBoundary>
                      <SmartPractice />
                    </ErrorBoundary>
                  </ProtectedRoute>
                }
              />
              <Route
                path="progress"
                element={
                  <ProtectedRoute>
                    <ErrorBoundary>
                      <KeywordStates />
                    </ErrorBoundary>
                  </ProtectedRoute>
                }
              />
              <Route path="admin" element={<Admin />} />
              <Route
                path="admin/learning-settings"
                element={
                  <ProtectedRoute>
                    <ErrorBoundary>
                      <LearningSettings />
                    </ErrorBoundary>
                  </ProtectedRoute>
                }
              />
            </Route>
          </Routes>
        </BrowserRouter>
      </AuthProvider>
    </QueryClientProvider>
  );
}