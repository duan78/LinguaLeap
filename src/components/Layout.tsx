import { Outlet, Link, useNavigate } from 'react-router-dom';
import { Book, LogOut, RefreshCw, BarChart2, Settings } from 'lucide-react';
import { useAuth } from '../context/AuthContext';
import { supabase } from '../lib/supabase';
import { useQueryClient } from '@tanstack/react-query';

export function Layout() {
  const { user, signOut } = useAuth();
  const navigate = useNavigate();
  const queryClient = useQueryClient();

  const handleSignOut = async () => {
    try {
      await signOut();
      navigate('/auth');
    } catch (error) {
      console.error('Error signing out:', error);
    }
  };

  const handleResetProgress = async () => {
    if (!user || !confirm('Are you sure you want to reset all progress? This cannot be undone.')) {
      return;
    }

    try {
      const { error } = await supabase
        .from('word_progress')
        .delete()
        .eq('user_id', user.id);

      if (error) throw error;

      // Invalidate all queries to refresh the UI
      await queryClient.invalidateQueries();

      alert('Progress has been reset successfully.');
    } catch (err) {
      console.error('Error resetting progress:', err);
      alert('Failed to reset progress. Please try again.');
    }
  };

  return (
    <div className="min-h-screen bg-gray-50">
      <nav className="bg-white shadow-sm">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between h-16">
            <div className="flex">
              <Link
                to="/"
                className="flex items-center px-2 py-2 text-gray-900 hover:text-indigo-600"
              >
                <Book className="h-6 w-6 mr-2" />
                <span className="font-semibold text-xl">LinguaLeap</span>
              </Link>
            </div>

            <div className="flex items-center">
              {user ? (
                <>
                  <Link
                    to="/dashboard"
                    className="px-3 py-2 rounded-md text-sm font-medium text-gray-900 hover:text-indigo-600"
                  >
                    Dashboard
                  </Link>
                  <Link
                    to="/lessons/vocabulary"
                    className="px-3 py-2 rounded-md text-sm font-medium text-gray-900 hover:text-indigo-600"
                  >
                    Vocabulary
                  </Link>
                  <Link
                    to="/progress"
                    className="px-3 py-2 rounded-md text-sm font-medium text-gray-900 hover:text-indigo-600"
                  >
                    <div className="flex items-center">
                      <BarChart2 className="h-4 w-4 mr-1" />
                      Progress
                    </div>
                  </Link>
                  <div className="relative group">
                    <Link
                      to="/admin"
                      className="px-3 py-2 rounded-md text-sm font-medium text-gray-900 hover:text-indigo-600"
                    >
                      Admin
                    </Link>
                    <div className="absolute left-0 mt-2 w-48 rounded-md shadow-lg bg-white ring-1 ring-black ring-opacity-5 opacity-0 invisible group-hover:opacity-100 group-hover:visible transition-all duration-200">
                      <div className="py-1">
                        <Link
                          to="/admin"
                          className="block px-4 py-2 text-sm text-gray-700 hover:bg-gray-100"
                        >
                          Manage Content
                        </Link>
                        <Link
                          to="/admin/learning-settings"
                          className="block px-4 py-2 text-sm text-gray-700 hover:bg-gray-100"
                        >
                          <div className="flex items-center">
                            <Settings className="h-4 w-4 mr-2" />
                            Learning Settings
                          </div>
                        </Link>
                      </div>
                    </div>
                  </div>
                  <button
                    onClick={handleResetProgress}
                    className="ml-4 inline-flex items-center px-3 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-yellow-600 hover:bg-yellow-700"
                  >
                    <RefreshCw className="h-4 w-4 mr-2" />
                    Reset Progress
                  </button>
                  <button
                    onClick={handleSignOut}
                    className="ml-4 inline-flex items-center px-3 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700"
                  >
                    <LogOut className="h-4 w-4 mr-2" />
                    Sign Out
                  </button>
                </>
              ) : (
                <Link
                  to="/auth"
                  className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700"
                >
                  Sign In
                </Link>
              )}
            </div>
          </div>
        </div>
      </nav>

      <main className="max-w-7xl mx-auto py-6 sm:px-6 lg:px-8">
        <Outlet />
      </main>
    </div>
  );
}