# SMK3 - Technical Assessment

## Health Summary

**MEDIUM - 30/100.** Static fleet-relative prioritization; actual query and refresh performance are **NOT PROVABLE FROM CURRENT EVIDENCE**.

## Key Metrics and Risk Scores
# SMK3 - Technical Assessment
| Tables | Columns | Measures | Relationships | Partitions | Hierarchies | Roles | Max rows | Segment used MB* |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 2 | 40 | 15 |  | 2 | 0 | 0 | 3135 | 0.028 |

| Complexity | Storage | Partition | Relationship | Static DAX | Overall |
|---:|---:|---:|---:|---:|---:|
| 36 | 33 | 10 | 9 | 57 | **30** |

## Model Complexity

Compatibility level: 1200. Calculated tables: 1; calculated columns detected in TMSL: 4. Complexity is interpreted relative to this 54-model fleet.

## Storage

| Top table/dimension storage structure | USED_SIZE MB | Maximum segment rows |
|---|---:|---:|
| Calendar | 0.015 | 730 |
| SMK3_SIGAP | 0.013 | 3135 |

| Potential dictionary/cardinality review candidate | Dictionary MB |
|---|---:|
| SMK3_SIGAP, ITEM | 1.017 |
| Calendar, Year Month Name | 1.016 |
| SMK3_SIGAP, DIVISI | 1.016 |
| SMK3_SIGAP, MENU_FORM | 1.016 |
| SMK3_SIGAP, FORM | 1.016 |
| Calendar, Month Name | 1.016 |
| Calendar, Day Name Short | 1.016 |
| Calendar, Day Name | 1.016 |

\* DMV accounting only; not authoritative resident model size. Column candidates require usage and actual cardinality validation.

## Partitions

2 metadata partitions across 2 tables. No fleet screening rule proves a partition defect. Partition-level size/statistics are unavailable.

## Relationships

 total, 0 inactive, 0 bidirectional indicators and 0 possible many-to-many indicators. Runtime Formula Engine impact is **REQUIRES VALIDATION**.

## Measures / DAX

15 measures; 16 selected static pattern hits. Candidate measures: SUM_BOBOT_BY_SUB_HEADER; SUM_BOBOT_BY_HEADER; TOTAL_GROUP_FORM2; NILAI_BGA_SUB. This is STATIC DAX RISK, not proof of slowness.

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
