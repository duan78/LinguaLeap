-- First drop any existing views to avoid dependency issues
DROP VIEW IF EXISTS word_progress_stats CASCADE;
DROP VIEW IF EXISTS keyword_learning_states CASCADE;
DROP VIEW IF EXISTS learning_progress_summary CASCADE;

-- Ensure word_progress table exists with correct structure
CREATE TABLE IF NOT EXISTS word_progress (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    flashcard_id UUID NOT NULL REFERENCES flashcards(id) ON DELETE CASCADE,
    state TEXT NOT NULL DEFAULT 'unknown' CHECK (state IN ('unknown', 'learning', 'known', 'mastered', 'long-term')),
    mastery_level INTEGER DEFAULT 0,
    correct_streak INTEGER DEFAULT 0,
    review_count INTEGER DEFAULT 0,
    score FLOAT DEFAULT 0,
    response_time INTEGER,
    last_reviewed TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    next_review TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, flashcard_id)
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_word_progress_user_id ON word_progress(user_id);
CREATE INDEX IF NOT EXISTS idx_word_progress_flashcard_id ON word_progress(flashcard_id);
CREATE INDEX IF NOT EXISTS idx_word_progress_state ON word_progress(state);
CREATE INDEX IF NOT EXISTS idx_word_progress_mastery_level ON word_progress(mastery_level);
CREATE INDEX IF NOT EXISTS idx_word_progress_next_review ON word_progress(next_review);

-- Create word_progress_stats view
CREATE OR REPLACE VIEW word_progress_stats AS
WITH user_stats AS (
    SELECT 
        wp.user_id,
        COUNT(DISTINCT wp.flashcard_id) as total_words,
        COUNT(DISTINCT CASE 
            WHEN wp.state IN ('mastered', 'long-term') 
            THEN wp.flashcard_id 
        END) as words_mastered,
        MAX(wp.last_reviewed) as last_review_date,
        CAST(AVG(
            CASE WHEN wp.review_count > 0 
            THEN wp.score
            ELSE 0 END
        ) AS NUMERIC(10,2)) as average_score,
        COUNT(DISTINCT CASE WHEN wp.state = 'unknown' THEN wp.flashcard_id END) as unknown_count,
        COUNT(DISTINCT CASE WHEN wp.state = 'learning' THEN wp.flashcard_id END) as learning_count,
        COUNT(DISTINCT CASE WHEN wp.state = 'known' THEN wp.flashcard_id END) as known_count,
        COUNT(DISTINCT CASE WHEN wp.state = 'mastered' THEN wp.flashcard_id END) as mastered_count,
        COUNT(DISTINCT CASE WHEN wp.state = 'long-term' THEN wp.flashcard_id END) as long_term_count
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
        COALESCE(
            (
                SELECT COUNT(DISTINCT review_date)
                FROM daily_reviews dr
                WHERE dr.user_id = us.user_id
                AND dr.review_date >= CURRENT_DATE - INTERVAL '30 days'
                AND dr.reviews_count > 0
            ),
            0
        ) as current_streak
    FROM user_stats us
)
SELECT 
    us.user_id,
    COALESCE(us.words_mastered, 0) as words_mastered,
    COALESCE(sc.current_streak, 0) as current_streak,
    COALESCE(us.average_score, 0) as average_score,
    CASE 
        WHEN us.total_words > 0 THEN 
            ROUND((us.words_mastered::NUMERIC / us.total_words) * 100)
        ELSE 0 
    END as review_success,
    COALESCE(us.unknown_count, 0) as unknown_count,
    COALESCE(us.learning_count, 0) as learning_count,
    COALESCE(us.known_count, 0) as known_count,
    COALESCE(us.mastered_count, 0) as mastered_count,
    COALESCE(us.long_term_count, 0) as long_term_count
FROM user_stats us
LEFT JOIN streak_calc sc ON us.user_id = sc.user_id;

-- Create keyword_learning_states view
CREATE OR REPLACE VIEW keyword_learning_states AS
WITH base_scores AS (
    SELECT 
        'unknown'::text as state,
        0 as base_score
    UNION ALL SELECT 'learning', 1
    UNION ALL SELECT 'known', 2
    UNION ALL SELECT 'mastered', 3
    UNION ALL SELECT 'long-term', 4
)
SELECT 
    f.id as flashcard_id,
    f.front_text as keyword,
    f.back_text as translation,
    f.example_sentence,
    l.title as lesson_title,
    wp.user_id,
    COALESCE(wp.state, 'unknown') as current_state,
    bs.base_score,
    COALESCE(wp.score, 0) as actual_score,
    COALESCE(wp.score, 0) + bs.base_score as total_score,
    COALESCE(wp.mastery_level, 0) as mastery_level,
    wp.last_reviewed,
    wp.next_review,
    CASE 
        WHEN wp.next_review IS NULL OR wp.next_review <= NOW() 
        THEN true 
        ELSE false 
    END as needs_review
FROM flashcards f
LEFT JOIN lessons l ON f.lesson_id = l.id
LEFT JOIN word_progress wp ON f.id = wp.flashcard_id
JOIN base_scores bs ON COALESCE(wp.state, 'unknown') = bs.state;

-- Create learning_progress_summary view
CREATE OR REPLACE VIEW learning_progress_summary AS
SELECT 
    user_id,
    COUNT(*) as total_words,
    COUNT(*) FILTER (WHERE current_state = 'unknown') as unknown_count,
    COUNT(*) FILTER (WHERE current_state = 'learning') as learning_count,
    COUNT(*) FILTER (WHERE current_state = 'known') as known_count,
    COUNT(*) FILTER (WHERE current_state = 'mastered') as mastered_count,
    COUNT(*) FILTER (WHERE current_state = 'long-term') as long_term_count,
    CAST(AVG(total_score) AS NUMERIC(10,2)) as average_total_score,
    COUNT(*) FILTER (WHERE needs_review) as words_due_review
FROM keyword_learning_states
GROUP BY user_id;

-- Create function to ensure word progress exists
CREATE OR REPLACE FUNCTION ensure_word_progress_exists(user_id UUID)
RETURNS void AS $$
BEGIN
    INSERT INTO word_progress (user_id, flashcard_id, state, mastery_level)
    SELECT 
        user_id,
        f.id,
        'unknown',
        0
    FROM flashcards f
    WHERE NOT EXISTS (
        SELECT 1 
        FROM word_progress wp 
        WHERE wp.user_id = ensure_word_progress_exists.user_id 
        AND wp.flashcard_id = f.id
    );
END;
$$ LANGUAGE plpgsql;

-- Enable RLS
ALTER TABLE word_progress ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "Users can manage their own progress"
    ON word_progress
    FOR ALL
    TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Grant necessary permissions
GRANT SELECT ON word_progress_stats TO authenticated;
GRANT SELECT ON keyword_learning_states TO authenticated;
GRANT SELECT ON learning_progress_summary TO authenticated;
GRANT EXECUTE ON FUNCTION ensure_word_progress_exists TO authenticated;
GRANT ALL ON word_progress TO authenticated;