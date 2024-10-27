-- Drop existing materialized view if it exists
DROP MATERIALIZED VIEW IF EXISTS word_progress_stats_mv;

-- Create materialized view for faster stats queries
CREATE MATERIALIZED VIEW word_progress_stats_mv AS
SELECT 
    wp.user_id,
    COUNT(DISTINCT CASE WHEN wp.mastery_level >= 5 THEN wp.flashcard_id END) as words_mastered,
    COUNT(DISTINCT CASE WHEN DATE(wp.last_reviewed) = CURRENT_DATE THEN wp.flashcard_id END) > 0 as has_practiced_today,
    ROUND(
        CASE 
            WHEN COUNT(DISTINCT wp.flashcard_id) > 0 THEN
                (COUNT(DISTINCT CASE WHEN wp.mastery_level > 0 THEN wp.flashcard_id END)::NUMERIC / 
                COUNT(DISTINCT wp.flashcard_id) * 100)
            ELSE 0
        END
    ) as review_success
FROM word_progress wp
GROUP BY wp.user_id;

-- Create index on materialized view
CREATE UNIQUE INDEX ON word_progress_stats_mv (user_id);

-- Create function to refresh materialized view
CREATE OR REPLACE FUNCTION refresh_word_progress_stats()
RETURNS TRIGGER AS $$
BEGIN
    REFRESH MATERIALIZED VIEW CONCURRENTLY word_progress_stats_mv;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to refresh materialized view
DROP TRIGGER IF EXISTS refresh_word_progress_stats_trigger ON word_progress;
CREATE TRIGGER refresh_word_progress_stats_trigger
AFTER INSERT OR UPDATE OR DELETE ON word_progress
FOR EACH STATEMENT
EXECUTE FUNCTION refresh_word_progress_stats();

-- Initial refresh of materialized view
REFRESH MATERIALIZED VIEW word_progress_stats_mv;

-- Grant permissions
GRANT SELECT ON word_progress_stats_mv TO authenticated;