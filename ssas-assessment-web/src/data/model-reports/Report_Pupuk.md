# Report_Pupuk - Technical Assessment

## Health Summary

**MEDIUM - 30/100.** Static fleet-relative prioritization; actual query and refresh performance are **NOT PROVABLE FROM CURRENT EVIDENCE**.

## Key Metrics and Risk Scores
# Report_Pupuk - Technical Assessment
| Tables | Columns | Measures | Relationships | Partitions | Hierarchies | Roles | Max rows | Segment used MB* |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 3 | 38 | 11 |  | 3 | 0 |  | 28679 | 0.582 |

| Complexity | Storage | Partition | Relationship | Static DAX | Overall |
|---:|---:|---:|---:|---:|---:|
| 35 | 40 | 17 | 9 | 40 | **30** |

## Model Complexity

Compatibility level: 1200. Calculated tables: 1; calculated columns detected in TMSL: 1. Complexity is interpreted relative to this 54-model fleet.

## Storage

| Top table/dimension storage structure | USED_SIZE MB | Maximum segment rows |
|---|---:|---:|
| FACT_PEMAKAIAN_PUPUK | 0.541 | 28679 |
| CALENDAR | 0.041 | 2191 |
| BridgeTable | 0 | 13 |

| Potential dictionary/cardinality review candidate | Dictionary MB |
|---|---:|
| FACT_PEMAKAIAN_PUPUK, BIAYA | 1.237 |
| FACT_PEMAKAIAN_PUPUK, PLANT | 1.017 |
| FACT_PEMAKAIAN_PUPUK, MATERIAL | 1.017 |
| FACT_PEMAKAIAN_PUPUK, MATERIAL_DESC | 1.017 |
| CALENDAR, Year Month Name | 1.017 |
| CALENDAR, Month Name | 1.016 |
| CALENDAR, Day Name | 1.016 |
| CALENDAR, Day Name Short | 1.016 |

\* DMV accounting only; not authoritative resident model size. Column candidates require usage and actual cardinality validation.

## Partitions

3 metadata partitions across 3 tables. No fleet screening rule proves a partition defect. Partition-level size/statistics are unavailable.

## Relationships

 total, 0 inactive, 0 bidirectional indicators and 0 possible many-to-many indicators. Runtime Formula Engine impact is **REQUIRES VALIDATION**.

## Measures / DAX

11 measures; 8 selected static pattern hits. Candidate measures: none by this narrow scan. This is STATIC DAX RISK, not proof of slowness.

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
