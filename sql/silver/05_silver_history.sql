-- ============================================================
-- File:       sql/silver/05_silver_history.sql
-- Layer:      Silver (Bronze → Normalized)
-- Purpose:    Unified cross-platform achievement history
-- Depends on: bronze_history_ps, bronze_history_steam, bronze_history_xbox
-- Creates:    silver_history
-- Author:     Poi (Adil Poyraz Aka)
-- Date:       2026-03-12
-- Notes:      All 3 bronze tables have identical schemas.
--             ~45.5M expected rows (19.5M + 10.7M + 15.3M).
--             Largest table in the project — may take 30-60 seconds.
-- ============================================================

CREATE OR REPLACE TABLE `fast-archive-478610-v8.gaming_project.silver_history` AS

SELECT playerid, achievementid, date_acquired, platform
FROM `fast-archive-478610-v8.gaming_project.bronze_history_ps`

UNION ALL

SELECT playerid, achievementid, date_acquired, platform
FROM `fast-archive-478610-v8.gaming_project.bronze_history_steam`

UNION ALL

SELECT playerid, achievementid, date_acquired, platform
FROM `fast-archive-478610-v8.gaming_project.bronze_history_xbox`;
