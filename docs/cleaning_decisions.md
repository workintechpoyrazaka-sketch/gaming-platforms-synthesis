# Cleaning Decisions Log

Every data cleaning choice documented here for transparency and reproducibility.

---

## Global Decisions

| # | Decision | Rationale | Applied In |
|---|----------|-----------|------------|
| 1 | snake_case all column names | Consistency across platforms | Bronze |
| 2 | Add `platform` column to all Silver tables | Enable cross-platform queries without table-name inference | Silver |
| 3 | Parse multi-value text fields (publishers, developers, genres, languages) using delimiter splitting | One value per row enables accurate aggregation | Silver |
| 4 | Cross-platform game matching by title (case-insensitive, trimmed) | No shared ID exists across platforms | Gold |
| 5 | Table naming: `raw_[tabletype]_[platform]` | Consistent naming, table type first for alphabetical grouping | Raw |
| 6 | Allow quoted newlines on all CSV uploads | Free-text fields (descriptions, reviews) contain newlines inside quoted values; without this setting, BigQuery misreads rows as broken | Raw |
| 7 | Max bad records: 100 per upload | Allows BigQuery to skip truly unparseable rows (special characters, corrupted Unicode) while catching systemic issues | Raw |
| 8 | TRIM + NULLIF('') on all string fields at Bronze | Removes leading/trailing whitespace; converts empty strings to proper NULLs so downstream queries don't confuse '' with missing data | Bronze |
| 9 | WHERE NOT NULL on primary/foreign keys at Bronze | Rows missing key fields are unusable for joins; filter early | Bronze |
| 10 | CAST(NULL AS TYPE) for missing columns in cross-platform UNIONs | Platforms have different schemas (e.g., PS has nickname+country, Steam has country+created, Xbox has nickname only). NULLs fill gaps so UNION ALL works. | Silver |

## Upload Decisions

| # | Decision | Rationale | Impact |
|---|----------|-----------|--------|
| 1 | Accept 0.22% row loss on raw_reviews_steam (2,655 / 1,204,534) | Line-based CSV splitter cut multi-line review records at part boundaries; re-splitting with CSV-aware parser not worth the time for 0.22% loss | Negligible |
| 2 | Accept <0.01% row loss on raw_achievements_ps (~100 / 846,563) | Rows with corrupted Unicode in description field couldn't be parsed | Negligible |
| 3 | Skip steam_friends.csv and steam_private_steamids.csv | Social network analysis not in scope for synthesis; can upload later if needed | None |
| 4 | Large files (>100MB) split into 90MB chunks via Python | BigQuery Console upload limit is 100MB; line-based splitting is imperfect for text-heavy CSVs (see decision #1) | Known limitation |

## Bronze Decisions

| # | Decision | Rationale | Impact |
|---|----------|-----------|--------|
| 1 | Reuse Task #5 bronze_games (3 tables) and bronze_prices (3 tables) | Already cleaned and typed correctly. Avoids duplicating work. Dependency documented. | 6 tables reused, 13 new tables created |
| 2 | Don't modify Task #5 tables for missing `platform` column | bronze_games_ps has `platform` but Steam/Xbox don't (Task #5 inconsistency). Fixed at Silver with inline literals. Keeps repo separation clean. | Handled at Silver |
| 3 | Zero row loss verified with explicit proof queries | Ran COUNTIF for NULL keys, COUNT DISTINCT for duplicates, COUNTIF for negative values. All returned 0. Evidence, not inference from matching counts. | Confirmed data quality |
| 4 | SELECT DISTINCT on history tables for deduplication | 45M+ rows; exact (playerid + achievementid + date_acquired) duplicates would inflate engagement metrics. No duplicates found, but the guard remains. | 0 duplicates found |
| 5 | Negative value guard on reviews (helpful >= 0, funny >= 0, awards >= 0) | Negative engagement scores would indicate data corruption. No negatives found, but the guard remains. | 0 negatives found |

## Silver Decisions

| # | Decision | Rationale | Impact |
|---|----------|-----------|--------|
| 1 | purchased_games library parsed via JSON_EXTRACT_ARRAY + UNNEST | Library field stores JSON array string "[1, 177458, ...]". Flattened to one row per player+game. | 195K rows → 34.8M rows (avg ~178 games/player) |
| 2 | Steam purchased_games: 54.2% NULL libraries excluded | 55,607 of 102,548 Steam rows have NULL library field. PS and Xbox are 100% populated. NULL rows excluded at Silver — no library to parse. | 46,941 Steam players retained with library data |
| 3 | silver_reviews is a pass-through from Bronze | Steam is the only platform with reviews. No UNION needed, but kept as silver_ table for pipeline consistency — Gold queries read from silver_* tables. | 1,201,879 rows |
| 4 | Player schema differences preserved with NULLs | PS: nickname + country. Steam: country + created. Xbox: nickname only. All columns included in silver_players; platforms missing a column get NULL. | Regional analysis limited to PS + Steam players (Xbox has no country) |

## Gold Decisions

| # | Decision | Rationale | Impact |
|---|----------|-----------|--------|
| 1 | platform_family mapping: PS3/PS4/PS5/PS Vita → 'ps' | silver tables use 'ps' but raw/overlap data preserves PS4/PS5 etc. platform_family bridges the naming gap for all Gold JOINs. | Required for every Gold query joining silver tables to gold_cross_platform_overlap |
| 2 | Cross-platform matching by LOWER(TRIM(title)) | No shared game ID exists across platforms. Title-based matching is imperfect (subtitle variations, punctuation differences) but best available method. | Some false matches and missed matches expected; edge cases not manually corrected |
| 3 | Latest price snapshot via ROW_NUMBER() PARTITION BY gameid ORDER BY date_acquired DESC | silver_prices has multiple snapshots per game over time. Analysis uses most recent price only. | One price per game for pricing analysis |
| 4 | Pricing analysis covers paid games only | Zero free games appear in silver_prices (minimum $0.19). Free-to-play games either absent from price tables or have NULL USD values (filtered out). | Free-to-play segment not represented in pricing findings |
| 5 | Price tier boundaries: <$5, $5-15, $15-30, $30-60, $60+ | Chosen to reflect natural pricing clusters in gaming (indie, mid-tier, AA, AAA, premium). Zero-padded labels for sort order. | 5 tiers for review-price analysis |
| 6 | silver_history → silver_achievements bridge for gameid | silver_history has no gameid column. Must join through silver_achievements (achievementid → gameid) to connect achievement unlocks to games. | Two-hop join required for Q04 achievement patterns |
| 7 | Achievement completion rate = unlocked / total per game | Per player-game pair. 1.0 = full completionist (100% of game's achievements unlocked). | Meaningful only for games with achievements defined in silver_achievements |
| 8 | Genre analysis uses full genre string (not split) | Genre field stores arrays like "['Action', 'RPG']". Splitting into individual genres deferred to Python notebook. Gold tables use the composite string. | Some genre combinations have small sample sizes; splitting improves analysis |
| 9 | Temporal analysis filtered to 2015+ with HAVING >= 50 | Focus on recent decade for relevance. Minimum 50 unlocks per month-platform-strategy group for statistical meaning. | Pre-2015 data excluded from temporal table |
| 10 | Geographic analysis excludes Xbox entirely | Xbox has no country field in the dataset. Not a cleaning issue — the data was never collected. | Q05 and Q07 geographic findings cover PS + Steam only |
| 11 | Top region in Q07 is per-platform, not per-strategy | A platform's top country doesn't change based on game strategy. Joining at platform level, not strategy level. | Same top_region value appears for all strategies within a platform |
| 12 | Q07 reach_depth_quadrant: 50K players + 40% completion thresholds | Based on observed distribution midpoints. Classifies each strategy×platform into high/low reach × high/low depth. | 4-quadrant framework for launch decision |
| 13 | Q07 review columns NULL for non-Steam rows | Review data exists only for Steam. PS and Xbox rows carry NULL for steam_avg_helpful, steam_reviews_per_game, steam_pct_with_awards. By design, not a bug. | Acknowledged asymmetry in methodology.md |
| 14 | PS price averaged within platform_family for cross-platform delta | A game on both PS4 and PS5 may have different prices. AVG within 'ps' family gives a single PS price for comparison. | Minor smoothing effect on PS prices |

## Platform-Specific Decisions

### PlayStation
| # | Decision | Rationale | Applied In |
|---|----------|-----------|------------|
| 1 | PS_GAMES has `platform` column (PS4/PS5) others don't | Preserve as-is in Bronze, normalize in Silver | Bronze/Silver |
| 2 | PS_ACHIEVEMENTS uses `rarity` (STRING: Common, Rare, Ultra Rare, etc.) | Different metric than Xbox `points`; both preserved in silver_achievements with NULLs for missing platform | Silver |
| 3 | PS_PURCHASED_GAMES `library` is JSON array of game IDs | Same format as Xbox. Parsed via JSON_EXTRACT_ARRAY + UNNEST at Silver. | Silver |
| 4 | PS sub-platforms (PS3, PS4, PS5, PS Vita) mapped to 'ps' family | Required for cross-platform overlap detection. Original platform preserved in gold_cross_platform_overlap. | Gold |

### Steam
| # | Decision | Rationale | Applied In |
|---|----------|-----------|------------|
| 1 | STEAM_PLAYERS has `created` (Timestamp) others don't | Account creation date; preserve, use where available | Bronze/Silver |
| 2 | STEAM_REVIEWS is Steam-only | Entire basis for Task #3 (Review Impact) and Q06 review signals | All layers |
| 3 | STEAM_ACHIEVEMENTS has no numeric value column | Unlike PS (rarity) and Xbox (points); binary completion only | Silver |
| 4 | 54.2% of Steam purchased_games have NULL library | Possible privacy settings or data collection gap. Documented, excluded at Silver. Potential selection bias acknowledged in methodology.md. | Silver/Gold |

### Xbox
| # | Decision | Rationale | Applied In |
|---|----------|-----------|------------|
| 1 | XBOX_ACHIEVEMENTS uses `points` (FLOAT64) | Gamerscore system; different metric than PS rarity | Silver |
| 2 | XBOX_PLAYERS has no `country` field | Regional analysis for Xbox not possible from this dataset | Silver/Gold |
| 3 | raw_prices_xbox.jpy was STRING (all other price cols FLOAT64) | Fixed by Task #5 Bronze with SAFE_CAST. Verified bronze_prices_xbox.jpy is FLOAT64. | Bronze (Task #5) |

## Task-Specific Decisions

### Task #6 Gold: Key Cross-Cutting Findings

| # | Finding | Cleaning/Design Implication |
|---|---------|----------------------------|
| 1 | PS platform values mismatch (silver uses 'ps', overlap preserves PS4/PS5) | Created platform_family column. All Gold JOINs use platform_family. Bug discovered when Q00 returned zero PS exclusives. |
| 2 | silver_history has no gameid (only playerid, achievementid, date_acquired, platform) | All achievement-to-game analysis requires two-hop join: history → achievements → games. Bug discovered at Q04 runtime. |
| 3 | Most players (~85-89%) have no library or achievement data | Medians are 0.0 across platforms. Engagement metrics represent the active minority (~11-17% with library, ~1-2% with achievements). |

---

*This is a living document. Updated with every cleaning decision.*
