-- GamingHub Database Schema
-- PostgreSQL for Supabase

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Users table
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  phone TEXT UNIQUE NOT NULL,
  name TEXT,
  role TEXT NOT NULL DEFAULT 'user' CHECK (role IN ('user', 'owner', 'manager', 'admin')),
  avatar_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Cybers (gaming centers)
CREATE TABLE cybers (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  owner_id UUID REFERENCES users(id) ON DELETE SET NULL,
  name TEXT NOT NULL,
  description TEXT,
  address TEXT,
  city TEXT,
  lat DOUBLE PRECISION,
  lng DOUBLE PRECISION,
  images TEXT[] DEFAULT '{}',
  rating NUMERIC(3,2) DEFAULT 0 CHECK (rating >= 0 AND rating <= 5),
  review_count INTEGER DEFAULT 0 CHECK (review_count >= 0),
  working_hours_from TIME DEFAULT '10:00',
  working_hours_to TIME DEFAULT '02:00',
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Rooms (inside each cyber)
CREATE TABLE rooms (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  cyber_id UUID REFERENCES cybers(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('ps5', 'pc', 'vip')),
  price_per_hour NUMERIC(10,2) NOT NULL CHECK (price_per_hour > 0),
  description TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Stations (individual seats inside a room)
CREATE TABLE stations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  room_id UUID REFERENCES rooms(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'maintenance', 'blocked')),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Bookings
CREATE TABLE bookings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  station_id UUID REFERENCES stations(id) ON DELETE CASCADE,
  start_time TIMESTAMPTZ NOT NULL,
  end_time TIMESTAMPTZ NOT NULL,
  duration_hours NUMERIC(4,2) NOT NULL CHECK (duration_hours > 0),
  total_amount NUMERIC(10,2) NOT NULL CHECK (total_amount > 0),
  booking_fee NUMERIC(10,2) DEFAULT 5.00 CHECK (booking_fee >= 0),
  status TEXT DEFAULT 'pending_payment' CHECK (status IN ('pending_payment', 'fee_under_review', 'confirmed', 'rejected', 'completed', 'cancelled')),
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  confirmed_at TIMESTAMPTZ,
  expires_at TIMESTAMPTZ,
  
  -- Ensure no overlapping confirmed bookings for the same station
  EXCLUDE (station_id WITH =) WHERE (status = 'confirmed' AND start_time < NOW() + INTERVAL '24 hours')
);

-- Payments (booking fee receipts)
CREATE TABLE payments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  booking_id UUID REFERENCES bookings(id) ON DELETE CASCADE,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  amount NUMERIC(10,2) NOT NULL CHECK (amount > 0),
  method TEXT NOT NULL CHECK (method IN ('instapay', 'vodafone_cash', 'fawry')),
  screenshot_url TEXT,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
  reviewed_by UUID REFERENCES users(id) ON DELETE SET NULL,
  reviewed_at TIMESTAMPTZ,
  rejection_reason TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Reviews
CREATE TABLE reviews (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  cyber_id UUID REFERENCES cybers(id) ON DELETE CASCADE,
  booking_id UUID REFERENCES bookings(id) ON DELETE SET NULL,
  rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
  comment TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- Ensure one review per booking
  UNIQUE(booking_id)
);

-- Notifications
CREATE TABLE notifications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  type TEXT,
  is_read BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for better performance
CREATE INDEX idx_users_phone ON users(phone);
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_cybers_owner_id ON cybers(owner_id);
CREATE INDEX idx_cybers_city ON cybers(city);
CREATE INDEX idx_cybers_is_active ON cybers(is_active);
CREATE INDEX idx_rooms_cyber_id ON rooms(cyber_id);
CREATE INDEX idx_rooms_type ON rooms(type);
CREATE INDEX idx_rooms_is_active ON rooms(is_active);
CREATE INDEX idx_stations_room_id ON stations(room_id);
CREATE INDEX idx_stations_status ON stations(status);
CREATE INDEX idx_bookings_user_id ON bookings(user_id);
CREATE INDEX idx_bookings_station_id ON bookings(station_id);
CREATE INDEX idx_bookings_start_time ON bookings(start_time);
CREATE INDEX idx_bookings_end_time ON bookings(end_time);
CREATE INDEX idx_bookings_status ON bookings(status);
CREATE INDEX idx_bookings_created_at ON bookings(created_at);
CREATE INDEX idx_payments_booking_id ON payments(booking_id);
CREATE INDEX idx_payments_user_id ON payments(user_id);
CREATE INDEX idx_payments_status ON payments(status);
CREATE INDEX idx_reviews_user_id ON reviews(user_id);
CREATE INDEX idx_reviews_cyber_id ON reviews(cyber_id);
CREATE INDEX idx_reviews_booking_id ON reviews(booking_id);
CREATE INDEX idx_notifications_user_id ON notifications(user_id);
CREATE INDEX idx_notifications_is_read ON notifications(is_read);

-- Security Definer Function to check if user is admin/manager (avoids infinite recursion)
CREATE OR REPLACE FUNCTION is_admin_or_manager()
RETURNS BOOLEAN AS $$
DECLARE
  user_role TEXT;
BEGIN
  SELECT role INTO user_role FROM users WHERE id = auth.uid();
  RETURN user_role IN ('admin', 'manager');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Row Level Security (RLS) Policies
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE cybers ENABLE ROW LEVEL SECURITY;
ALTER TABLE rooms ENABLE ROW LEVEL SECURITY;
ALTER TABLE stations ENABLE ROW LEVEL SECURITY;
ALTER TABLE bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- Drop old policies to avoid conflicts
DROP POLICY IF EXISTS "Users can view their own profile" ON users;
DROP POLICY IF EXISTS "Users can update their own profile" ON users;
DROP POLICY IF EXISTS "Admins can view all users" ON users;
DROP POLICY IF EXISTS "Anyone can view active cybers" ON cybers;
DROP POLICY IF EXISTS "Owners can manage their cybers" ON cybers;
DROP POLICY IF EXISTS "Admins can manage all cybers" ON cybers;
DROP POLICY IF EXISTS "Anyone can view active rooms" ON rooms;
DROP POLICY IF EXISTS "Owners can manage their rooms" ON rooms;
DROP POLICY IF EXISTS "Admins can manage all rooms" ON rooms;
DROP POLICY IF EXISTS "Anyone can view stations" ON stations;
DROP POLICY IF EXISTS "Owners can manage their stations" ON stations;
DROP POLICY IF EXISTS "Admins can manage all stations" ON stations;
DROP POLICY IF EXISTS "Users can view their own bookings" ON bookings;
DROP POLICY IF EXISTS "Owners can view bookings for their cybers" ON bookings;
DROP POLICY IF EXISTS "Users can create bookings" ON bookings;
DROP POLICY IF EXISTS "Users can update their own bookings" ON bookings;
DROP POLICY IF EXISTS "Owners can update booking status" ON bookings;
DROP POLICY IF EXISTS "Users can view their own payments" ON payments;
DROP POLICY IF EXISTS "Managers can view all payments" ON payments;
DROP POLICY IF EXISTS "Users can create payments" ON payments;
DROP POLICY IF EXISTS "Managers can update payment status" ON payments;
DROP POLICY IF EXISTS "Anyone can view reviews" ON reviews;
DROP POLICY IF EXISTS "Users can create reviews for their completed bookings" ON reviews;
DROP POLICY IF EXISTS "Users can view their own notifications" ON notifications;
DROP POLICY IF EXISTS "Users can update their own notifications" ON notifications;

-- Users table policies
CREATE POLICY "Users can view their own profile" ON users
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile" ON users
  FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Admins can view all users" ON users
  FOR SELECT USING (is_admin_or_manager());

-- Cybers table policies
CREATE POLICY "Anyone can view active cybers" ON cybers
  FOR SELECT USING (is_active = true);

CREATE POLICY "Owners can manage their cybers" ON cybers
  FOR ALL USING (owner_id = auth.uid());

CREATE POLICY "Admins can manage all cybers" ON cybers
  FOR ALL USING (is_admin_or_manager());

-- Rooms table policies
CREATE POLICY "Anyone can view active rooms" ON rooms
  FOR SELECT USING (is_active = true);

CREATE POLICY "Owners can manage their rooms" ON rooms
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM cybers 
      WHERE id = rooms.cyber_id AND owner_id = auth.uid()
    )
  );

CREATE POLICY "Admins can manage all rooms" ON rooms
  FOR ALL USING (is_admin_or_manager());

-- Stations table policies
CREATE POLICY "Anyone can view stations" ON stations
  FOR SELECT USING (true);

CREATE POLICY "Owners can manage their stations" ON stations
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM rooms r
      JOIN cybers c ON r.cyber_id = c.id
      WHERE r.id = stations.room_id AND c.owner_id = auth.uid()
    )
  );

CREATE POLICY "Admins can manage all stations" ON stations
  FOR ALL USING (is_admin_or_manager());

-- Bookings table policies
CREATE POLICY "Users can view their own bookings" ON bookings
  FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Owners can view bookings for their cybers" ON bookings
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM stations s
      JOIN rooms r ON s.room_id = r.id
      JOIN cybers c ON r.cyber_id = c.id
      WHERE s.id = bookings.station_id AND c.owner_id = auth.uid()
    )
  );

CREATE POLICY "Users can create bookings" ON bookings
  FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update their own bookings" ON bookings
  FOR UPDATE USING (user_id = auth.uid());

CREATE POLICY "Owners can update booking status" ON bookings
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM stations s
      JOIN rooms r ON s.room_id = r.id
      JOIN cybers c ON r.cyber_id = c.id
      WHERE s.id = bookings.station_id AND c.owner_id = auth.uid()
    )
  );

-- Payments table policies
CREATE POLICY "Users can view their own payments" ON payments
  FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Managers can view all payments" ON payments
  FOR SELECT USING (is_admin_or_manager());

CREATE POLICY "Users can create payments" ON payments
  FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "Managers can update payment status" ON payments
  FOR UPDATE USING (is_admin_or_manager());

-- Reviews table policies
CREATE POLICY "Anyone can view reviews" ON reviews
  FOR SELECT USING (true);

CREATE POLICY "Users can create reviews for their completed bookings" ON reviews
  FOR INSERT WITH CHECK (
    user_id = auth.uid() AND
    EXISTS (
      SELECT 1 FROM bookings 
      WHERE id = reviews.booking_id 
        AND user_id = auth.uid() 
        AND status = 'completed'
    )
  );

-- Notifications table policies
CREATE POLICY "Users can view their own notifications" ON notifications
  FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Users can update their own notifications" ON notifications
  FOR UPDATE USING (user_id = auth.uid());

-- Functions for updating cyber ratings
CREATE OR REPLACE FUNCTION update_cyber_rating()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE cybers 
  SET 
    rating = COALESCE(
      (SELECT AVG(rating) FROM reviews WHERE cyber_id = NEW.cyber_id), 
      0
    ),
    review_count = (
      SELECT COUNT(*) FROM reviews WHERE cyber_id = NEW.cyber_id
    )
  WHERE id = NEW.cyber_id;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update cyber ratings when reviews are added/updated/deleted
CREATE TRIGGER update_cyber_rating_trigger
  AFTER INSERT OR UPDATE OR DELETE ON reviews
  FOR EACH ROW EXECUTE FUNCTION update_cyber_rating();

-- Function to check booking conflicts
CREATE OR REPLACE FUNCTION check_booking_conflict()
RETURNS TRIGGER AS $$
BEGIN
  -- Check for overlapping confirmed bookings
  IF EXISTS (
    SELECT 1 FROM bookings 
    WHERE station_id = NEW.station_id 
      AND status = 'confirmed'
      AND (
        (NEW.start_time <= start_time AND NEW.end_time > start_time) OR
        (NEW.start_time < end_time AND NEW.end_time >= end_time) OR
        (NEW.start_time >= start_time AND NEW.end_time <= end_time)
      )
      AND id != COALESCE(NEW.id, '00000000-0000-0000-0000-000000000000')::uuid
  ) THEN
    RAISE EXCEPTION 'Station is already booked for this time slot';
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to prevent booking conflicts
CREATE TRIGGER check_booking_conflict_trigger
  BEFORE INSERT OR UPDATE ON bookings
  FOR EACH ROW EXECUTE FUNCTION check_booking_conflict();

-- Function to auto-cancel expired bookings
CREATE OR REPLACE FUNCTION cancel_expired_bookings()
RETURNS void AS $$
BEGIN
  UPDATE bookings 
  SET status = 'cancelled'
  WHERE status = 'pending_payment' 
    AND expires_at < NOW();
END;
$$ LANGUAGE plpgsql;
