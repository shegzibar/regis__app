-- Run in Supabase SQL Editor if profile save fails on missing columns.
ALTER TABLE cybers ADD COLUMN IF NOT EXISTS cover_image TEXT;
ALTER TABLE cybers ADD COLUMN IF NOT EXISTS is_featured BOOLEAN DEFAULT false;

-- Owners must read/update their own row in users (usually already applied).
-- ALTER TABLE users ENABLE ROW LEVEL SECURITY;
-- CREATE POLICY "Users can update their own profile" ON users
--   FOR UPDATE USING (auth.uid() = id);
