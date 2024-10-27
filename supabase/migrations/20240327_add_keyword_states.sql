-- Create enum for learning states if not exists
DO $$ BEGIN
    CREATE TYPE learning_state AS ENUM (
        'unknown',
        'learning',
        'known',
        'memorized',
        'long_term'
    );
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

-- Create or replace the keyword learning states view
CREATE OR REPLACE VIEW keyword_learning_states AS
WITH base_scores AS (
    SELECT 
        'unknown'::learning_state as state,
        0 as base_score
    UNION ALL SELECT 'learning', 1
    UNION ALL SELECT 'known', 2
    UNION ALL SELECT 'memorized', 3
    UNION ALL SELECT 'long_term', 4
),
word_stats AS (
    SELECT 
        f.id as flashcard_id,
        f.front_text as keyword,
        f.back_text as translation,
        l.title as lesson_title,
        wp.user_id,
        wp.score,
        wp.mastery_level,
        CASE
            WHEN wp.mastery_level IS NULL OR wp.mastery_level = 0 THEN 'unknown'
            WHEN wp.mastery_level = 1 THEN 'learning'
            WHEN wp.mastery_level = 2 THEN 'known'
            WHEN wp.mastery_level = 3 THEN 'memorized'
            WHEN wp.mastery_level >= 4 THEN 'long_term'
        END::learning_state as current_state,
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

-- Create a summary view for learning progress
CREATE OR REPLACE VIEW learning_progress_summary AS
SELECT 
    user_id,
    COUNT(*) as total_words,
    COUNT(*) FILTER (WHERE current_state = 'unknown') as unknown_count,
    COUNT(*) FILTER (WHERE current_state = 'learning') as learning_count,
    COUNT(*) FILTER (WHERE current_state = 'known') as known_count,
    COUNT(*) FILTER (WHERE current_state = 'memorized') as memorized_count,
    COUNT(*) FILTER (WHERE current_state = 'long_term') as long_term_count,
    ROUND(AVG(total_score), 2) as average_total_score,
    COUNT(*) FILTER (WHERE needs_review) as words_due_review
FROM keyword_learning_states
GROUP BY user_id;

-- Grant necessary permissions
GRANT SELECT ON keyword_learning_states TO authenticated;
GRANT SELECT ON learning_progress_summary TO authenticated;