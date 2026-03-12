-- ============================================================
-- File:       sql/silver/01_silver_games.sql
-- Layer:      Silver (Bronze → Normalized)
-- Purpose:    Unified cross-platform games table
-- Depends on: bronze_games_ps, bronze_games_steam, bronze_games_xbox
-- Creates:    silver_games
-- Author:     Poi (Adil Poyraz Aka)
-- Date:       2026-03-12
-- Notes:      PS bronze already has platform column; Steam/Xbox need it added.
--             All schemas otherwise identical after Bronze.
--             131,888 expected rows (23,151 + 98,248 + 10,489).
-- ============================================================

CREATE OR REPLACE TABLE `fast-archive-478610-v8.gaming_project.silver_games` AS

-- PS already has platform column from Bronze
SELECT
  gameid,
  title,
  platform,
  developers,
  publishers,
  genres,
  supported_languages,
  release_date
FROM `fast-archive-478610-v8.gaming_project.bronze_games_ps`

UNION ALL

-- Steam: add platform
SELECT
  gameid,
  title,
  'steam' AS platform,
  developers,
  publishers,
  genres,
  supported_languages,
  release_date
FROM `fast-archive-478610-v8.gaming_project.bronze_games_steam`

UNION ALL

-- Xbox: add platform
SELECT
  gameid,
  title,
  'xbox' AS platform,
  developers,
  publishers,
  genres,
  supported_languages,
  release_date
FROM `fast-archive-478610-v8.gaming_project.bronze_games_xbox`;
