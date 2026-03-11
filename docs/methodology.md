# Methodology

## Data Pipeline Architecture

### Bronze Layer (Raw → Standardized)
- Column renaming to consistent snake_case
- Data type casting (strings to dates, decimals, integers)
- Null value standardization
- No business logic — preserves raw data with structural consistency

### Silver Layer (Standardized → Cleaned & Normalized)
- Cross-platform schema normalization (e.g., PS `library` text field → individual game rows)
- Multi-value field parsing (publishers, developers, genres, languages using delimiter splitting)
- Deduplication where applicable
- Platform identifier column added to enable cross-platform JOINs
- Achievement metric normalization (PS rarity, Xbox points, Steam binary)

### Gold Layer (Cleaned → Analysis-Ready)
- Task-specific aggregations and metrics
- Each task folder contains its own Gold queries
- Built on Silver tables — no direct Bronze dependencies in Gold

## Cross-Platform Joining Strategy

Games are matched across platforms by **title** (case-insensitive, trimmed). No shared ID exists across Steam, PlayStation, and Xbox.

## Analytical Framework

Each task follows: SQL aggregation → statistical testing → visualization → interpretation.

Statistical tests and ML models are applied where the data supports them, not forced.

## Tools

| Step | Tool | Why |
|------|------|-----|
| Storage & aggregation | BigQuery | Handles 60GB dataset, SQL-first approach |
| Statistical analysis | Python (scipy) | Hypothesis testing, correlation |
| Visualization | Plotly | Interactive, portfolio-quality charts |
| Machine Learning | scikit-learn | Clustering, classification where warranted |
| Version control | Git/GitHub | Reproducibility, portfolio presentation |

---

*Updated as each task completes.*
