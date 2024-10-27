-- Drop existing views
DROP VIEW IF EXISTS word_progress_stats CASCADE;
DROP VIEW IF EXISTS keyword_learning_states CASCADE;
DROP VIEW IF EXISTS learning_progress_summary CASCADE;

-- First ensure the word_progress table has the correct columns
ALTER TABLE word_progress
ADD COLUMN IF NOT EXISTS score NUMERIC(10,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS mastery_level INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS correct_streak INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS review_count INTEGER DEFAULT 0;

-- Create function to calculate word status based on mastery level and correct streak
CREATE OR REPLACE FUNCTION calculate_word_status(
    mastery_level INTEGER,
    correct_streak INTEGER,
    review_count INTEGER
) RETURNS TEXT AS $$
BEGIN
    RETURN CASE
        WHEN mastery_level = 0 OR review_count = 0 THEN 'new'
        WHEN mastery_level < 2 THEN 'learning'
        WHEN mastery_level < 4 THEN 'known'
        WHEN mastery_level < 6 THEN 'mastered'
        ELSE 'long-term'
    END;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Create function to calculate word score
CREATE OR REPLACE FUNCTION calculate_word_score(
    mastery_level INTEGER,
    correct_streak INTEGER,
    review_count INTEGER
) RETURNS NUMERIC AS $$
BEGIN
    -- Base score from mastery level (0-5)
    RETURN CAST(
        mastery_level + 
        -- Bonus from correct streak (up to 1 point)
        LEAST(correct_streak::NUMERIC / 5, 1) +
        -- Bonus from review count (up to 1 point)
        LEAST(review_count::NUMERIC / 10, 1)
    AS NUMERIC(10,2));
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Create word_progress_stats view
CREATE OR REPLACE VIEW word_progress_stats AS
WITH user_stats AS (
    SELECT 
        wp.user_id,
        COUNT(DISTINCT wp.flashcard_id) as total_words,
        COUNT(DISTINCT CASE 
            WHEN calculate_word_status(wp.mastery_level, wp.correct_streak, wp.review_count) 
                IN ('mastered', 'long-term') 
            THEN wp.flashcard_id 
        END) as words_mastered,
        MAX(wp.last_reviewed) as last_review_date,
        -- Calculate average score from all reviewed words
        CAST(AVG(
            CASE WHEN wp.review_count > 0 
            THEN calculate_word_score(wp.mastery_level, wp.correct_streak, wp.review_count)
            ELSE 0 END
        ) AS NUMERIC(10,2)) as average_score,
        -- Calculate success rate
        CAST(
            CASE 
                WHEN SUM(wp.review_count) > 0 
                THEN (SUM(wp.correct_streak)::NUMERIC / NULLIF(SUM(wp.review_count), 0) * 100)
                ELSE 0 
            END 
        AS NUMERIC(10,2)) as review_success,
        COUNT(DISTINCT CASE 
            WHEN wp.last_reviewed >= CURRENT_DATE 
            THEN wp.flashcard_id 
        END) as words_reviewed_today,
        -- Count words by status
        COUNT(DISTINCT CASE 
            WHEN calculate_word_status(wp.mastery_level, wp.correct_streak, wp.review_count) = 'new' 
            THEN wp.flashcard_id 
        END) as unknown_count,
        COUNT(DISTINCT CASE 
            WHEN calculate_word_status(wp.mastery_level, wp.correct_streak, wp.review_count) = 'learning' 
            THEN wp.flashcard_id 
        END) as learning_count,
        COUNT(DISTINCT CASE 
            WHEN calculate_word_status(wp.mastery_level, wp.correct_streak, wp.review_count) = 'known' 
            THEN wp.flashcard_id 
        END) as known_count,
        COUNT(DISTINCT CASE 
            WHEN calculate_word_status(wp.mastery_level, wp.correct_streak, wp.review_count) = 'mastered' 
            THEN wp.flashcard_id 
        END) as mastered_count,
        COUNT(DISTINCT CASE 
            WHEN calculate_word_status(wp.mastery_level, wp.correct_streak, wp.review_count) = 'long-term' 
            THEN wp.flashcard_id 
        END) as long_term_count
    FROM word_progress wp
    GROUP BY wp.user_id
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
        CASE 
            WHEN us.words_reviewed_today > 0 THEN
                COALESCE((
                    SELECT COUNT(DISTINCT review_date)
                    FROM daily_reviews dr
                    WHERE dr.user_id = us.user_id
                    AND dr.review_date >= CURRENT_DATE - INTERVAL '30 days'
                    AND dr.reviews_count > 0
                ), 0)
            ELSE 
                GREATEST(
                    COALESCE((
                        SELECT COUNT(DISTINCT review_date)
                        FROM daily_reviews dr
                        WHERE dr.user_id = us.user_id
                        AND dr.review_date >= CURRENT_DATE - INTERVAL '30 days'
                        AND dr.review_date < CURRENT_DATE
                        AND dr.reviews_count > 0
                    ), 0) - 1,
                    0
                )
        END as current_streak
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

-- Create trigger to automatically update status and score
CREATE OR REPLACE FUNCTION update_word_progress()
RETURNS TRIGGER AS $$
BEGIN
    -- Update score
    NEW.score = calculate_word_score(NEW.mastery_level, NEW.correct_streak, NEW.review_count);
    
    -- Update status based on mastery level and correct streak
    NEW.status = calculate_word_status(NEW.mastery_level, NEW.correct_streak, NEW.review_count);
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create or replace the trigger
DROP TRIGGER IF EXISTS word_progress_update_trigger ON word_progress;
CREATE TRIGGER word_progress_update_trigger
    BEFORE INSERT OR UPDATE OF mastery_level, correct_streak, review_count
    ON word_progress
    FOR EACH ROW
    EXECUTE FUNCTION update_word_progress();

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_word_progress_score ON word_progress(score);
CREATE INDEX IF NOT EXISTS idx_word_progress_mastery ON word_progress(mastery_level);
CREATE INDEX IF NOT EXISTS idx_word_progress_status ON word_progress(status);

-- Grant necessary permissions
GRANT SELECT ON word_progress_stats TO authenticated;