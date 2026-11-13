-- Online Gaming Behavior: staging load + normalized (3NF) schema
-- Intentionally fail if schemas already exist; never erase an existing database.
CREATE SCHEMA staging; CREATE SCHEMA gaming;

-- 1. Raw staging table (mirrors CSV exactly)
CREATE TABLE staging.raw_players (
  player_id INT, age INT, gender TEXT, location TEXT, game_genre TEXT,
  play_time_hours NUMERIC, in_game_purchases INT, game_difficulty TEXT,
  sessions_per_week INT, avg_session_duration_minutes INT,
  player_level INT, achievements_unlocked INT, engagement_level TEXT);
\copy staging.raw_players FROM 'data/online_gaming_behavior_dataset.csv' WITH (FORMAT csv, HEADER true)

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM staging.raw_players WHERE in_game_purchases IS NULL OR in_game_purchases NOT IN (0,1)) THEN
    RAISE EXCEPTION 'Purchases must be 0 or 1';
  END IF;
END $$;

-- 2. Lookup (dimension) tables
CREATE TABLE gaming.gender (gender_id SMALLSERIAL PRIMARY KEY, gender_name TEXT UNIQUE NOT NULL);
CREATE TABLE gaming.location (location_id SMALLSERIAL PRIMARY KEY, location_name TEXT UNIQUE NOT NULL);
CREATE TABLE gaming.game_genre (genre_id SMALLSERIAL PRIMARY KEY, genre_name TEXT UNIQUE NOT NULL);
CREATE TABLE gaming.difficulty (difficulty_id SMALLINT PRIMARY KEY, difficulty_name TEXT UNIQUE NOT NULL);
CREATE TABLE gaming.engagement_level (engagement_id SMALLINT PRIMARY KEY, engagement_name TEXT UNIQUE NOT NULL);

INSERT INTO gaming.gender (gender_name) SELECT DISTINCT gender FROM staging.raw_players ORDER BY 1;
INSERT INTO gaming.location (location_name) SELECT DISTINCT location FROM staging.raw_players ORDER BY 1;
INSERT INTO gaming.game_genre (genre_name) SELECT DISTINCT game_genre FROM staging.raw_players ORDER BY 1;
INSERT INTO gaming.difficulty VALUES (1,'Easy'),(2,'Medium'),(3,'Hard');          -- ordinal
INSERT INTO gaming.engagement_level VALUES (1,'Low'),(2,'Medium'),(3,'High');     -- ordinal

-- 3. Player entity (demographics)
CREATE TABLE gaming.player (
  player_id   INT PRIMARY KEY,
  age         SMALLINT NOT NULL CHECK (age >= 0),
  gender_id   SMALLINT NOT NULL REFERENCES gaming.gender,
  location_id SMALLINT NOT NULL REFERENCES gaming.location);

-- 4. Gameplay profile (one snapshot per player)
CREATE TABLE gaming.player_gameplay (
  player_id INT PRIMARY KEY REFERENCES gaming.player ON DELETE CASCADE,
  genre_id SMALLINT NOT NULL REFERENCES gaming.game_genre,
  difficulty_id SMALLINT NOT NULL REFERENCES gaming.difficulty,
  play_time_hours NUMERIC NOT NULL CHECK (play_time_hours >= 0),
  in_game_purchases BOOLEAN NOT NULL,
  sessions_per_week SMALLINT NOT NULL CHECK (sessions_per_week >= 0),
  avg_session_duration_minutes SMALLINT NOT NULL CHECK (avg_session_duration_minutes >= 0),
  player_level SMALLINT NOT NULL CHECK (player_level >= 0),
  achievements_unlocked SMALLINT NOT NULL CHECK (achievements_unlocked >= 0),
  engagement_id SMALLINT NOT NULL REFERENCES gaming.engagement_level);

INSERT INTO gaming.player
SELECT r.player_id, r.age, g.gender_id, l.location_id FROM staging.raw_players r
JOIN gaming.gender g ON g.gender_name=r.gender JOIN gaming.location l ON l.location_name=r.location;

INSERT INTO gaming.player_gameplay
SELECT r.player_id, gg.genre_id, d.difficulty_id, r.play_time_hours, r.in_game_purchases=1,
       r.sessions_per_week, r.avg_session_duration_minutes, r.player_level, r.achievements_unlocked, e.engagement_id
FROM staging.raw_players r
JOIN gaming.game_genre gg ON gg.genre_name=r.game_genre
JOIN gaming.difficulty d ON d.difficulty_name=r.game_difficulty
JOIN gaming.engagement_level e ON e.engagement_name=r.engagement_level;

CREATE INDEX ON gaming.player_gameplay (engagement_id);
CREATE INDEX ON gaming.player_gameplay (genre_id);

-- 5. Analysis view (denormalized, for Python / Power BI)
CREATE VIEW gaming.v_player_analysis AS
SELECT p.player_id, p.age, ge.gender_name AS gender, lo.location_name AS location,
       gg.genre_name AS game_genre, d.difficulty_name AS game_difficulty,
       pg.play_time_hours, pg.in_game_purchases, pg.sessions_per_week,
       pg.avg_session_duration_minutes, pg.player_level, pg.achievements_unlocked,
       e.engagement_name AS engagement_level
FROM gaming.player p JOIN gaming.player_gameplay pg USING (player_id)
JOIN gaming.gender ge USING (gender_id) JOIN gaming.location lo USING (location_id)
JOIN gaming.game_genre gg USING (genre_id) JOIN gaming.difficulty d USING (difficulty_id)
JOIN gaming.engagement_level e USING (engagement_id);

-- Fail the transaction if inner joins silently lose rows or values change.
DO $$
BEGIN
  IF EXISTS (
    SELECT player_id, age, gender, location, game_genre, play_time_hours,
           in_game_purchases, game_difficulty, sessions_per_week,
           avg_session_duration_minutes, player_level, achievements_unlocked, engagement_level
    FROM staging.raw_players
    EXCEPT ALL
    SELECT player_id, age, gender, location, game_genre, play_time_hours,
           in_game_purchases::int, game_difficulty, sessions_per_week,
           avg_session_duration_minutes, player_level, achievements_unlocked, engagement_level
    FROM gaming.v_player_analysis
  ) OR (SELECT count(*) FROM staging.raw_players) <> (SELECT count(*) FROM gaming.v_player_analysis) THEN
    RAISE EXCEPTION 'Normalized data does not match staging';
  END IF;
END $$;
