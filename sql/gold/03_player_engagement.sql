-- ============================================================
-- File:       sql/gold/03_player_engagement.sql
-- Layer:      Gold
-- Purpose:    Measure player engagement across platforms using
--             two success proxies:
--               1. Library size (games owned per player)
--               2. Achievement activity (achievements unlocked per player)
--             Connects to platform_strategy via purchased games.
--             Key questions:
--               1. Which platform has the most engaged players?
--               2. Do players who own multi-platform games engage deeper?
--               3. Library size vs achievement activity — do they correlate?
-- Depends on: silver_players, silver_purchased_games, silver_history,
--             gold_cross_platform_overlap
-- Creates:    gold_player_engagement_by_platform,
--             gold_player_engagement_by_strategy
-- Author:     Poi (Adil Poyraz Aka)
-- Date:       2026-03-12
-- Notes:      Steam 54.2% NULL libraries excluded at Silver.
--             Retained Steam players may skew toward more active profiles.
--             Xbox has no country field — regional cuts limited to PS+Steam.
--             silver_purchased_games uses 'ps' while gold_cross_platform_overlap
--             preserves original platform (PS4/PS5/etc). Table 2 joins on
--             platform_family to bridge this difference.
-- ============================================================


-- ============================================================
-- TABLE 1: Player engagement by platform
-- One row per platform — library size + achievement stats
-- ============================================================

CREATE OR REPLACE TABLE `fast-archive-478610-v8.gaming_project.gold_player_engagement_by_platform` AS

WITH
-- Step 1: Library size per player
-- Count distinct games each player owns
player_library AS (
  SELECT
    playerid,
    platform,
    COUNT(DISTINCT gameid) AS games_owned
  FROM `fast-archive-478610-v8.gaming_project.silver_purchased_games`
  GROUP BY playerid, platform
),

-- Step 2: Achievement activity per player
-- Count distinct achievements unlocked
player_achievements AS (
  SELECT
    playerid,
    platform,
    COUNT(DISTINCT achievementid) AS achievements_unlocked
  FROM `fast-archive-478610-v8.gaming_project.silver_history`
  GROUP BY playerid, platform
),

-- Step 3: Combine — full player picture
-- LEFT JOINs because a player may have library data but no achievements or vice versa
player_combined AS (
  SELECT
    p.playerid,
    p.platform,
    COALESCE(l.games_owned, 0) AS games_owned,
    COALESCE(a.achievements_unlocked, 0) AS achievements_unlocked
  FROM `fast-archive-478610-v8.gaming_project.silver_players` p
  LEFT JOIN player_library l
    ON p.playerid = l.playerid AND p.platform = l.platform
  LEFT JOIN player_achievements a
    ON p.playerid = a.playerid AND p.platform = a.platform
)

-- Step 4: Aggregate by platform
SELECT
  platform,
  COUNT(*) AS total_players,

  -- Library metrics
  COUNTIF(games_owned > 0) AS players_with_library,
  ROUND(COUNTIF(games_owned > 0) / COUNT(*) * 100, 1) AS library_coverage_pct,
  ROUND(AVG(games_owned), 1) AS avg_games_owned,
  ROUND(APPROX_QUANTILES(games_owned, 100)[OFFSET(50)], 1) AS median_games_owned,
  MAX(games_owned) AS max_games_owned,

  -- Achievement metrics
  COUNTIF(achievements_unlocked > 0) AS players_with_achievements,
  ROUND(COUNTIF(achievements_unlocked > 0) / COUNT(*) * 100, 1) AS achievement_coverage_pct,
  ROUND(AVG(achievements_unlocked), 1) AS avg_achievements_unlocked,
  ROUND(APPROX_QUANTILES(achievements_unlocked, 100)[OFFSET(50)], 1) AS median_achievements_unlocked,
  MAX(achievements_unlocked) AS max_achievements_unlocked,

  -- Engagement ratio: achievements per game owned (depth signal)
  -- Only for players who own at least 1 game
  ROUND(
    AVG(CASE WHEN games_owned > 0 THEN achievements_unlocked / games_owned END),
    2
  ) AS avg_achievements_per_game
FROM player_combined
GROUP BY platform
ORDER BY total_players DESC
;


-- ============================================================
-- TABLE 2: Player engagement by platform strategy
-- Do players who own multi-platform games engage more deeply?
-- Measures engagement per player based on the strategy of games they own
-- NOTE: Joins on platform_family because silver_purchased_games uses
--       'ps' while gold_cross_platform_overlap uses 'PS4'/'PS5'/etc.
-- ============================================================

CREATE OR REPLACE TABLE `fast-archive-478610-v8.gaming_project.gold_player_engagement_by_strategy` AS

WITH
-- Step 1: Tag each purchased game with its platform strategy
-- Join on platform_family (not platform) to bridge naming difference
purchased_with_strategy AS (
  SELECT
    pg.playerid,
    pg.platform,
    pg.gameid,
    o.platform_strategy
  FROM `fast-archive-478610-v8.gaming_project.silver_purchased_games` pg
  JOIN `fast-archive-478610-v8.gaming_project.gold_cross_platform_overlap` o
    ON pg.gameid = o.gameid AND pg.platform = o.platform_family
),

-- Step 2: Count games per player per strategy
player_strategy_counts AS (
  SELECT
    playerid,
    platform,
    platform_strategy,
    COUNT(DISTINCT gameid) AS games_owned_in_strategy
  FROM purchased_with_strategy
  GROUP BY playerid, platform, platform_strategy
),

-- Step 3: Get achievement counts per player (same platform)
player_achievements AS (
  SELECT
    playerid,
    platform,
    COUNT(DISTINCT achievementid) AS total_achievements
  FROM `fast-archive-478610-v8.gaming_project.silver_history`
  GROUP BY playerid, platform
)

-- Step 4: For each strategy, what's the profile of players who own those games?
SELECT
  psc.platform_strategy,
  psc.platform,
  COUNT(DISTINCT psc.playerid) AS player_count,
  ROUND(AVG(psc.games_owned_in_strategy), 1) AS avg_games_in_strategy,
  ROUND(APPROX_QUANTILES(psc.games_owned_in_strategy, 100)[OFFSET(50)], 1) AS median_games_in_strategy,

  -- How active are these players overall? (total achievements, not just for this strategy)
  ROUND(AVG(COALESCE(pa.total_achievements, 0)), 1) AS avg_total_achievements,
  ROUND(APPROX_QUANTILES(COALESCE(pa.total_achievements, 0), 100)[OFFSET(50)], 1) AS median_total_achievements
FROM player_strategy_counts psc
LEFT JOIN player_achievements pa
  ON psc.playerid = pa.playerid AND psc.platform = pa.platform
GROUP BY psc.platform_strategy, psc.platform
ORDER BY psc.platform_strategy, player_count DESC
;
