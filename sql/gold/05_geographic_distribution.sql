-- ============================================================
-- File:       sql/gold/05_geographic_distribution.sql
-- Layer:      Gold
-- Purpose:    Analyze geographic distribution of players and
--             how region correlates with engagement behavior.
--             Key questions:
--               1. Where are the players? Top countries by platform.
--               2. Do players in different regions own more/fewer games?
--               3. Do regions show different platform preferences?
--               4. Regional achievement engagement patterns.
-- Depends on: silver_players, silver_purchased_games, silver_history,
--             silver_achievements, gold_cross_platform_overlap
-- Creates:    gold_geographic_player_distribution,
--             gold_geographic_engagement
-- Author:     Poi (Adil Poyraz Aka)
-- Date:       2026-03-12
-- Notes:      Xbox has NO country field — regional analysis is
--             PS + Steam only. This is a known dataset limitation,
--             not a cleaning issue.
--             silver_players.country may contain inconsistent values
--             (country codes vs full names, casing). Cleaning applied
--             inline at query time.
-- ============================================================


-- ============================================================
-- TABLE 1: Geographic player distribution
-- Where are the players? Count by country × platform
-- ============================================================

CREATE OR REPLACE TABLE `fast-archive-478610-v8.gaming_project.gold_geographic_player_distribution` AS

WITH
-- Step 1: Get players with country data (PS + Steam only)
players_with_country AS (
  SELECT
    playerid,
    platform,
    UPPER(TRIM(country)) AS country_clean
  FROM `fast-archive-478610-v8.gaming_project.silver_players`
  WHERE country IS NOT NULL
    AND TRIM(country) != ''
),

-- Step 2: Count players per country per platform
country_platform_counts AS (
  SELECT
    country_clean,
    platform,
    COUNT(DISTINCT playerid) AS player_count
  FROM players_with_country
  GROUP BY country_clean, platform
),

-- Step 3: Total players per country (both platforms combined)
country_totals AS (
  SELECT
    country_clean,
    SUM(player_count) AS total_players
  FROM country_platform_counts
  GROUP BY country_clean
)

-- Step 4: Combine with platform breakdown and ranking
SELECT
  cpc.country_clean AS country,
  cpc.platform,
  cpc.player_count,
  ct.total_players AS total_players_all_platforms,
  ROUND(cpc.player_count / ct.total_players * 100, 1) AS platform_share_pct,
  RANK() OVER (ORDER BY ct.total_players DESC) AS country_rank_overall,
  RANK() OVER (PARTITION BY cpc.platform ORDER BY cpc.player_count DESC) AS country_rank_in_platform
FROM country_platform_counts cpc
JOIN country_totals ct
  ON cpc.country_clean = ct.country_clean
ORDER BY ct.total_players DESC, cpc.platform
;


-- ============================================================
-- TABLE 2: Geographic engagement
-- Do players in different regions engage differently?
-- Library size + achievement activity by country
-- ============================================================

CREATE OR REPLACE TABLE `fast-archive-478610-v8.gaming_project.gold_geographic_engagement` AS

WITH
-- Step 1: Players with country (PS + Steam only)
players_with_country AS (
  SELECT
    playerid,
    platform,
    UPPER(TRIM(country)) AS country_clean
  FROM `fast-archive-478610-v8.gaming_project.silver_players`
  WHERE country IS NOT NULL
    AND TRIM(country) != ''
),

-- Step 2: Library size per player
player_library AS (
  SELECT
    playerid,
    platform,
    COUNT(DISTINCT gameid) AS games_owned
  FROM `fast-archive-478610-v8.gaming_project.silver_purchased_games`
  GROUP BY playerid, platform
),

-- Step 3: Achievement activity per player
-- Bridge through silver_achievements for gameid
player_achievements AS (
  SELECT
    h.playerid,
    h.platform,
    COUNT(DISTINCT h.achievementid) AS achievements_unlocked,
    COUNT(DISTINCT a.gameid) AS games_with_achievements
  FROM `fast-archive-478610-v8.gaming_project.silver_history` h
  JOIN `fast-archive-478610-v8.gaming_project.silver_achievements` a
    ON h.achievementid = a.achievementid AND h.platform = a.platform
  GROUP BY h.playerid, h.platform
),

-- Step 4: Combine player data
player_full AS (
  SELECT
    pwc.playerid,
    pwc.platform,
    pwc.country_clean,
    COALESCE(pl.games_owned, 0) AS games_owned,
    COALESCE(pa.achievements_unlocked, 0) AS achievements_unlocked,
    COALESCE(pa.games_with_achievements, 0) AS games_with_achievements
  FROM players_with_country pwc
  LEFT JOIN player_library pl
    ON pwc.playerid = pl.playerid AND pwc.platform = pl.platform
  LEFT JOIN player_achievements pa
    ON pwc.playerid = pa.playerid AND pwc.platform = pa.platform
)

-- Step 5: Aggregate by country × platform
SELECT
  country_clean AS country,
  platform,
  COUNT(*) AS total_players,

  -- Library engagement
  COUNTIF(games_owned > 0) AS players_with_library,
  ROUND(AVG(games_owned), 1) AS avg_games_owned,
  ROUND(APPROX_QUANTILES(games_owned, 100)[OFFSET(50)], 1) AS median_games_owned,

  -- Achievement engagement
  COUNTIF(achievements_unlocked > 0) AS players_with_achievements,
  ROUND(AVG(achievements_unlocked), 1) AS avg_achievements,
  ROUND(APPROX_QUANTILES(achievements_unlocked, 100)[OFFSET(50)], 1) AS median_achievements,

  -- Depth: achievements per game (for players with library)
  ROUND(
    AVG(CASE WHEN games_owned > 0 THEN achievements_unlocked / games_owned END),
    2
  ) AS avg_achievements_per_game
FROM player_full
GROUP BY country_clean, platform
HAVING COUNT(*) >= 50  -- Minimum sample for meaningful stats
ORDER BY total_players DESC
;
