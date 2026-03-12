-- ============================================================
-- File:       sql/silver/06_silver_purchased_games.sql
-- Layer:      Silver (Bronze → Normalized)
-- Purpose:    Flatten JSON game library arrays into one row per player+game
-- Depends on: bronze_purchased_games_ps, bronze_purchased_games_steam, bronze_purchased_games_xbox
-- Creates:    silver_purchased_games
-- Author:     Poi (Adil Poyraz Aka)
-- Date:       2026-03-12
-- Notes:      Raw library format is a JSON array string: "[1, 177458, 659933, ...]"
--             Each element is a game ID.
--
--             TECHNIQUE — JSON_EXTRACT_ARRAY + UNNEST:
--               JSON_EXTRACT_ARRAY(library) parses the JSON string into an ARRAY.
--               UNNEST() expands the array into one row per element.
--               Each element comes back as a JSON-typed STRING, so we CAST to INT64.
--
--             Steam note: 54.2% of Steam rows have NULL library (55,607 of 102,548).
--             These are excluded by the WHERE clause (JSON_EXTRACT_ARRAY on NULL = NULL).
--
--             Expected output: millions of rows (one per player+game ownership).
-- ============================================================

CREATE OR REPLACE TABLE `fast-archive-478610-v8.gaming_project.silver_purchased_games` AS

-- PS
SELECT
  playerid,
  CAST(game_id AS INT64) AS gameid,
  platform
FROM `fast-archive-478610-v8.gaming_project.bronze_purchased_games_ps`,
  UNNEST(JSON_EXTRACT_ARRAY(library)) AS game_id
WHERE library IS NOT NULL

UNION ALL

-- Steam (54.2% NULL libraries will be excluded)
SELECT
  playerid,
  CAST(game_id AS INT64) AS gameid,
  platform
FROM `fast-archive-478610-v8.gaming_project.bronze_purchased_games_steam`,
  UNNEST(JSON_EXTRACT_ARRAY(library)) AS game_id
WHERE library IS NOT NULL

UNION ALL

-- Xbox
SELECT
  playerid,
  CAST(game_id AS INT64) AS gameid,
  platform
FROM `fast-archive-478610-v8.gaming_project.bronze_purchased_games_xbox`,
  UNNEST(JSON_EXTRACT_ARRAY(library)) AS game_id
WHERE library IS NOT NULL;
