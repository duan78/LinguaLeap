-- Optimize queries and add missing indexes
CREATE INDEX IF NOT EXISTS idx_word_progress_user_mastery 
ON word_progress(user_id, mastery_level);

CREATE INDEX IF NOT EXISTS idx_word_progress_last_reviewed 
ON word_progress(last_reviewed);

CREATE INDEX IF NOT EXISTS idx_flashcards_lesson_id 
ON flashcards(lesson_id);

-- Create materialized view for faster stats queries
CREATE MATERIALIZED VIEW word_progress_stats_mv AS
SELECT 
    wp.user_id,
    COUNT(DISTINCT CASE WHEN wp.mastery_level >= 5 THEN wp.flashcard_id END) as words_mastered,
    COUNT(DISTINCT CASE WHEN DATE(wp.last_reviewed) = CURRENT_DATE THEN wp.flashcard_id END) > 0 as has_practiced_today,
    ROUND(
        (COUNT(DISTINCT CASE WHEN wp.mastery_level > 0 THEN wp.flashcard_id END)::NUMERIC / 
        NULLIF(COUNT(DISTINCT wp.flashcard_id), 0) * 100)
    ) as review_success
FROM word_progress wp
GROUP BY wp.user_id;

-- Create function to refresh materialized view
CREATE OR REPLACE FUNCTION refresh_word_progress_stats()
RETURNS TRIGGER AS $$
BEGIN
    REFRESH MATERIALIZED VIEW CONCURRENTLY word_progress_stats_mv;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to refresh materialized view
CREATE TRIGGER refresh_word_progress_stats_trigger
AFTER INSERT OR UPDATE OR DELETE ON word_progress
FOR EACH STATEMENT
EXECUTE FUNCTION refresh_word_progress_stats();

-- Grant permissions
GRANT SELECT ON word_progress_stats_mv TO authenticated;