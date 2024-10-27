import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { supabase } from '../../lib/supabase';
import { Pencil, Save, X } from 'lucide-react';
import LoadingSpinner from '../../components/LoadingSpinner';
import { PostgrestError } from '@supabase/supabase-js';

interface LearningSetting {
  id: string;
  name: string;
  description: string | null;
  state: string;
  min_mastery_level: number;
  min_correct_streak: number;
  min_review_count: number;
  score_weight: number;
  next_review_delay: string;
}

interface EditForm extends Partial<LearningSetting> {}

export function LearningSettings() {
  const queryClient = useQueryClient();
  const [editingId, setEditingId] = useState<string | null>(null);
  const [editForm, setEditForm] = useState<EditForm>({});

  const { data: settings, isLoading, error } = useQuery<LearningSetting[], PostgrestError>({
    queryKey: ['learning-settings'],
    queryFn: async () => {
      const { data, error } = await supabase
        .from('learning_settings')
        .select('*')
        .order('min_mastery_level');

      if (error) throw error;
      if (!data) return [];
      return data;
    }
  });

  const updateMutation = useMutation({
    mutationFn: async (setting: LearningSetting) => {
      const { data, error } = await supabase
        .from('learning_settings')
        .update({
          name: setting.name,
          description: setting.description,
          state: setting.state,
          min_mastery_level: setting.min_mastery_level,
          min_correct_streak: setting.min_correct_streak,
          min_review_count: setting.min_review_count,
          score_weight: setting.score_weight,
          next_review_delay: setting.next_review_delay
        })
        .eq('id', setting.id)
        .select()
        .single();

      if (error) throw error;
      return data;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['learning-settings'] });
      setEditingId(null);
      setEditForm({});
    },
    onError: (error) => {
      console.error('Failed to update learning settings:', error);
      alert('Failed to update settings. Please try again.');
    }
  });

  const handleEdit = (setting: LearningSetting) => {
    setEditingId(setting.id);
    setEditForm(setting);
  };

  const handleSave = async () => {
    if (!editingId || !editForm.id) {
      console.error('Invalid edit form state');
      return;
    }

    try {
      await updateMutation.mutateAsync(editForm as LearningSetting);
    } catch (err) {
      console.error('Error saving settings:', err);
    }
  };

  const handleCancel = () => {
    setEditingId(null);
    setEditForm({});
  };

  if (isLoading) {
    return (
      <div className="flex justify-center items-center min-h-[50vh]">
        <LoadingSpinner />
      </div>
    );
  }

  if (error) {
    return (
      <div className="container mx-auto px-4 py-8">
        <div className="bg-red-50 border border-red-200 rounded-lg p-4">
          <h2 className="text-red-700 font-semibold mb-2">Error Loading Settings</h2>
          <p className="text-red-600">{error.message}</p>
          <button
            onClick={() => queryClient.invalidateQueries({ queryKey: ['learning-settings'] })}
            className="mt-4 px-4 py-2 bg-red-600 text-white rounded hover:bg-red-700"
          >
            Retry
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="container mx-auto px-4 py-8">
      <h1 className="text-2xl font-bold mb-8">Learning Settings</h1>

      <div className="bg-white rounded-lg shadow overflow-hidden">
        <table className="min-w-full divide-y divide-gray-200">
          <thead className="bg-gray-50">
            <tr>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">State</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Name</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Requirements</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Scoring</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Review Delay</th>
              <th className="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase">Actions</th>
            </tr>
          </thead>
          <tbody className="bg-white divide-y divide-gray-200">
            {settings?.map((setting) => (
              <tr key={setting.id}>
                {editingId === setting.id ? (
                  <>
                    <td className="px-6 py-4">
                      <input
                        type="text"
                        value={editForm.state || ''}
                        onChange={(e) => setEditForm({ ...editForm, state: e.target.value })}
                        className="w-full px-2 py-1 border rounded"
                      />
                    </td>
                    <td className="px-6 py-4">
                      <input
                        type="text"
                        value={editForm.name || ''}
                        onChange={(e) => setEditForm({ ...editForm, name: e.target.value })}
                        className="w-full px-2 py-1 border rounded"
                      />
                    </td>
                    <td className="px-6 py-4">
                      <div className="space-y-2">
                        <div className="flex items-center gap-2">
                          <label className="text-sm">Mastery Level:</label>
                          <input
                            type="number"
                            value={editForm.min_mastery_level || 0}
                            onChange={(e) => setEditForm({ 
                              ...editForm, 
                              min_mastery_level: parseInt(e.target.value) 
                            })}
                            className="w-20 px-2 py-1 border rounded"
                          />
                        </div>
                        <div className="flex items-center gap-2">
                          <label className="text-sm">Correct Streak:</label>
                          <input
                            type="number"
                            value={editForm.min_correct_streak || 0}
                            onChange={(e) => setEditForm({ 
                              ...editForm, 
                              min_correct_streak: parseInt(e.target.value) 
                            })}
                            className="w-20 px-2 py-1 border rounded"
                          />
                        </div>
                        <div className="flex items-center gap-2">
                          <label className="text-sm">Review Count:</label>
                          <input
                            type="number"
                            value={editForm.min_review_count || 0}
                            onChange={(e) => setEditForm({ 
                              ...editForm, 
                              min_review_count: parseInt(e.target.value) 
                            })}
                            className="w-20 px-2 py-1 border rounded"
                          />
                        </div>
                      </div>
                    </td>
                    <td className="px-6 py-4">
                      <input
                        type="number"
                        step="0.01"
                        min="0"
                        max="1"
                        value={editForm.score_weight || 0}
                        onChange={(e) => setEditForm({ 
                          ...editForm, 
                          score_weight: parseFloat(e.target.value) 
                        })}
                        className="w-20 px-2 py-1 border rounded"
                      />
                    </td>
                    <td className="px-6 py-4">
                      <input
                        type="text"
                        value={editForm.next_review_delay || ''}
                        onChange={(e) => setEditForm({ 
                          ...editForm, 
                          next_review_delay: e.target.value 
                        })}
                        className="w-full px-2 py-1 border rounded"
                        placeholder="e.g., 1 day"
                      />
                    </td>
                    <td className="px-6 py-4 text-right space-x-2">
                      <button
                        onClick={handleSave}
                        disabled={updateMutation.isPending}
                        className="text-green-600 hover:text-green-900 disabled:opacity-50"
                      >
                        <Save className="h-5 w-5" />
                      </button>
                      <button
                        onClick={handleCancel}
                        disabled={updateMutation.isPending}
                        className="text-gray-600 hover:text-gray-900 disabled:opacity-50"
                      >
                        <X className="h-5 w-5" />
                      </button>
                    </td>
                  </>
                ) : (
                  <>
                    <td className="px-6 py-4">{setting.state}</td>
                    <td className="px-6 py-4">{setting.name}</td>
                    <td className="px-6 py-4">
                      <div className="space-y-1">
                        <div className="text-sm">
                          Mastery Level: {setting.min_mastery_level}
                        </div>
                        <div className="text-sm">
                          Correct Streak: {setting.min_correct_streak}
                        </div>
                        <div className="text-sm">
                          Review Count: {setting.min_review_count}
                        </div>
                      </div>
                    </td>
                    <td className="px-6 py-4">{setting.score_weight}</td>
                    <td className="px-6 py-4">{setting.next_review_delay}</td>
                    <td className="px-6 py-4 text-right">
                      <button
                        onClick={() => handleEdit(setting)}
                        className="text-blue-600 hover:text-blue-900"
                      >
                        <Pencil className="h-5 w-5" />
                      </button>
                    </td>
                  </>
                )}
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}

export default LearningSettings;