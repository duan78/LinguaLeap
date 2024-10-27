-- Drop existing policies if they exist
DO $$ 
BEGIN
    -- Drop existing policies
    DROP POLICY IF EXISTS "Only admins can modify learning settings" ON learning_settings;
    DROP POLICY IF EXISTS "Anyone can view learning settings" ON learning_settings;
    
    -- Drop existing function
    DROP FUNCTION IF EXISTS is_admin;
EXCEPTION
    WHEN undefined_object THEN 
        NULL;
END $$;

-- Create improved is_admin function with explicit table references
CREATE OR REPLACE FUNCTION is_admin(check_user_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 
        FROM admin_users a
        WHERE a.user_id = check_user_id
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create improved RLS policies with explicit table references
CREATE POLICY "Only admins can modify learning settings"
    ON learning_settings
    USING (is_admin(auth.uid()))
    WITH CHECK (is_admin(auth.uid()));

-- Create policy for viewing settings
CREATE POLICY "Anyone can view learning settings"
    ON learning_settings FOR SELECT
    TO authenticated
    USING (true);

-- Grant necessary permissions
GRANT EXECUTE ON FUNCTION is_admin TO authenticated;
GRANT SELECT ON learning_settings TO authenticated;
GRANT UPDATE ON learning_settings TO authenticated;

-- Create index for better performance if it doesn't exist
CREATE INDEX IF NOT EXISTS idx_admin_users_user_id ON admin_users(user_id);