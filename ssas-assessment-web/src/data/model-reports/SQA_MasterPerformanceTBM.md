# SQA_MasterPerformanceTBM - Technical Assessment

## Health Summary

**LOW - 23/100.** Static fleet-relative prioritization; actual query and refresh performance are **NOT PROVABLE FROM CURRENT EVIDENCE**.

## Key Metrics and Risk Scores
# SQA_MasterPerformanceTBM - Technical Assessment
| Tables | Columns | Measures | Relationships | Partitions | Hierarchies | Roles | Max rows | Segment used MB* |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
|  | 22 | 13 | 0 |  | 0 | 0 | 6221 | 0 |

| Complexity | Storage | Partition | Relationship | Static DAX | Overall |
|---:|---:|---:|---:|---:|---:|
| 18 | 17 | 2 | 22 | 64 | **23** |

## Model Complexity

Compatibility level: 1200. Calculated tables: 0; calculated columns detected in TMSL: 0. Complexity is interpreted relative to this 54-model fleet.

## Storage

| Top table/dimension storage structure | USED_SIZE MB | Maximum segment rows |
|---|---:|---:|
| TBM | 0 | 6221 |

| Potential dictionary/cardinality review candidate | Dictionary MB |
|---|---:|
| TBM, MENU_FORM | 0.016 |
| TBM, UNIT | 0.016 |
| TBM, HPO | 0.016 |
| TBM, FORM | 0.016 |
| TBM, DIVISI | 0.016 |
| TBM, VALUE | 0.016 |
| TBM, ITEM | 0.016 |
| TBM, REGION | 0.016 |

\* DMV accounting only; not authoritative resident model size. Column candidates require usage and actual cardinality validation.

## Partitions

 metadata partitions across  tables. No fleet screening rule proves a partition defect. Partition-level size/statistics are unavailable.

## Relationships

0 total, 0 inactive, 0 bidirectional indicators and 0 possible many-to-many indicators. Runtime Formula Engine impact is **REQUIRES VALIDATION**.

## Measures / DAX

13 measures; 16 selected static pattern hits. Candidate measures: Sum Absolut; Sum Absolut Unit; Sum Absolut Reg; measuress; Sum Absolut MDO; Sum Absolut GROUP REG. This is STATIC DAX RISK, not proof of slowness.

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
