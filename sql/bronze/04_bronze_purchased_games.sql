-- ============================================================
-- File:       sql/bronze/04_bronze_purchased_games.sql
-- Layer:      Bronze (Raw → Cleaned)
-- Purpose:    Clean purchased games (player libraries) for all 3 platforms
-- Depends on: raw_purchased_games_ps, raw_purchased_games_steam, raw_purchased_games_xbox
-- Creates:    bronze_purchased_games_ps, bronze_purchased_games_steam, bronze_purchased_games_xbox
-- Author:     Poi (Adil Poyraz Aka)
-- Date:       2026-03-12
-- Notes:      Each row = one player + their game library (STRING field).
--             Library format TBD — likely comma-separated game IDs or titles.
--             Bronze preserves the raw library string; Silver will parse it.
--             TRIM + NULLIF on library field.
-- ============================================================

-- PlayStation Purchased Games
CREATE OR REPLACE TABLE `fast-archive-478610-v8.gaming_project.bronze_purchased_games_ps` AS
SELECT
  playerid,
  NULLIF(TRIM(library), '') AS library,
  'ps' AS platform
FROM `fast-archive-478610-v8.gaming_project.raw_purchased_games_ps`
WHERE playerid IS NOT NULL;

-- Steam Purchased Games
CREATE OR REPLACE TABLE `fast-archive-478610-v8.gaming_project.bronze_purchased_games_steam` AS
SELECT
  playerid,
  NULLIF(TRIM(library), '') AS library,
  'steam' AS platform
FROM `fast-archive-478610-v8.gaming_project.raw_purchased_games_steam`
WHERE playerid IS NOT NULL;

-- Xbox Purchased Games
CREATE OR REPLACE TABLE `fast-archive-478610-v8.gaming_project.bronze_purchased_games_xbox` AS
SELECT
  playerid,
  NULLIF(TRIM(library), '') AS library,
  'xbox' AS platform
FROM `fast-archive-478610-v8.gaming_project.raw_purchased_games_xbox`
WHERE playerid IS NOT NULL;
