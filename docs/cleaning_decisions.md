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

## Upload Decisions

| # | Decision | Rationale | Impact |
|---|----------|-----------|--------|
| 1 | Accept 0.22% row loss on raw_reviews_steam (2,655 / 1,204,534) | Line-based CSV splitter cut multi-line review records at part boundaries; re-splitting with CSV-aware parser not worth the time for 0.22% loss | Negligible |
| 2 | Accept <0.01% row loss on raw_achievements_ps (~100 / 846,563) | Rows with corrupted Unicode in description field couldn't be parsed | Negligible |
| 3 | Skip steam_friends.csv and steam_private_steamids.csv | Social network analysis not in scope for synthesis; can upload later if needed | None |
| 4 | Large files (>100MB) split into 90MB chunks via Python | BigQuery Console upload limit is 100MB; line-based splitting is imperfect for text-heavy CSVs (see decision #1) | Known limitation |

## Platform-Specific Decisions

### PlayStation
| # | Decision | Rationale | Applied In |
|---|----------|-----------|------------|
| 1 | PS_GAMES has `platform` column (PS4/PS5) others don't | Preserve as-is in Bronze, normalize in Silver | Bronze/Silver |
| 2 | PS_ACHIEVEMENTS uses `rarity` (Decimal) | Different metric than Xbox `points`; normalize in Silver | Silver |
| 3 | PS_PURCHASED_GAMES `library` is Text (comma-separated list) | Needs parsing into individual rows in Silver; Steam/Xbox already have one gameid per row | Silver |

### Steam
| # | Decision | Rationale | Applied In |
|---|----------|-----------|------------|
| 1 | STEAM_PLAYERS has `created` (Date) others don't | Account creation date; preserve, use where available | Bronze |
| 2 | STEAM_REVIEWS is Steam-only | Entire basis for Task #3 (Review Impact) | All layers |
| 3 | STEAM_ACHIEVEMENTS has no numeric value column | Unlike PS (rarity) and Xbox (points); binary completion only | Silver |

### Xbox
| # | Decision | Rationale | Applied In |
|---|----------|-----------|------------|
| 1 | XBOX_ACHIEVEMENTS uses `points` (Integer) | Gamerscore system; different metric than PS rarity | Silver |

## Task-Specific Decisions

*Added as each task's Gold layer is built.*

---

*This is a living document. Updated with every cleaning decision.*
