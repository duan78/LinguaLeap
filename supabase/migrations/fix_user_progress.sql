-- First drop the existing unique constraint
ALTER TABLE public.user_progress 
DROP CONSTRAINT IF EXISTS user_progress_user_id_key;

-- Add the correct unique constraint for the combination of user_id and word_id
ALTER TABLE public.user_progress 
ADD CONSTRAINT user_progress_user_word_unique 
UNIQUE (user_id, word_id);

-- Update RLS policies to ensure they work with the new constraint
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