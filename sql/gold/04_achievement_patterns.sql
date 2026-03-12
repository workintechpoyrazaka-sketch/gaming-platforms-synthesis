-- ============================================================
-- File:       sql/gold/04_achievement_patterns.sql
-- Layer:      Gold
-- Purpose:    Analyze achievement completion patterns as a
--             retention/depth signal. Uses silver_history timestamps
--             to add a time dimension.
--             Key questions:
--               1. Which platform has higher achievement completion rates?
--               2. Do certain genres drive deeper achievement engagement?
--               3. Is there a "launch window" — when do players unlock?
--               4. Do multi-platform games have different completion
--                  patterns than exclusives?
-- Depends on: silver_achievements, silver_history, silver_games,
--             gold_cross_platform_overlap
-- Creates:    gold_achievement_completion_by_platform,
--             gold_achievement_by_genre,
--             gold_achievement_temporal
-- Author:     Poi (Adil Poyraz Aka)
-- Date:       2026-03-12
-- Notes:      silver_history has no gameid — must join through
--             silver_achievements to get game context.
--             Join path: history → achievements (gameid) → overlap (strategy)
--             PS has rarity tiers, Xbox has points, Steam has neither.
--             Completion rate = unlocked / total achievements per game.
--             Platform naming: silver_history uses 'ps', overlap uses
--             PS4/PS5/etc — join on platform_family.
-- ============================================================


-- ============================================================
-- TABLE 1: Achievement completion by platform and strategy
-- How thoroughly do players complete games on each platform?
-- ============================================================

CREATE OR REPLACE TABLE `fast-archive-478610-v8.gaming_project.gold_achievement_completion_by_platform` AS

WITH
-- Step 1: Count total achievements available per game per platform_family
game_achievement_count AS (
  SELECT
    gameid,
    CASE
      WHEN platform IN ('PS3', 'PS4', 'PS5', 'PS Vita') THEN 'ps'
      ELSE platform
    END AS platform_family,
    COUNT(DISTINCT achievementid) AS total_achievements
  FROM `fast-archive-478610-v8.gaming_project.silver_achievements`
  GROUP BY gameid, platform
),

-- Step 2: Bridge history to games via achievements
-- silver_history has no gameid; silver_achievements links achievementid → gameid
history_with_game AS (
  SELECT
    h.playerid,
    h.platform AS platform_family,
    a.gameid,
    h.achievementid
  FROM `fast-archive-478610-v8.gaming_project.silver_history` h
  JOIN `fast-archive-478610-v8.gaming_project.silver_achievements` a
    ON h.achievementid = a.achievementid AND h.platform = a.platform
),

-- Step 3: Count achievements unlocked per player per game
player_game_unlocks AS (
  SELECT
    playerid,
    platform_family,
    gameid,
    COUNT(DISTINCT achievementid) AS unlocked_achievements
  FROM history_with_game
  GROUP BY playerid, platform_family, gameid
),

-- Step 4: Calculate completion rate per player per game
player_completion AS (
  SELECT
    pgu.playerid,
    pgu.platform_family,
    pgu.gameid,
    pgu.unlocked_achievements,
    gac.total_achievements,
    ROUND(pgu.unlocked_achievements / NULLIF(gac.total_achievements, 0), 4) AS completion_rate
  FROM player_game_unlocks pgu
  JOIN game_achievement_count gac
    ON pgu.gameid = gac.gameid AND pgu.platform_family = gac.platform_family
),

-- Step 5: Add platform strategy from overlap backbone
completion_with_strategy AS (
  SELECT
    pc.playerid,
    pc.platform_family,
    pc.gameid,
    pc.unlocked_achievements,
    pc.total_achievements,
    pc.completion_rate,
    o.platform_strategy
  FROM player_completion pc
  JOIN `fast-archive-478610-v8.gaming_project.gold_cross_platform_overlap` o
    ON pc.gameid = o.gameid AND pc.platform_family = o.platform_family
)

-- Step 6: Aggregate by platform_family and strategy
SELECT
  platform_family,
  platform_strategy,
  COUNT(DISTINCT playerid) AS players,
  COUNT(DISTINCT gameid) AS games,
  COUNT(*) AS player_game_pairs,

  -- Completion metrics
  ROUND(AVG(completion_rate) * 100, 1) AS avg_completion_pct,
  ROUND(APPROX_QUANTILES(completion_rate, 100)[OFFSET(50)] * 100, 1) AS median_completion_pct,

  -- Full completionists (100% of achievements)
  COUNTIF(completion_rate = 1.0) AS full_completions,
  ROUND(COUNTIF(completion_rate = 1.0) / COUNT(*) * 100, 1) AS full_completion_pct
FROM completion_with_strategy
GROUP BY platform_family, platform_strategy
ORDER BY platform_family, avg_completion_pct DESC
;


-- ============================================================
-- TABLE 2: Achievement engagement by genre
-- Which genres drive the deepest achievement hunting?
-- ============================================================

CREATE OR REPLACE TABLE `fast-archive-478610-v8.gaming_project.gold_achievement_by_genre` AS

WITH
-- Step 1: Total achievements per game
game_achievement_count AS (
  SELECT
    gameid,
    CASE
      WHEN platform IN ('PS3', 'PS4', 'PS5', 'PS Vita') THEN 'ps'
      ELSE platform
    END AS platform_family,
    COUNT(DISTINCT achievementid) AS total_achievements
  FROM `fast-archive-478610-v8.gaming_project.silver_achievements`
  GROUP BY gameid, platform
),

-- Step 2: Bridge history → achievements for gameid
history_with_game AS (
  SELECT
    h.playerid,
    h.platform AS platform_family,
    a.gameid,
    h.achievementid
  FROM `fast-archive-478610-v8.gaming_project.silver_history` h
  JOIN `fast-archive-478610-v8.gaming_project.silver_achievements` a
    ON h.achievementid = a.achievementid AND h.platform = a.platform
),

-- Step 3: Player completion per game
player_game_unlocks AS (
  SELECT
    playerid,
    platform_family,
    gameid,
    COUNT(DISTINCT achievementid) AS unlocked_achievements
  FROM history_with_game
  GROUP BY playerid, platform_family, gameid
),

player_completion AS (
  SELECT
    pgu.platform_family,
    pgu.gameid,
    pgu.unlocked_achievements,
    gac.total_achievements,
    ROUND(pgu.unlocked_achievements / NULLIF(gac.total_achievements, 0), 4) AS completion_rate
  FROM player_game_unlocks pgu
  JOIN game_achievement_count gac
    ON pgu.gameid = gac.gameid AND pgu.platform_family = gac.platform_family
),

-- Step 4: Join to overlap for genre data
completion_with_genre AS (
  SELECT
    pc.platform_family,
    pc.gameid,
    pc.completion_rate,
    o.genres
  FROM player_completion pc
  JOIN `fast-archive-478610-v8.gaming_project.gold_cross_platform_overlap` o
    ON pc.gameid = o.gameid AND pc.platform_family = o.platform_family
  WHERE o.genres IS NOT NULL
)

-- Step 5: Aggregate by genre
SELECT
  genres,
  COUNT(*) AS player_game_pairs,
  COUNT(DISTINCT gameid) AS games,
  ROUND(AVG(completion_rate) * 100, 1) AS avg_completion_pct,
  ROUND(APPROX_QUANTILES(completion_rate, 100)[OFFSET(50)] * 100, 1) AS median_completion_pct,
  ROUND(COUNTIF(completion_rate = 1.0) / COUNT(*) * 100, 1) AS full_completion_pct
FROM completion_with_genre
GROUP BY genres
HAVING COUNT(*) >= 100  -- Minimum sample size
ORDER BY avg_completion_pct DESC
;


-- ============================================================
-- TABLE 3: Temporal achievement patterns
-- When do players unlock achievements?
-- Uses silver_history timestamps to find engagement trends
-- ============================================================

CREATE OR REPLACE TABLE `fast-archive-478610-v8.gaming_project.gold_achievement_temporal` AS

WITH
-- Step 1: Bridge history → achievements for gameid, extract time components
unlock_times AS (
  SELECT
    h.playerid,
    h.platform AS platform_family,
    a.gameid,
    h.date_acquired,
    EXTRACT(YEAR FROM h.date_acquired) AS unlock_year,
    EXTRACT(MONTH FROM h.date_acquired) AS unlock_month,
    EXTRACT(DAYOFWEEK FROM h.date_acquired) AS unlock_dow,
    EXTRACT(HOUR FROM h.date_acquired) AS unlock_hour
  FROM `fast-archive-478610-v8.gaming_project.silver_history` h
  JOIN `fast-archive-478610-v8.gaming_project.silver_achievements` a
    ON h.achievementid = a.achievementid AND h.platform = a.platform
  WHERE h.date_acquired IS NOT NULL
),

-- Step 2: Add platform strategy
unlock_with_strategy AS (
  SELECT
    ut.*,
    o.platform_strategy
  FROM unlock_times ut
  JOIN `fast-archive-478610-v8.gaming_project.gold_cross_platform_overlap` o
    ON ut.gameid = o.gameid AND ut.platform_family = o.platform_family
)

-- Step 3: Aggregate by year-month and platform
SELECT
  platform_family,
  platform_strategy,
  unlock_year,
  unlock_month,
  COUNT(*) AS unlock_count,
  COUNT(DISTINCT playerid) AS active_players,
  COUNT(DISTINCT gameid) AS active_games,
  ROUND(COUNT(*) / COUNT(DISTINCT playerid), 1) AS unlocks_per_player
FROM unlock_with_strategy
WHERE unlock_year >= 2015
GROUP BY platform_family, platform_strategy, unlock_year, unlock_month
HAVING COUNT(*) >= 50
ORDER BY unlock_year, unlock_month, platform_family
;
