-- ============================================================
-- File:       sql/gold/06_review_signals.sql
-- Layer:      Gold
-- Purpose:    Analyze Steam review patterns as the third success
--             proxy (advocacy). Steam-only — no review data exists
--             for PS or Xbox in this dataset.
--             Key questions:
--               1. Do higher-priced games get more helpful reviews?
--               2. Which genres generate the most review engagement?
--               3. Do multi-platform games get reviewed differently
--                  than Steam exclusives?
--               4. What's the relationship between review volume
--                  and helpfulness/awards?
-- Depends on: silver_reviews, silver_games, silver_prices,
--             gold_cross_platform_overlap
-- Creates:    gold_review_by_strategy,
--             gold_review_by_price_tier,
--             gold_review_by_genre
-- Author:     Poi (Adil Poyraz Aka)
-- Date:       2026-03-12
-- Notes:      Steam only. This asymmetry is acknowledged in
--             methodology.md — Q07 synthesis must handle the fact
--             that advocacy signal exists for one platform only.
--             Review fields: review (text), helpful (int),
--             funny (int), awards (int), posted (timestamp).
-- ============================================================


-- ============================================================
-- TABLE 1: Review engagement by platform strategy
-- Do Steam exclusives get different review behavior than
-- multi-platform games reviewed on Steam?
-- ============================================================

CREATE OR REPLACE TABLE `fast-archive-478610-v8.gaming_project.gold_review_by_strategy` AS

WITH
-- Step 1: Join reviews to overlap backbone for strategy
reviews_with_strategy AS (
  SELECT
    r.playerid,
    r.gameid,
    r.helpful,
    r.funny,
    r.awards,
    r.posted,
    o.platform_strategy,
    o.title_normalized,
    o.genres
  FROM `fast-archive-478610-v8.gaming_project.silver_reviews` r
  JOIN `fast-archive-478610-v8.gaming_project.gold_cross_platform_overlap` o
    ON r.gameid = o.gameid AND o.platform_family = 'steam'
)

-- Step 2: Aggregate by strategy
SELECT
  platform_strategy,
  COUNT(*) AS review_count,
  COUNT(DISTINCT gameid) AS games_reviewed,
  COUNT(DISTINCT playerid) AS unique_reviewers,

  -- Helpfulness
  ROUND(AVG(helpful), 2) AS avg_helpful,
  ROUND(APPROX_QUANTILES(helpful, 100)[OFFSET(50)], 2) AS median_helpful,
  ROUND(COUNTIF(helpful > 0) / COUNT(*) * 100, 1) AS pct_with_helpful_votes,

  -- Funny votes
  ROUND(AVG(funny), 2) AS avg_funny,
  ROUND(COUNTIF(funny > 0) / COUNT(*) * 100, 1) AS pct_with_funny_votes,

  -- Awards
  ROUND(AVG(awards), 2) AS avg_awards,
  ROUND(COUNTIF(awards > 0) / COUNT(*) * 100, 1) AS pct_with_awards,

  -- Reviews per game (volume signal)
  ROUND(COUNT(*) / COUNT(DISTINCT gameid), 1) AS avg_reviews_per_game
FROM reviews_with_strategy
GROUP BY platform_strategy
ORDER BY review_count DESC
;


-- ============================================================
-- TABLE 2: Review engagement by price tier
-- Do expensive games get more thoughtful reviews?
-- ============================================================

CREATE OR REPLACE TABLE `fast-archive-478610-v8.gaming_project.gold_review_by_price_tier` AS

WITH
-- Step 1: Get latest Steam prices
latest_prices AS (
  SELECT
    gameid,
    usd,
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

-- Step 2: Assign price tiers
priced_reviews AS (
  SELECT
    r.playerid,
    r.gameid,
    r.helpful,
    r.funny,
    r.awards,
    cp.usd,
    CASE
      WHEN cp.usd < 5 THEN '01_under_5'
      WHEN cp.usd < 15 THEN '02_5_to_15'
      WHEN cp.usd < 30 THEN '03_15_to_30'
      WHEN cp.usd < 60 THEN '04_30_to_60'
      ELSE '05_60_plus'
    END AS price_tier
  FROM `fast-archive-478610-v8.gaming_project.silver_reviews` r
  JOIN current_prices cp
    ON r.gameid = cp.gameid
)

-- Step 3: Aggregate by price tier
SELECT
  price_tier,
  COUNT(*) AS review_count,
  COUNT(DISTINCT gameid) AS games_reviewed,
  ROUND(AVG(usd), 2) AS avg_price_in_tier,

  -- Helpfulness
  ROUND(AVG(helpful), 2) AS avg_helpful,
  ROUND(APPROX_QUANTILES(helpful, 100)[OFFSET(50)], 2) AS median_helpful,
  ROUND(COUNTIF(helpful > 0) / COUNT(*) * 100, 1) AS pct_with_helpful_votes,

  -- Funny
  ROUND(AVG(funny), 2) AS avg_funny,
  ROUND(COUNTIF(funny > 0) / COUNT(*) * 100, 1) AS pct_with_funny_votes,

  -- Awards
  ROUND(AVG(awards), 2) AS avg_awards,
  ROUND(COUNTIF(awards > 0) / COUNT(*) * 100, 1) AS pct_with_awards,

  -- Volume
  ROUND(COUNT(*) / COUNT(DISTINCT gameid), 1) AS avg_reviews_per_game
FROM priced_reviews
GROUP BY price_tier
ORDER BY price_tier
;


-- ============================================================
-- TABLE 3: Review engagement by genre
-- Which genres generate the most review advocacy?
-- ============================================================

CREATE OR REPLACE TABLE `fast-archive-478610-v8.gaming_project.gold_review_by_genre` AS

WITH
-- Step 1: Join reviews to overlap for genre data
reviews_with_genre AS (
  SELECT
    r.playerid,
    r.gameid,
    r.helpful,
    r.funny,
    r.awards,
    o.genres
  FROM `fast-archive-478610-v8.gaming_project.silver_reviews` r
  JOIN `fast-archive-478610-v8.gaming_project.gold_cross_platform_overlap` o
    ON r.gameid = o.gameid AND o.platform_family = 'steam'
  WHERE o.genres IS NOT NULL
)

-- Step 2: Aggregate by genre combination
SELECT
  genres,
  COUNT(*) AS review_count,
  COUNT(DISTINCT gameid) AS games_reviewed,

  -- Helpfulness
  ROUND(AVG(helpful), 2) AS avg_helpful,
  ROUND(COUNTIF(helpful > 0) / COUNT(*) * 100, 1) AS pct_with_helpful_votes,

  -- Funny
  ROUND(AVG(funny), 2) AS avg_funny,
  ROUND(COUNTIF(funny > 0) / COUNT(*) * 100, 1) AS pct_with_funny_votes,

  -- Awards
  ROUND(AVG(awards), 2) AS avg_awards,
  ROUND(COUNTIF(awards > 0) / COUNT(*) * 100, 1) AS pct_with_awards,

  -- Volume per game
  ROUND(COUNT(*) / COUNT(DISTINCT gameid), 1) AS avg_reviews_per_game
FROM reviews_with_genre
GROUP BY genres
HAVING COUNT(*) >= 100  -- Minimum sample
ORDER BY avg_helpful DESC
;
