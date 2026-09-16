# Solar Acc - Technical Assessment

## Health Summary

**LOW - 29/100.** Static fleet-relative prioritization; actual query and refresh performance are **NOT PROVABLE FROM CURRENT EVIDENCE**.

## Key Metrics and Risk Scores
# Solar Acc - Technical Assessment
| Tables | Columns | Measures | Relationships | Partitions | Hierarchies | Roles | Max rows | Segment used MB* |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 3 | 40 | 8 | 2 | 3 | 0 | 0 | 4128 | 0.051 |

| Complexity | Storage | Partition | Relationship | Static DAX | Overall |
|---:|---:|---:|---:|---:|---:|
| 35 | 33 | 17 | 31 | 26 | **29** |

## Model Complexity

Compatibility level: 1200. Calculated tables: 1; calculated columns detected in TMSL: 1. Complexity is interpreted relative to this 54-model fleet.

## Storage

| Top table/dimension storage structure | USED_SIZE MB | Maximum segment rows |
|---|---:|---:|
| SolarAcc | 0.031 | 4128 |
| Calendar | 0.02 | 730 |
| DIM_CATEGORY_UNIT | 0 | 4 |

| Potential dictionary/cardinality review candidate | Dictionary MB |
|---|---:|
| SolarAcc, COMPANY | 1.017 |
| Calendar, Month Name Short | 1.016 |
| SolarAcc, CATEGORY_UNIT | 1.016 |
| Calendar, Year Month Name | 1.016 |
| Calendar, Quarter Name | 1.016 |
| Calendar, Month Name | 1.016 |
| Calendar, Day Name Short | 1.016 |
| DIM_CATEGORY_UNIT, CATEGORY_UNIT | 1.016 |

\* DMV accounting only; not authoritative resident model size. Column candidates require usage and actual cardinality validation.

## Partitions

3 metadata partitions across 3 tables. No fleet screening rule proves a partition defect. Partition-level size/statistics are unavailable.

## Relationships

2 total, 0 inactive, 0 bidirectional indicators and 0 possible many-to-many indicators. Runtime Formula Engine impact is **REQUIRES VALIDATION**.

## Measures / DAX

8 measures; 2 selected static pattern hits. Candidate measures: none by this narrow scan. This is STATIC DAX RISK, not proof of slowness.

## Security

0 roles observed. Security effectiveness, membership, RLS selectivity and runtime cost are not fully provable from role metadata alone.

## Findings

No material fleet-outlier finding generated. This does not prove absence of runtime issues.

## Recommendations

Prioritize evidence collection, then address confirmed storage/partition/relationship/DAX hotspots. Treat apparent unused objects only as **CANDIDATE FOR USAGE VALIDATION**.

## Evidence Gaps

No historical query duration/CPU, FE/SE timing, peak concurrency, refresh duration, memory-pressure series or object usage telemetry.

## Deep-Dive Recommendation

**NO - retain in fleet monitoring unless runtime evidence elevates it**.
