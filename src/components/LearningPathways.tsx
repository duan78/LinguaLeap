import React from 'react';
import { Link } from 'react-router-dom';
import { Book, Brain, MessageSquare, Mic } from 'lucide-react';
import { useLessons } from '../hooks/useLessons';
import LoadingSpinner from './LoadingSpinner';

interface LearningPathwaysProps {
  masteredCount: number;
  unknownCount: number;
  learningCount: number;
  knownCount: number;
  longTermCount: number;
}

export function LearningPathways({
  masteredCount,
  unknownCount,
  learningCount,
  knownCount,
  longTermCount
}: LearningPathwaysProps) {
  const { data: lessons, isLoading, error } = useLessons();

  if (isLoading) {
    return <LoadingSpinner />;
  }

  if (error) {
    return (
      <div className="text-red-500 bg-red-50 p-4 rounded-lg">
        Failed to load lessons. Please try again.
      </div>
    );
  }

  const paths = [
    {
      icon: Book,
      title: 'Vocabulary Lessons',
      description: `${lessons?.length || 0} lessons available`,
      link: '/lessons/vocabulary',
      count: unknownCount,
      color: 'bg-blue-50 text-blue-600'
    },
    {
      icon: Brain,
      title: 'Learning',
      description: 'Words in progress',
      link: '/practice/group/learning',
      count: learningCount,
      color: 'bg-yellow-50 text-yellow-600'
    },
    {
      icon: Mic,
      title: 'Known',
      description: 'Words you know well',
      link: '/practice/group/known',
      count: knownCount,
      color: 'bg-green-50 text-green-600'
    },
    {
      icon: MessageSquare,
      title: 'Mastered',
      description: 'Fully mastered words',
      link: '/practice/group/mastered',
      count: masteredCount,
      color: 'bg-blue-50 text-blue-600'
    }
  ];

  return (
    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
      {paths.map((path) => (
        <Link
          key={path.title}
          to={path.link}
          className="block p-6 rounded-lg border border-gray-100 hover:border-gray-200 hover:shadow-md transition-all duration-200"
        >
          <div className="flex items-center gap-4">
            <div className={`p-3 rounded-lg ${path.color}`}>
              <path.icon className="w-6 h-6" />
            </div>
            <div>
              <h3 className="font-semibold text-gray-900">{path.title}</h3>
              <p className="text-sm text-gray-600">{path.description}</p>
              <div className="mt-2 text-sm font-medium text-gray-700">
                {path.count} words to learn
              </div>
            </div>
          </div>
        </Link>
      ))}
    </div>
  );
}