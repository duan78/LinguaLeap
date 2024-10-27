-- Drop existing view
DROP VIEW IF EXISTS word_progress_stats;

-- Create word_progress_stats view with fixed calculations
CREATE OR REPLACE VIEW word_progress_stats AS
WITH user_stats AS (
    SELECT 
        wp.user_id,
        COUNT(DISTINCT wp.flashcard_id) as total_words,
        COUNT(DISTINCT CASE 
            WHEN wp.status IN ('mastered', 'long-term') 
            THEN wp.flashcard_id 
        END) as words_mastered,
        MAX(wp.last_reviewed) as last_review_date,
        -- Calculate average score only for reviewed words
        COALESCE(
            AVG(CASE 
                WHEN wp.review_count > 0 
                THEN wp.score 
            END),
            0
        ) as average_score,
        -- Calculate success rate based on correct reviews
        COALESCE(
            ROUND(
                (SUM(CASE WHEN wp.review_count > 0 THEN wp.correct_streak ELSE 0 END)::NUMERIC / 
                NULLIF(SUM(wp.review_count), 0) * 100),
                2
            ),
            0
        ) as review_success,
        COUNT(DISTINCT CASE 
            WHEN wp.last_reviewed >= CURRENT_DATE 
            THEN wp.flashcard_id 
        END) as words_reviewed_today,
        -- Count words by status
        COUNT(DISTINCT CASE WHEN wp.status = 'new' THEN wp.flashcard_id END) as unknown_count,
        COUNT(DISTINCT CASE WHEN wp.status = 'learning' THEN wp.flashcard_id END) as learning_count,
        COUNT(DISTINCT CASE WHEN wp.status = 'known' THEN wp.flashcard_id END) as known_count,
        COUNT(DISTINCT CASE WHEN wp.status = 'mastered' THEN wp.flashcard_id END) as mastered_count,
        COUNT(DISTINCT CASE WHEN wp.status = 'long-term' THEN wp.flashcard_id END) as long_term_count
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
            WHEN us.words_reviewed_today > 0 THEN
                COALESCE((
                    SELECT COUNT(DISTINCT review_date)
                    FROM daily_reviews dr
                    WHERE dr.user_id = us.user_id
                    AND dr.review_date >= CURRENT_DATE - INTERVAL '30 days'
                    AND dr.reviews_count > 0
                ), 0)
            ELSE 
                GREATEST(
                    COALESCE((
                        SELECT COUNT(DISTINCT review_date)
                        FROM daily_reviews dr
                        WHERE dr.user_id = us.user_id
                        AND dr.review_date >= CURRENT_DATE - INTERVAL '30 days'
                        AND dr.review_date < CURRENT_DATE
                        AND dr.reviews_count > 0
                    ), 0) - 1,
                    0
                )
        END as current_streak
    FROM user_stats us
)
SELECT 
    us.user_id,
    COALESCE(us.words_mastered, 0) as words_mastered,
    COALESCE(sc.current_streak, 0) as current_streak,
    COALESCE(us.review_success, 0) as review_success,
    ROUND(COALESCE(us.average_score, 0)::numeric, 2) as average_score,
    COALESCE(us.unknown_count, 0) as unknown_count,
    COALESCE(us.learning_count, 0) as learning_count,
    COALESCE(us.known_count, 0) as known_count,
    COALESCE(us.mastered_count, 0) as mastered_count,
    COALESCE(us.long_term_count, 0) as long_term_count
FROM user_stats us
LEFT JOIN streak_calc sc ON us.user_id = sc.user_id;

-- Update word_progress table to ensure correct tracking
ALTER TABLE word_progress
ALTER COLUMN score SET DEFAULT 0,
ALTER COLUMN review_count SET DEFAULT 0,
ALTER COLUMN correct_streak SET DEFAULT 0;

-- Add status check constraint if not exists
DO $$ 
BEGIN
    ALTER TABLE word_progress
    ADD CONSTRAINT word_progress_status_check 
    CHECK (status IN ('new', 'learning', 'known', 'mastered', 'long-term'));
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_word_progress_score ON word_progress(score);
CREATE INDEX IF NOT EXISTS idx_word_progress_reviews ON word_progress(review_count);
CREATE INDEX IF NOT EXISTS idx_word_progress_status ON word_progress(status);

-- Grant necessary permissions
GRANT SELECT ON word_progress_stats TO authenticated;