-- First ensure we have the learning_state type
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'learning_state') THEN
        CREATE TYPE learning_state AS ENUM (
            'new',
            'learning',
            'known',
            'mastered',
            'long-term'
        );
    END IF;
END $$;

-- Drop existing view if it exists
DROP VIEW IF EXISTS keyword_learning_states;

-- Create keyword_learning_states view
CREATE OR REPLACE VIEW keyword_learning_states AS
WITH base_scores AS (
    SELECT 
        'new'::learning_state as state,
        0 as base_score
    UNION ALL SELECT 'learning'::learning_state, 1
    UNION ALL SELECT 'known'::learning_state, 2
    UNION ALL SELECT 'mastered'::learning_state, 3
    UNION ALL SELECT 'long-term'::learning_state, 4
)
SELECT 
    f.id as flashcard_id,
    f.front_text as keyword,
    f.back_text as translation,
    f.example_sentence,
    l.title as lesson_title,
    wp.user_id,
    COALESCE(wp.state, 'new')::learning_state as current_state,
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
JOIN base_scores bs ON COALESCE(wp.state, 'new')::learning_state = bs.state;

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_flashcards_lesson_id ON flashcards(lesson_id);
CREATE INDEX IF NOT EXISTS idx_word_progress_flashcard_id ON word_progress(flashcard_id);
CREATE INDEX IF NOT EXISTS idx_word_progress_state ON word_progress(state);

-- Grant necessary permissions
GRANT SELECT ON keyword_learning_states TO authenticated;