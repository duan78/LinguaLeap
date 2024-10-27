-- Drop existing constraint if it exists
ALTER TABLE public.user_progress 
DROP CONSTRAINT IF EXISTS user_progress_user_id_key;

-- Ensure we have the correct composite unique constraint
ALTER TABLE public.user_progress 
DROP CONSTRAINT IF EXISTS user_progress_user_word_unique;

ALTER TABLE public.user_progress 
ADD CONSTRAINT user_progress_user_word_unique 
UNIQUE (user_id, word_id);

-- Update indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_user_progress_user_id 
ON public.user_progress(user_id);

CREATE INDEX IF NOT EXISTS idx_user_progress_word_id 
ON public.user_progress(word_id);

CREATE INDEX IF NOT EXISTS idx_user_progress_status 
ON public.user_progress(status);

-- Ensure we have the correct foreign key constraints
ALTER TABLE public.user_progress 
DROP CONSTRAINT IF EXISTS user_progress_word_id_fkey;

ALTER TABLE public.user_progress 
ADD CONSTRAINT user_progress_word_id_fkey 
FOREIGN KEY (word_id) 
REFERENCES flashcards(id) 
ON DELETE CASCADE;