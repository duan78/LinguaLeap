-- Drop existing view if it exists
DROP VIEW IF EXISTS word_progress_stats;

-- Create the stats view
CREATE VIEW word_progress_stats AS
SELECT 
    user_id,
    COUNT(*) FILTER (WHERE status = 'mastered') as mastered_count,
    COUNT(*) FILTER (WHERE status = 'learning') as learning_count,
    COUNT(*) FILTER (WHERE status = 'reviewing') as reviewing_count,
    COUNT(*) FILTER (WHERE status = 'new') as new_count,
    COUNT(*) as total_words,
    COALESCE(
        AVG(CASE 
            WHEN correct_count + incorrect_count > 0 
            THEN CAST(correct_count AS FLOAT) / NULLIF(correct_count + incorrect_count, 0) 
            ELSE 0 
        END),
        0
    ) as accuracy
FROM word_progress
GROUP BY user_id;

-- Grant necessary permissions
GRANT SELECT ON word_progress_stats TO authenticated;