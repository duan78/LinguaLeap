-- Add order_index column if it doesn't exist
ALTER TABLE lessons 
ADD COLUMN IF NOT EXISTS order_index INTEGER DEFAULT 0;

-- Create index for better performance
CREATE INDEX IF NOT EXISTS idx_lessons_order ON lessons(order_index);

-- Create view for lesson progress
CREATE OR REPLACE VIEW lesson_progress AS
SELECT 
    l.id as lesson_id,
    l.title,
    l.description,
    l.order_index,
    COUNT(DISTINCT f.id) as flashcard_count,
    COUNT(DISTINCT CASE WHEN wp.mastery_level >= 5 THEN f.id END) as mastered_count
FROM lessons l
LEFT JOIN flashcards f ON f.lesson_id = l.id
LEFT JOIN word_progress wp ON wp.flashcard_id = f.id
GROUP BY l.id, l.title, l.description, l.order_index;

-- Grant necessary permissions
GRANT SELECT ON lesson_progress TO authenticated;