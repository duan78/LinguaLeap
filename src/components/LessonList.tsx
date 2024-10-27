import React from 'react';
import { Link } from 'react-router-dom';
import type { Lesson } from '../hooks/useLessons';

interface LessonListProps {
  lessons: Lesson[];
  limit?: number;
}

export function LessonList({ lessons, limit }: LessonListProps) {
  const displayLessons = limit ? lessons.slice(0, limit) : lessons;

  return (
    <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
      {displayLessons.map((lesson) => (
        <Link
          key={lesson.id}
          to={`/practice/vocabulary/${lesson.id}`}
          className="block p-6 bg-white border rounded-lg hover:border-blue-500 transition-colors"
        >
          <h3 className="font-semibold text-lg mb-2">{lesson.title}</h3>
          <p className="text-gray-600 mb-4">{lesson.description}</p>
          <div className="flex justify-between text-sm">
            <span className="text-blue-600">
              {lesson.mastered_count}/{lesson.flashcard_count} words mastered
            </span>
            <span className="text-gray-500">
              {Math.round((lesson.mastered_count / lesson.flashcard_count) * 100) || 0}%
            </span>
          </div>
          <div className="mt-2 w-full bg-gray-200 rounded-full h-2">
            <div
              className="bg-blue-600 h-2 rounded-full transition-all duration-300"
              style={{
                width: `${(lesson.mastered_count / lesson.flashcard_count) * 100 || 0}%`
              }}
            />
          </div>
        </Link>
      ))}
    </div>
  );
}