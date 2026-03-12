-- ============================================================
-- File:       sql/silver/04_silver_achievements.sql
-- Layer:      Silver (Bronze → Normalized)
-- Purpose:    Unified cross-platform achievements table
-- Depends on: bronze_achievements_ps, bronze_achievements_steam, bronze_achievements_xbox
-- Creates:    silver_achievements
-- Author:     Poi (Adil Poyraz Aka)
-- Date:       2026-03-12
-- Notes:      Platform-specific columns preserved with NULLs:
--               PS    → rarity (trophy tier)     (no points)
--               Steam → no extras
--               Xbox  → points (gamerscore)      (no rarity)
--             ~3.14M expected rows (846,563 + 1,939,027 + 351,111).
-- ============================================================

CREATE OR REPLACE TABLE `fast-archive-478610-v8.gaming_project.silver_achievements` AS

-- PS: has rarity, no points
SELECT
  achievementid,
  gameid,
  title,
  description,
  rarity,
  CAST(NULL AS FLOAT64) AS points,
  platform
FROM `fast-archive-478610-v8.gaming_project.bronze_achievements_ps`

UNION ALL

-- Steam: no rarity, no points
SELECT
  achievementid,
  gameid,
  title,
  description,
  CAST(NULL AS STRING)  AS rarity,
  CAST(NULL AS FLOAT64) AS points,
  platform
FROM `fast-archive-478610-v8.gaming_project.bronze_achievements_steam`

UNION ALL

-- Xbox: no rarity, has points
SELECT
  achievementid,
  gameid,
  title,
  description,
  CAST(NULL AS STRING) AS rarity,
  points,
  platform
FROM `fast-archive-478610-v8.gaming_project.bronze_achievements_xbox`;
