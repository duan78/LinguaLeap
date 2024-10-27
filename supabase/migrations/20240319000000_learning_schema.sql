-- Add new columns to lessons table
ALTER TABLE lessons
ADD COLUMN type TEXT NOT NULL DEFAULT 'vocabulary'
CHECK (type IN ('vocabulary', 'grammar', 'conversation', 'pronunciation')),
ADD COLUMN xp_reward INTEGER NOT NULL DEFAULT 10;

-- Create exercises table
CREATE TABLE exercises (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  lesson_id uuid REFERENCES lessons(id),
  type TEXT NOT NULL
    CHECK (type IN ('multiple-choice', 'fill-blank', 'speaking', 'matching')),
  question TEXT NOT NULL,
  correct_answer TEXT NOT NULL,
  options JSONB,
  audio_url TEXT,
  image_url TEXT,
  hint TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create achievements table
CREATE TABLE achievements (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  icon TEXT NOT NULL,
  xp_reward INTEGER NOT NULL,
  condition JSONB NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add new columns to profiles table
ALTER TABLE profiles
ADD COLUMN total_xp INTEGER NOT NULL DEFAULT 0,
ADD COLUMN current_streak INTEGER NOT NULL DEFAULT 0,
ADD COLUMN longest_streak INTEGER NOT NULL DEFAULT 0,
ADD COLUMN achievements JSONB NOT NULL DEFAULT '[]',
ADD COLUMN level INTEGER NOT NULL DEFAULT 1,
ADD COLUMN speaking_confidence FLOAT DEFAULT 0,
ADD COLUMN vocabulary_mastered INTEGER DEFAULT 0;

-- Update user_progress table
ALTER TABLE user_progress
ADD COLUMN completed_exercises INTEGER DEFAULT 0,
ADD COLUMN total_exercises INTEGER DEFAULT 0,
ADD COLUMN xp_gained INTEGER DEFAULT 0,
ADD COLUMN accuracy FLOAT DEFAULT 0;

-- Sample achievements
INSERT INTO achievements (title, description, icon, xp_reward, condition) VALUES
('First Steps', 'Complete your first lesson', '🎯', 50, '{"type": "lessons_completed", "value": 1}'),
('Consistent Learner', 'Maintain a 3-day streak', '🔥', 100, '{"type": "streak_days", "value": 3}'),
('Perfect Score', 'Get 100% on 5 lessons', '⭐', 200, '{"type": "perfect_scores", "value": 5}'),
('Vocabulary Master', 'Learn 100 words', '📚', 500, '{"type": "vocabulary_mastered", "value": 100}');

-- Sample exercises for existing French lessons
INSERT INTO exercises (lesson_id, type, question, correct_answer, options, hint) VALUES
((SELECT id FROM lessons WHERE title = 'Basic Greetings' LIMIT 1),
'multiple-choice',
'How do you say "Hello" in French?',
'Bonjour',
'["Bonjour", "Au revoir", "Merci", "Sil vous plaît"]',
'This is the most common greeting in French'),

((SELECT id FROM lessons WHERE title = 'Basic Greetings' LIMIT 1),
'speaking',
'Pronounce: Bonjour',
'bonjour',
NULL,
'Focus on the "jour" sound');

-- Add RLS policies for new tables
ALTER TABLE exercises ENABLE ROW LEVEL SECURITY;
ALTER TABLE achievements ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view exercises"
  ON exercises FOR SELECT
  TO PUBLIC
  USING (true);

CREATE POLICY "Anyone can view achievements"
  ON achievements FOR SELECT
  TO PUBLIC
  USING (true);