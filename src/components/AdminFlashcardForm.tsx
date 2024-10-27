import React, { useState } from 'react';
import { Plus } from 'lucide-react';
import { supabase } from '../lib/supabase';

interface Flashcard {
  front_text: string;
  back_text: string;
  example_sentence?: string;
  lesson_id?: string;
}

interface Props {
  lessons: Array<{ id: string; title: string }>;
  onFlashcardAdded: () => void;
}

export function AdminFlashcardForm({ lessons, onFlashcardAdded }: Props) {
  const [newCard, setNewCard] = useState<Flashcard>({
    front_text: '',
    back_text: '',
    example_sentence: '',
    lesson_id: ''
  });

  async function handleAddFlashcard() {
    try {
      const { error } = await supabase
        .from('flashcards')
        .insert([newCard]);

      if (error) throw error;

      setNewCard({ front_text: '', back_text: '', example_sentence: '', lesson_id: '' });
      onFlashcardAdded();
    } catch (err) {
      console.error('Error adding flashcard:', err);
    }
  }

  return (
    <div className="bg-white p-6 rounded-lg shadow-sm mb-6">
      <h3 className="text-lg font-medium mb-4">Add New Flashcard</h3>
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        <input
          type="text"
          placeholder="Front Text"
          value={newCard.front_text}
          onChange={e => setNewCard(prev => ({ ...prev, front_text: e.target.value }))}
          className="border rounded-lg px-3 py-2"
        />
        <input
          type="text"
          placeholder="Back Text"
          value={newCard.back_text}
          onChange={e => setNewCard(prev => ({ ...prev, back_text: e.target.value }))}
          className="border rounded-lg px-3 py-2"
        />
        <input
          type="text"
          placeholder="Example Sentence"
          value={newCard.example_sentence || ''}
          onChange={e => setNewCard(prev => ({ ...prev, example_sentence: e.target.value }))}
          className="border rounded-lg px-3 py-2"
        />
        <select
          value={newCard.lesson_id || ''}
          onChange={e => setNewCard(prev => ({ ...prev, lesson_id: e.target.value }))}
          className="border rounded-lg px-3 py-2"
        >
          <option value="">Select Lesson</option>
          {lessons.map(lesson => (
            <option key={lesson.id} value={lesson.id}>
              {lesson.title}
            </option>
          ))}
        </select>
      </div>
      <button
        onClick={handleAddFlashcard}
        className="mt-4 flex items-center gap-2 px-4 py-2 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700"
      >
        <Plus className="h-4 w-4" />
        Add Flashcard
      </button>
    </div>
  );
}