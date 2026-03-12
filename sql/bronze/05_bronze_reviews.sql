-- ============================================================
-- File:       sql/bronze/05_bronze_reviews.sql
-- Layer:      Bronze (Raw → Cleaned)
-- Purpose:    Clean Steam reviews (only platform with review data)
-- Depends on: raw_reviews_steam
-- Creates:    bronze_reviews_steam
-- Author:     Poi (Adil Poyraz Aka)
-- Date:       2026-03-12
-- Notes:      Steam-only table. 1.2M reviews with text, helpfulness votes,
--             funny votes, and awards. 
--             TRIM review text. Filter rows missing critical foreign keys.
--             Negative helpful/funny/awards values filtered (data corruption).
-- ============================================================

-- Steam Reviews
CREATE OR REPLACE TABLE `fast-archive-478610-v8.gaming_project.bronze_reviews_steam` AS
SELECT
  reviewid,
  playerid,
  gameid,
  NULLIF(TRIM(review), '') AS review,
  helpful,
  funny,
  awards,
  posted,
  'steam' AS platform
FROM `fast-archive-478610-v8.gaming_project.raw_reviews_steam`
WHERE reviewid IS NOT NULL
  AND playerid IS NOT NULL
  AND gameid IS NOT NULL
  AND helpful >= 0        -- guard against corrupted negative values
  AND funny >= 0
  AND awards >= 0;
