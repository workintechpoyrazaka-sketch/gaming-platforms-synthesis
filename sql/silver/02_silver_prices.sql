-- ============================================================
-- File:       sql/silver/02_silver_prices.sql
-- Layer:      Silver (Bronze → Normalized)
-- Purpose:    Unified cross-platform prices table
-- Depends on: bronze_prices_ps, bronze_prices_steam, bronze_prices_xbox
-- Creates:    silver_prices
-- Author:     Poi (Adil Poyraz Aka)
-- Date:       2026-03-12
-- Notes:      All 3 bronze tables have identical schemas (Task #5 fixed Xbox jpy).
--             ~4.5M expected rows (62,816 + 4,414,273 + 22,638).
--             Multiple price snapshots per game over time (date_acquired).
-- ============================================================

CREATE OR REPLACE TABLE `fast-archive-478610-v8.gaming_project.silver_prices` AS

SELECT gameid, usd, eur, gbp, jpy, rub, date_acquired, 'ps' AS platform
FROM `fast-archive-478610-v8.gaming_project.bronze_prices_ps`

UNION ALL

SELECT gameid, usd, eur, gbp, jpy, rub, date_acquired, 'steam' AS platform
FROM `fast-archive-478610-v8.gaming_project.bronze_prices_steam`

UNION ALL

SELECT gameid, usd, eur, gbp, jpy, rub, date_acquired, 'xbox' AS platform
FROM `fast-archive-478610-v8.gaming_project.bronze_prices_xbox`;
