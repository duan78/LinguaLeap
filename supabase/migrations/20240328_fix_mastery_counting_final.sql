-- Drop existing views and functions
DROP VIEW IF EXISTS word_progress_stats CASCADE;
DROP VIEW IF EXISTS keyword_learning_states CASCADE;
DROP VIEW IF EXISTS learning_progress_summary CASCADE;
DROP FUNCTION IF EXISTS calculate_lesson_completion CASCADE;

-- Create consistent mastery check function
CREATE OR REPLACE FUNCTION is_word_mastered(
    mastery_level INTEGER,
    correct_streak INTEGER,
    review_count INTEGER
) RETURNS BOOLEAN AS $$
BEGIN
    RETURN mastery_level >= 3;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Create word_progress_stats view with fixed mastery counting
CREATE OR REPLACE VIEW word_progress_stats AS
WITH user_stats AS (
    SELECT 
        wp.user_id,
        COUNT(DISTINCT wp.flashcard_id) as total_words,
        COUNT(DISTINCT CASE 
            WHEN wp.mastery_level >= 3 
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

-- Create function to calculate lesson completion with consistent mastery check
CREATE OR REPLACE FUNCTION calculate_lesson_completion(
    lesson_id UUID,
    user_id UUID
) RETURNS TABLE (
    total_flashcards BIGINT,
    mastered_flashcards BIGINT,
    completion_percentage NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    WITH lesson_stats AS (
        SELECT 
            COUNT(DISTINCT f.id) as total,
            COUNT(DISTINCT CASE 
                WHEN wp.mastery_level >= 3 
                THEN f.id 
            END) as mastered
        FROM flashcards f
        LEFT JOIN word_progress wp ON f.id = wp.flashcard_id AND wp.user_id = $2
        WHERE f.lesson_id = $1
    )
    SELECT 
        total as total_flashcards,
        mastered as mastered_flashcards,
        CASE 
            WHEN total > 0 THEN 
                ROUND((mastered::NUMERIC / total * 100)::NUMERIC, 2)
            ELSE 0 
        END as completion_percentage
    FROM lesson_stats;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to update mastery level
CREATE OR REPLACE FUNCTION update_word_mastery()
RETURNS TRIGGER AS $$
BEGIN
    -- Update mastery level based on performance
    IF NEW.correct_streak >= 5 THEN
        NEW.mastery_level := 4; -- Long-term mastery
    ELSIF NEW.correct_streak >= 3 THEN
        NEW.mastery_level := 3; -- Mastered
    ELSIF NEW.correct_streak >= 2 THEN
        NEW.mastery_level := 2; -- Known
    ELSIF NEW.correct_streak >= 1 THEN
        NEW.mastery_level := 1; -- Learning
    ELSE
        NEW.mastery_level := 0; -- Unknown
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create or replace the trigger
DROP TRIGGER IF EXISTS word_mastery_update_trigger ON word_progress;
CREATE TRIGGER word_mastery_update_trigger
    BEFORE INSERT OR UPDATE OF correct_streak
    ON word_progress
    FOR EACH ROW
    EXECUTE FUNCTION update_word_mastery();

-- Grant necessary permissions
GRANT SELECT ON word_progress_stats TO authenticated;
GRANT EXECUTE ON FUNCTION calculate_lesson_completion TO authenticated;
GRANT EXECUTE ON FUNCTION is_word_mastered TO authenticated;