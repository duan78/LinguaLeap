-- First, drop the existing constraint if it exists
ALTER TABLE public.user_progress 
DROP CONSTRAINT IF EXISTS user_progress_user_word_unique;

-- Add the missing column and rename for consistency
ALTER TABLE public.user_progress 
ADD COLUMN IF NOT EXISTS word_id uuid REFERENCES flashcards(id),
ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'new' CHECK (status IN ('new', 'learning', 'mastered')),
ADD COLUMN IF NOT EXISTS strength FLOAT DEFAULT 0,
ADD COLUMN IF NOT EXISTS next_review TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
ADD COLUMN IF NOT EXISTS last_reviewed_at TIMESTAMP WITH TIME ZONE;

-- Now add the unique constraint with the correct columns
ALTER TABLE public.user_progress 
ADD CONSTRAINT user_progress_user_word_unique 
UNIQUE (user_id, word_id);

-- Ensure RLS policies are up to date
DROP POLICY IF EXISTS "Users can view their own progress" ON public.user_progress;
DROP POLICY IF EXISTS "Users can update their own progress" ON public.user_progress;
DROP POLICY IF EXISTS "Users can insert their own progress" ON public.user_progress;

CREATE POLICY "Users can view their own progress"
ON public.user_progress
FOR SELECT
TO authenticated
USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own progress"
ON public.user_progress
FOR UPDATE
TO authenticated
USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own progress"
ON public.user_progress
FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = user_id);