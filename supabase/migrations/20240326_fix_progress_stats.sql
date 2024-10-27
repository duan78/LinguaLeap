-- Drop existing views if they exist
DROP VIEW IF EXISTS word_progress_stats;
DROP MATERIALIZED VIEW IF EXISTS word_progress_stats_mv;

-- Create word_progress_stats view
CREATE OR REPLACE VIEW word_progress_stats AS
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

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_word_progress_user_id ON word_progress(user_id);
CREATE INDEX IF NOT EXISTS idx_word_progress_flashcard_id ON word_progress(flashcard_id);
CREATE INDEX IF NOT EXISTS idx_word_progress_last_reviewed ON word_progress(last_reviewed);
CREATE INDEX IF NOT EXISTS idx_word_progress_mastery_level ON word_progress(mastery_level);

-- Grant necessary permissions
GRANT SELECT ON word_progress_stats TO authenticated;
GRANT ALL ON word_progress TO authenticated;