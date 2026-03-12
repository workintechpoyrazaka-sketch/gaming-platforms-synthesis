-- ============================================================
-- File:       sql/gold/00_cross_platform_overlap.sql
-- Layer:      Gold
-- Purpose:    Classify every game as exclusive or multi-platform.
--             This is the backbone table — all subsequent Gold
--             queries reference platform_strategy from this table.
-- Depends on: silver_games
-- Creates:    gold_cross_platform_overlap
-- Author:     Poi (Adil Poyraz Aka)
-- Date:       2026-03-12
-- Notes:      Cross-platform matching uses LOWER(TRIM(title)).
--             No shared game ID exists across platforms.
--             PlayStation has 4 sub-platforms (PS3, PS4, PS5, PS Vita)
--             mapped to family 'ps' for overlap detection.
--             platform_strategy values:
--               exclusive_ps, exclusive_steam, exclusive_xbox,
--               multi_2, multi_3
-- ============================================================

CREATE OR REPLACE TABLE `fast-archive-478610-v8.gaming_project.gold_cross_platform_overlap` AS

WITH
-- Step 1: Normalize titles and map platform sub-types to families
-- PS3, PS4, PS5, PS Vita all map to 'ps' for cross-platform comparison
-- Original platform column preserved for console-level analysis
normalized_games AS (
  SELECT
    gameid,
    platform,
    CASE
      WHEN platform IN ('PS3', 'PS4', 'PS5', 'PS Vita') THEN 'ps'
      ELSE platform  -- 'steam' and 'xbox' are already clean single values
    END AS platform_family,
    title,
    LOWER(TRIM(title)) AS title_normalized,
    genres,
    release_date
  FROM `fast-archive-478610-v8.gaming_project.silver_games`
  WHERE title IS NOT NULL
),

-- Step 2: For each normalized title, find which platform families carry it
title_platform_map AS (
  SELECT
    title_normalized,
    ARRAY_AGG(DISTINCT platform_family) AS platform_families,
    COUNT(DISTINCT platform_family) AS family_count
  FROM normalized_games
  GROUP BY title_normalized
),

-- Step 3: Classify each title into a platform strategy
title_strategy AS (
  SELECT
    title_normalized,
    family_count,
    platform_families,
    CASE
      WHEN family_count = 3 THEN 'multi_3'
      WHEN family_count = 2 THEN 'multi_2'
      WHEN family_count = 1 AND 'ps' IN UNNEST(platform_families) THEN 'exclusive_ps'
      WHEN family_count = 1 AND 'steam' IN UNNEST(platform_families) THEN 'exclusive_steam'
      WHEN family_count = 1 AND 'xbox' IN UNNEST(platform_families) THEN 'exclusive_xbox'
    END AS platform_strategy
  FROM title_platform_map
)

-- Step 4: Join strategy back to every individual game row
-- Preserves original platform (PS4, PS5, etc.) for console-level detail
-- Adds platform_family, platform_strategy, and family_count for analysis
SELECT
  g.gameid,
  g.platform,
  g.platform_family,
  g.title,
  g.title_normalized,
  g.genres,
  g.release_date,
  s.family_count,
  s.platform_strategy
FROM normalized_games g
JOIN title_strategy s
  ON g.title_normalized = s.title_normalized
;
