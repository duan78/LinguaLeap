-- First create the learning_settings table if it doesn't exist
CREATE TABLE IF NOT EXISTS learning_settings (
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

-- Enable RLS
ALTER TABLE learning_settings ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
DROP POLICY IF EXISTS "Anyone can view learning settings" ON learning_settings;
DROP POLICY IF EXISTS "Only admins can modify learning settings" ON learning_settings;

CREATE POLICY "Anyone can view learning settings"
    ON learning_settings FOR SELECT
    TO authenticated
    USING (true);

CREATE POLICY "Only admins can modify learning settings"
    ON learning_settings
    USING (is_admin(auth.uid()))
    WITH CHECK (is_admin(auth.uid()));

-- Insert default settings if they don't exist
INSERT INTO learning_settings 
(state, name, description, min_mastery_level, min_correct_streak, min_review_count, score_weight, next_review_delay) 
VALUES
('new', 'New Words', 'Words that have not been studied yet', 0, 0, 0, 0.00, '1 hour'),
('learning', 'Learning', 'Words in the initial learning phase', 1, 1, 1, 0.25, '6 hours'),
('known', 'Known', 'Words that are becoming familiar', 2, 2, 3, 0.50, '1 day'),
('mastered', 'Mastered', 'Words that are well-known', 3, 3, 5, 0.75, '3 days'),
('long-term', 'Long-term Memory', 'Words fully mastered', 4, 5, 7, 1.00, '7 days')
ON CONFLICT (state) DO NOTHING;

-- Grant necessary permissions
GRANT SELECT ON learning_settings TO authenticated;