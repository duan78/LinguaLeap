-- First, drop the existing constraint
ALTER TABLE word_progress 
DROP CONSTRAINT IF EXISTS word_progress_status_check;

-- Add the correct constraint
ALTER TABLE word_progress 
ADD CONSTRAINT word_progress_status_check 
CHECK (status IN ('new', 'learning', 'known', 'mastered', 'long-term'));