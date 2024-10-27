-- Add word progress tracking
CREATE TABLE word_progress (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id uuid REFERENCES auth.users NOT NULL,
    word_id uuid REFERENCES flashcards NOT NULL,
    status TEXT NOT NULL CHECK (status IN ('new', 'learning', 'mastered')),
    strength FLOAT DEFAULT 0,
    reviews INTEGER DEFAULT 0,
    last_reviewed_at TIMESTAMP WITH TIME ZONE,
    next_review_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    UNIQUE(user_id, word_id)
);

-- Enable RLS
ALTER TABLE word_progress ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Users can view own word progress"
    ON word_progress FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can update own word progress"
    ON word_progress FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own word progress"
    ON word_progress FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Updated_at trigger for word_progress
CREATE TRIGGER on_word_progress_updated
    BEFORE UPDATE ON word_progress
    FOR EACH ROW
    EXECUTE FUNCTION handle_updated_at();

-- Grant permissions
GRANT ALL ON word_progress TO authenticated;
GRANT ALL ON word_progress TO anon;</content>