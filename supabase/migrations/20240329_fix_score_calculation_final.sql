-- Drop existing views
DROP VIEW IF EXISTS word_progress_stats CASCADE;
DROP VIEW IF EXISTS keyword_learning_states CASCADE;

-- Create word_progress_stats view with consistent score calculation
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
        -- Calculate average score only from words that have been reviewed
        CAST(AVG(
            CASE 
                WHEN wp.review_count > 0 
                THEN wp.score + wp.mastery_level + LEAST(wp.correct_streak::NUMERIC / 5, 1)
                ELSE NULL 
            END
        ) AS NUMERIC(10,2)) as average_score,
        -- Calculate success rate based on correct reviews vs total reviews
        CAST(
            CASE 
                WHEN SUM(wp.review_count) > 0 
                THEN (SUM(wp.correct_streak)::NUMERIC / NULLIF(SUM(wp.review_count), 0) * 100)
                ELSE 0 
            END 
        AS NUMERIC(10,2)) as review_success,
        -- Count words by state
        COUNT(DISTINCT CASE WHEN wp.state = 'unknown' THEN wp.flashcard_id END) as unknown_count,
        COUNT(DISTINCT CASE WHEN wp.state = 'learning' THEN wp.flashcard_id END) as learning_count,
        COUNT(DISTINCT CASE WHEN wp.state = 'known' THEN wp.flashcard_id END) as known_count,
        COUNT(DISTINCT CASE WHEN wp.state = 'mastered' THEN wp.flashcard_id END) as mastered_count,
        COUNT(DISTINCT CASE WHEN wp.state = 'long-term' THEN wp.flashcard_id END) as long_term_count
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
        'unknown'::text as state,
        0 as base_score
    UNION ALL SELECT 'learning', 1
    UNION ALL SELECT 'known', 2
    UNION ALL SELECT 'mastered', 3
    UNION ALL SELECT 'long-term', 4
)
SELECT 
    f.id as flashcard_id,
    f.front_text as keyword,
    f.back_text as translation,
    f.example_sentence,
    l.title as lesson_title,
    wp.user_id,
    COALESCE(wp.state, 'unknown') as current_state,
    bs.base_score,
    COALESCE(wp.score, 0) as actual_score,
    -- Use the same score calculation as word_progress_stats
    CASE 
        WHEN wp.review_count > 0 
        THEN wp.score + wp.mastery_level + LEAST(wp.correct_streak::NUMERIC / 5, 1)
        ELSE 0 
    END as total_score,
    COALESCE(wp.mastery_level, 0) as mastery_level,
    wp.last_reviewed,
    wp.next_review,
    CASE 
        WHEN wp.next_review IS NULL OR wp.next_review <= NOW() 
        THEN true 
        ELSE false 
    END as needs_review
FROM flashcards f
LEFT JOIN lessons l ON f.lesson_id = l.id
LEFT JOIN word_progress wp ON f.id = wp.flashcard_id
JOIN base_scores bs ON COALESCE(wp.state, 'unknown') = bs.state;

-- Grant necessary permissions
GRANT SELECT ON word_progress_stats TO authenticated;
GRANT SELECT ON keyword_learning_states TO authenticated;