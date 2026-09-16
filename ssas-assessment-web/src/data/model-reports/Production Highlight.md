# Production Highlight - Technical Assessment

## Health Summary

**MEDIUM - 37/100.** Static fleet-relative prioritization; actual query and refresh performance are **NOT PROVABLE FROM CURRENT EVIDENCE**.

## Key Metrics and Risk Scores
# Production Highlight - Technical Assessment
| Tables | Columns | Measures | Relationships | Partitions | Hierarchies | Roles | Max rows | Segment used MB* |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 4 | 54 | 81 | 4 | 4 | 0 |  | 1829 | 0 |

| Complexity | Storage | Partition | Relationship | Static DAX | Overall |
|---:|---:|---:|---:|---:|---:|
| 49 | 14 | 22 | 41 | 69 | **37** |

## Model Complexity

Compatibility level: 1200. Calculated tables: 0; calculated columns detected in TMSL: 0. Complexity is interpreted relative to this 54-model fleet.

## Storage

| Top table/dimension storage structure | USED_SIZE MB | Maximum segment rows |
|---|---:|---:|
| DIM_REPORT_PRODUCTION_HIGHLIGHT | 0 | 15 |
| FACT_PRODUCTION_HIGHLIGHT_ADJ | 0 | 432 |
| FACT_PRODUCTION_HIGHLIGHT | 0 | 900 |
| DIM_DATE | 0 | 1826 |

| Potential dictionary/cardinality review candidate | Dictionary MB |
|---|---:|
| DIM_REPORT_PRODUCTION_HIGHLIGHT, Header | 0.016 |
| DIM_REPORT_PRODUCTION_HIGHLIGHT, UoM | 0.016 |
| DIM_REPORT_PRODUCTION_HIGHLIGHT, ReportItem | 0.016 |
| DIM_DATE, DayOfWeek | 0.016 |
| DIM_DATE, DaySuffix | 0.016 |
| FACT_PRODUCTION_HIGHLIGHT_ADJ, dateid | 0.016 |
| FACT_PRODUCTION_HIGHLIGHT, dateid | 0.016 |
| DIM_DATE, CalendarQuarterName | 0.016 |

\* DMV accounting only; not authoritative resident model size. Column candidates require usage and actual cardinality validation.

## Partitions

4 metadata partitions across 4 tables. No fleet screening rule proves a partition defect. Partition-level size/statistics are unavailable.

## Relationships

4 total, 0 inactive, 0 bidirectional indicators and 0 possible many-to-many indicators. Runtime Formula Engine impact is **REQUIRES VALIDATION**.

## Measures / DAX

81 measures; 111 selected static pattern hits. Candidate measures: Q1; Q2; Q3; Q4; H1; H2; 9M; MTD Mar; MTD Jun; MTD Sept; MTD Dec; Q1 Luas Areal; Q2 Luas Areal; Q3 Luas Areal; Q4 Luas Areal; H1 Luas Areal; 9M Luas Areal; H2 Luas Areal; Q1 Yield; Q2 Yield; Q3 Yield; Q4 Yield; H1 Yield; H2 Yield; 9M Yield; Q1 Adj; Q2 Adj; Q3 Adj; Q4 Adj. This is STATIC DAX RISK, not proof of slowness.

## Security

 roles observed. Security effectiveness, membership, RLS selectivity and runtime cost are not fully provable from role metadata alone.

## Findings

### F-048 - DAX

- **Severity / Classification / Confidence:** MEDIUM / REQUIRES VALIDATION / MEDIUM
- **Observation:** Static scan found 111 selected risk-pattern occurrences; candidate measures: Q1; Q2; Q3; Q4; H1; H2; 9M; MTD Mar; MTD Jun; MTD Sept; MTD Dec; Q1 Luas Areal; Q2 Luas Areal; Q3 Luas Areal; Q4 Luas Areal; H1 Luas Areal; 9M Luas Areal; H2 Luas Areal; Q1 Yield; Q2 Yield; Q3 Yield; Q4 Yield; H1 Yield; H2 Yield; 9M Yield; Q1 Adj; Q2 Adj; Q3 Adj; Q4 Adj.
- **Evidence:** metadata/measures.csv; model/database.tmsl.json
- **Analysis / Performance impact:** Iterator/context-transition patterns may increase Formula Engine work; syntax alone does not prove slowness.
- **Recommendation:** Capture representative query plans and Server Timings; refactor only measured hotspots using reusable base measures or reduced iterator input.
- **Expected benefit:** Potentially lower CPU and latency for confirmed hotspots.
- **Implementation effort:** MEDIUM
- **Validation:** Benchmark representative queries/refresh and verify semantic parity before production.


## Recommendations

Prioritize evidence collection, then address confirmed storage/partition/relationship/DAX hotspots. Treat apparent unused objects only as **CANDIDATE FOR USAGE VALIDATION**.

## Evidence Gaps

No historical query duration/CPU, FE/SE timing, peak concurrency, refresh duration, memory-pressure series or object usage telemetry.

## Deep-Dive Recommendation

**NO - retain in fleet monitoring unless runtime evidence elevates it**.
