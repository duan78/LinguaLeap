import React from 'react';
import { Book, GraduationCap, Languages } from 'lucide-react';
import { Link } from 'react-router-dom';

export function Home() {
  const features = [
    {
      icon: Book,
      title: 'Structured Learning',
      description: 'Progress through carefully designed lessons that build upon each other',
    },
    {
      icon: Languages,
      title: 'Interactive Practice',
      description: 'Learn through engaging exercises and real-world conversations',
    },
    {
      icon: GraduationCap,
      title: 'Track Progress',
      description: 'Monitor your advancement with detailed statistics and insights',
    },
  ];

  return (
    <div className="min-h-screen bg-gradient-to-b from-blue-50 to-white">
      <div className="container mx-auto px-4 py-16">
        <div className="text-center mb-16">
          <h1 className="text-4xl md:text-5xl font-bold mb-6 bg-clip-text text-transparent bg-gradient-to-r from-blue-600 to-indigo-600">
            Master Languages Effectively
          </h1>
          <p className="text-xl text-gray-600 mb-8">
            Learn, practice, and perfect your language skills with our comprehensive platform
          </p>
          <Link
            to="/lessons/vocabulary"
            className="inline-block bg-blue-600 text-white px-8 py-3 rounded-lg font-semibold hover:bg-blue-700 transition-colors"
          >
            Start Learning
          </Link>
        </div>

        <div className="grid md:grid-cols-3 gap-8 mb-16">
          {features.map((feature) => (
            <div
              key={feature.title}
              className="bg-white p-6 rounded-xl shadow-md hover:shadow-lg transition-shadow"
            >
              <feature.icon className="w-12 h-12 text-blue-600 mb-4" />
              <h2 className="text-xl font-semibold mb-3">{feature.title}</h2>
              <p className="text-gray-600">{feature.description}</p>
            </div>
          ))}
        </div>

        <div className="text-center">
          <h2 className="text-2xl font-bold mb-4">Ready to begin?</h2>
          <p className="text-gray-600 mb-8">
            Join thousands of learners who have improved their language skills with our platform
          </p>
          <Link
            to="/auth"
            className="inline-block bg-indigo-600 text-white px-8 py-3 rounded-lg font-semibold hover:bg-indigo-700 transition-colors"
          >
            Create Free Account
          </Link>
        </div>
      </div>
    </div>
  );
}

export default Home;