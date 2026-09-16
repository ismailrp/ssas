# SummarySalaryPayment_Tabular - Technical Assessment

## Health Summary

**LOW - 14/100.** Static fleet-relative prioritization; actual query and refresh performance are **NOT PROVABLE FROM CURRENT EVIDENCE**.

## Key Metrics and Risk Scores
# SummarySalaryPayment_Tabular - Technical Assessment
| Tables | Columns | Measures | Relationships | Partitions | Hierarchies | Roles | Max rows | Segment used MB* |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 2 | 56 | 0 |  | 2 | 0 |  | 1229 | 0 |

| Complexity | Storage | Partition | Relationship | Static DAX | Overall |
|---:|---:|---:|---:|---:|---:|
| 26 | 17 | 10 | 9 | 0 | **14** |

## Model Complexity

Compatibility level: 1200. Calculated tables: 0; calculated columns detected in TMSL: 0. Complexity is interpreted relative to this 54-model fleet.

## Storage

| Top table/dimension storage structure | USED_SIZE MB | Maximum segment rows |
|---|---:|---:|
| STG_MAP_UNIT | 0 | 144 |
| MART_SUMMARY_MCM | 0 | 1227 |

| Potential dictionary/cardinality review candidate | Dictionary MB |
|---|---:|
| STG_MAP_UNIT, F24 | 0.016 |
| STG_MAP_UNIT, DESC_WILAYAH2 | 0.016 |
| STG_MAP_UNIT, GROUP REGION2 | 0.016 |
| STG_MAP_UNIT, REGION_CODE | 0.016 |
| STG_MAP_UNIT, GROUP REGION | 0.016 |
| STG_MAP_UNIT, PERUSAHAAN  | 0.016 |
| STG_MAP_UNIT, WILAYAH2 | 0.016 |
| STG_MAP_UNIT, F17 | 0.016 |

\* DMV accounting only; not authoritative resident model size. Column candidates require usage and actual cardinality validation.

## Partitions

2 metadata partitions across 2 tables. No fleet screening rule proves a partition defect. Partition-level size/statistics are unavailable.

## Relationships

 total, 0 inactive, 0 bidirectional indicators and 0 possible many-to-many indicators. Runtime Formula Engine impact is **REQUIRES VALIDATION**.

## Measures / DAX

0 measures; 0 selected static pattern hits. Candidate measures: none by this narrow scan. This is STATIC DAX RISK, not proof of slowness.

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
