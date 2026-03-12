-- ============================================================
-- File:       sql/silver/07_silver_reviews.sql
-- Layer:      Silver (Bronze → Normalized)
-- Purpose:    Silver reviews table (Steam only — no other platform has reviews)
-- Depends on: bronze_reviews_steam
-- Creates:    silver_reviews
-- Author:     Poi (Adil Poyraz Aka)
-- Date:       2026-03-12
-- Notes:      Pass-through from Bronze. No cross-platform UNION needed.
--             Kept as a separate Silver table for pipeline consistency —
--             Gold queries expect to read from silver_* tables.
--             ~1.2M rows.
-- ============================================================

CREATE OR REPLACE TABLE `fast-archive-478610-v8.gaming_project.silver_reviews` AS
SELECT
  reviewid,
  playerid,
  gameid,
  review,
  helpful,
  funny,
  awards,
  posted,
  platform
FROM `fast-archive-478610-v8.gaming_project.bronze_reviews_steam`;
