import React from 'react';
import { useNavigate } from 'react-router-dom';
import { useKeywordStates } from '../hooks/useKeywordStates';
import { Brain, CheckCircle2, GraduationCap, HelpCircle, Star } from 'lucide-react';
import LoadingSpinner from '../components/LoadingSpinner';

export function ProgressGroups() {
  const { keywords, isLoading, error } = useKeywordStates();
  const navigate = useNavigate();

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
          Error loading flashcards: {error.message}
        </div>
      </div>
    );
  }

  const keywordList = keywords.data || [];

  const groups = {
    unknown: {
      title: 'Unknown',
      icon: HelpCircle,
      color: 'bg-gray-50 hover:bg-gray-100',
      iconColor: 'text-gray-400',
      textColor: 'text-gray-900',
      words: keywordList.filter(k => k.current_state === 'unknown')
    },
    learning: {
      title: 'Learning',
      icon: Brain,
      color: 'bg-blue-50 hover:bg-blue-100',
      iconColor: 'text-blue-400',
      textColor: 'text-blue-900',
      words: keywordList.filter(k => k.current_state === 'learning')
    },
    known: {
      title: 'Known',
      icon: CheckCircle2,
      color: 'bg-green-50 hover:bg-green-100',
      iconColor: 'text-green-400',
      textColor: 'text-green-900',
      words: keywordList.filter(k => k.current_state === 'known')
    },
    memorized: {
      title: 'Mastered',
      icon: Star,
      color: 'bg-purple-50 hover:bg-purple-100',
      iconColor: 'text-purple-400',
      textColor: 'text-purple-900',
      words: keywordList.filter(k => k.current_state === 'memorized')
    },
    longTerm: {
      title: 'Long-term',
      icon: GraduationCap,
      color: 'bg-yellow-50 hover:bg-yellow-100',
      iconColor: 'text-yellow-400',
      textColor: 'text-yellow-900',
      words: keywordList.filter(k => k.current_state === 'long_term')
    }
  };

  return (
    <div className="container mx-auto px-4 py-8">
      <h1 className="text-2xl font-bold mb-8">Progress Groups</h1>
      <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-3">
        {Object.entries(groups).map(([key, group]) => (
          <button
            key={key}
            onClick={() => navigate(`/practice/group/${key}`)}
            className={`p-6 rounded-lg ${group.color} transition-colors duration-200`}
          >
            <div className="flex items-center gap-4">
              <div className={`p-3 rounded-lg ${group.iconColor}`}>
                <group.icon className="w-6 h-6" />
              </div>
              <div className="text-left">
                <h3 className={`font-semibold ${group.textColor}`}>{group.title}</h3>
                <p className="text-sm text-gray-600">{group.words.length} words</p>
              </div>
            </div>
          </button>
        ))}
      </div>
    </div>
  );
}