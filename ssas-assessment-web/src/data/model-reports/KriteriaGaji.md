# KriteriaGaji - Technical Assessment

## Health Summary

**MEDIUM - 47/100.** Static fleet-relative prioritization; actual query and refresh performance are **NOT PROVABLE FROM CURRENT EVIDENCE**.

## Key Metrics and Risk Scores
# KriteriaGaji - Technical Assessment
| Tables | Columns | Measures | Relationships | Partitions | Hierarchies | Roles | Max rows | Segment used MB* |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 12 | 110 | 4 | 16 | 12 | 0 |  | 45698 | 0.723 |

| Complexity | Storage | Partition | Relationship | Static DAX | Overall |
|---:|---:|---:|---:|---:|---:|
| 68 | 46 | 37 | 68 | 10 | **47** |

## Model Complexity

Compatibility level: 1200. Calculated tables: 2; calculated columns detected in TMSL: 8. Complexity is interpreted relative to this 54-model fleet.

## Storage

| Top table/dimension storage structure | USED_SIZE MB | Maximum segment rows |
|---|---:|---:|
| FACT_PREMI_PER_GAPOK | 0.188 | 45698 |
| FACT_PEMBAYARAN_GAJI | 0.171 | 41574 |
| FACT_PEMBAYARAN_PREMI | 0.17 | 45169 |
| FACT_METODE_PEMBAYARAN | 0.083 | 18697 |
| DIM_DATE | 0.083 | 2191 |
| DIM_DIVISION | 0.018 | 1320 |
| DIM_PLANT | 0.004 | 116 |
| UNIT_LIVE_SPARTA | 0.003 | 113 |

| Potential dictionary/cardinality review candidate | Dictionary MB |
|---|---:|
| DIM_DATE, StandardDate | 1.049 |
| DIM_PLANT, PLANT | 1.017 |
| DIM_DIVISION, DIVISION_NAME_CODE | 1.017 |
| DIM_PLANT, PLANT_CODE | 1.017 |
| UNIT_LIVE_SPARTA, PLANT_CODE | 1.017 |
| UNIT_LIVE_SPARTA, PLANT | 1.017 |
| DIM_DATE, LastDateOfMonth | 1.017 |
| DIM_DIVISION, DIVISION_CODE | 1.017 |

\* DMV accounting only; not authoritative resident model size. Column candidates require usage and actual cardinality validation.

## Partitions

12 metadata partitions across 12 tables. No fleet screening rule proves a partition defect. Partition-level size/statistics are unavailable.

## Relationships

16 total, 0 inactive, 1 bidirectional indicators and 0 possible many-to-many indicators. Runtime Formula Engine impact is **REQUIRES VALIDATION**.

## Measures / DAX

4 measures; 0 selected static pattern hits. Candidate measures: none by this narrow scan. This is STATIC DAX RISK, not proof of slowness.

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
