# LHA_bahan - Technical Assessment

## Health Summary

**MEDIUM - 57/100.** Static fleet-relative prioritization; actual query and refresh performance are **NOT PROVABLE FROM CURRENT EVIDENCE**.

## Key Metrics and Risk Scores
# LHA_bahan - Technical Assessment
| Tables | Columns | Measures | Relationships | Partitions | Hierarchies | Roles | Max rows | Segment used MB* |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 13 | 113 | 5 | 12 | 13 | 0 |  | 578569 | 15.637 |

| Complexity | Storage | Partition | Relationship | Static DAX | Overall |
|---:|---:|---:|---:|---:|---:|
| 68 | 74 | 40 | 55 | 35 | **57** |

## Model Complexity

Compatibility level: 1200. Calculated tables: 1; calculated columns detected in TMSL: 1. Complexity is interpreted relative to this 54-model fleet.

## Storage

| Top table/dimension storage structure | USED_SIZE MB | Maximum segment rows |
|---|---:|---:|
| FACT_SPARTA_BAHAN | 12.804 | 578566 |
| DIM_MATERIAL | 1.789 | 64140 |
| DIM_BLOCK | 0.947 | 38289 |
| Calendar | 0.027 | 1461 |
| DIM_ACTIVITY | 0.024 | 894 |
| DIM_DIVISION | 0.018 | 1320 |
| DIM_ACTIVITY_GROUP | 0.009 | 278 |
| DIM_MATERIAL_CATEGORY | 0.006 | 203 |

| Potential dictionary/cardinality review candidate | Dictionary MB |
|---|---:|
| FACT_SPARTA_BAHAN, ESTIMASI_HARGA_PEMAKAIAN | 5.21 |
| DIM_MATERIAL, MATERIAL | 4.429 |
| DIM_MATERIAL, MATERIAL_CODE | 3.502 |
| FACT_SPARTA_BAHAN, PEMAKAIAN_BAHAN | 1.282 |
| DIM_MATERIAL, MATERIAL_ID | 1.245 |
| DIM_BLOCK, BLOCK | 1.189 |
| DIM_BLOCK, BLOCK_ID | 1.146 |
| DIM_BLOCK, BLOCK_CODE | 1.102 |

\* DMV accounting only; not authoritative resident model size. Column candidates require usage and actual cardinality validation.

## Partitions

13 metadata partitions across 13 tables. No fleet screening rule proves a partition defect. Partition-level size/statistics are unavailable.

## Relationships

12 total, 1 inactive, 0 bidirectional indicators and 0 possible many-to-many indicators. Runtime Formula Engine impact is **REQUIRES VALIDATION**.

## Measures / DAX

5 measures; 5 selected static pattern hits. Candidate measures: none by this narrow scan. This is STATIC DAX RISK, not proof of slowness.

## Security

 roles observed. Security effectiveness, membership, RLS selectivity and runtime cost are not fully provable from role metadata alone.

## Findings

### F-033 - Storage

- **Severity / Classification / Confidence:** HIGH / OBSERVED / HIGH
- **Observation:** Fleet-relative storage score 74; USED_SIZE 15.637 MB, dictionary 48.601 MB, maximum recorded storage-table rows 578,569.
- **Evidence:** storage/storage_column_segments.csv; storage/storage_table_columns.csv; storage/storage_tables.csv
- **Analysis / Performance impact:** Disproportionate encoded data increases capacity and scan exposure; actual query cost is not proven.
- **Recommendation:** Review top table/column consumers and remove or reshape only after dependency and usage validation.
- **Expected benefit:** Reduced model footprint and potentially faster scans/refresh.
- **Implementation effort:** MEDIUM
- **Validation:** Benchmark representative queries/refresh and verify semantic parity before production.


## Recommendations

Prioritize evidence collection, then address confirmed storage/partition/relationship/DAX hotspots. Treat apparent unused objects only as **CANDIDATE FOR USAGE VALIDATION**.

## Evidence Gaps

No historical query duration/CPU, FE/SE timing, peak concurrency, refresh duration, memory-pressure series or object usage telemetry.

## Deep-Dive Recommendation

**NO - retain in fleet monitoring unless runtime evidence elevates it**.
