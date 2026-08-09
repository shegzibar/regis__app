-- Tournaments table (local or international)
CREATE TABLE tournaments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  description TEXT,
  type TEXT NOT NULL CHECK (type IN ('local', 'international')), -- local = single cyber, international = all cybers
  cyber_id UUID REFERENCES cybers(id) ON DELETE CASCADE, -- NULL for international tournaments
  admin_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  game_type TEXT NOT NULL CHECK (game_type IN ('ps5', 'ps4', 'pc', 'vip', 'mixed')),
  max_players INT DEFAULT 100,
  start_date TIMESTAMP NOT NULL,
  end_date TIMESTAMP NOT NULL,
  status TEXT NOT NULL DEFAULT 'registration' CHECK (status IN ('registration', 'active', 'completed', 'cancelled')),
  prize_pool NUMERIC(10, 2) DEFAULT 0, -- total prize value in EGP
  prize_per_hour NUMERIC(5, 2) DEFAULT 1, -- points earned per hour (usually 1 EGP = 1 point)
  cover_image_url TEXT,
  rules TEXT,
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP DEFAULT now()
);

-- Tournament participants (users who joined)
CREATE TABLE tournament_participants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tournament_id UUID NOT NULL REFERENCES tournaments(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  score INT DEFAULT 0, -- total points earned
  rank INT, -- final ranking (1st, 2nd, 3rd, etc)
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'disqualified', 'winner', 'runner_up')),
  joined_at TIMESTAMP DEFAULT now(),
  UNIQUE(tournament_id, user_id) -- user can't join same tournament twice
);

-- Tournament leaderboard (cached rankings for realtime updates)
CREATE TABLE tournament_leaderboard (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tournament_id UUID NOT NULL REFERENCES tournaments(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  position INT NOT NULL, -- 1st, 2nd, 3rd, etc
  score INT NOT NULL, -- total points
  wins INT DEFAULT 0,
  losses INT DEFAULT 0,
  updated_at TIMESTAMP DEFAULT now(),
  UNIQUE(tournament_id, position)
);

-- Create indexes for fast queries
CREATE INDEX idx_tournaments_cyber ON tournaments(cyber_id);
CREATE INDEX idx_tournaments_status ON tournaments(status);
CREATE INDEX idx_participants_tournament ON tournament_participants(tournament_id);
CREATE INDEX idx_participants_user ON tournament_participants(user_id);
CREATE INDEX idx_leaderboard_tournament ON tournament_leaderboard(tournament_id);
CREATE INDEX idx_leaderboard_user ON tournament_leaderboard(tournament_id, user_id);

-- Enable realtime for tournaments tables
ALTER PUBLICATION supabase_realtime ADD TABLE tournaments;
ALTER PUBLICATION supabase_realtime ADD TABLE tournament_participants;
ALTER PUBLICATION supabase_realtime ADD TABLE tournament_leaderboard;
