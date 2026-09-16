# LkkPhase2 - Technical Assessment

## Health Summary

**HIGH - 63/100.** Static fleet-relative prioritization; actual query and refresh performance are **NOT PROVABLE FROM CURRENT EVIDENCE**.

## Key Metrics and Risk Scores
# LkkPhase2 - Technical Assessment
| Tables | Columns | Measures | Relationships | Partitions | Hierarchies | Roles | Max rows | Segment used MB* |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 18 | 230 | 86 | 53 | 18 | 0 |  | 320616 | 12.766 |

| Complexity | Storage | Partition | Relationship | Static DAX | Overall |
|---:|---:|---:|---:|---:|---:|
| 88 | 75 | 44 | 69 | 22 | **63** |

## Model Complexity

Compatibility level: 1200. Calculated tables: 0; calculated columns detected in TMSL: 0. Complexity is interpreted relative to this 54-model fleet.

## Storage

| Top table/dimension storage structure | USED_SIZE MB | Maximum segment rows |
|---|---:|---:|
| fact_lkk_by_tm | 6.691 | 320616 |
| fact_lkk_by_panen | 2.483 | 103320 |
| fact_lkk_by_total | 1.465 | 62640 |
| fact_lkk_by_umum | 1.301 | 58896 |
| fact_produksi_tbs | 0.305 | 8376 |
| fact_tbs_angkut | 0.258 | 5088 |
| fact_areal_statement | 0.167 | 8389 |
| DimDate | 0.091 | 2191 |

| Potential dictionary/cardinality review candidate | Dictionary MB |
|---|---:|
| fact_lkk_by_tm, anggaran_sdbi_amount_tm | 9.341 |
| fact_lkk_by_tm, aktual_sdbi_amount_tm | 5.323 |
| fact_lkk_by_tm, aktual_bi_amount_tm | 5.275 |
| fact_lkk_by_tm, anggaran_bi_amount_tm | 4.634 |
| fact_lkk_by_panen, aktual_sdbi_amount_panen | 2.527 |
| fact_lkk_by_panen, anggaran_sdbi_amount_panen | 2.519 |
| fact_lkk_by_panen, aktual_bi_amount_panen | 2.516 |
| fact_lkk_by_panen, anggaran_bi_amount_panen | 2.392 |

\* DMV accounting only; not authoritative resident model size. Column candidates require usage and actual cardinality validation.

## Partitions

18 metadata partitions across 18 tables. No fleet screening rule proves a partition defect. Partition-level size/statistics are unavailable.

## Relationships

53 total, 0 inactive, 0 bidirectional indicators and 0 possible many-to-many indicators. Runtime Formula Engine impact is **REQUIRES VALIDATION**.

## Measures / DAX

86 measures; 1 selected static pattern hits. Candidate measures: none by this narrow scan. This is STATIC DAX RISK, not proof of slowness.

## Security

 roles observed. Security effectiveness, membership, RLS selectivity and runtime cost are not fully provable from role metadata alone.

## Findings

### F-018 - Storage

- **Severity / Classification / Confidence:** HIGH / OBSERVED / HIGH
- **Observation:** Fleet-relative storage score 75; USED_SIZE 12.766 MB, dictionary 132.257 MB, maximum recorded storage-table rows 320,616.
- **Evidence:** storage/storage_column_segments.csv; storage/storage_table_columns.csv; storage/storage_tables.csv
- **Analysis / Performance impact:** Disproportionate encoded data increases capacity and scan exposure; actual query cost is not proven.
- **Recommendation:** Review top table/column consumers and remove or reshape only after dependency and usage validation.
- **Expected benefit:** Reduced model footprint and potentially faster scans/refresh.
- **Implementation effort:** MEDIUM
- **Validation:** Benchmark representative queries/refresh and verify semantic parity before production.

### F-019 - Model Complexity

- **Severity / Classification / Confidence:** MEDIUM / OBSERVED / HIGH
- **Observation:** 18 tables, 230 columns, 86 measures; fleet-relative complexity score 88.
- **Evidence:** metadata/tables.csv; metadata/columns.csv; metadata/measures.csv
- **Analysis / Performance impact:** Broad models increase metadata, refresh, usability, and optimization surface.
- **Recommendation:** Inventory report dependencies and label low-value columns as CANDIDATE FOR USAGE VALIDATION before removal.
- **Expected benefit:** Smaller semantic surface and possible storage/refresh reduction.
- **Implementation effort:** MEDIUM
- **Validation:** Benchmark representative queries/refresh and verify semantic parity before production.


## Recommendations

Prioritize evidence collection, then address confirmed storage/partition/relationship/DAX hotspots. Treat apparent unused objects only as **CANDIDATE FOR USAGE VALIDATION**.

## Evidence Gaps

No historical query duration/CPU, FE/SE timing, peak concurrency, refresh duration, memory-pressure series or object usage telemetry.

## Deep-Dive Recommendation

**YES**.
