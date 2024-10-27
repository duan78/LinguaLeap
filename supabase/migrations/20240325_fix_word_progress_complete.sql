-- First drop the existing view and table
DROP VIEW IF EXISTS word_progress_stats;
DROP TABLE IF EXISTS word_progress CASCADE;

-- Create the word_progress table with all necessary columns
CREATE TABLE public.word_progress (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    flashcard_id UUID NOT NULL REFERENCES flashcards(id) ON DELETE CASCADE,
    status TEXT NOT NULL DEFAULT 'new' CHECK (status IN ('new', 'learning', 'reviewing', 'mastered')),
    strength FLOAT DEFAULT 0,
    next_review TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_reviewed TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    review_count INTEGER DEFAULT 0,
    correct_reviews INTEGER DEFAULT 0,
    incorrect_reviews INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, flashcard_id)
);

-- Enable RLS
ALTER TABLE public.word_progress ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "Users can view their own progress"
ON public.word_progress FOR SELECT
USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own progress"
ON public.word_progress FOR INSERT
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own progress"
ON public.word_progress FOR UPDATE
USING (auth.uid() = user_id);

-- Create the stats view with corrected column names
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
            WHEN review_count > 0 
            THEN CAST(correct_reviews AS FLOAT) / NULLIF(review_count, 0)
            ELSE 0 
        END),
        0
    ) as accuracy
FROM word_progress
GROUP BY user_id;

-- Grant necessary permissions
GRANT ALL ON public.word_progress TO authenticated;
GRANT SELECT ON word_progress_stats TO authenticated;

-- Create updated_at trigger
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_word_progress_updated_at
    BEFORE UPDATE ON public.word_progress
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Create indexes for better performance
CREATE INDEX idx_word_progress_user_id ON word_progress(user_id);
CREATE INDEX idx_word_progress_flashcard_id ON word_progress(flashcard_id);
CREATE INDEX idx_word_progress_status ON word_progress(status);
CREATE INDEX idx_word_progress_next_review ON word_progress(next_review);