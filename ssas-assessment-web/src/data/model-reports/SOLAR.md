# SOLAR - Technical Assessment

## Health Summary

**MEDIUM - 52/100.** Static fleet-relative prioritization; actual query and refresh performance are **NOT PROVABLE FROM CURRENT EVIDENCE**.

## Key Metrics and Risk Scores
# SOLAR - Technical Assessment
| Tables | Columns | Measures | Relationships | Partitions | Hierarchies | Roles | Max rows | Segment used MB* |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 5 | 76 | 22 | 4 | 5 | 0 | 0 | 418474 | 5.47 |

| Complexity | Storage | Partition | Relationship | Static DAX | Overall |
|---:|---:|---:|---:|---:|---:|
| 56 | 66 | 25 | 51 | 51 | **52** |

## Model Complexity

Compatibility level: 1200. Calculated tables: 0; calculated columns detected in TMSL: 2. Complexity is interpreted relative to this 54-model fleet.

## Storage

| Top table/dimension storage structure | USED_SIZE MB | Maximum segment rows |
|---|---:|---:|
| FACT_PEMAKAIAN_SOLAR | 5.379 | 418474 |
| DIM_DATE | 0.087 | 2191 |
| DIM_PLANT | 0.003 | 116 |
| DIM_AREA | 0.001 | 14 |
| DIM_REGION | 0.001 | 15 |

| Potential dictionary/cardinality review candidate | Dictionary MB |
|---|---:|
| FACT_PEMAKAIAN_SOLAR, ACTUAL_RP | 10.308 |
| FACT_PEMAKAIAN_SOLAR, IO_CODE | 1.1 |
| DIM_DATE, StandardDate | 1.049 |
| FACT_PEMAKAIAN_SOLAR, UNIT_IO | 1.017 |
| FACT_PEMAKAIAN_SOLAR, PLANT | 1.017 |
| DIM_PLANT, PLANT_CODE | 1.017 |
| DIM_PLANT, PLANT | 1.017 |
| DIM_DATE, LastDateOfMonth | 1.017 |

\* DMV accounting only; not authoritative resident model size. Column candidates require usage and actual cardinality validation.

## Partitions

5 metadata partitions across 5 tables. No fleet screening rule proves a partition defect. Partition-level size/statistics are unavailable.

## Relationships

4 total, 0 inactive, 1 bidirectional indicators and 0 possible many-to-many indicators. Runtime Formula Engine impact is **REQUIRES VALIDATION**.

## Measures / DAX

22 measures; 22 selected static pattern hits. Candidate measures: none by this narrow scan. This is STATIC DAX RISK, not proof of slowness.

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
