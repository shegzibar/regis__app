-- ==========================================
-- WALLET & POINTS SYSTEM MIGRATION SCRIPT
-- ==========================================

-- 1. Add short_id to profiles table
-- We use a 6-character unique ID for the QR code
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS short_id TEXT UNIQUE;

-- Generate random short_ids for existing users
UPDATE profiles 
SET short_id = substring(md5(random()::text) from 1 for 6) 
WHERE short_id IS NULL;

-- 2. Create wallets table
CREATE TABLE IF NOT EXISTS wallets (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE UNIQUE NOT NULL,
  balance INTEGER DEFAULT 0 CHECK (balance >= 0),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Function to automatically create a wallet when a new user is created
CREATE OR REPLACE FUNCTION public.handle_new_user_wallet()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.wallets (user_id, balance)
  VALUES (NEW.id, 0);
  
  -- Also generate a short_id for new users if not provided
  IF NEW.short_id IS NULL THEN
    NEW.short_id := substring(md5(random()::text) from 1 for 6);
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to create wallet for new users
DROP TRIGGER IF EXISTS on_auth_user_created_wallet ON profiles;
CREATE TRIGGER on_auth_user_created_wallet
  BEFORE INSERT ON profiles
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user_wallet();

-- Create wallets for existing users who don't have one
INSERT INTO wallets (user_id, balance)
SELECT id, 0 FROM profiles 
WHERE id NOT IN (SELECT user_id FROM wallets);

-- 3. Create wallet_transactions table
CREATE TABLE IF NOT EXISTS wallet_transactions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  wallet_id UUID REFERENCES wallets(id) ON DELETE CASCADE NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('earned', 'redeemed')),
  amount INTEGER NOT NULL CHECK (amount > 0),
  note TEXT,
  cyber_name TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Function to update wallet balance on new transaction
CREATE OR REPLACE FUNCTION update_wallet_balance()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.type = 'earned' THEN
    UPDATE wallets SET balance = balance + NEW.amount, updated_at = NOW() WHERE id = NEW.wallet_id;
  ELSIF NEW.type = 'redeemed' THEN
    UPDATE wallets SET balance = balance - NEW.amount, updated_at = NOW() WHERE id = NEW.wallet_id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for wallet transactions
DROP TRIGGER IF EXISTS on_wallet_transaction_insert ON wallet_transactions;
CREATE TRIGGER on_wallet_transaction_insert
  AFTER INSERT ON wallet_transactions
  FOR EACH ROW EXECUTE FUNCTION update_wallet_balance();

-- 4. RLS Policies
ALTER TABLE wallets ENABLE ROW LEVEL SECURITY;
ALTER TABLE wallet_transactions ENABLE ROW LEVEL SECURITY;

-- Users can view their own wallet
DROP POLICY IF EXISTS "Users can view their own wallet" ON wallets;
CREATE POLICY "Users can view their own wallet" ON wallets
  FOR SELECT USING (user_id = auth.uid());

-- Users can view their own transactions
DROP POLICY IF EXISTS "Users can view their own transactions" ON wallet_transactions;
CREATE POLICY "Users can view their own transactions" ON wallet_transactions
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM wallets w WHERE w.id = wallet_transactions.wallet_id AND w.user_id = auth.uid()
    )
  );

-- Admins and Managers can add transactions (e.g. from cyber dashboard)
DROP POLICY IF EXISTS "Admins and managers can insert transactions" ON wallet_transactions;
CREATE POLICY "Admins and managers can insert transactions" ON wallet_transactions
  FOR INSERT WITH CHECK (
    is_admin_or_manager()
  );

-- Admins and Managers can read all wallets
DROP POLICY IF EXISTS "Admins and managers can view all wallets" ON wallets;
CREATE POLICY "Admins and managers can view all wallets" ON wallets
  FOR SELECT USING (
    is_admin_or_manager()
  );
