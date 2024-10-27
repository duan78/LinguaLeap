import React from 'react';
import { useProgress } from '../hooks/useProgress';
import { DashboardStats } from '../components/DashboardStats';
import { LearningPathways } from '../components/LearningPathways';
import { AlertCircle } from 'lucide-react';
import LoadingSpinner from '../components/LoadingSpinner';

export function Dashboard() {
  const { 
    data: progress, 
    isLoading: progressLoading, 
    error: progressError,
    refetch: refetchProgress 
  } = useProgress();

  if (progressLoading) {
    return (
      <div className="flex justify-center items-center min-h-[50vh]">
        <LoadingSpinner />
      </div>
    );
  }

  if (progressError) {
    return (
      <div className="bg-red-50 border border-red-200 rounded-lg p-4 max-w-2xl mx-auto">
        <div className="flex items-center gap-2 text-red-600 mb-2">
          <AlertCircle className="h-5 w-5" />
          <h3 className="font-semibold">Error Loading Dashboard</h3>
        </div>
        <div className="text-red-700 text-sm mb-4">
          {progressError.message}
        </div>
        <button 
          onClick={() => refetchProgress()}
          className="px-4 py-2 bg-red-600 text-white rounded hover:bg-red-700 transition-colors"
        >
          Try Again
        </button>
      </div>
    );
  }

  return (
    <div className="container mx-auto px-4 py-8">
      {/* Welcome Section */}
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-gray-900 mb-2">Welcome Back!</h1>
        <p className="text-gray-600">
          Track your progress and continue your language learning journey.
        </p>
      </div>

      {/* Stats Overview */}
      {progress && <DashboardStats progress={progress} />}

      {/* Learning Pathways */}
      <div className="bg-white rounded-lg shadow-md p-6">
        <h2 className="text-xl font-bold mb-6">Learning Pathways</h2>
        <LearningPathways 
          masteredCount={progress?.mastered_count || 0}
          unknownCount={progress?.unknown_count || 0}
          learningCount={progress?.learning_count || 0}
          knownCount={progress?.known_count || 0}
          longTermCount={progress?.long_term_count || 0}
        />
      </div>
    </div>
  );
}