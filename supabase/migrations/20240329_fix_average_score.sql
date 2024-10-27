-- Drop existing views
DROP VIEW IF EXISTS word_progress_stats CASCADE;
DROP VIEW IF EXISTS keyword_learning_states CASCADE;

-- Create keyword_learning_states view with correct score calculation
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
    COALESCE(wp.score, 0) + bs.base_score as total_score,
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

-- Create word_progress_stats view using the same score calculation
CREATE OR REPLACE VIEW word_progress_stats AS
WITH keyword_stats AS (
    SELECT 
        user_id,
        COUNT(*) as total_words,
        COUNT(*) FILTER (WHERE current_state IN ('mastered', 'long-term')) as words_mastered,
        AVG(total_score) FILTER (WHERE actual_score > 0) as average_score,
        COUNT(*) FILTER (WHERE current_state = 'unknown') as unknown_count,
        COUNT(*) FILTER (WHERE current_state = 'learning') as learning_count,
        COUNT(*) FILTER (WHERE current_state = 'known') as known_count,
        COUNT(*) FILTER (WHERE current_state = 'mastered') as mastered_count,
        COUNT(*) FILTER (WHERE current_state = 'long-term') as long_term_count
    FROM keyword_learning_states
    GROUP BY user_id
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
        ks.user_id,
        COALESCE(
            (
                SELECT COUNT(DISTINCT review_date)
                FROM daily_reviews dr
                WHERE dr.user_id = ks.user_id
                AND dr.review_date >= CURRENT_DATE - INTERVAL '30 days'
                AND dr.reviews_count > 0
            ),
            0
        ) as current_streak
    FROM keyword_stats ks
)
SELECT 
    ks.user_id,
    ks.total_words,
    COALESCE(ks.words_mastered, 0) as words_mastered,
    COALESCE(sc.current_streak, 0) as current_streak,
    CASE 
        WHEN ks.total_words > 0 THEN 
            ROUND((ks.words_mastered::NUMERIC / ks.total_words) * 100)
        ELSE 0 
    END as review_success,
    ROUND(COALESCE(ks.average_score, 0)::NUMERIC, 2) as average_score,
    COALESCE(ks.unknown_count, 0) as unknown_count,
    COALESCE(ks.learning_count, 0) as learning_count,
    COALESCE(ks.known_count, 0) as known_count,
    COALESCE(ks.mastered_count, 0) as mastered_count,
    COALESCE(ks.long_term_count, 0) as long_term_count
FROM keyword_stats ks
LEFT JOIN streak_calc sc ON ks.user_id = sc.user_id;

-- Grant necessary permissions
GRANT SELECT ON word_progress_stats TO authenticated;
GRANT SELECT ON keyword_learning_states TO authenticated;