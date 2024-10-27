-- Add response_time column to word_progress table
ALTER TABLE word_progress 
ADD COLUMN IF NOT EXISTS response_time INTEGER;

-- Ensure all necessary columns exist with correct types
ALTER TABLE word_progress
ADD COLUMN IF NOT EXISTS status TEXT NOT NULL DEFAULT 'new' CHECK (status IN ('new', 'learning', 'known', 'mastered', 'long-term')),
ADD COLUMN IF NOT EXISTS mastery_level INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS correct_streak INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS review_count INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS last_reviewed TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
ADD COLUMN IF NOT EXISTS next_review TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- Create or update indexes for better performance
CREATE INDEX IF NOT EXISTS idx_word_progress_user_id ON word_progress(user_id);
CREATE INDEX IF NOT EXISTS idx_word_progress_flashcard_id ON word_progress(flashcard_id);
CREATE INDEX IF NOT EXISTS idx_word_progress_status ON word_progress(status);
CREATE INDEX IF NOT EXISTS idx_word_progress_mastery_level ON word_progress(mastery_level);