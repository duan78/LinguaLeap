import React from 'react';
import { Link } from 'react-router-dom';
import { Book, Mic, MessageSquare } from 'lucide-react';

interface LearningPathsProps {
  masteredCount: number;
}

export function LearningPaths({ masteredCount }: LearningPathsProps) {
  const paths = [
    {
      icon: Book,
      title: 'Vocabulary',
      description: 'Learn essential words and phrases',
      link: '/lessons/vocabulary',
      count: masteredCount
    },
    {
      icon: MessageSquare,
      title: 'Grammar',
      description: 'Master language structure',
      link: '/lessons/grammar'
    },
    {
      icon: Mic,
      title: 'Pronunciation',
      description: 'Perfect your accent',
      link: '/lessons/pronunciation'
    }
  ];

  return (
    <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
      {paths.map((path) => (
        <Link
          key={path.title}
          to={path.link}
          className="bg-white rounded-lg shadow-sm hover:shadow-md transition-shadow duration-200 p-6"
        >
          <div className="flex items-center mb-4">
            <div className="p-3 rounded-lg bg-indigo-50">
              <path.icon className="w-6 h-6 text-indigo-600" />
            </div>
          </div>
          <h3 className="text-lg font-semibold mb-2">{path.title}</h3>
          <p className="text-gray-600 mb-4">{path.description}</p>
          {path.count !== undefined && (
            <div className="text-sm text-indigo-600">
              {path.count} words mastered
            </div>
          )}
        </Link>
      ))}
    </div>
  );
}