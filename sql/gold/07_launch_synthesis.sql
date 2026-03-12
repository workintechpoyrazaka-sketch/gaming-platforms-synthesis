-- ============================================================
-- File:       sql/gold/07_launch_synthesis.sql
-- Layer:      Gold
-- Purpose:    Final synthesis query — combines findings from
--             Q00 through Q06 into a single decision framework.
--             Answers: "If we were launching a game, which
--             platform strategy, price point, and region
--             maximizes reach and engagement?"
-- Depends on: gold_cross_platform_overlap, gold_pricing_by_strategy,
--             gold_player_engagement_by_strategy,
--             gold_achievement_completion_by_platform,
--             gold_geographic_player_distribution,
--             gold_review_by_strategy
-- Creates:    gold_launch_synthesis
-- Author:     Poi (Adil Poyraz Aka)
-- Date:       2026-03-12
-- Notes:      This table has one row per platform_strategy × platform_family.
--             Review data (Steam only) is NULL for PS and Xbox rows.
--             Xbox geographic data is NULL (no country in dataset).
--             Output columns match the target defined in methodology.md.
-- ============================================================

CREATE OR REPLACE TABLE `fast-archive-478610-v8.gaming_project.gold_launch_synthesis` AS

WITH
-- ============================================================
-- DIMENSION 1: Catalog landscape (from Q00)
-- How many games exist per strategy × platform?
-- ============================================================
catalog AS (
  SELECT
    platform_strategy,
    platform_family,
    COUNT(*) AS game_count,
    COUNT(DISTINCT title_normalized) AS unique_titles,
    COUNT(DISTINCT genres) AS genre_variety
  FROM `fast-archive-478610-v8.gaming_project.gold_cross_platform_overlap`
  GROUP BY platform_strategy, platform_family
),

-- ============================================================
-- DIMENSION 2: Pricing (from Q02)
-- Average and median price per strategy
-- ============================================================
pricing AS (
  SELECT
    platform_strategy,
    avg_price_usd,
    median_price_usd,
    free_game_pct
  FROM `fast-archive-478610-v8.gaming_project.gold_pricing_by_strategy`
),

-- ============================================================
-- DIMENSION 3: Player engagement (from Q03)
-- Library size and achievement activity per strategy × platform
-- ============================================================
engagement AS (
  SELECT
    platform_strategy,
    platform AS platform_family,
    player_count,
    avg_games_in_strategy,
    avg_total_achievements
  FROM `fast-archive-478610-v8.gaming_project.gold_player_engagement_by_strategy`
),

-- ============================================================
-- DIMENSION 4: Achievement completion (from Q04)
-- Completion depth per strategy × platform
-- ============================================================
completion AS (
  SELECT
    platform_strategy,
    platform_family,
    avg_completion_pct,
    full_completion_pct
  FROM `fast-archive-478610-v8.gaming_project.gold_achievement_completion_by_platform`
),

-- ============================================================
-- DIMENSION 5: Top region per platform (from Q05)
-- The #1 country for each platform by player count
-- ============================================================
top_regions AS (
  SELECT
    platform,
    country,
    player_count,
    ROW_NUMBER() OVER (PARTITION BY platform ORDER BY player_count DESC) AS rn
  FROM `fast-archive-478610-v8.gaming_project.gold_geographic_player_distribution`
),

top_region_per_platform AS (
  SELECT
    platform AS platform_family,
    country AS top_region,
    player_count AS top_region_players
  FROM top_regions
  WHERE rn = 1
),

-- ============================================================
-- DIMENSION 6: Review signals — Steam only (from Q06)
-- ============================================================
reviews AS (
  SELECT
    platform_strategy,
    review_count,
    avg_helpful AS steam_avg_helpful,
    avg_reviews_per_game AS steam_reviews_per_game,
    pct_with_awards AS steam_pct_with_awards
  FROM `fast-archive-478610-v8.gaming_project.gold_review_by_strategy`
)

-- ============================================================
-- FINAL JOIN: One row per strategy × platform_family
-- ============================================================
SELECT
  c.platform_strategy,
  c.platform_family,

  -- Catalog
  c.game_count,
  c.unique_titles,
  c.genre_variety,

  -- Pricing (strategy-level, not platform-level)
  p.avg_price_usd,
  p.median_price_usd,

  -- Player engagement
  e.player_count AS players_in_strategy,
  e.avg_games_in_strategy,
  e.avg_total_achievements,

  -- Achievement completion
  comp.avg_completion_pct,
  comp.full_completion_pct,

  -- Geography (NULL for xbox — no country data)
  tr.top_region,
  tr.top_region_players,

  -- Reviews (NULL for ps and xbox — Steam only)
  r.steam_avg_helpful,
  r.steam_reviews_per_game,
  r.steam_pct_with_awards,

  -- Derived: reach vs depth classification
  -- Reach = player count, Depth = completion rate
  CASE
    WHEN e.player_count > 50000 AND comp.avg_completion_pct > 40 THEN 'high_reach_high_depth'
    WHEN e.player_count > 50000 AND comp.avg_completion_pct <= 40 THEN 'high_reach_low_depth'
    WHEN e.player_count <= 50000 AND comp.avg_completion_pct > 40 THEN 'low_reach_high_depth'
    ELSE 'low_reach_low_depth'
  END AS reach_depth_quadrant

FROM catalog c

-- Pricing is per strategy (not per platform)
LEFT JOIN pricing p
  ON c.platform_strategy = p.platform_strategy

-- Engagement is per strategy × platform
LEFT JOIN engagement e
  ON c.platform_strategy = e.platform_strategy
  AND c.platform_family = e.platform_family

-- Completion is per strategy × platform
LEFT JOIN completion comp
  ON c.platform_strategy = comp.platform_strategy
  AND c.platform_family = comp.platform_family

-- Top region is per platform (not per strategy)
LEFT JOIN top_region_per_platform tr
  ON c.platform_family = tr.platform_family

-- Reviews are per strategy, Steam only
LEFT JOIN reviews r
  ON c.platform_strategy = r.platform_strategy
  AND c.platform_family = 'steam'

ORDER BY c.platform_strategy, c.platform_family
;
