-- Drop existing objects in reverse dependency order
DROP VIEW IF EXISTS word_progress_stats CASCADE;
DROP MATERIALIZED VIEW IF EXISTS word_progress_stats_mv CASCADE;
DROP TABLE IF EXISTS word_progress CASCADE;
DROP TABLE IF EXISTS flashcards CASCADE;
DROP TABLE IF EXISTS lessons CASCADE;

-- Create lessons table
CREATE TABLE lessons (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    description TEXT,
    level TEXT NOT NULL,
    type TEXT NOT NULL DEFAULT 'vocabulary',
    order_index INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT valid_lesson_type CHECK (type IN ('vocabulary', 'grammar', 'pronunciation', 'conversation')),
    CONSTRAINT valid_lesson_level CHECK (level IN ('beginner', 'intermediate', 'advanced'))
);

-- Create flashcards table
CREATE TABLE flashcards (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    lesson_id UUID REFERENCES lessons(id) ON DELETE CASCADE,
    front_text TEXT NOT NULL,
    back_text TEXT NOT NULL,
    example_sentence TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create word_progress table
CREATE TABLE word_progress (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    flashcard_id UUID NOT NULL REFERENCES flashcards(id) ON DELETE CASCADE,
    mastery_level INTEGER DEFAULT 0,
    last_reviewed TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    next_review TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    review_count INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, flashcard_id)
);

-- Create word_progress_stats view
CREATE VIEW word_progress_stats AS
WITH user_stats AS (
    SELECT 
        wp.user_id,
        COUNT(DISTINCT wp.flashcard_id) as total_words,
        COUNT(DISTINCT CASE WHEN wp.mastery_level >= 5 THEN wp.flashcard_id END) as words_mastered,
        MAX(wp.last_reviewed) as last_review_date
    FROM word_progress wp
    GROUP BY wp.user_id
),
daily_reviews AS (
    SELECT 
        user_id,
        DATE(last_reviewed) as review_date,
        COUNT(*) as reviews_count
    FROM word_progress
    WHERE last_reviewed >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY user_id, DATE(last_reviewed)
),
streak_calc AS (
    SELECT 
        us.user_id,
        CASE 
            WHEN us.last_review_date = CURRENT_DATE THEN
                COALESCE((
                    SELECT COUNT(DISTINCT review_date)
                    FROM daily_reviews dr
                    WHERE dr.user_id = us.user_id
                    AND dr.review_date >= CURRENT_DATE - INTERVAL '30 days'
                    AND dr.reviews_count > 0
                ), 0)
            ELSE 0
        END as current_streak
    FROM user_stats us
)
SELECT 
    us.user_id,
    COALESCE(us.words_mastered, 0) as words_mastered,
    COALESCE(sc.current_streak, 0) as current_streak,
    CASE 
        WHEN us.total_words > 0 THEN 
            ROUND((us.words_mastered::NUMERIC / us.total_words) * 100)
        ELSE 0 
    END as review_success
FROM user_stats us
LEFT JOIN streak_calc sc ON us.user_id = sc.user_id;

-- Insert sample data
INSERT INTO lessons (title, description, level, type, order_index) VALUES
('Basic Greetings', 'Learn essential French greetings', 'beginner', 'vocabulary', 1),
('Numbers 1-10', 'Master counting in French', 'beginner', 'vocabulary', 2),
('Common Phrases', 'Essential everyday expressions', 'beginner', 'vocabulary', 3);

INSERT INTO flashcards (lesson_id, front_text, back_text, example_sentence) VALUES
-- Basic Greetings
((SELECT id FROM lessons WHERE title = 'Basic Greetings'), 'Bonjour', 'Hello', 'Bonjour, comment allez-vous?'),
((SELECT id FROM lessons WHERE title = 'Basic Greetings'), 'Au revoir', 'Goodbye', 'Au revoir, à bientôt!'),
((SELECT id FROM lessons WHERE title = 'Basic Greetings'), 'S''il vous plaît', 'Please', 'Un café, s''il vous plaît.'),
((SELECT id FROM lessons WHERE title = 'Basic Greetings'), 'Merci', 'Thank you', 'Merci beaucoup!'),
((SELECT id FROM lessons WHERE title = 'Basic Greetings'), 'De rien', 'You''re welcome', 'De rien, c''est normal.'),

-- Numbers
((SELECT id FROM lessons WHERE title = 'Numbers 1-10'), 'Un', 'One', 'J''ai un chat.'),
((SELECT id FROM lessons WHERE title = 'Numbers 1-10'), 'Deux', 'Two', 'J''ai deux frères.'),
((SELECT id FROM lessons WHERE title = 'Numbers 1-10'), 'Trois', 'Three', 'Trois petits chats.'),
((SELECT id FROM lessons WHERE title = 'Numbers 1-10'), 'Quatre', 'Four', 'Quatre saisons.'),
((SELECT id FROM lessons WHERE title = 'Numbers 1-10'), 'Cinq', 'Five', 'Cinq minutes.'),

-- Common Phrases
((SELECT id FROM lessons WHERE title = 'Common Phrases'), 'Comment allez-vous?', 'How are you?', 'Bonjour, comment allez-vous?'),
((SELECT id FROM lessons WHERE title = 'Common Phrases'), 'Je m''appelle...', 'My name is...', 'Je m''appelle Marie.'),
((SELECT id FROM lessons WHERE title = 'Common Phrases'), 'Enchanté(e)', 'Nice to meet you', 'Enchanté de vous rencontrer.'),
((SELECT id FROM lessons WHERE title = 'Common Phrases'), 'Bonne nuit', 'Good night', 'Bonne nuit et faites de beaux rêves.'),
((SELECT id FROM lessons WHERE title = 'Common Phrases'), 'À bientôt', 'See you soon', 'À bientôt, mon ami!');

-- Enable RLS
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
CREATE INDEX idx_word_progress_last_reviewed ON word_progress(last_reviewed);
CREATE INDEX idx_word_progress_mastery_level ON word_progress(mastery_level);
CREATE INDEX idx_lessons_order_index ON lessons(order_index);

-- Grant permissions
GRANT ALL ON lessons TO anon, authenticated;
GRANT ALL ON flashcards TO anon, authenticated;
GRANT ALL ON word_progress TO authenticated;
GRANT SELECT ON word_progress_stats TO authenticated;