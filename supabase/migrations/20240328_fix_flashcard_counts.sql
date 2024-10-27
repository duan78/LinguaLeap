-- Drop existing views
DROP VIEW IF EXISTS word_progress_stats CASCADE;
DROP VIEW IF EXISTS keyword_learning_states CASCADE;

-- Create keyword_learning_states view with consistent state mapping
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
            WHEN wp.status = 'new' OR wp.status IS NULL THEN 'unknown'::learning_state
            WHEN wp.status = 'learning' THEN 'learning'::learning_state
            WHEN wp.status = 'known' THEN 'known'::learning_state
            WHEN wp.status = 'mastered' THEN 'memorized'::learning_state
            WHEN wp.status = 'long-term' THEN 'long_term'::learning_state
        END as current_state,
        wp.score,
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

-- Create word_progress_stats view with consistent counting
CREATE OR REPLACE VIEW word_progress_stats AS
WITH user_stats AS (
    SELECT 
        kls.user_id,
        COUNT(DISTINCT kls.flashcard_id) as total_words,
        COUNT(DISTINCT CASE 
            WHEN kls.current_state IN ('memorized', 'long_term') 
            THEN kls.flashcard_id 
        END) as words_mastered,
        COUNT(DISTINCT CASE 
            WHEN kls.current_state = 'unknown' 
            THEN kls.flashcard_id 
        END) as unknown_count,
        COUNT(DISTINCT CASE 
            WHEN kls.current_state = 'learning' 
            THEN kls.flashcard_id 
        END) as learning_count,
        COUNT(DISTINCT CASE 
            WHEN kls.current_state = 'known' 
            THEN kls.flashcard_id 
        END) as known_count,
        COUNT(DISTINCT CASE 
            WHEN kls.current_state = 'memorized' 
            THEN kls.flashcard_id 
        END) as mastered_count,
        COUNT(DISTINCT CASE 
            WHEN kls.current_state = 'long_term' 
            THEN kls.flashcard_id 
        END) as long_term_count,
        CAST(AVG(kls.total_score) AS NUMERIC(10,2)) as average_score,
        CAST(
            CASE 
                WHEN COUNT(*) > 0 THEN
                    COUNT(CASE WHEN kls.current_state != 'unknown' THEN 1 END)::NUMERIC / 
                    COUNT(*) * 100
                ELSE 0
            END 
        AS NUMERIC(10,2)) as review_success
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

-- Grant necessary permissions
GRANT SELECT ON word_progress_stats TO authenticated;
GRANT SELECT ON keyword_learning_states TO authenticated;