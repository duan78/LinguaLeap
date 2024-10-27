import React, { useEffect } from 'react';
import { Link } from 'react-router-dom';
import { Book, Brain, GraduationCap, Star, Clock, RefreshCw } from 'lucide-react';
import { useKeywordStates } from '../hooks/useKeywordStates';
import LoadingSpinner from './LoadingSpinner';
import { ensureWordProgress } from '../services/progressService';
import { useAuth } from '../context/AuthContext';

const stateIcons = {
  unknown: Book,
  learning: Brain,
  known: GraduationCap,
  mastered: Star,
  'long-term': Clock
};

const stateColors = {
  unknown: 'text-gray-500',
  learning: 'text-blue-500',
  known: 'text-green-500',
  mastered: 'text-purple-500',
  'long-term': 'text-yellow-500'
};

export function KeywordStatesList() {
  const { user } = useAuth();
  const { data, isLoading, error, refetch } = useKeywordStates();
  const keywords = data?.data || [];

  useEffect(() => {
    if (user) {
      ensureWordProgress(user.id).catch(console.error);
    }
  }, [user]);

  if (isLoading) {
    return <LoadingSpinner />;
  }

  if (error) {
    return (
      <div className="bg-red-50 border border-red-200 rounded-lg p-6 text-center">
        <div className="text-red-600 font-semibold mb-2">
          Error loading keyword states: {error.message}
        </div>
        <button
          onClick={() => refetch()}
          className="inline-flex items-center px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700"
        >
          <RefreshCw className="w-4 h-4 mr-2" />
          Retry
        </button>
      </div>
    );
  }

  if (!keywords.length) {
    return (
      <div className="text-center py-8">
        <p>No vocabulary words found. Start learning by visiting the lessons page!</p>
        <Link
          to="/lessons/vocabulary"
          className="mt-4 inline-block px-4 py-2 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700"
        >
          Go to Lessons
        </Link>
      </div>
    );
  }

  // Calculate counts for each state
  const stateCounts = keywords.reduce((acc, keyword) => {
    const state = keyword.current_state;
    acc[state] = (acc[state] || 0) + 1;
    return acc;
  }, {} as Record<string, number>);

  // Calculate total words and average score
  const totalWords = keywords.length;
  const averageScore = keywords.reduce((sum, keyword) => sum + keyword.total_score, 0) / totalWords;
  const dueForReview = keywords.filter(k => k.needs_review).length;

  const formatDateTime = (dateString: string | null) => {
    if (!dateString) return 'Not set';
    const date = new Date(dateString);
    return date.toLocaleString(undefined, {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    });
  };

  return (
    <div className="space-y-6">
      {/* Progress Summary */}
      <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-4">
        <div className="bg-white p-4 rounded-lg shadow">
          <div className="text-sm text-gray-600">Total Words</div>
          <div className="text-2xl font-bold">{totalWords}</div>
        </div>
        <div className="bg-white p-4 rounded-lg shadow">
          <div className="text-sm text-gray-600">Due for Review</div>
          <div className="text-2xl font-bold text-orange-500">{dueForReview}</div>
        </div>
        <div className="bg-white p-4 rounded-lg shadow">
          <div className="text-sm text-gray-600">Average Score</div>
          <div className="text-2xl font-bold text-blue-500">
            {averageScore.toFixed(1)}
          </div>
        </div>
        <div className="bg-white p-4 rounded-lg shadow">
          <div className="text-sm text-gray-600">Mastered Words</div>
          <div className="text-2xl font-bold text-green-500">
            {(stateCounts.mastered || 0) + (stateCounts['long-term'] || 0)}
          </div>
        </div>
      </div>

      {/* Keywords List */}
      <div className="bg-white rounded-lg shadow overflow-hidden">
        <table className="min-w-full divide-y divide-gray-200">
          <thead className="bg-gray-50">
            <tr>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Keyword
              </th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Translation
              </th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                State
              </th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Score
              </th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Next Review
              </th>
            </tr>
          </thead>
          <tbody className="bg-white divide-y divide-gray-200">
            {keywords.map((keyword) => {
              const StateIcon = stateIcons[keyword.current_state];
              const stateColor = stateColors[keyword.current_state];

              return (
                <tr key={keyword.flashcard_id}>
                  <td className="px-6 py-4 whitespace-nowrap">
                    {keyword.keyword}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    {keyword.translation}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className="flex items-center">
                      <StateIcon className={`w-4 h-4 mr-2 ${stateColor}`} />
                      <Link
                        to={`/practice/group/${keyword.current_state}`}
                        className="capitalize hover:text-indigo-600"
                      >
                        {keyword.current_state.replace('-', ' ')}
                      </Link>
                    </div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className="flex items-center space-x-1">
                      <span className="font-medium">{keyword.total_score.toFixed(1)}</span>
                      <span className="text-gray-500 text-sm">
                        ({keyword.base_score} + {keyword.actual_score.toFixed(1)})
                      </span>
                    </div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    {keyword.needs_review ? (
                      <span className="text-orange-500 font-medium">Due now</span>
                    ) : (
                      <span className="text-gray-500">
                        {formatDateTime(keyword.next_review)}
                      </span>
                    )}
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>
    </div>
  );
}