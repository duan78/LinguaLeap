-- Drop existing views
DROP VIEW IF EXISTS word_progress_stats CASCADE;

-- Create word_progress_stats view with simplified structure
CREATE OR REPLACE VIEW word_progress_stats AS
WITH user_stats AS (
    SELECT 
        wp.user_id,
        COUNT(DISTINCT wp.flashcard_id) as total_words,
        COUNT(DISTINCT CASE 
            WHEN wp.mastery_level >= 5 
            THEN wp.flashcard_id 
        END) as words_mastered,
        MAX(wp.last_reviewed) as last_review_date,
        -- Calculate average score
        CAST(AVG(
            CASE WHEN wp.review_count > 0 
            THEN wp.mastery_level + LEAST(wp.correct_streak::NUMERIC / 5, 1)
            ELSE 0 END
        ) AS NUMERIC(10,2)) as average_score,
        -- Calculate success rate
        CAST(
            CASE 
                WHEN SUM(wp.review_count) > 0 
                THEN (SUM(wp.correct_streak)::NUMERIC / NULLIF(SUM(wp.review_count), 0) * 100)
                ELSE 0 
            END 
        AS NUMERIC(10,2)) as review_success,
        -- Count words by mastery level
        COUNT(DISTINCT CASE WHEN wp.mastery_level = 0 THEN wp.flashcard_id END) as unknown_count,
        COUNT(DISTINCT CASE WHEN wp.mastery_level = 1 THEN wp.flashcard_id END) as learning_count,
        COUNT(DISTINCT CASE WHEN wp.mastery_level = 2 THEN wp.flashcard_id END) as known_count,
        COUNT(DISTINCT CASE WHEN wp.mastery_level = 3 THEN wp.flashcard_id END) as mastered_count,
        COUNT(DISTINCT CASE WHEN wp.mastery_level >= 4 THEN wp.flashcard_id END) as long_term_count
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
    COALESCE(us.review_success, 0) as review_success,
    COALESCE(us.average_score, 0) as average_score,
    COALESCE(us.unknown_count, 0) as unknown_count,
    COALESCE(us.learning_count, 0) as learning_count,
    COALESCE(us.known_count, 0) as known_count,
    COALESCE(us.mastered_count, 0) as mastered_count,
    COALESCE(us.long_term_count, 0) as long_term_count
FROM user_stats us
LEFT JOIN streak_calc sc ON us.user_id = sc.user_id;

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_word_progress_user_id ON word_progress(user_id);
CREATE INDEX IF NOT EXISTS idx_word_progress_mastery ON word_progress(mastery_level);
CREATE INDEX IF NOT EXISTS idx_word_progress_last_reviewed ON word_progress(last_reviewed);

-- Grant necessary permissions
GRANT SELECT ON word_progress_stats TO authenticated;