-- Drop existing views to avoid dependency issues
DROP VIEW IF EXISTS word_progress_stats CASCADE;
DROP VIEW IF EXISTS keyword_learning_states CASCADE;
DROP VIEW IF EXISTS learning_progress_summary CASCADE;

-- Create keyword_learning_states view with consistent score calculation
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
    wp.correct_streak,
    wp.review_count,
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

-- Create word_progress_stats view with corrected calculations
CREATE OR REPLACE VIEW word_progress_stats AS
WITH user_stats AS (
    SELECT 
        kls.user_id,
        COUNT(DISTINCT kls.flashcard_id) as total_words,
        COUNT(DISTINCT CASE 
            WHEN kls.current_state IN ('mastered', 'long-term') 
            THEN kls.flashcard_id 
        END) as words_mastered,
        -- Calculate success rate based on correct streaks vs total reviews
        CAST(
            SUM(CASE 
                WHEN kls.review_count > 0 
                THEN kls.correct_streak::NUMERIC / NULLIF(kls.review_count, 0)
                ELSE 0 
            END) * 100 / 
            NULLIF(COUNT(CASE WHEN kls.review_count > 0 THEN 1 END), 0)
        AS NUMERIC(10,2)) as review_success,
        -- Calculate average score only for reviewed words
        CAST(AVG(
            CASE 
                WHEN kls.review_count > 0 
                THEN kls.total_score 
                ELSE NULL 
            END
        ) AS NUMERIC(10,2)) as average_score,
        COUNT(DISTINCT CASE WHEN kls.current_state = 'unknown' THEN kls.flashcard_id END) as unknown_count,
        COUNT(DISTINCT CASE WHEN kls.current_state = 'learning' THEN kls.flashcard_id END) as learning_count,
        COUNT(DISTINCT CASE WHEN kls.current_state = 'known' THEN kls.flashcard_id END) as known_count,
        COUNT(DISTINCT CASE WHEN kls.current_state = 'mastered' THEN kls.flashcard_id END) as mastered_count,
        COUNT(DISTINCT CASE WHEN kls.current_state = 'long-term' THEN kls.flashcard_id END) as long_term_count,
        MAX(kls.last_reviewed) as last_review_date
    FROM keyword_learning_states kls
    GROUP BY kls.user_id
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
    CAST(AVG(total_score) AS NUMERIC(10,2)) as average_total_score,
    COUNT(*) FILTER (WHERE needs_review) as words_due_review
FROM keyword_learning_states
GROUP BY user_id;

-- Grant necessary permissions
GRANT SELECT ON word_progress_stats TO authenticated;
GRANT SELECT ON keyword_learning_states TO authenticated;
GRANT SELECT ON learning_progress_summary TO authenticated;