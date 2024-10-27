import React from 'react';
import { Trophy, Star, CheckCircle } from 'lucide-react';
import { useProgress } from '../hooks/useProgress';
import LoadingSpinner from './LoadingSpinner';

export function ProgressStats() {
  const { data, isLoading, error } = useProgress();

  if (isLoading) {
    return (
      <div className="flex justify-center items-center p-4">
        <LoadingSpinner />
      </div>
    );
  }

  if (error) {
    return (
      <div className="text-red-500 bg-red-50 p-4 rounded-lg text-center">
        Failed to load progress data. Please try again.
      </div>
    );
  }

  const stats = [
    {
      title: 'Words Mastered',
      value: data?.words_mastered || 0,
      icon: Trophy,
      color: 'text-yellow-500',
      description: 'Words you know well'
    },
    {
      title: 'Current Streak',
      value: data?.current_streak || 0,
      icon: Star,
      color: 'text-blue-500',
      description: 'Days in a row'
    },
    {
      title: 'Review Success',
      value: `${data?.review_success || 0}%`,
      icon: CheckCircle,
      color: 'text-green-500',
      description: 'Correct answers'
    }
  ];

  return (
    <div className="grid gap-6 md:grid-cols-3">
      {stats.map((stat) => (
        <div
          key={stat.title}
          className="bg-white p-6 rounded-lg shadow-md hover:shadow-lg transition-shadow"
        >
          <div className="flex items-center justify-between mb-4">
            <h2 className="text-lg font-semibold">{stat.title}</h2>
            <stat.icon className={`w-6 h-6 ${stat.color}`} />
          </div>
          <p className="text-3xl font-bold mb-2">{stat.value}</p>
          <p className="text-gray-600 text-sm">{stat.description}</p>
        </div>
      ))}
    </div>
  );
}