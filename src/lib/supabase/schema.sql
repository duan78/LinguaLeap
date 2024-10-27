-- Drop existing tables if they exist
DROP VIEW IF EXISTS word_progress_stats CASCADE;
DROP TABLE IF EXISTS word_progress CASCADE;
DROP TABLE IF EXISTS flashcards CASCADE;
DROP TABLE IF EXISTS lessons CASCADE;

-- Create lessons table
CREATE TABLE lessons (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title VARCHAR(255) NOT NULL,
  description TEXT,
  level VARCHAR(50),
  order_index INTEGER,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW())
);

-- Create flashcards table
CREATE TABLE flashcards (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  lesson_id UUID REFERENCES lessons(id) ON DELETE CASCADE,
  front TEXT NOT NULL,
  back TEXT NOT NULL,
  example TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW())
);

-- Create word progress table
CREATE TABLE word_progress (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL,
  flashcard_id UUID REFERENCES flashcards(id) ON DELETE CASCADE,
  correct_count INTEGER DEFAULT 0,
  incorrect_count INTEGER DEFAULT 0,
  last_reviewed TIMESTAMP WITH TIME ZONE,
  next_review TIMESTAMP WITH TIME ZONE,
  mastery_level INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
  UNIQUE(user_id, flashcard_id)
);

-- Create progress stats view
CREATE OR REPLACE VIEW word_progress_stats AS
WITH user_stats AS (
  SELECT 
    user_id,
    COUNT(CASE WHEN mastery_level >= 5 THEN 1 END) as mastered_count,
    COALESCE(
      EXTRACT(DAY FROM NOW() - MAX(last_reviewed))::INTEGER,
      0
    ) as current_streak,
    CASE 
      WHEN SUM(correct_count + incorrect_count) > 0 
      THEN ROUND(SUM(correct_count)::NUMERIC / NULLIF(SUM(correct_count + incorrect_count), 0), 2)
      ELSE 0 
    END as accuracy
  FROM word_progress
  GROUP BY user_id
)
SELECT * FROM user_stats;

-- Insert sample lessons
INSERT INTO lessons (id, title, description, level, order_index) VALUES
('7c35bda7-25cf-4007-88ce-773eb1afeebc', 'Basic Greetings', 'Learn essential greetings and introductions', 'beginner', 1),
('085878eb-83ef-4f1a-938a-b1b35ae246f5', 'Numbers 1-10', 'Master counting from one to ten', 'beginner', 2);

-- Insert sample flashcards
INSERT INTO flashcards (lesson_id, front, back, example) VALUES
('7c35bda7-25cf-4007-88ce-773eb1afeebc', 'Hello', 'Bonjour', 'Bonjour, comment allez-vous?'),
('7c35bda7-25cf-4007-88ce-773eb1afeebc', 'Goodbye', 'Au revoir', 'Au revoir, à bientôt!'),
('085878eb-83ef-4f1a-938a-b1b35ae246f5', 'One', 'Un', 'J''ai un chat.'),
('085878eb-83ef-4f1a-938a-b1b35ae246f5', 'Two', 'Deux', 'J''ai deux chiens.');

-- Create RLS policies
ALTER TABLE lessons ENABLE ROW LEVEL SECURITY;
ALTER TABLE flashcards ENABLE ROW LEVEL SECURITY;
ALTER TABLE word_progress ENABLE ROW LEVEL SECURITY;

-- Lessons policies
CREATE POLICY "Lessons are viewable by everyone" ON lessons
  FOR SELECT USING (true);

-- Flashcards policies
CREATE POLICY "Flashcards are viewable by everyone" ON flashcards
  FOR SELECT USING (true);

-- Word progress policies
CREATE POLICY "Users can view their own progress" ON word_progress
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own progress" ON word_progress
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own progress" ON word_progress
  FOR UPDATE USING (auth.uid() = user_id);