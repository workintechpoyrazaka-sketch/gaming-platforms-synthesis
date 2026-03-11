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

## Platform-Specific Decisions

### PlayStation
| # | Decision | Rationale | Applied In |
|---|----------|-----------|------------|
| | *To be documented during Bronze/Silver build* | | |

### Steam
| # | Decision | Rationale | Applied In |
|---|----------|-----------|------------|
| | *To be documented during Bronze/Silver build* | | |

### Xbox
| # | Decision | Rationale | Applied In |
|---|----------|-----------|------------|
| | *To be documented during Bronze/Silver build* | | |

## Task-Specific Decisions

*Added as each task's Gold layer is built.*

---

*This is a living document. Updated with every cleaning decision.*
