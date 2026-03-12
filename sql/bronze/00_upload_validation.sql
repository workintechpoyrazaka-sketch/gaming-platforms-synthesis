-- =================================================================
-- FILE: upload_validation.sql
-- LAYER: Data Upload Verification
-- PURPOSE: Validate all raw table uploads against expected counts
-- AUTHOR: Poi
-- DATE: 2026-03-12
-- NOTES: Run after all CSV uploads complete. Row counts verified
--        against local Python CSV parser counts.
-- =================================================================

SELECT
  table_id,
  row_count
FROM `fast-archive-478610-v8.gaming_project.__TABLES__`
WHERE table_id LIKE 'raw_%'
ORDER BY table_id;

-- EXPECTED COUNTS (from upload session 2026-03-12):
-- ┌──────────────────────────────┬────────────┐
-- │ Table                        │ Rows       │
-- ├──────────────────────────────┼────────────┤
-- │ raw_achievements_ps          │    846,563 │
-- │ raw_achievements_steam       │  1,939,027 │
-- │ raw_achievements_xbox        │    351,111 │
-- │ raw_games_ps                 │     23,151 │
-- │ raw_games_steam              │     98,248 │
-- │ raw_games_xbox               │     10,489 │
-- │ raw_history_ps               │ 19,510,083 │
-- │ raw_history_steam            │ 10,693,879 │
-- │ raw_history_xbox             │ 15,275,900 │
-- │ raw_players_ps               │    356,600 │
-- │ raw_players_steam            │    424,683 │
-- │ raw_players_xbox             │    274,450 │
-- │ raw_prices_ps                │     62,816 │
-- │ raw_prices_steam             │  4,414,273 │
-- │ raw_prices_xbox              │     22,638 │
-- │ raw_purchased_games_ps       │     46,582 │
-- │ raw_purchased_games_steam    │    102,548 │
-- │ raw_purchased_games_xbox     │     46,466 │
-- │ raw_reviews_steam            │  1,201,879 │
-- └──────────────────────────────┴────────────┘
-- Total: 19 raw tables
--
-- KNOWN DATA LOSS:
-- raw_reviews_steam: 2,655 rows lost (0.22%) due to line-based
--   CSV splitting cutting multi-line review text at part boundaries.
-- raw_achievements_ps: <100 rows lost due to unparseable Unicode
--   characters in description field.
-- Both losses are under 0.5% and do not affect analysis validity.
