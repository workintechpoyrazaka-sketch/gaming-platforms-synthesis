# CSV → BigQuery Upload Mapping

**Dataset:** `fast-archive-478610-v8.gaming_project`

## Already Uploaded (from Task #5)

| CSV File | BigQuery Table | Status |
|----------|---------------|--------|
| ps_games.csv | PS_GAMES | ✅ |
| steam_games.csv | STEAM_GAMES | ✅ |
| xbox_games.csv | XBOX_GAMES | ✅ |
| ps_prices.csv | PS_PRICES | ✅ |
| steam_prices.csv | STEAM_PRICES | ✅ |
| xbox_prices.csv | XBOX_PRICES | ✅ |

## Need to Upload

### Players (3 tables)

| CSV File | BigQuery Table | Key Columns | Notes |
|----------|---------------|-------------|-------|
| steam_players.csv | STEAM_PLAYERS | playerid, country, created | Has account creation date |
| ps_players.csv | PS_PLAYERS | playerid, nickname, country | |
| xbox_players.csv | XBOX_PLAYERS | playerid, nickname, + others | Check exact columns on upload |

### Purchased Games (3 tables)

| CSV File | BigQuery Table | Key Columns | Notes |
|----------|---------------|-------------|-------|
| steam_purchased_games.csv | STEAM_PURCHASED_GAMES | playerid, gameid | One row per player-game |
| ps_purchased_games.csv | PS_PURCHASED_GAMES | playerid, library | ⚠️ Library is TEXT — needs Silver-layer parsing |
| xbox_purchased_games.csv | XBOX_PURCHASED_GAMES | playerid, gameid | One row per player-game |

### Achievements (3 tables)

| CSV File | BigQuery Table | Key Columns | Notes |
|----------|---------------|-------------|-------|
| steam_achievements.csv | STEAM_ACHIEVEMENTS | achievementid, gameid, title, description | No numeric value |
| ps_achievements.csv | PS_ACHIEVEMENTS | achievementid, gameid, title, description, rarity | Rarity = Decimal |
| xbox_achievements.csv | XBOX_ACHIEVEMENTS | achievementid, gameid, title, description, points | Points = Integer |

### History (3 tables)

| CSV File | BigQuery Table | Key Columns | Notes |
|----------|---------------|-------------|-------|
| steam_history.csv | STEAM_HISTORY | playerid, achievementid, date_acquired | Timestamp |
| ps_history.csv | PS_HISTORY | playerid, achievementid, date_acquired | Timestamp |
| xbox_history.csv | XBOX_HISTORY | playerid, achievementid, date_acquired | Timestamp |

### Steam-Only (3 tables)

| CSV File | BigQuery Table | Key Columns | Notes |
|----------|---------------|-------------|-------|
| steam_reviews.csv | STEAM_REVIEWS | reviewid, playerid, gameid, review, helpful, funny, awards, posted | Core for Task #3 |
| steam_friends.csv | STEAM_FRIENDS | playerid, friends | May skip — social network not in scope |
| steam_private_steamids.csv | STEAM_PRIVATE_STEAMIDS | playerid | May skip — just a filter list |

## Upload Order (Recommended)

1. **Players** (small, fast) — unlocks Task #4 regional analysis
2. **Purchased Games** (medium) — unlocks ownership metrics
3. **Achievements** (medium) — unlocks Task #2
4. **History** (large) — unlocks engagement over time
5. **Steam Reviews** (large) — unlocks Task #3
6. **Friends / Private SteamIDs** — skip unless needed

## Large File Strategy

BigQuery Console upload limit: **100MB** (CSV).
If any file exceeds this, split with:
```bash
# Split into 50MB chunks
split -b 50M large_file.csv large_file_part_
# Add header to each chunk (except first)
head -1 large_file.csv > header.txt
for f in large_file_part_a*; do
  if [ "$f" != "large_file_part_aa" ]; then
    cat header.txt "$f" > temp && mv temp "$f"
  fi
done
```

Or use `bq load` CLI for files up to 5GB.
