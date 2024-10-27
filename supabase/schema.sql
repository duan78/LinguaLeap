-- Drop existing objects in reverse dependency order
DROP VIEW IF EXISTS word_progress_stats;
DROP TABLE IF EXISTS word_progress;
DROP TABLE IF EXISTS flashcards;
DROP TABLE IF EXISTS lessons;

-- Create lessons table
CREATE TABLE lessons (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title TEXT NOT NULL,
    description TEXT,
    difficulty_level INTEGER DEFAULT 1,
    order_index INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create flashcards table
CREATE TABLE flashcards (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    lesson_id UUID REFERENCES lessons(id) ON DELETE CASCADE,
    front_text TEXT NOT NULL,
    back_text TEXT NOT NULL,
    example_sentence TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create word_progress table
CREATE TABLE word_progress (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    flashcard_id UUID NOT NULL REFERENCES flashcards(id) ON DELETE CASCADE,
    mastery_level INTEGER DEFAULT 0,
    last_reviewed TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    next_review TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, flashcard_id)
);

-- Create word_progress_stats view with corrected ROUND function
CREATE OR REPLACE VIEW word_progress_stats AS
WITH user_stats AS (
    SELECT 
        wp.user_id,
        COUNT(DISTINCT wp.flashcard_id) as total_words_learned,
        COUNT(DISTINCT CASE WHEN wp.mastery_level >= 5 THEN wp.flashcard_id END) as words_mastered,
        CAST(
            CASE 
                WHEN COUNT(DISTINCT wp.flashcard_id) > 0 
                THEN (COUNT(DISTINCT CASE WHEN wp.mastery_level >= 5 THEN wp.flashcard_id END)::NUMERIC * 100) / 
                     COUNT(DISTINCT wp.flashcard_id)
                ELSE 0 
            END 
        AS INTEGER) as mastery_percentage,
        MAX(wp.last_reviewed)::DATE as last_review_date
    FROM word_progress wp
    GROUP BY wp.user_id
),
daily_reviews AS (
    SELECT 
        user_id,
        last_reviewed::DATE as review_date,
        COUNT(*) as reviews_count
    FROM word_progress
    GROUP BY user_id, last_reviewed::DATE
),
streak_calc AS (
    SELECT 
        dr.user_id,
        COUNT(*) as current_streak
    FROM daily_reviews dr
    WHERE dr.reviews_count > 0
    AND dr.review_date >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY dr.user_id
)
SELECT 
    us.user_id,
    us.total_words_learned,
    us.words_mastered,
    us.mastery_percentage as review_success,
    COALESCE(sc.current_streak, 0) as current_streak,
    us.last_review_date
FROM user_stats us
LEFT JOIN streak_calc sc ON us.user_id = sc.user_id;

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
GRANT SELECT ON word_progress_stats TO authenticated;