# Gaming Platforms Synthesis

**Cross-cutting analysis connecting pricing, engagement, reviews, regional markets, and publisher strategy across Steam, PlayStation, and Xbox.**

> *"If we were launching a game, which publisher model, region, price, and platform maximizes success?"*

---

## Project Overview

A synthesis analysis of the [Gaming Profiles 2025](https://www.kaggle.com/datasets/artyomkruglov/gaming-profiles-2025-steam-playstation-xbox) dataset — 60GB of player, game, pricing, achievement, and review data across three major gaming platforms. This project connects six analytical dimensions into one unified narrative.

| Dimension | What It Answers |
|-----------|----------------|
| **Price Competition** | How do pricing strategies differ across platforms? |
| **Player Engagement** | What drives achievement completion behavior? |
| **Review Impact** | Do reviews predict ownership? (Steam-only) |
| **Regional Markets** | Which countries prefer which genres and platforms? |
| **Publisher Strategy** | What separates top publishers from the rest? |
| **Synthesis** | How do all dimensions interact? |

## Architecture

### Data Pipeline

```
Kaggle CSVs → BigQuery Bronze (raw) → Silver (cleaned, normalized) → Gold (analysis-ready)
```

**BigQuery project:** `fast-archive-478610-v8` / `gaming_project`

### Tech Stack

| Layer | Tools |
|-------|-------|
| Storage & SQL | Google BigQuery |
| Analysis | Python, Pandas, scipy |
| Visualization | Plotly |
| ML | scikit-learn |
| Version Control | Git / GitHub |

## Repository Structure

```
gaming-platforms-synthesis/
├── README.md
├── sql/
│   ├── bronze/          # Raw → Bronze layer scripts
│   ├── silver/          # Bronze → Silver layer scripts
│   └── gold/            # Analysis-ready queries
├── notebooks/           # Colab analysis notebooks
├── charts/              # Exported visualizations
├── presentation/        # Final presentation
└── docs/
    ├── methodology.md
    ├── cleaning_decisions.md
    └── upload_mapping.md
```

## Dataset

**Source:** [Gaming Profiles 2025](https://www.kaggle.com/datasets/artyomkruglov/gaming-profiles-2025-steam-playstation-xbox)

**Scale:** 131,884+ games across Steam, PlayStation, and Xbox. 18 core tables covering games, prices, players, achievements, play history, purchased games, and reviews.

| Platform | Tables |
|----------|--------|
| Steam | Games, Prices, Players, Achievements, History, Purchased Games, Reviews, Friends |
| PlayStation | Games, Prices, Players, Achievements, History, Purchased Games |
| Xbox | Games, Prices, Players, Achievements, History, Purchased Games |

## Key Findings

*Updated as analysis progresses.*

## Methodology

See [docs/methodology.md](docs/methodology.md) for detailed approach.

## How to Reproduce

1. Download the dataset from [Kaggle](https://www.kaggle.com/datasets/artyomkruglov/gaming-profiles-2025-steam-playstation-xbox)
2. Upload CSVs into a BigQuery dataset (see [docs/upload_mapping.md](docs/upload_mapping.md))
3. Run Bronze scripts in `sql/bronze/` in order
4. Run Silver scripts in `sql/silver/` in order
5. Run Gold scripts in `sql/gold/`
6. Open notebook(s) in `notebooks/` for analysis and visualization

## What I Learned

*Updated as analysis progresses.*

## Related

- **Publisher Analysis (Task #5):** [gaming-publisher-analysis](https://github.com/YOUR_USERNAME/gaming-publisher-analysis) — standalone deep-dive into publisher strategy with 3 ML models

## Author

**Poi** — Data Analyst | [LinkedIn](YOUR_LINKEDIN_URL) | [GitHub](https://github.com/YOUR_USERNAME)

Built as a portfolio project during the Workintech Data Analyst → Data Scientist program (2025–2026).
