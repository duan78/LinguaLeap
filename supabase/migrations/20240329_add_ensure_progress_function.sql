-- Create function to ensure word progress exists for all flashcards
CREATE OR REPLACE FUNCTION ensure_word_progress_exists(user_id UUID)
RETURNS void AS $$
BEGIN
    INSERT INTO word_progress (user_id, flashcard_id, state, mastery_level)
    SELECT 
        user_id,
        f.id,
        'new',
        0
    FROM flashcards f
    WHERE NOT EXISTS (
        SELECT 1 
        FROM word_progress wp 
        WHERE wp.user_id = ensure_word_progress_exists.user_id 
        AND wp.flashcard_id = f.id
    );
END;
$$ LANGUAGE plpgsql;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION ensure_word_progress_exists TO authenticated;