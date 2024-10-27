import React from 'react';
import { Book, GraduationCap, Bookmark, Star, Brain, CheckCircle2, HelpCircle } from 'lucide-react';
import { Link } from 'react-router-dom';
import type { ProgressStats } from '../types/progress';

interface DashboardStatsProps {
  progress: ProgressStats;
}

export function DashboardStats({ progress }: DashboardStatsProps) {
  return (
    <div className="space-y-8">
      {/* Main Stats */}
      <div className="grid gap-6 md:grid-cols-4">
        <div className="bg-white p-6 rounded-lg shadow-md">
          <div className="flex items-center mb-4">
            <Book className="w-6 h-6 text-blue-500 mr-2" />
            <h2 className="text-xl font-semibold">Total Progress</h2>
          </div>
          <p className="text-3xl font-bold text-blue-600">
            {progress.words_mastered} / {progress.total_words || 0}
          </p>
        </div>

        <div className="bg-white p-6 rounded-lg shadow-md">
          <div className="flex items-center mb-4">
            <GraduationCap className="w-6 h-6 text-green-500 mr-2" />
            <h2 className="text-xl font-semibold">Current Streak</h2>
          </div>
          <p className="text-3xl font-bold text-green-600">{progress.current_streak} days</p>
        </div>

        <div className="bg-white p-6 rounded-lg shadow-md">
          <div className="flex items-center mb-4">
            <Bookmark className="w-6 h-6 text-purple-500 mr-2" />
            <h2 className="text-xl font-semibold">Success Rate</h2>
          </div>
          <p className="text-3xl font-bold text-purple-600">{progress.review_success}%</p>
        </div>

        <div className="bg-white p-6 rounded-lg shadow-md">
          <div className="flex items-center mb-4">
            <Star className="w-6 h-6 text-yellow-500 mr-2" />
            <h2 className="text-xl font-semibold">Average Score</h2>
          </div>
          <p className="text-3xl font-bold text-yellow-600">{progress.average_score}</p>
        </div>
      </div>

      {/* Learning Progress */}
      <div className="bg-white p-6 rounded-lg shadow-md">
        <div className="flex justify-between items-center mb-6">
          <h2 className="text-xl font-semibold">Learning Progress</h2>
          <Link
            to="/practice/smart"
            className="px-4 py-2 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700 transition-colors"
          >
            Smart Practice
          </Link>
        </div>
        <div className="grid gap-4 md:grid-cols-5">
          <Link
            to="/practice/group/unknown"
            className="flex items-center p-4 bg-gray-50 rounded-lg hover:bg-gray-100 transition-colors"
          >
            <HelpCircle className="w-8 h-8 text-gray-400 mr-3" />
            <div>
              <p className="text-sm text-gray-600">Unknown</p>
              <p className="text-2xl font-bold">{progress.unknown_count || 0}</p>
            </div>
          </Link>

          <Link
            to="/practice/group/learning"
            className="flex items-center p-4 bg-blue-50 rounded-lg hover:bg-blue-100 transition-colors"
          >
            <Brain className="w-8 h-8 text-blue-400 mr-3" />
            <div>
              <p className="text-sm text-gray-600">Learning</p>
              <p className="text-2xl font-bold text-blue-600">{progress.learning_count || 0}</p>
            </div>
          </Link>

          <Link
            to="/practice/group/known"
            className="flex items-center p-4 bg-green-50 rounded-lg hover:bg-green-100 transition-colors"
          >
            <CheckCircle2 className="w-8 h-8 text-green-400 mr-3" />
            <div>
              <p className="text-sm text-gray-600">Known</p>
              <p className="text-2xl font-bold text-green-600">{progress.known_count || 0}</p>
            </div>
          </Link>

          <Link
            to="/practice/group/mastered"
            className="flex items-center p-4 bg-purple-50 rounded-lg hover:bg-purple-100 transition-colors"
          >
            <Star className="w-8 h-8 text-purple-400 mr-3" />
            <div>
              <p className="text-sm text-gray-600">Mastered</p>
              <p className="text-2xl font-bold text-purple-600">{progress.mastered_count || 0}</p>
            </div>
          </Link>

          <Link
            to="/practice/group/longTerm"
            className="flex items-center p-4 bg-yellow-50 rounded-lg hover:bg-yellow-100 transition-colors"
          >
            <GraduationCap className="w-8 h-8 text-yellow-400 mr-3" />
            <div>
              <p className="text-sm text-gray-600">Long-term</p>
              <p className="text-2xl font-bold text-yellow-600">{progress.long_term_count || 0}</p>
            </div>
          </Link>
        </div>
      </div>
    </div>
  );
}