import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { supabase } from '../../lib/supabase';
import { Plus, Pencil, Trash2, Save, X } from 'lucide-react';
import LoadingSpinner from '../LoadingSpinner';

interface Flashcard {
  id: string;
  lesson_id: string;
  front_text: string;
  back_text: string;
  example_sentence?: string;
}

interface EditingFlashcard extends Omit<Flashcard, 'id'> {
  id?: string;
}

export function FlashcardManager() {
  const queryClient = useQueryClient();
  const [isCreating, setIsCreating] = useState(false);
  const [editingFlashcard, setEditingFlashcard] = useState<EditingFlashcard | null>(null);
  const [selectedLesson, setSelectedLesson] = useState<string>('');

  const { data: lessons } = useQuery({
    queryKey: ['admin-lessons'],
    queryFn: async () => {
      const { data, error } = await supabase
        .from('lessons')
        .select('*')
        .order('order_index');
      
      if (error) throw error;
      return data;
    }
  });

  const { data: flashcards, isLoading, error } = useQuery({
    queryKey: ['admin-flashcards', selectedLesson],
    queryFn: async () => {
      const query = supabase
        .from('flashcards')
        .select('*, lessons(title)')
        .order('created_at');

      if (selectedLesson) {
        query.eq('lesson_id', selectedLesson);
      }

      const { data, error } = await query;
      if (error) throw error;
      return data;
    }
  });

  const createMutation = useMutation({
    mutationFn: async (flashcard: Omit<Flashcard, 'id'>) => {
      const { data, error } = await supabase
        .from('flashcards')
        .insert([flashcard])
        .select()
        .single();

      if (error) throw error;
      return data;
    },
    onSuccess: () => {
      queryClient.invalidateQueries(['admin-flashcards']);
      setIsCreating(false);
      setEditingFlashcard(null);
    }
  });

  const updateMutation = useMutation({
    mutationFn: async (flashcard: Flashcard) => {
      const { error } = await supabase
        .from('flashcards')
        .update(flashcard)
        .eq('id', flashcard.id);

      if (error) throw error;
    },
    onSuccess: () => {
      queryClient.invalidateQueries(['admin-flashcards']);
      setEditingFlashcard(null);
    }
  });

  const deleteMutation = useMutation({
    mutationFn: async (id: string) => {
      const { error } = await supabase
        .from('flashcards')
        .delete()
        .eq('id', id);

      if (error) throw error;
    },
    onSuccess: () => {
      queryClient.invalidateQueries(['admin-flashcards']);
    }
  });

  const handleSave = async (flashcard: EditingFlashcard) => {
    if (flashcard.id) {
      await updateMutation.mutateAsync(flashcard as Flashcard);
    } else {
      await createMutation.mutateAsync(flashcard);
    }
  };

  const handleDelete = async (id: string) => {
    if (confirm('Are you sure you want to delete this flashcard?')) {
      await deleteMutation.mutateAsync(id);
    }
  };

  if (isLoading) return <LoadingSpinner />;

  if (error) {
    return (
      <div className="text-red-500 bg-red-50 p-4 rounded-lg">
        Error loading flashcards: {error.message}
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div className="flex items-center gap-4">
          <h2 className="text-xl font-semibold">Manage Flashcards</h2>
          <select
            value={selectedLesson}
            onChange={(e) => setSelectedLesson(e.target.value)}
            className="px-3 py-2 border rounded-lg"
          >
            <option value="">All Lessons</option>
            {lessons?.map((lesson) => (
              <option key={lesson.id} value={lesson.id}>
                {lesson.title}
              </option>
            ))}
          </select>
        </div>
        <button
          onClick={() => {
            setIsCreating(true);
            setEditingFlashcard({
              lesson_id: selectedLesson || '',
              front_text: '',
              back_text: '',
              example_sentence: ''
            });
          }}
          className="flex items-center gap-2 px-4 py-2 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700"
          disabled={isCreating || !selectedLesson}
        >
          <Plus className="h-4 w-4" />
          Add Flashcard
        </button>
      </div>

      <div className="bg-white rounded-lg shadow overflow-hidden">
        <table className="min-w-full divide-y divide-gray-200">
          <thead className="bg-gray-50">
            <tr>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Front Text
              </th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Back Text
              </th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Example
              </th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Lesson
              </th>
              <th className="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">
                Actions
              </th>
            </tr>
          </thead>
          <tbody className="bg-white divide-y divide-gray-200">
            {editingFlashcard && (
              <tr>
                <td className="px-6 py-4">
                  <input
                    type="text"
                    value={editingFlashcard.front_text}
                    onChange={(e) => setEditingFlashcard({ ...editingFlashcard, front_text: e.target.value })}
                    className="w-full px-2 py-1 border rounded"
                    placeholder="Front text"
                  />
                </td>
                <td className="px-6 py-4">
                  <input
                    type="text"
                    value={editingFlashcard.back_text}
                    onChange={(e) => setEditingFlashcard({ ...editingFlashcard, back_text: e.target.value })}
                    className="w-full px-2 py-1 border rounded"
                    placeholder="Back text"
                  />
                </td>
                <td className="px-6 py-4">
                  <input
                    type="text"
                    value={editingFlashcard.example_sentence || ''}
                    onChange={(e) => setEditingFlashcard({ ...editingFlashcard, example_sentence: e.target.value })}
                    className="w-full px-2 py-1 border rounded"
                    placeholder="Example sentence"
                  />
                </td>
                <td className="px-6 py-4">
                  <select
                    value={editingFlashcard.lesson_id}
                    onChange={(e) => setEditingFlashcard({ ...editingFlashcard, lesson_id: e.target.value })}
                    className="w-full px-2 py-1 border rounded"
                  >
                    <option value="">Select Lesson</option>
                    {lessons?.map((lesson) => (
                      <option key={lesson.id} value={lesson.id}>
                        {lesson.title}
                      </option>
                    ))}
                  </select>
                </td>
                <td className="px-6 py-4 text-right space-x-2">
                  <button
                    onClick={() => handleSave(editingFlashcard)}
                    className="text-green-600 hover:text-green-900"
                  >
                    <Save className="h-5 w-5" />
                  </button>
                  <button
                    onClick={() => {
                      setEditingFlashcard(null);
                      setIsCreating(false);
                    }}
                    className="text-gray-600 hover:text-gray-900"
                  >
                    <X className="h-5 w-5" />
                  </button>
                </td>
              </tr>
            )}
            {flashcards?.map((flashcard: any) => (
              <tr key={flashcard.id}>
                <td className="px-6 py-4">{flashcard.front_text}</td>
                <td className="px-6 py-4">{flashcard.back_text}</td>
                <td className="px-6 py-4">{flashcard.example_sentence}</td>
                <td className="px-6 py-4">{flashcard.lessons.title}</td>
                <td className="px-6 py-4 text-right space-x-2">
                  <button
                    onClick={() => setEditingFlashcard(flashcard)}
                    className="text-blue-600 hover:text-blue-900"
                  >
                    <Pencil className="h-5 w-5" />
                  </button>
                  <button
                    onClick={() => handleDelete(flashcard.id)}
                    className="text-red-600 hover:text-red-900"
                  >
                    <Trash2 className="h-5 w-5" />
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}