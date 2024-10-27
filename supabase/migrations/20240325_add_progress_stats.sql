-- Create word progress stats view
CREATE OR REPLACE VIEW word_progress_stats AS
WITH user_stats AS (
    SELECT 
        wp.user_id,
        COUNT(DISTINCT CASE WHEN wp.mastery_level >= 5 THEN wp.flashcard_id END) as words_mastered,
        COUNT(DISTINCT wp.flashcard_id) as total_words_studied,
        MAX(wp.last_reviewed) as last_review_date,
        COALESCE(
            SUM(CASE WHEN wp.mastery_level > 0 THEN 1 ELSE 0 END)::float / 
            NULLIF(COUNT(wp.id), 0),
            0
        ) * 100 as success_rate
    FROM word_progress wp
    GROUP BY wp.user_id
),
streak_calc AS (
    SELECT 
        user_id,
        CASE 
            WHEN last_review_date >= CURRENT_DATE - INTERVAL '1 day' THEN
                1 + COALESCE((
                    SELECT COUNT(DISTINCT DATE(last_reviewed))
                    FROM word_progress wp2
                    WHERE wp2.user_id = user_stats.user_id
                    AND DATE(wp2.last_reviewed) < CURRENT_DATE
                    AND DATE(wp2.last_reviewed) >= CURRENT_DATE - INTERVAL '30 days'
                ), 0)
            ELSE 0
        END as current_streak
    FROM user_stats
)
SELECT 
    us.user_id,
    us.words_mastered,
    us.total_words_studied,
    us.success_rate,
    sc.current_streak,
    us.last_review_date
FROM user_stats us
JOIN streak_calc sc ON us.user_id = sc.user_id;