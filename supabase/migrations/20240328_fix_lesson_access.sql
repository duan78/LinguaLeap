-- Drop existing function if it exists
DROP FUNCTION IF EXISTS calculate_lesson_completion;

-- Create function to calculate lesson completion
CREATE OR REPLACE FUNCTION calculate_lesson_completion(
    lesson_id UUID,
    user_id UUID
) RETURNS TABLE (
    total_flashcards BIGINT,
    mastered_flashcards BIGINT
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
        mastered as mastered_flashcards
    FROM lesson_stats;
END;
$$ LANGUAGE plpgsql;

-- Grant necessary permissions
GRANT EXECUTE ON FUNCTION calculate_lesson_completion TO authenticated;