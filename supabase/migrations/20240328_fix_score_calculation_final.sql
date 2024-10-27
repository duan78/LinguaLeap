-- Drop existing views to avoid dependency issues
DROP VIEW IF EXISTS word_progress_stats CASCADE;
DROP VIEW IF EXISTS keyword_learning_states CASCADE;
DROP VIEW IF EXISTS learning_progress_summary CASCADE;

-- Create a consistent score calculation function
CREATE OR REPLACE FUNCTION calculate_word_score(
    mastery_level INTEGER,
    correct_streak INTEGER,
    review_count INTEGER
) RETURNS NUMERIC AS $$
BEGIN
    RETURN CAST(
        -- Base score from mastery level (0-5)
        CASE
            WHEN mastery_level = 0 THEN 0
            WHEN mastery_level = 1 THEN 1
            WHEN mastery_level = 2 THEN 2
            WHEN mastery_level = 3 THEN 3
            WHEN mastery_level = 4 THEN 4
            ELSE 5
        END +
        -- Bonus from correct streak (up to 1 point)
        LEAST(correct_streak::NUMERIC / 5, 1) +
        -- Bonus from review count (up to 1 point)
        LEAST(review_count::NUMERIC / 10, 1)
    AS NUMERIC(10,2));
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Create word_progress_stats view with consistent score calculation
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
        -- Calculate average score using the consistent function
        CAST(AVG(
            CASE WHEN wp.review_count > 0 
            THEN calculate_word_score(wp.mastery_level, wp.correct_streak, wp.review_count)
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

-- Create keyword_learning_states view with the same score calculation
CREATE OR REPLACE VIEW keyword_learning_states AS
WITH base_scores AS (
    SELECT 
        'unknown'::learning_state as state,
        0 as base_score
    UNION ALL SELECT 'learning'::learning_state, 1
    UNION ALL SELECT 'known'::learning_state, 2
    UNION ALL SELECT 'memorized'::learning_state, 3
    UNION ALL SELECT 'long_term'::learning_state, 4
),
word_stats AS (
    SELECT 
        f.id as flashcard_id,
        f.front_text as keyword,
        f.back_text as translation,
        l.title as lesson_title,
        wp.user_id,
        wp.mastery_level,
        CASE
            WHEN wp.mastery_level IS NULL OR wp.mastery_level = 0 THEN 'unknown'::learning_state
            WHEN wp.mastery_level = 1 THEN 'learning'::learning_state
            WHEN wp.mastery_level = 2 THEN 'known'::learning_state
            WHEN wp.mastery_level = 3 THEN 'memorized'::learning_state
            WHEN wp.mastery_level >= 4 THEN 'long_term'::learning_state
        END as current_state,
        calculate_word_score(wp.mastery_level, wp.correct_streak, wp.review_count) as score,
        wp.last_reviewed,
        wp.next_review
    FROM flashcards f
    LEFT JOIN lessons l ON f.lesson_id = l.id
    LEFT JOIN word_progress wp ON f.id = wp.flashcard_id
)
SELECT 
    ws.flashcard_id,
    ws.keyword,
    ws.translation,
    ws.lesson_title,
    ws.user_id,
    ws.current_state,
    bs.base_score,
    COALESCE(ws.score, 0) as actual_score,
    COALESCE(ws.score, 0) + bs.base_score as total_score,
    ws.mastery_level,
    ws.last_reviewed,
    ws.next_review,
    CASE 
        WHEN ws.next_review <= NOW() THEN true 
        ELSE false 
    END as needs_review
FROM word_stats ws
JOIN base_scores bs ON ws.current_state = bs.state;

-- Create learning_progress_summary view
CREATE OR REPLACE VIEW learning_progress_summary AS
SELECT 
    user_id,
    COUNT(*) as total_words,
    COUNT(*) FILTER (WHERE current_state = 'unknown') as unknown_count,
    COUNT(*) FILTER (WHERE current_state = 'learning') as learning_count,
    COUNT(*) FILTER (WHERE current_state = 'known') as known_count,
    COUNT(*) FILTER (WHERE current_state = 'memorized') as memorized_count,
    COUNT(*) FILTER (WHERE current_state = 'long_term') as long_term_count,
    CAST(AVG(total_score) AS NUMERIC(10,2)) as average_total_score,
    COUNT(*) FILTER (WHERE needs_review) as words_due_review
FROM keyword_learning_states
GROUP BY user_id;

-- Create trigger to update score automatically
CREATE OR REPLACE FUNCTION update_word_score()
RETURNS TRIGGER AS $$
BEGIN
    NEW.score = calculate_word_score(NEW.mastery_level, NEW.correct_streak, NEW.review_count);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create or replace the trigger
DROP TRIGGER IF EXISTS word_score_update_trigger ON word_progress;
CREATE TRIGGER word_score_update_trigger
    BEFORE INSERT OR UPDATE OF mastery_level, correct_streak, review_count
    ON word_progress
    FOR EACH ROW
    EXECUTE FUNCTION update_word_score();

-- Grant necessary permissions
GRANT SELECT ON word_progress_stats TO authenticated;
GRANT SELECT ON keyword_learning_states TO authenticated;
GRANT SELECT ON learning_progress_summary TO authenticated;