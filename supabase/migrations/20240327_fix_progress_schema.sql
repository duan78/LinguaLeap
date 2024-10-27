-- Drop existing table if it exists
DROP TABLE IF EXISTS word_progress CASCADE;

-- Create word_progress table with correct schema
CREATE TABLE word_progress (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    flashcard_id UUID NOT NULL REFERENCES flashcards(id) ON DELETE CASCADE,
    status TEXT NOT NULL DEFAULT 'new' CHECK (status IN ('new', 'learning', 'reviewing', 'mastered')),
    mastery_level INTEGER DEFAULT 0,
    correct_streak INTEGER DEFAULT 0,
    review_count INTEGER DEFAULT 0,
    last_reviewed TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    next_review TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, flashcard_id)
);

-- Enable RLS
ALTER TABLE word_progress ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "Users can manage their own progress"
    ON word_progress
    FOR ALL
    TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Create indexes for better performance
CREATE INDEX idx_word_progress_user_id ON word_progress(user_id);
CREATE INDEX idx_word_progress_flashcard_id ON word_progress(flashcard_id);
CREATE INDEX idx_word_progress_mastery_level ON word_progress(mastery_level);
CREATE INDEX idx_word_progress_last_reviewed ON word_progress(last_reviewed);

-- Grant necessary permissions
GRANT ALL ON word_progress TO authenticated;