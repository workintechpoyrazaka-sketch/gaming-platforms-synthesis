# Analysis Methodology

**Project:** Gaming Platforms Synthesis (Task #6)
**Author:** Poi (Adil Poyraz Aka)
**Date:** 2026-03-12

---

## Research Question

> If we were launching a game in 2025, which combination of platform strategy, pricing model, and target region maximizes player reach and engagement?

## Thesis

Multi-platform releases reach more players than exclusives, but single-platform games may achieve deeper per-player engagement. The optimal launch strategy depends on whether the goal is **reach** (maximize players) or **depth** (maximize engagement per player).

## Success Proxies

This dataset has no direct revenue data. "Success" is measured through three observable proxies:

| Proxy | What It Measures | Source Table | Available For |
|-------|-----------------|--------------|---------------|
| **Library presence** | How many players own a game | `silver_purchased_games` | All 3 platforms |
| **Achievement completion** | How deeply players engage with a game | `silver_history` + `silver_achievements` | All 3 platforms |
| **Review reception** | How players evaluate their experience | `silver_reviews` | Steam only |

### Why three proxies, not one?

Each captures a different phase of the player lifecycle:

- **Library presence** = acquisition (the player chose to get this game)
- **Achievement completion** = retention (the player kept playing)
- **Review reception** = advocacy (the player cared enough to write about it)

When all three align, the signal is strong. When they diverge, the divergence itself is a finding.

### Known limitations of each proxy

- **Library presence** is inflated by free games, bundles, and Steam sales. A game in 10M libraries isn't necessarily "successful" — it may have been free.
- **Achievement completion** varies by platform design: PlayStation uses rarity tiers, Xbox uses point values, Steam tracks binary unlock only. Cross-platform comparison requires normalization.
- **Review reception** exists only for Steam. The final synthesis (Q07) must acknowledge this asymmetry — Steam recommendations carry a signal the other platforms lack.
- **Steam library NULL bias**: 54.2% of Steam players have NULL library data. Retained players may skew toward more active or public profiles, inflating Steam engagement metrics relative to PS and Xbox.

## Cross-Platform Matching

No shared game ID exists across platforms. Games are matched by:

```
LOWER(TRIM(title))
```

This is imperfect — title variations exist (e.g., "Game: Subtitle" vs "Game — Subtitle"). Cleaning decisions for edge cases documented in `cleaning_decisions.md` as they arise during Gold queries.

## Gold Layer Structure

| Query | Purpose | Key Tables | Output |
|-------|---------|------------|--------|
| Q00 | Cross-platform overlap | silver_games | Foundation: which games are exclusive vs multi-platform |
| Q02 | Pricing analysis | silver_games + silver_prices | Price differences for same game across platforms |
| Q03 | Player engagement | silver_players + silver_purchased_games + silver_achievements | Library size + achievement activity by platform |
| Q04 | Achievement patterns | silver_achievements + silver_history + silver_games | Completion rates by platform, genre, game age |
| Q05 | Geographic distribution | silver_players + silver_purchased_games | Player regions vs library behavior |
| Q06 | Review signals | silver_reviews + silver_games + silver_prices | What predicts positive/helpful reviews (Steam only) |
| Q07 | Launch synthesis | Gold outputs from Q00–Q06 | Final recommendation: platform × price × region strategy |

## Q07 Target Output

The synthesis query produces a decision framework, not a single number. Target columns:

| Column | Description |
|--------|-------------|
| `platform_strategy` | exclusive_ps, exclusive_steam, exclusive_xbox, multi_2, multi_3 |
| `avg_price_usd` | Mean USD price for games in this strategy |
| `avg_players_per_game` | Mean library presence (ownership proxy) |
| `avg_achievement_completion_rate` | Mean completion rate across players |
| `top_genre` | Most common genre in this strategy |
| `top_region` | Region with highest player concentration |
| `steam_avg_review_score` | Mean review helpfulness (Steam subset only, NULL for others) |
| `game_count` | Sample size for this strategy |

This table lets someone filter by their goal (reach vs depth) and see which strategy wins.

## Analytical Sequence

1. **Map the landscape** (Q00) — How much overlap exists? What % of games are exclusive vs shared?
2. **Compare economics** (Q02) — Do multi-platform games cost more? Platform pricing premiums?
3. **Measure engagement** (Q03, Q04) — Do exclusives get played more deeply? Achievement patterns?
4. **Locate the audience** (Q05) — Where are the players? Regional concentration by platform?
5. **Hear the players** (Q06) — What do Steam reviewers value? Price sensitivity in reviews?
6. **Synthesize** (Q07) — Given all evidence, what's the optimal launch strategy?

---

*This document is written before analysis begins. Findings may challenge or refine the thesis. That's the point.*
