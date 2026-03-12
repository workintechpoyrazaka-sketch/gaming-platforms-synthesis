-- ============================================================
-- File:       sql/gold/02_pricing_analysis.sql
-- Layer:      Gold
-- Purpose:    Analyze pricing patterns across platforms and
--             platform strategies (exclusive vs multi-platform).
--             Key questions:
--               1. Do multi-platform games cost more than exclusives?
--               2. Same game, different platform — price premium?
--               3. How does pricing vary by platform family?
-- Depends on: gold_cross_platform_overlap, silver_prices
-- Creates:    gold_pricing_by_strategy, gold_pricing_cross_platform_delta
-- Author:     Poi (Adil Poyraz Aka)
-- Date:       2026-03-12
-- Notes:      silver_prices has multiple snapshots per game over time.
--             Using most recent price per game (MAX date_acquired).
--             USD used as base currency for cross-platform comparison.
--             Two output tables:
--               1. Strategy-level summary (exclusive vs multi pricing)
--               2. Same-game price deltas across platforms
-- ============================================================


-- ============================================================
-- TABLE 1: Pricing by platform strategy
-- One row per platform_strategy — average, median, spread
-- ============================================================

CREATE OR REPLACE TABLE `fast-archive-478610-v8.gaming_project.gold_pricing_by_strategy` AS

WITH
-- Step 1: Get the most recent price snapshot per game
-- silver_prices has multiple time snapshots; we want current pricing
latest_prices AS (
  SELECT
    gameid,
    usd,
    date_acquired,
    ROW_NUMBER() OVER (
      PARTITION BY gameid
      ORDER BY date_acquired DESC
    ) AS rn
  FROM `fast-archive-478610-v8.gaming_project.silver_prices`
  WHERE usd IS NOT NULL
),

current_prices AS (
  SELECT gameid, usd
  FROM latest_prices
  WHERE rn = 1
),

-- Step 2: Join prices to the overlap backbone
priced_games AS (
  SELECT
    o.gameid,
    o.platform,
    o.platform_family,
    o.title_normalized,
    o.platform_strategy,
    o.family_count,
    o.genres,
    p.usd
  FROM `fast-archive-478610-v8.gaming_project.gold_cross_platform_overlap` o
  JOIN current_prices p
    ON o.gameid = p.gameid
)

-- Step 3: Aggregate by platform strategy
SELECT
  platform_strategy,
  COUNT(*) AS game_count,
  COUNT(DISTINCT title_normalized) AS unique_titles,

  -- Central tendency
  ROUND(AVG(usd), 2) AS avg_price_usd,
  ROUND(APPROX_QUANTILES(usd, 100)[OFFSET(50)], 2) AS median_price_usd,

  -- Spread
  ROUND(MIN(usd), 2) AS min_price_usd,
  ROUND(MAX(usd), 2) AS max_price_usd,
  ROUND(STDDEV(usd), 2) AS stddev_price_usd,

  -- Free game prevalence
  COUNTIF(usd = 0) AS free_game_count,
  ROUND(COUNTIF(usd = 0) / COUNT(*) * 100, 1) AS free_game_pct
FROM priced_games
GROUP BY platform_strategy
ORDER BY avg_price_usd DESC
;


-- ============================================================
-- TABLE 2: Same-game price deltas across platforms
-- Only for multi-platform games (multi_2, multi_3)
-- Shows whether a platform charges more for the same title
-- ============================================================

CREATE OR REPLACE TABLE `fast-archive-478610-v8.gaming_project.gold_pricing_cross_platform_delta` AS

WITH
-- Step 1: Most recent prices (same as above)
latest_prices AS (
  SELECT
    gameid,
    usd,
    date_acquired,
    ROW_NUMBER() OVER (
      PARTITION BY gameid
      ORDER BY date_acquired DESC
    ) AS rn
  FROM `fast-archive-478610-v8.gaming_project.silver_prices`
  WHERE usd IS NOT NULL
),

current_prices AS (
  SELECT gameid, usd
  FROM latest_prices
  WHERE rn = 1
),

-- Step 2: Get multi-platform games with their prices per platform
multi_platform_priced AS (
  SELECT
    o.title_normalized,
    o.platform_family,
    o.platform_strategy,
    p.usd
  FROM `fast-archive-478610-v8.gaming_project.gold_cross_platform_overlap` o
  JOIN current_prices p
    ON o.gameid = p.gameid
  WHERE o.platform_strategy IN ('multi_2', 'multi_3')
),

-- Step 3: Pivot to one row per title with price per platform family
-- Use AVG in case a title has multiple entries within same family (e.g. PS4+PS5)
title_prices AS (
  SELECT
    title_normalized,
    platform_strategy,
    AVG(CASE WHEN platform_family = 'ps' THEN usd END) AS ps_price,
    AVG(CASE WHEN platform_family = 'steam' THEN usd END) AS steam_price,
    AVG(CASE WHEN platform_family = 'xbox' THEN usd END) AS xbox_price
  FROM multi_platform_priced
  GROUP BY title_normalized, platform_strategy
)

-- Step 4: Calculate deltas
-- Positive delta = that platform charges more than the average of the others
SELECT
  title_normalized,
  platform_strategy,
  ROUND(ps_price, 2) AS ps_price_usd,
  ROUND(steam_price, 2) AS steam_price_usd,
  ROUND(xbox_price, 2) AS xbox_price_usd,

  -- Absolute differences between platforms
  ROUND(ps_price - steam_price, 2) AS ps_vs_steam_delta,
  ROUND(ps_price - xbox_price, 2) AS ps_vs_xbox_delta,
  ROUND(steam_price - xbox_price, 2) AS steam_vs_xbox_delta,

  -- Which platform is cheapest for this title?
  CASE
    WHEN LEAST(
      COALESCE(ps_price, 999999),
      COALESCE(steam_price, 999999),
      COALESCE(xbox_price, 999999)
    ) = ps_price THEN 'ps'
    WHEN LEAST(
      COALESCE(ps_price, 999999),
      COALESCE(steam_price, 999999),
      COALESCE(xbox_price, 999999)
    ) = steam_price THEN 'steam'
    WHEN LEAST(
      COALESCE(ps_price, 999999),
      COALESCE(steam_price, 999999),
      COALESCE(xbox_price, 999999)
    ) = xbox_price THEN 'xbox'
  END AS cheapest_platform
FROM title_prices
;
