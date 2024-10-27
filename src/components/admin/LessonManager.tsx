import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { supabase } from '../../lib/supabase';
import { Plus, Pencil, Trash2, Save, X } from 'lucide-react';
import LoadingSpinner from '../LoadingSpinner';

interface Lesson {
  id: string;
  title: string;
  description: string;
  level: string;
  type: string;
  order_index: number;
}

interface EditingLesson extends Omit<Lesson, 'id'> {
  id?: string;
}

export function LessonManager() {
  const queryClient = useQueryClient();
  const [isCreating, setIsCreating] = useState(false);
  const [editingLesson, setEditingLesson] = useState<EditingLesson | null>(null);

  const { data: lessons, isLoading, error } = useQuery<Lesson[]>({
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

  const createMutation = useMutation({
    mutationFn: async (lesson: Omit<Lesson, 'id'>) => {
      const { data, error } = await supabase
        .from('lessons')
        .insert([lesson])
        .select()
        .single();

      if (error) throw error;
      return data;
    },
    onSuccess: () => {
      queryClient.invalidateQueries(['admin-lessons']);
      setIsCreating(false);
      setEditingLesson(null);
    }
  });

  const updateMutation = useMutation({
    mutationFn: async (lesson: Lesson) => {
      const { error } = await supabase
        .from('lessons')
        .update(lesson)
        .eq('id', lesson.id);

      if (error) throw error;
    },
    onSuccess: () => {
      queryClient.invalidateQueries(['admin-lessons']);
      setEditingLesson(null);
    }
  });

  const deleteMutation = useMutation({
    mutationFn: async (id: string) => {
      const { error } = await supabase
        .from('lessons')
        .delete()
        .eq('id', id);

      if (error) throw error;
    },
    onSuccess: () => {
      queryClient.invalidateQueries(['admin-lessons']);
    }
  });

  const handleSave = async (lesson: EditingLesson) => {
    if (lesson.id) {
      await updateMutation.mutateAsync(lesson as Lesson);
    } else {
      await createMutation.mutateAsync(lesson);
    }
  };

  const handleDelete = async (id: string) => {
    if (confirm('Are you sure you want to delete this lesson? This will also delete all associated flashcards.')) {
      await deleteMutation.mutateAsync(id);
    }
  };

  if (isLoading) return <LoadingSpinner />;

  if (error) {
    return (
      <div className="text-red-500 bg-red-50 p-4 rounded-lg">
        Error loading lessons: {error.message}
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <h2 className="text-xl font-semibold">Manage Lessons</h2>
        <button
          onClick={() => {
            setIsCreating(true);
            setEditingLesson({
              title: '',
              description: '',
              level: 'beginner',
              type: 'vocabulary',
              order_index: (lessons?.length || 0) + 1
            });
          }}
          className="flex items-center gap-2 px-4 py-2 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700"
          disabled={isCreating}
        >
          <Plus className="h-4 w-4" />
          Add Lesson
        </button>
      </div>

      <div className="bg-white rounded-lg shadow overflow-hidden">
        <table className="min-w-full divide-y divide-gray-200">
          <thead className="bg-gray-50">
            <tr>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Title
              </th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Description
              </th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Level
              </th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Type
              </th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Order
              </th>
              <th className="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">
                Actions
              </th>
            </tr>
          </thead>
          <tbody className="bg-white divide-y divide-gray-200">
            {editingLesson && (
              <tr>
                <td className="px-6 py-4">
                  <input
                    type="text"
                    value={editingLesson.title}
                    onChange={(e) => setEditingLesson({ ...editingLesson, title: e.target.value })}
                    className="w-full px-2 py-1 border rounded"
                    placeholder="Lesson title"
                  />
                </td>
                <td className="px-6 py-4">
                  <input
                    type="text"
                    value={editingLesson.description}
                    onChange={(e) => setEditingLesson({ ...editingLesson, description: e.target.value })}
                    className="w-full px-2 py-1 border rounded"
                    placeholder="Description"
                  />
                </td>
                <td className="px-6 py-4">
                  <select
                    value={editingLesson.level}
                    onChange={(e) => setEditingLesson({ ...editingLesson, level: e.target.value })}
                    className="w-full px-2 py-1 border rounded"
                  >
                    <option value="beginner">Beginner</option>
                    <option value="intermediate">Intermediate</option>
                    <option value="advanced">Advanced</option>
                  </select>
                </td>
                <td className="px-6 py-4">
                  <select
                    value={editingLesson.type}
                    onChange={(e) => setEditingLesson({ ...editingLesson, type: e.target.value })}
                    className="w-full px-2 py-1 border rounded"
                  >
                    <option value="vocabulary">Vocabulary</option>
                    <option value="grammar">Grammar</option>
                    <option value="pronunciation">Pronunciation</option>
                    <option value="conversation">Conversation</option>
                  </select>
                </td>
                <td className="px-6 py-4">
                  <input
                    type="number"
                    value={editingLesson.order_index}
                    onChange={(e) => setEditingLesson({ ...editingLesson, order_index: parseInt(e.target.value) })}
                    className="w-20 px-2 py-1 border rounded"
                  />
                </td>
                <td className="px-6 py-4 text-right space-x-2">
                  <button
                    onClick={() => handleSave(editingLesson)}
                    className="text-green-600 hover:text-green-900"
                  >
                    <Save className="h-5 w-5" />
                  </button>
                  <button
                    onClick={() => {
                      setEditingLesson(null);
                      setIsCreating(false);
                    }}
                    className="text-gray-600 hover:text-gray-900"
                  >
                    <X className="h-5 w-5" />
                  </button>
                </td>
              </tr>
            )}
            {lessons?.map((lesson) => (
              <tr key={lesson.id}>
                <td className="px-6 py-4">{lesson.title}</td>
                <td className="px-6 py-4">{lesson.description}</td>
                <td className="px-6 py-4 capitalize">{lesson.level}</td>
                <td className="px-6 py-4 capitalize">{lesson.type}</td>
                <td className="px-6 py-4">{lesson.order_index}</td>
                <td className="px-6 py-4 text-right space-x-2">
                  <button
                    onClick={() => setEditingLesson(lesson)}
                    className="text-blue-600 hover:text-blue-900"
                  >
                    <Pencil className="h-5 w-5" />
                  </button>
                  <button
                    onClick={() => handleDelete(lesson.id)}
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