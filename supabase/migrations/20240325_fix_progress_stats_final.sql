-- Drop existing view if it exists
DROP VIEW IF EXISTS word_progress_stats;

-- Create word_progress_stats view with proper handling of null values and defaults
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

-- Ensure the view exists for all users, even those without progress
INSERT INTO word_progress (user_id, flashcard_id, mastery_level)
SELECT 
    au.id as user_id,
    f.id as flashcard_id,
    0 as mastery_level
FROM auth.users au
CROSS JOIN flashcards f
WHERE NOT EXISTS (
    SELECT 1 
    FROM word_progress wp 
    WHERE wp.user_id = au.id 
    AND wp.flashcard_id = f.id
)
ON CONFLICT (user_id, flashcard_id) DO NOTHING;

-- Grant necessary permissions
GRANT SELECT ON word_progress_stats TO authenticated;