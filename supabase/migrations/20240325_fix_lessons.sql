-- Add type column to lessons if it doesn't exist
ALTER TABLE lessons 
ADD COLUMN IF NOT EXISTS type TEXT NOT NULL DEFAULT 'vocabulary'
CHECK (type IN ('vocabulary', 'grammar', 'pronunciation', 'conversation'));

-- Update existing lessons to have the vocabulary type
UPDATE lessons SET type = 'vocabulary' WHERE type IS NULL;

-- Add order_index if it doesn't exist
ALTER TABLE lessons 
ADD COLUMN IF NOT EXISTS order_index INTEGER NOT NULL DEFAULT 0;

-- Create index for better performance
CREATE INDEX IF NOT EXISTS idx_lessons_type ON lessons(type);

-- Update sample data to ensure type is set
UPDATE lessons 
SET type = 'vocabulary', 
    order_index = CASE 
      WHEN title LIKE '%Greetings%' THEN 1
      WHEN title LIKE '%Numbers%' THEN 2
      ELSE 3
    END
WHERE type IS NULL;