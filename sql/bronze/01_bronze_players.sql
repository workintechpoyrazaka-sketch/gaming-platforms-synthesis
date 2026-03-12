-- ============================================================
-- File:       sql/bronze/01_bronze_players.sql
-- Layer:      Bronze (Raw → Cleaned)
-- Purpose:    Clean and type-check player tables for all 3 platforms
-- Depends on: raw_players_ps, raw_players_steam, raw_players_xbox
-- Creates:    bronze_players_ps, bronze_players_steam, bronze_players_xbox
-- Author:     Poi (Adil Poyraz Aka)
-- Date:       2026-03-12
-- Notes:      Schemas differ across platforms:
--               PS    → playerid, nickname, country
--               Steam → playerid, country, created
--               Xbox  → playerid, nickname (only)
--             Each table gets a platform tag for easier Silver UNION.
--             TRIM + NULLIF on all string fields.
-- ============================================================

-- PlayStation Players
CREATE OR REPLACE TABLE `fast-archive-478610-v8.gaming_project.bronze_players_ps` AS
SELECT
  playerid,
  NULLIF(TRIM(nickname), '') AS nickname,
  NULLIF(TRIM(country), '')  AS country,
  'ps' AS platform
FROM `fast-archive-478610-v8.gaming_project.raw_players_ps`
WHERE playerid IS NOT NULL;

-- Steam Players
CREATE OR REPLACE TABLE `fast-archive-478610-v8.gaming_project.bronze_players_steam` AS
SELECT
  playerid,
  NULLIF(TRIM(country), '') AS country,
  created,                    -- TIMESTAMP, no cast needed
  'steam' AS platform
FROM `fast-archive-478610-v8.gaming_project.raw_players_steam`
WHERE playerid IS NOT NULL;

-- Xbox Players
CREATE OR REPLACE TABLE `fast-archive-478610-v8.gaming_project.bronze_players_xbox` AS
SELECT
  playerid,
  NULLIF(TRIM(nickname), '') AS nickname,
  'xbox' AS platform
FROM `fast-archive-478610-v8.gaming_project.raw_players_xbox`
WHERE playerid IS NOT NULL;
