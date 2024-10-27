-- First, drop and recreate the lessons table with the correct structure
DROP TABLE IF EXISTS lessons CASCADE;

CREATE TABLE lessons (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title TEXT NOT NULL,
    description TEXT,
    level TEXT NOT NULL,
    type TEXT NOT NULL DEFAULT 'vocabulary',
    order_index INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT valid_lesson_type CHECK (type IN ('vocabulary', 'grammar', 'pronunciation', 'conversation')),
    CONSTRAINT valid_lesson_level CHECK (level IN ('beginner', 'intermediate', 'advanced'))
);

-- Create index for better performance
CREATE INDEX idx_lessons_type_order ON lessons(type, order_index);

-- Insert sample lessons
INSERT INTO lessons (title, description, level, type, order_index) VALUES
('Basic Greetings', 'Learn essential French greetings and introductions', 'beginner', 'vocabulary', 1),
('Numbers 1-10', 'Master counting in French from one to ten', 'beginner', 'vocabulary', 2),
('Common Phrases', 'Essential everyday French expressions', 'beginner', 'vocabulary', 3);

-- Enable RLS
ALTER TABLE lessons ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "Anyone can view lessons"
    ON lessons FOR SELECT
    TO PUBLIC
    USING (true);

-- Grant necessary permissions
GRANT SELECT ON lessons TO anon, authenticated;