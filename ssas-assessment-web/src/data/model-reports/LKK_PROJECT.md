# LKK_PROJECT - Technical Assessment

## Health Summary

**LOW - 16/100.** Static fleet-relative prioritization; actual query and refresh performance are **NOT PROVABLE FROM CURRENT EVIDENCE**.

## Key Metrics and Risk Scores
# LKK_PROJECT - Technical Assessment
| Tables | Columns | Measures | Relationships | Partitions | Hierarchies | Roles | Max rows | Segment used MB* |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
|  | 18 | 5 | 0 |  | 0 |  | 331164 | 0 |

| Complexity | Storage | Partition | Relationship | Static DAX | Overall |
|---:|---:|---:|---:|---:|---:|
| 14 | 27 | 2 | 22 | 10 | **16** |

## Model Complexity

Compatibility level: 1200. Calculated tables: 0; calculated columns detected in TMSL: 0. Complexity is interpreted relative to this 54-model fleet.

## Storage

| Top table/dimension storage structure | USED_SIZE MB | Maximum segment rows |
|---|---:|---:|
| FACT_LKK_BIAYA_UMUM | 0 | 331164 |

| Potential dictionary/cardinality review candidate | Dictionary MB |
|---|---:|
| FACT_LKK_BIAYA_UMUM, LEVEL_3 | 0.016 |
| FACT_LKK_BIAYA_UMUM, LEVEL_2 | 0.016 |
| FACT_LKK_BIAYA_UMUM, INPLS | 0.016 |
| FACT_LKK_BIAYA_UMUM, KETERANGAN | 0.016 |
| FACT_LKK_BIAYA_UMUM, LEVEL_1 | 0.016 |
| FACT_LKK_BIAYA_UMUM, CATEGORY | 0.016 |
| FACT_LKK_BIAYA_UMUM, UNITN | 0.016 |
| FACT_LKK_BIAYA_UMUM, ACTV_LEVEL1 | 0.016 |

\* DMV accounting only; not authoritative resident model size. Column candidates require usage and actual cardinality validation.

## Partitions

 metadata partitions across  tables. No fleet screening rule proves a partition defect. Partition-level size/statistics are unavailable.

## Relationships

0 total, 0 inactive, 0 bidirectional indicators and 0 possible many-to-many indicators. Runtime Formula Engine impact is **REQUIRES VALIDATION**.

## Measures / DAX

5 measures; 0 selected static pattern hits. Candidate measures: none by this narrow scan. This is STATIC DAX RISK, not proof of slowness.

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
