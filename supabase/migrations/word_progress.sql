-- Create word_progress table
CREATE TABLE IF NOT EXISTS public.word_progress (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    word_id UUID REFERENCES flashcards(id) ON DELETE CASCADE,
    status TEXT NOT NULL CHECK (status IN ('new', 'learning', 'mastered')),
    review_count INTEGER DEFAULT 0,
    last_reviewed TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    next_review TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, word_id)
);

-- Add RLS policies
ALTER TABLE public.word_progress ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own word progress"
    ON public.word_progress
    FOR SELECT
    TO authenticated
    USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own word progress"
    ON public.word_progress
    FOR UPDATE
    TO authenticated
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own word progress"
    ON public.word_progress
    FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = user_id);

-- Add function to update updated_at timestamp
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

-- Create view for word progress statistics
CREATE OR REPLACE VIEW public.word_progress_stats AS
SELECT 
    user_id,
    COUNT(*) FILTER (WHERE status = 'new') as new_count,
    COUNT(*) FILTER (WHERE status = 'learning') as learning_count,
    COUNT(*) FILTER (WHERE status = 'mastered') as mastered_count,
    COUNT(*) as total_count
FROM public.word_progress
GROUP BY user_id;