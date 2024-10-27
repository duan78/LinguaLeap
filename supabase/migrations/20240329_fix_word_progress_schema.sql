-- Drop existing views to avoid dependency issues
DROP VIEW IF EXISTS word_progress_stats CASCADE;
DROP VIEW IF EXISTS keyword_learning_states CASCADE;
DROP VIEW IF EXISTS learning_progress_summary CASCADE;

-- Backup existing data
CREATE TEMP TABLE word_progress_backup AS SELECT * FROM word_progress;

-- Drop and recreate word_progress table with correct schema
DROP TABLE IF EXISTS word_progress CASCADE;

CREATE TABLE word_progress (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    flashcard_id UUID NOT NULL REFERENCES flashcards(id) ON DELETE CASCADE,
    state TEXT NOT NULL DEFAULT 'new' CHECK (state IN ('new', 'learning', 'known', 'mastered', 'long-term')),
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
CREATE INDEX idx_word_progress_user_id ON word_progress(user_id);
CREATE INDEX idx_word_progress_flashcard_id ON word_progress(flashcard_id);
CREATE INDEX idx_word_progress_state ON word_progress(state);
CREATE INDEX idx_word_progress_mastery_level ON word_progress(mastery_level);
CREATE INDEX idx_word_progress_next_review ON word_progress(next_review);

-- Restore data with state mapping
INSERT INTO word_progress (
    user_id,
    flashcard_id,
    state,
    mastery_level,
    correct_streak,
    review_count,
    score,
    response_time,
    last_reviewed,
    next_review,
    created_at,
    updated_at
)
SELECT 
    user_id,
    flashcard_id,
    CASE 
        WHEN mastery_level = 0 THEN 'new'
        WHEN mastery_level = 1 THEN 'learning'
        WHEN mastery_level = 2 THEN 'known'
        WHEN mastery_level = 3 THEN 'mastered'
        ELSE 'long-term'
    END as state,
    mastery_level,
    COALESCE(correct_streak, 0),
    COALESCE(review_count, 0),
    COALESCE(score, 0),
    response_time,
    COALESCE(last_reviewed, NOW()),
    COALESCE(next_review, NOW()),
    COALESCE(created_at, NOW()),
    COALESCE(updated_at, NOW())
FROM word_progress_backup;

-- Drop temporary backup table
DROP TABLE word_progress_backup;

-- Recreate views
CREATE VIEW word_progress_stats AS
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
        COUNT(DISTINCT CASE 
            WHEN wp.state = 'new' THEN wp.flashcard_id 
        END) as unknown_count,
        COUNT(DISTINCT CASE 
            WHEN wp.state = 'learning' THEN wp.flashcard_id 
        END) as learning_count,
        COUNT(DISTINCT CASE 
            WHEN wp.state = 'known' THEN wp.flashcard_id 
        END) as known_count,
        COUNT(DISTINCT CASE 
            WHEN wp.state = 'mastered' THEN wp.flashcard_id 
        END) as mastered_count,
        COUNT(DISTINCT CASE 
            WHEN wp.state = 'long-term' THEN wp.flashcard_id 
        END) as long_term_count
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
GRANT ALL ON word_progress TO authenticated;