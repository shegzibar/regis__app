-- Function to update tournament scores on booking completion
CREATE OR REPLACE FUNCTION update_tournament_scores(p_user_id UUID, p_duration_hours NUMERIC)
RETURNS void AS $$
DECLARE
    t_id UUID;
    t_points NUMERIC;
    t_current_score INT;
    t_new_score INT;
BEGIN
    -- Find all active tournaments the user is participating in
    FOR t_id, t_points IN
        SELECT t.id, t.prize_per_hour
        FROM tournaments t
        JOIN tournament_participants tp ON t.id = tp.tournament_id
        WHERE tp.user_id = p_user_id
        AND t.status IN ('registration', 'active')
        AND t.start_date <= now()
        AND t.end_date >= now()
    LOOP
        -- Calculate points earned from this booking
        t_current_score := (p_duration_hours * t_points)::INT;
        
        -- Update participant score
        UPDATE tournament_participants
        SET score = score + t_current_score
        WHERE tournament_id = t_id AND user_id = p_user_id
        RETURNING score INTO t_new_score;
        
        -- Update leaderboard
        UPDATE tournament_leaderboard
        SET score = t_new_score,
            updated_at = now()
        WHERE tournament_id = t_id AND user_id = p_user_id;
        
        -- Recalculate positions for this tournament
        WITH ranked AS (
            SELECT user_id, 
                   RANK() OVER (ORDER BY score DESC) as new_position
            FROM tournament_leaderboard
            WHERE tournament_id = t_id
        )
        UPDATE tournament_leaderboard tl
        SET position = r.new_position
        FROM ranked r
        WHERE tl.tournament_id = t_id AND tl.user_id = r.user_id;
        
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Function to distribute prizes
CREATE OR REPLACE FUNCTION distribute_tournament_prizes(p_tournament_id UUID)
RETURNS void AS $$
DECLARE
    t_prize_pool NUMERIC;
    v_participant RECORD;
    v_prize NUMERIC;
    v_wallet_id UUID;
BEGIN
    SELECT prize_pool INTO t_prize_pool
    FROM tournaments
    WHERE id = p_tournament_id;
    
    -- Distribute to top 3 (50%, 30%, 20%)
    FOR v_participant IN
        SELECT user_id, position
        FROM tournament_leaderboard
        WHERE tournament_id = p_tournament_id
        AND position <= 3
    LOOP
        IF v_participant.position = 1 THEN
            v_prize := t_prize_pool * 0.50;
        ELSIF v_participant.position = 2 THEN
            v_prize := t_prize_pool * 0.30;
        ELSIF v_participant.position = 3 THEN
            v_prize := t_prize_pool * 0.20;
        END IF;
        
        IF v_prize > 0 THEN
            -- Get wallet id
            SELECT id INTO v_wallet_id
            FROM wallets
            WHERE user_id = v_participant.user_id;
            
            -- Insert transaction
            INSERT INTO wallet_transactions (wallet_id, type, amount, note)
            VALUES (v_wallet_id, 'bonus', v_prize, 'Tournament Prize for position ' || v_participant.position);
            
            -- Update participant status
            UPDATE tournament_participants
            SET rank = v_participant.position,
                status = 'winner'
            WHERE tournament_id = p_tournament_id AND user_id = v_participant.user_id;
        END IF;
    END LOOP;
    
    -- Set tournament as completed
    UPDATE tournaments
    SET status = 'completed'
    WHERE id = p_tournament_id;
END;
$$ LANGUAGE plpgsql;
