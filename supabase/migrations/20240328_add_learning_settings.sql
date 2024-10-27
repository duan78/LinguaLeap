-- Create table for learning settings
CREATE TABLE learning_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    description TEXT,
    state TEXT NOT NULL,
    min_mastery_level INTEGER NOT NULL,
    min_correct_streak INTEGER NOT NULL,
    min_review_count INTEGER NOT NULL,
    score_weight NUMERIC(3,2) NOT NULL,
    next_review_delay INTERVAL NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(state)
);

-- Insert default settings
INSERT INTO learning_settings 
(state, name, description, min_mastery_level, min_correct_streak, min_review_count, score_weight, next_review_delay) 
VALUES
('new', 'New Words', 'Words that have not been studied yet', 0, 0, 0, 0.00, '1 hour'),
('learning', 'Learning', 'Words in the initial learning phase', 1, 1, 1, 0.25, '6 hours'),
('known', 'Known', 'Words that are becoming familiar', 2, 2, 3, 0.50, '1 day'),
('mastered', 'Mastered', 'Words that are well-known', 3, 3, 5, 0.75, '3 days'),
('long-term', 'Long-term Memory', 'Words fully mastered', 4, 5, 7, 1.00, '7 days');

-- Create function to calculate word state based on settings
CREATE OR REPLACE FUNCTION calculate_word_state(
    mastery_level INTEGER,
    correct_streak INTEGER,
    review_count INTEGER
) RETURNS TEXT AS $$
DECLARE
    state_record RECORD;
BEGIN
    -- Find the highest matching state based on requirements
    SELECT *
    FROM learning_settings
    WHERE min_mastery_level <= mastery_level
    AND min_correct_streak <= correct_streak
    AND min_review_count <= review_count
    ORDER BY min_mastery_level DESC, min_correct_streak DESC, min_review_count DESC
    LIMIT 1
    INTO state_record;

    -- Return 'new' if no state matches
    RETURN COALESCE(state_record.state, 'new');
END;
$$ LANGUAGE plpgsql STABLE;

-- Create function to calculate next review date
CREATE OR REPLACE FUNCTION calculate_next_review(
    current_state TEXT,
    last_reviewed TIMESTAMP WITH TIME ZONE
) RETURNS TIMESTAMP WITH TIME ZONE AS $$
DECLARE
    delay_interval INTERVAL;
BEGIN
    -- Get delay for the current state
    SELECT next_review_delay INTO delay_interval
    FROM learning_settings
    WHERE state = current_state;

    -- Return next review date
    RETURN last_reviewed + COALESCE(delay_interval, '1 hour'::INTERVAL);
END;
$$ LANGUAGE plpgsql STABLE;

-- Create function to calculate word score
CREATE OR REPLACE FUNCTION calculate_word_score(
    current_state TEXT,
    correct_streak INTEGER,
    review_count INTEGER
) RETURNS NUMERIC AS $$
DECLARE
    base_weight NUMERIC;
BEGIN
    -- Get score weight for the current state
    SELECT score_weight INTO base_weight
    FROM learning_settings
    WHERE state = current_state;

    -- Calculate score with bonuses
    RETURN ROUND(
        (COALESCE(base_weight, 0) * 5) + -- Base score (0-5)
        LEAST(correct_streak::NUMERIC / 5, 1) + -- Streak bonus (0-1)
        LEAST(review_count::NUMERIC / 10, 1) -- Review count bonus (0-1)
    , 2);
END;
$$ LANGUAGE plpgsql STABLE;

-- Enable RLS
ALTER TABLE learning_settings ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "Anyone can view learning settings"
    ON learning_settings FOR SELECT
    TO authenticated
    USING (true);

CREATE POLICY "Only admins can modify learning settings"
    ON learning_settings
    USING (auth.uid() IN (SELECT user_id FROM admin_users))
    WITH CHECK (auth.uid() IN (SELECT user_id FROM admin_users));

-- Grant permissions
GRANT SELECT ON learning_settings TO authenticated;
GRANT ALL ON learning_settings TO authenticated;