-- First, ensure the score column exists and has the correct type
ALTER TABLE word_progress
ALTER COLUMN score TYPE FLOAT USING score::float;

-- Drop existing view
DROP VIEW IF EXISTS word_progress_stats;

-- Create word_progress_stats view with improved score calculation
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
        -- Calculate average score based on mastery level and correct streaks
        ROUND(
            AVG(
                CASE 
                    WHEN wp.review_count > 0 THEN
                        -- Base score from mastery level (0-5 scale)
                        CASE 
                            WHEN wp.status = 'new' THEN 0
                            WHEN wp.status = 'learning' THEN 1
                            WHEN wp.status = 'known' THEN 2
                            WHEN wp.status = 'mastered' THEN 4
                            WHEN wp.status = 'long-term' THEN 5
                        END::float +
                        -- Bonus from correct streak (up to 1 point)
                        LEAST(wp.correct_streak::float / 5, 1)
                    ELSE 0
                END
            )::numeric,
            2
        ) as average_score,
        -- Calculate success rate
        ROUND(
            CASE 
                WHEN SUM(wp.review_count) > 0 THEN
                    (SUM(wp.correct_streak)::float / SUM(wp.review_count) * 100)
                ELSE 0
            END,
            2
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
    COALESCE(us.average_score, 0) as average_score,
    COALESCE(us.unknown_count, 0) as unknown_count,
    COALESCE(us.learning_count, 0) as learning_count,
    COALESCE(us.known_count, 0) as known_count,
    COALESCE(us.mastered_count, 0) as mastered_count,
    COALESCE(us.long_term_count, 0) as long_term_count
FROM user_stats us
LEFT JOIN streak_calc sc ON us.user_id = sc.user_id;

-- Update function to calculate and update scores
CREATE OR REPLACE FUNCTION update_word_progress_score()
RETURNS TRIGGER AS $$
BEGIN
    -- Calculate new score based on status and streak
    NEW.score = 
        CASE 
            WHEN NEW.status = 'new' THEN 0
            WHEN NEW.status = 'learning' THEN 1
            WHEN NEW.status = 'known' THEN 2
            WHEN NEW.status = 'mastered' THEN 4
            WHEN NEW.status = 'long-term' THEN 5
        END::float +
        LEAST(NEW.correct_streak::float / 5, 1);
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for score updates
DROP TRIGGER IF EXISTS update_word_progress_score_trigger ON word_progress;
CREATE TRIGGER update_word_progress_score_trigger
    BEFORE INSERT OR UPDATE OF status, correct_streak ON word_progress
    FOR EACH ROW
    EXECUTE FUNCTION update_word_progress_score();

-- Grant necessary permissions
GRANT SELECT ON word_progress_stats TO authenticated;