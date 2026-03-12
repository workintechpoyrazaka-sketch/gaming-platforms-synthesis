-- ============================================================
-- File:       sql/bronze/02_bronze_achievements.sql
-- Layer:      Bronze (Raw → Cleaned)
-- Purpose:    Clean and type-check achievement tables for all 3 platforms
-- Depends on: raw_achievements_ps, raw_achievements_steam, raw_achievements_xbox
-- Creates:    bronze_achievements_ps, bronze_achievements_steam, bronze_achievements_xbox
-- Author:     Poi (Adil Poyraz Aka)
-- Date:       2026-03-12
-- Notes:      Platform-specific columns preserved:
--               PS    → rarity (STRING: Common, Rare, Ultra Rare, etc.)
--               Steam → no extras
--               Xbox  → points (FLOAT64: gamerscore value)
--             TRIM + NULLIF on all string fields.
-- ============================================================

-- PlayStation Achievements
CREATE OR REPLACE TABLE `fast-archive-478610-v8.gaming_project.bronze_achievements_ps` AS
SELECT
  NULLIF(TRIM(achievementid), '') AS achievementid,
  gameid,
  NULLIF(TRIM(title), '')         AS title,
  NULLIF(TRIM(description), '')   AS description,
  NULLIF(TRIM(rarity), '')        AS rarity,       -- PS-specific: trophy rarity tier
  'ps' AS platform
FROM `fast-archive-478610-v8.gaming_project.raw_achievements_ps`
WHERE achievementid IS NOT NULL
  AND gameid IS NOT NULL;

-- Steam Achievements
CREATE OR REPLACE TABLE `fast-archive-478610-v8.gaming_project.bronze_achievements_steam` AS
SELECT
  NULLIF(TRIM(achievementid), '') AS achievementid,
  gameid,
  NULLIF(TRIM(title), '')         AS title,
  NULLIF(TRIM(description), '')   AS description,
  'steam' AS platform
FROM `fast-archive-478610-v8.gaming_project.raw_achievements_steam`
WHERE achievementid IS NOT NULL
  AND gameid IS NOT NULL;

-- Xbox Achievements
CREATE OR REPLACE TABLE `fast-archive-478610-v8.gaming_project.bronze_achievements_xbox` AS
SELECT
  NULLIF(TRIM(achievementid), '') AS achievementid,
  gameid,
  NULLIF(TRIM(title), '')         AS title,
  NULLIF(TRIM(description), '')   AS description,
  points,                           -- Xbox-specific: gamerscore points
  'xbox' AS platform
FROM `fast-archive-478610-v8.gaming_project.raw_achievements_xbox`
WHERE achievementid IS NOT NULL
  AND gameid IS NOT NULL;
