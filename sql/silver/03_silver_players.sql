-- ============================================================
-- File:       sql/silver/03_silver_players.sql
-- Layer:      Silver (Bronze → Normalized)
-- Purpose:    Unified cross-platform players table
-- Depends on: bronze_players_ps, bronze_players_steam, bronze_players_xbox
-- Creates:    silver_players
-- Author:     Poi (Adil Poyraz Aka)
-- Date:       2026-03-12
-- Notes:      Schemas differ — unified with NULLs for missing columns:
--               PS    → has nickname, country       (no created)
--               Steam → has country, created        (no nickname)
--               Xbox  → has nickname                (no country, no created)
--             ~1.06M expected rows (356,600 + 424,683 + 274,450).
-- ============================================================

CREATE OR REPLACE TABLE `fast-archive-478610-v8.gaming_project.silver_players` AS

-- PS: has nickname + country, no created
SELECT
  playerid,
  nickname,
  country,
  CAST(NULL AS TIMESTAMP) AS created,
  platform
FROM `fast-archive-478610-v8.gaming_project.bronze_players_ps`

UNION ALL

-- Steam: has country + created, no nickname
SELECT
  playerid,
  CAST(NULL AS STRING)    AS nickname,
  country,
  created,
  platform
FROM `fast-archive-478610-v8.gaming_project.bronze_players_steam`

UNION ALL

-- Xbox: has nickname only
SELECT
  playerid,
  nickname,
  CAST(NULL AS STRING)    AS country,
  CAST(NULL AS TIMESTAMP) AS created,
  platform
FROM `fast-archive-478610-v8.gaming_project.bronze_players_xbox`;
