# Realisasi Budget HO - Technical Assessment

## Health Summary

**MEDIUM - 46/100.** Static fleet-relative prioritization; actual query and refresh performance are **NOT PROVABLE FROM CURRENT EVIDENCE**.

## Key Metrics and Risk Scores
# Realisasi Budget HO - Technical Assessment
| Tables | Columns | Measures | Relationships | Partitions | Hierarchies | Roles | Max rows | Segment used MB* |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 4 | 109 | 76 | 3 | 4 | 0 | 29 | 48528 | 1.405 |

| Complexity | Storage | Partition | Relationship | Static DAX | Overall |
|---:|---:|---:|---:|---:|---:|
| 66 | 50 | 22 | 47 | 35 | **46** |

## Model Complexity

Compatibility level: 1200. Calculated tables: 0; calculated columns detected in TMSL: 52. Complexity is interpreted relative to this 54-model fleet.

## Storage

| Top table/dimension storage structure | USED_SIZE MB | Maximum segment rows |
|---|---:|---:|
| FACT_REALISASI_VS_ANGGARAN_HO | 1.294 | 48528 |
| DIM_DATE | 0.097 | 2191 |
| DIM_DEPARTEMEN | 0.012 | 522 |
| DIM_ACC_CAPEX_OPEX | 0.002 | 95 |

| Potential dictionary/cardinality review candidate | Dictionary MB |
|---|---:|
| DIM_DATE, StandardDate | 1.049 |
| DIM_DEPARTEMEN, GD_YEAR | 1.02 |
| FACT_REALISASI_VS_ANGGARAN_HO, GD_YEAR | 1.02 |
| DIM_DEPARTEMEN, Departement | 1.018 |
| DIM_DEPARTEMEN, Dept_Code | 1.018 |
| DIM_DEPARTEMEN, Group Departement | 1.017 |
| DIM_DATE, LastDateOfMonth | 1.017 |
| FACT_REALISASI_VS_ANGGARAN_HO, ID_ACC | 1.017 |

\* DMV accounting only; not authoritative resident model size. Column candidates require usage and actual cardinality validation.

## Partitions

4 metadata partitions across 4 tables. No fleet screening rule proves a partition defect. Partition-level size/statistics are unavailable.

## Relationships

3 total, 0 inactive, 1 bidirectional indicators and 0 possible many-to-many indicators. Runtime Formula Engine impact is **REQUIRES VALIDATION**.

## Measures / DAX

76 measures; 5 selected static pattern hits. Candidate measures: none by this narrow scan. This is STATIC DAX RISK, not proof of slowness.

## Security

29 roles observed. Security effectiveness, membership, RLS selectivity and runtime cost are not fully provable from role metadata alone.

## Findings

No material fleet-outlier finding generated. This does not prove absence of runtime issues.

## Recommendations

Prioritize evidence collection, then address confirmed storage/partition/relationship/DAX hotspots. Treat apparent unused objects only as **CANDIDATE FOR USAGE VALIDATION**.

## Evidence Gaps

No historical query duration/CPU, FE/SE timing, peak concurrency, refresh duration, memory-pressure series or object usage telemetry.

## Deep-Dive Recommendation

**NO - retain in fleet monitoring unless runtime evidence elevates it**.
