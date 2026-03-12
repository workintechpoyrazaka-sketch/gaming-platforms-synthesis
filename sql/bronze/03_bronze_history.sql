-- ============================================================
-- File:       sql/bronze/03_bronze_history.sql
-- Layer:      Bronze (Raw → Cleaned)
-- Purpose:    Clean and deduplicate achievement history for all 3 platforms
-- Depends on: raw_history_ps, raw_history_steam, raw_history_xbox
-- Creates:    bronze_history_ps, bronze_history_steam, bronze_history_xbox
-- Author:     Poi (Adil Poyraz Aka)
-- Date:       2026-03-12
-- Notes:      History = when a player unlocked an achievement.
--             45M+ total rows across 3 platforms.
--             Deduplication: exact (playerid + achievementid + date_acquired) duplicates removed.
--             NULL playerid or achievementid = unusable row, filtered out.
-- ============================================================

-- PlayStation History
CREATE OR REPLACE TABLE `fast-archive-478610-v8.gaming_project.bronze_history_ps` AS
SELECT DISTINCT
  playerid,
  TRIM(achievementid) AS achievementid,
  date_acquired,
  'ps' AS platform
FROM `fast-archive-478610-v8.gaming_project.raw_history_ps`
WHERE playerid IS NOT NULL
  AND achievementid IS NOT NULL;

-- Steam History
CREATE OR REPLACE TABLE `fast-archive-478610-v8.gaming_project.bronze_history_steam` AS
SELECT DISTINCT
  playerid,
  TRIM(achievementid) AS achievementid,
  date_acquired,
  'steam' AS platform
FROM `fast-archive-478610-v8.gaming_project.raw_history_steam`
WHERE playerid IS NOT NULL
  AND achievementid IS NOT NULL;

-- Xbox History
CREATE OR REPLACE TABLE `fast-archive-478610-v8.gaming_project.bronze_history_xbox` AS
SELECT DISTINCT
  playerid,
  TRIM(achievementid) AS achievementid,
  date_acquired,
  'xbox' AS platform
FROM `fast-archive-478610-v8.gaming_project.raw_history_xbox`
WHERE playerid IS NOT NULL
  AND achievementid IS NOT NULL;
