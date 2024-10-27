-- Drop the existing view if it exists
DROP VIEW IF EXISTS word_progress_stats;

-- Drop and recreate the word_progress table with all necessary columns
DROP TABLE IF EXISTS word_progress CASCADE;

CREATE TABLE public.word_progress (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    flashcard_id UUID NOT NULL REFERENCES flashcards(id) ON DELETE CASCADE,
    status TEXT NOT NULL DEFAULT 'new' CHECK (status IN ('new', 'learning', 'reviewing', 'mastered')),
    next_review TIMESTAMP WITH TIME ZONE,
    last_reviewed TIMESTAMP WITH TIME ZONE,
    review_count INTEGER DEFAULT 0,
    correct_count INTEGER DEFAULT 0,
    incorrect_count INTEGER DEFAULT 0,
    streak INTEGER DEFAULT 0,
    ease_factor FLOAT DEFAULT 2.5,
    interval INTEGER DEFAULT 0,
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

-- Create the stats view
CREATE VIEW word_progress_stats AS
SELECT 
    user_id,
    COUNT(*) FILTER (WHERE status = 'mastered') as mastered_count,
    COUNT(*) FILTER (WHERE status = 'learning') as learning_count,
    COUNT(*) FILTER (WHERE status = 'reviewing') as reviewing_count,
    COUNT(*) FILTER (WHERE status = 'new') as new_count,
    COUNT(*) as total_words,
    AVG(CASE WHEN correct_count + incorrect_count > 0 
        THEN CAST(correct_count AS FLOAT) / NULLIF(correct_count + incorrect_count, 0) 
        ELSE 0 
    END) as accuracy
FROM word_progress
GROUP BY user_id;

-- Grant necessary permissions
GRANT ALL ON public.word_progress TO authenticated;
GRANT ALL ON public.word_progress_stats TO authenticated;

-- Create function to update timestamps
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger for updating timestamps
CREATE TRIGGER update_word_progress_updated_at
    BEFORE UPDATE ON public.word_progress
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();