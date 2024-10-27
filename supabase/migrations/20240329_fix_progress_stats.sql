-- Drop existing views
DROP VIEW IF EXISTS word_progress_stats CASCADE;
DROP VIEW IF EXISTS keyword_learning_states CASCADE;

-- Create or replace the function to calculate mastery level
CREATE OR REPLACE FUNCTION calculate_mastery_level(
    correct_streak INTEGER,
    review_count INTEGER,
    response_time INTEGER DEFAULT NULL
) RETURNS INTEGER AS $$
BEGIN
    IF correct_streak >= 5 AND review_count >= 7 THEN
        RETURN 5; -- Long-term memory
    ELSIF correct_streak >= 3 AND review_count >= 5 THEN
        RETURN 4; -- Mastered
    ELSIF correct_streak >= 2 AND review_count >= 3 THEN
        RETURN 3; -- Known
    ELSIF correct_streak >= 1 THEN
        RETURN 2; -- Learning
    ELSIF review_count > 0 THEN
        RETURN 1; -- Started learning
    ELSE
        RETURN 0; -- New
    END IF;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Create word_progress_stats view with proper calculations
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
        CAST(AVG(wp.score) AS NUMERIC(10,2)) as average_score,
        COUNT(DISTINCT CASE WHEN wp.state = 'new' THEN wp.flashcard_id END) as unknown_count,
        COUNT(DISTINCT CASE WHEN wp.state = 'learning' THEN wp.flashcard_id END) as learning_count,
        COUNT(DISTINCT CASE WHEN wp.state = 'known' THEN wp.flashcard_id END) as known_count,
        COUNT(DISTINCT CASE WHEN wp.state = 'mastered' THEN wp.flashcard_id END) as mastered_count,
        COUNT(DISTINCT CASE WHEN wp.state = 'long-term' THEN wp.flashcard_id END) as long_term_count,
        COUNT(DISTINCT CASE 
            WHEN wp.last_reviewed >= CURRENT_DATE 
            THEN wp.flashcard_id 
        END) as words_reviewed_today
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

-- Create trigger to update mastery level and state
CREATE OR REPLACE FUNCTION update_word_progress()
RETURNS TRIGGER AS $$
BEGIN
    -- Calculate mastery level based on streak and review count
    NEW.mastery_level := calculate_mastery_level(
        NEW.correct_streak,
        NEW.review_count,
        NEW.response_time
    );
    
    -- Update state based on mastery level
    NEW.state := CASE
        WHEN NEW.mastery_level >= 5 THEN 'long-term'
        WHEN NEW.mastery_level = 4 THEN 'mastered'
        WHEN NEW.mastery_level = 3 THEN 'known'
        WHEN NEW.mastery_level > 0 THEN 'learning'
        ELSE 'new'
    END;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create or replace the trigger
DROP TRIGGER IF EXISTS word_progress_update_trigger ON word_progress;
CREATE TRIGGER word_progress_update_trigger
    BEFORE INSERT OR UPDATE OF correct_streak, review_count
    ON word_progress
    FOR EACH ROW
    EXECUTE FUNCTION update_word_progress();

-- Grant necessary permissions
GRANT SELECT ON word_progress_stats TO authenticated;