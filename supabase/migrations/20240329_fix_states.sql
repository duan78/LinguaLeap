-- First, update existing records
UPDATE word_progress 
SET state = 'unknown' 
WHERE state = 'new';

-- Update the state check constraint
ALTER TABLE word_progress 
DROP CONSTRAINT IF EXISTS word_progress_state_check;

ALTER TABLE word_progress 
ADD CONSTRAINT word_progress_state_check 
CHECK (state IN ('unknown', 'learning', 'known', 'mastered', 'long-term'));

-- Create function to ensure consistent state calculation
CREATE OR REPLACE FUNCTION calculate_word_state(
    mastery_level INTEGER,
    correct_streak INTEGER,
    review_count INTEGER
) RETURNS TEXT AS $$
BEGIN
    IF mastery_level >= 4 AND correct_streak >= 5 THEN
        RETURN 'long-term';
    ELSIF mastery_level >= 3 THEN
        RETURN 'mastered';
    ELSIF mastery_level >= 2 THEN
        RETURN 'known';
    ELSIF mastery_level >= 1 THEN
        RETURN 'learning';
    ELSE
        RETURN 'unknown';
    END IF;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Create trigger to maintain consistent states
CREATE OR REPLACE FUNCTION update_word_state()
RETURNS TRIGGER AS $$
BEGIN
    NEW.state := calculate_word_state(
        NEW.mastery_level,
        NEW.correct_streak,
        NEW.review_count
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS word_state_update_trigger ON word_progress;
CREATE TRIGGER word_state_update_trigger
    BEFORE INSERT OR UPDATE OF mastery_level, correct_streak, review_count
    ON word_progress
    FOR EACH ROW
    EXECUTE FUNCTION update_word_state();