import React from 'react';
import { Link } from 'react-router-dom';
import { Book } from 'lucide-react';

interface LessonCardProps {
  id: string;
  title: string;
  description: string;
  flashcardCount: number;
  masteredCount: number;
}

export function LessonCard({ id, title, description, flashcardCount, masteredCount }: LessonCardProps) {
  const progress = flashcardCount > 0 ? (masteredCount / flashcardCount) * 100 : 0;

  return (
    <Link
      to={`/practice/vocabulary/${id}`}
      className="block bg-white rounded-lg shadow-sm hover:shadow-md transition-shadow duration-200"
    >
      <div className="p-6">
        <div className="flex items-center gap-3 mb-3">
          <Book className="w-5 h-5 text-blue-500" />
          <h3 className="text-lg font-semibold text-gray-900">{title}</h3>
        </div>
        <p className="text-gray-600 mb-4">{description}</p>
        <div className="mt-4">
          <div className="flex justify-between text-sm text-gray-500 mb-2">
            <span>{masteredCount} of {flashcardCount} words mastered</span>
            <span>{Math.round(progress)}%</span>
          </div>
          <div className="w-full bg-gray-200 rounded-full h-2">
            <div
              className="bg-blue-500 rounded-full h-2 transition-all duration-300"
              style={{ width: `${progress}%` }}
            />
          </div>
        </div>
      </div>
    </Link>
  );
}