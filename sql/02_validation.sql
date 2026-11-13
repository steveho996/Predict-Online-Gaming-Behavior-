SELECT (SELECT count(*) FROM staging.raw_players) raw_rows,
       (SELECT count(*) FROM gaming.player) players,
       (SELECT count(*) FROM gaming.player_gameplay) gameplay,
       (SELECT count(*) FROM gaming.v_player_analysis) view_rows;
SELECT count(*) - count(DISTINCT player_id) AS duplicate_ids FROM staging.raw_players;
SELECT engagement_level, count(*), round(100.0*count(*)/sum(count(*)) over(),1) pct
FROM gaming.v_player_analysis GROUP BY 1 ORDER BY 2 DESC;
