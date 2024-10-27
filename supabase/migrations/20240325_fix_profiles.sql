-- Modify profiles table to make some fields optional
ALTER TABLE profiles
ALTER COLUMN native_language DROP NOT NULL,
ALTER COLUMN learning_language DROP NOT NULL,
ALTER COLUMN username DROP NOT NULL;

-- Add default values for numeric fields
ALTER TABLE profiles
ALTER COLUMN daily_goal SET DEFAULT 10,
ALTER COLUMN streak_count SET DEFAULT 0,
ALTER COLUMN total_xp SET DEFAULT 0,
ALTER COLUMN current_streak SET DEFAULT 0,
ALTER COLUMN longest_streak SET DEFAULT 0,
ALTER COLUMN speaking_confidence SET DEFAULT 0,
ALTER COLUMN vocabulary_mastered SET DEFAULT 0;

-- Ensure RLS policies are correct
DROP POLICY IF EXISTS "Users can insert their own profile" ON profiles;
DROP POLICY IF EXISTS "Users can update their own profile" ON profiles;
DROP POLICY IF EXISTS "Users can view their own profile" ON profiles;

CREATE POLICY "Users can insert their own profile"
ON profiles FOR INSERT
WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update their own profile"
ON profiles FOR UPDATE
USING (auth.uid() = id);

CREATE POLICY "Users can view their own profile"
ON profiles FOR SELECT
USING (auth.uid() = id);

-- Create trigger to automatically create profile on user creation
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.profiles (id, username, created_at)
  VALUES (new.id, split_part(new.email, '@', 1), now())
  ON CONFLICT (id) DO NOTHING;
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();