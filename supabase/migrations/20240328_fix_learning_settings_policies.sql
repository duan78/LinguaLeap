-- Update learning_settings policies to use is_admin function
DROP POLICY IF EXISTS "Only admins can modify learning settings" ON learning_settings;

CREATE POLICY "Only admins can modify learning settings"
    ON learning_settings
    USING (is_admin(auth.uid()))
    WITH CHECK (is_admin(auth.uid()));