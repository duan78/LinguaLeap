-- Drop existing tables if they exist
DROP VIEW IF EXISTS word_progress_stats CASCADE;
DROP TABLE IF EXISTS word_progress CASCADE;
DROP TABLE IF EXISTS flashcards CASCADE;
DROP TABLE IF EXISTS lessons CASCADE;

-- Create lessons table
CREATE TABLE lessons (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(255) NOT NULL,
    description TEXT,
    difficulty_level INTEGER DEFAULT 1,
    order_index INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create flashcards table
CREATE TABLE flashcards (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    lesson_id UUID REFERENCES lessons(id) ON DELETE CASCADE,
    front_text TEXT NOT NULL,
    back_text TEXT NOT NULL,
    example_sentence TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create word progress table
CREATE TABLE word_progress (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    flashcard_id UUID NOT NULL REFERENCES flashcards(id) ON DELETE CASCADE,
    mastery_level INTEGER DEFAULT 0,
    last_reviewed TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    next_review TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, flashcard_id)
);

-- Insert sample data
INSERT INTO lessons (id, title, description, difficulty_level, order_index) VALUES
    ('7c35bda7-25cf-4007-88ce-773eb1afeebc', 'Basic Greetings', 'Learn essential greetings and introductions', 1, 1),
    ('cac59d02-4dd1-413a-9d14-75cb8da77ed9', 'Numbers 1-10', 'Master counting from one to ten', 1, 2),
    ('085878eb-83ef-4f1a-938a-b1b35ae246f5', 'Common Phrases', 'Essential everyday expressions', 1, 3);

INSERT INTO flashcards (lesson_id, front_text, back_text, example_sentence) VALUES
    ('7c35bda7-25cf-4007-88ce-773eb1afeebc', 'Hello', 'Bonjour', 'Bonjour, comment allez-vous?'),
    ('7c35bda7-25cf-4007-88ce-773eb1afeebc', 'Goodbye', 'Au revoir', 'Au revoir, à bientôt!'),
    ('7c35bda7-25cf-4007-88ce-773eb1afeebc', 'Good morning', 'Bon matin', 'Bon matin, avez-vous bien dormi?'),
    ('cac59d02-4dd1-413a-9d14-75cb8da77ed9', 'One', 'Un', 'J''ai un chat.'),
    ('cac59d02-4dd1-413a-9d14-75cb8da77ed9', 'Two', 'Deux', 'J''ai deux chiens.'),
    ('cac59d02-4dd1-413a-9d14-75cb8da77ed9', 'Three', 'Trois', 'Trois petits chats.'),
    ('085878eb-83ef-4f1a-938a-b1b35ae246f5', 'Please', 'S''il vous plaît', 'S''il vous plaît, pouvez-vous m''aider?'),
    ('085878eb-83ef-4f1a-938a-b1b35ae246f5', 'Thank you', 'Merci', 'Merci beaucoup!'),
    ('085878eb-83ef-4f1a-938a-b1b35ae246f5', 'You''re welcome', 'De rien', 'De rien, c''est un plaisir.');

-- Set up RLS policies
ALTER TABLE lessons ENABLE ROW LEVEL SECURITY;
ALTER TABLE flashcards ENABLE ROW LEVEL SECURITY;
ALTER TABLE word_progress ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "Anyone can view lessons"
    ON lessons FOR SELECT
    TO PUBLIC
    USING (true);

CREATE POLICY "Anyone can view flashcards"
    ON flashcards FOR SELECT
    TO PUBLIC
    USING (true);

CREATE POLICY "Users can manage their own progress"
    ON word_progress
    FOR ALL
    TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Create indexes for better performance
CREATE INDEX idx_flashcards_lesson_id ON flashcards(lesson_id);
CREATE INDEX idx_word_progress_user_id ON word_progress(user_id);
CREATE INDEX idx_word_progress_flashcard_id ON word_progress(flashcard_id);
CREATE INDEX idx_lessons_order_index ON lessons(order_index);

-- Grant permissions
GRANT ALL ON lessons TO anon, authenticated;
GRANT ALL ON flashcards TO anon, authenticated;
GRANT ALL ON word_progress TO authenticated;