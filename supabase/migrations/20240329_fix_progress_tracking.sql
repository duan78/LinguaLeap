-- Drop existing views to avoid dependency issues
DROP VIEW IF EXISTS word_progress_stats CASCADE;
DROP VIEW IF EXISTS keyword_learning_states CASCADE;
DROP VIEW IF EXISTS learning_progress_summary CASCADE;

-- Create function to calculate score consistently
CREATE OR REPLACE FUNCTION calculate_word_score(
    mastery_level INTEGER,
    correct_streak INTEGER,
    response_time INTEGER DEFAULT NULL
) RETURNS NUMERIC AS $$
BEGIN
    -- Base score from mastery level (0-5)
    RETURN CAST(
        mastery_level + 
        -- Bonus from correct streak (up to 1 point)
        LEAST(correct_streak::NUMERIC / 5, 1) +
        -- Time bonus (up to 1 point, only if response time is provided)
        CASE 
            WHEN response_time IS NOT NULL THEN
                LEAST((5000 - LEAST(response_time, 5000))::NUMERIC / 5000, 1)
            ELSE 0
        END
    AS NUMERIC(10,2));
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Create trigger to update score automatically
CREATE OR REPLACE FUNCTION update_word_progress()
RETURNS TRIGGER AS $$
BEGIN
    -- Calculate new score
    NEW.score := calculate_word_score(NEW.mastery_level, NEW.correct_streak, NEW.response_time);
    
    -- Update state based on mastery level and streak
    NEW.state := CASE
        WHEN NEW.mastery_level >= 4 AND NEW.correct_streak >= 5 THEN 'long-term'
        WHEN NEW.mastery_level >= 3 THEN 'mastered'
        WHEN NEW.mastery_level >= 2 THEN 'known'
        WHEN NEW.mastery_level >= 1 THEN 'learning'
        ELSE 'unknown'
    END;
    
    -- Update next review date based on state
    NEW.next_review := CASE NEW.state
        WHEN 'long-term' THEN NOW() + INTERVAL '7 days'
        WHEN 'mastered' THEN NOW() + INTERVAL '3 days'
        WHEN 'known' THEN NOW() + INTERVAL '1 day'
        WHEN 'learning' THEN NOW() + INTERVAL '4 hours'
        ELSE NOW() + INTERVAL '1 hour'
    END;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create or replace the trigger
DROP TRIGGER IF EXISTS word_progress_update_trigger ON word_progress;
CREATE TRIGGER word_progress_update_trigger
    BEFORE INSERT OR UPDATE OF mastery_level, correct_streak, response_time
    ON word_progress
    FOR EACH ROW
    EXECUTE FUNCTION update_word_progress();

-- Create keyword_learning_states view with consistent calculations
CREATE OR REPLACE VIEW keyword_learning_states AS
SELECT 
    f.id as flashcard_id,
    f.front_text as keyword,
    f.back_text as translation,
    f.example_sentence,
    l.title as lesson_title,
    wp.user_id,
    wp.state as current_state,
    wp.mastery_level,
    wp.score as actual_score,
    wp.score as total_score,
    wp.last_reviewed,
    wp.next_review,
    CASE 
        WHEN wp.next_review IS NULL OR wp.next_review <= NOW() 
        THEN true 
        ELSE false 
    END as needs_review
FROM flashcards f
LEFT JOIN lessons l ON f.lesson_id = l.id
LEFT JOIN word_progress wp ON f.id = wp.flashcard_id;

-- Create word_progress_stats view using the same calculations
CREATE OR REPLACE VIEW word_progress_stats AS
WITH user_stats AS (
    SELECT 
        wp.user_id,
        COUNT(DISTINCT wp.flashcard_id) as total_words,
        COUNT(DISTINCT CASE 
            WHEN wp.state IN ('mastered', 'long-term') 
            THEN wp.flashcard_id 
        END) as words_mastered,
        AVG(wp.score) FILTER (WHERE wp.review_count > 0) as average_score,
        COUNT(DISTINCT CASE WHEN wp.state = 'unknown' THEN wp.flashcard_id END) as unknown_count,
        COUNT(DISTINCT CASE WHEN wp.state = 'learning' THEN wp.flashcard_id END) as learning_count,
        COUNT(DISTINCT CASE WHEN wp.state = 'known' THEN wp.flashcard_id END) as known_count,
        COUNT(DISTINCT CASE WHEN wp.state = 'mastered' THEN wp.flashcard_id END) as mastered_count,
        COUNT(DISTINCT CASE WHEN wp.state = 'long-term' THEN wp.flashcard_id END) as long_term_count,
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
    us.total_words,
    COALESCE(us.words_mastered, 0) as words_mastered,
    COALESCE(sc.current_streak, 0) as current_streak,
    ROUND(COALESCE(us.average_score, 0)::NUMERIC, 2) as average_score,
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
    ROUND(AVG(total_score)::NUMERIC, 2) as average_total_score,
    COUNT(*) FILTER (WHERE needs_review) as words_due_review
FROM keyword_learning_states
GROUP BY user_id;

-- Grant necessary permissions
GRANT SELECT ON word_progress_stats TO authenticated;
GRANT SELECT ON keyword_learning_states TO authenticated;
GRANT SELECT ON learning_progress_summary TO authenticated;