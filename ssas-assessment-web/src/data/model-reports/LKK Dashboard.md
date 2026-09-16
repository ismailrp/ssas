# LKK Dashboard - Technical Assessment

## Health Summary

**MEDIUM - 40/100.** Static fleet-relative prioritization; actual query and refresh performance are **NOT PROVABLE FROM CURRENT EVIDENCE**.

## Key Metrics and Risk Scores
# LKK Dashboard - Technical Assessment
| Tables | Columns | Measures | Relationships | Partitions | Hierarchies | Roles | Max rows | Segment used MB* |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 9 | 89 | 3 |  | 9 | 0 |  | 221064 | 3.794 |

| Complexity | Storage | Partition | Relationship | Static DAX | Overall |
|---:|---:|---:|---:|---:|---:|
| 54 | 60 | 32 | 9 | 29 | **40** |

## Model Complexity

Compatibility level: 1200. Calculated tables: 7; calculated columns detected in TMSL: 1. Complexity is interpreted relative to this 54-model fleet.

## Storage

| Top table/dimension storage structure | USED_SIZE MB | Maximum segment rows |
|---|---:|---:|
| FACT_LKK_DASHBOARD | 3.695 | 221064 |
| DIM_DATE | 0.076 | 2191 |
| CALENDAR | 0.022 | 1096 |
| Table_Desc_Biaya_Pupuk | 0 | 23 |
| Table_Desc_Biaya_Umum | 0 | 25 |
| Table_Measure | 0 | 1 |
| Table_Desc_1 | 0 | 25 |
| Table_Desc_Biaya_Panen | 0 | 23 |

| Potential dictionary/cardinality review candidate | Dictionary MB |
|---|---:|
| FACT_LKK_DASHBOARD, ACTUAL | 9.295 |
| FACT_LKK_DASHBOARD, BUDGET | 5.153 |
| DIM_DATE, StandardDate | 1.049 |
| FACT_LKK_DASHBOARD, UNIT | 1.017 |
| DIM_DATE, LastDateOfMonth | 1.017 |
| FACT_LKK_DASHBOARD, REPORT_TYPE | 1.016 |
| DIM_DATE, CalendarMonthName | 1.016 |
| FACT_LKK_DASHBOARD, COST_TYPE | 1.016 |

\* DMV accounting only; not authoritative resident model size. Column candidates require usage and actual cardinality validation.

## Partitions

9 metadata partitions across 9 tables. No fleet screening rule proves a partition defect. Partition-level size/statistics are unavailable.

## Relationships

 total, 0 inactive, 0 bidirectional indicators and 0 possible many-to-many indicators. Runtime Formula Engine impact is **REQUIRES VALIDATION**.

## Measures / DAX

3 measures; 3 selected static pattern hits. Candidate measures: none by this narrow scan. This is STATIC DAX RISK, not proof of slowness.

## Security

 roles observed. Security effectiveness, membership, RLS selectivity and runtime cost are not fully provable from role metadata alone.

## Findings

No material fleet-outlier finding generated. This does not prove absence of runtime issues.

## Recommendations

Prioritize evidence collection, then address confirmed storage/partition/relationship/DAX hotspots. Treat apparent unused objects only as **CANDIDATE FOR USAGE VALIDATION**.

## Evidence Gaps

No historical query duration/CPU, FE/SE timing, peak concurrency, refresh duration, memory-pressure series or object usage telemetry.

## Deep-Dive Recommendation

**NO - retain in fleet monitoring unless runtime evidence elevates it**.
