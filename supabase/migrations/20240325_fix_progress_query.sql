-- Drop existing view if it exists
DROP VIEW IF EXISTS word_progress_stats;

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_word_progress_user_id ON word_progress(user_id);
CREATE INDEX IF NOT EXISTS idx_word_progress_mastery ON word_progress(mastery_level);
CREATE INDEX IF NOT EXISTS idx_word_progress_last_reviewed ON word_progress(last_reviewed);

-- Create RLS policies if they don't exist
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'word_progress' AND policyname = 'Users can view their own progress'
    ) THEN
        CREATE POLICY "Users can view their own progress"
            ON word_progress FOR SELECT
            TO authenticated
            USING (auth.uid() = user_id);
    END IF;
END $$;

-- Grant necessary permissions
GRANT SELECT ON word_progress TO authenticated;