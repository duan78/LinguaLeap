-- Drop existing tables if they exist
DROP TABLE IF EXISTS word_progress CASCADE;
DROP TABLE IF EXISTS flashcards CASCADE;
DROP TABLE IF EXISTS lessons CASCADE;

-- Create lessons table
CREATE TABLE lessons (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    description TEXT,
    level TEXT NOT NULL,
    type TEXT NOT NULL,
    order_index INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW())
);

-- Create flashcards table
CREATE TABLE flashcards (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    front_text TEXT NOT NULL,
    back_text TEXT NOT NULL,
    example_sentence TEXT,
    lesson_id UUID REFERENCES lessons(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW())
);

-- Create word progress table
CREATE TABLE word_progress (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    flashcard_id UUID REFERENCES flashcards(id),
    status TEXT NOT NULL DEFAULT 'new',
    next_review TIMESTAMP WITH TIME ZONE,
    review_count INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW())
);

-- Add some sample data with order_index
INSERT INTO lessons (title, description, level, type, order_index) VALUES
('Basic Greetings', 'Learn common greetings and introductions', 'beginner', 'vocabulary', 1),
('Numbers 1-10', 'Learn to count from one to ten', 'beginner', 'vocabulary', 2),
('Common Verbs', 'Essential verbs for daily conversation', 'beginner', 'vocabulary', 3);

INSERT INTO flashcards (front_text, back_text, example_sentence, lesson_id) VALUES
('Hello', 'Bonjour', 'Hello, how are you?', (SELECT id FROM lessons WHERE title = 'Basic Greetings')),
('Goodbye', 'Au revoir', 'Goodbye, see you tomorrow!', (SELECT id FROM lessons WHERE title = 'Basic Greetings')),
('Thank you', 'Merci', 'Thank you very much!', (SELECT id FROM lessons WHERE title = 'Basic Greetings')),
('One', 'Un', 'I need one ticket.', (SELECT id FROM lessons WHERE title = 'Numbers 1-10')),
('Two', 'Deux', 'I have two cats.', (SELECT id FROM lessons WHERE title = 'Numbers 1-10')),
('To be', 'Être', 'I am happy.', (SELECT id FROM lessons WHERE title = 'Common Verbs')),
('To have', 'Avoir', 'I have a car.', (SELECT id FROM lessons WHERE title = 'Common Verbs'));

-- Create indexes for better performance
CREATE INDEX idx_flashcards_lesson_id ON flashcards(lesson_id);
CREATE INDEX idx_word_progress_user_id ON word_progress(user_id);
CREATE INDEX idx_word_progress_flashcard_id ON word_progress(flashcard_id);
CREATE INDEX idx_lessons_order_index ON lessons(order_index);