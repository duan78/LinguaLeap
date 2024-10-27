import React from 'react';
import { useLessons } from '../hooks/useLessons';
import { LessonCard } from '../components/LessonCard';
import LoadingSpinner from '../components/LoadingSpinner';

const LessonList = () => {
  const { data: lessons, isLoading, error } = useLessons();

  if (isLoading) {
    return (
      <div className="flex justify-center items-center min-h-[50vh]">
        <LoadingSpinner />
      </div>
    );
  }

  if (error) {
    return (
      <div className="text-center py-8">
        <div className="text-red-500 bg-red-50 p-4 rounded-lg inline-block">
          Failed to load lessons. Please try again.
        </div>
      </div>
    );
  }

  if (!lessons?.length) {
    return (
      <div className="text-center py-8">
        <p className="text-gray-600">No lessons available yet.</p>
      </div>
    );
  }

  return (
    <div className="container mx-auto px-4 py-8">
      <h1 className="text-2xl font-bold mb-8">Vocabulary Lessons</h1>
      <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-3">
        {lessons.map((lesson) => (
          <LessonCard
            key={lesson.id}
            id={lesson.id}
            title={lesson.title}
            description={lesson.description}
            flashcardCount={lesson.flashcard_count}
            masteredCount={lesson.mastered_count}
          />
        ))}
      </div>
    </div>
  );
};

export default LessonList;