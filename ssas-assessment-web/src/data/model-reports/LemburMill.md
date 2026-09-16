# LemburMill - Technical Assessment

## Health Summary

**HIGH - 61/100.** Static fleet-relative prioritization; actual query and refresh performance are **NOT PROVABLE FROM CURRENT EVIDENCE**.

## Key Metrics and Risk Scores
# LemburMill - Technical Assessment
| Tables | Columns | Measures | Relationships | Partitions | Hierarchies | Roles | Max rows | Segment used MB* |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 12 | 151 | 0 | 22 | 12 | 0 |  | 1765530 | 14.377 |

| Complexity | Storage | Partition | Relationship | Static DAX | Overall |
|---:|---:|---:|---:|---:|---:|
| 63 | 80 | 85 | 65 | 0 | **61** |

## Model Complexity

Compatibility level: 1200. Calculated tables: 2; calculated columns detected in TMSL: 0. Complexity is interpreted relative to this 54-model fleet.

## Storage

| Top table/dimension storage structure | USED_SIZE MB | Maximum segment rows |
|---|---:|---:|
| FACT_UTILITY_DETAIL | 13.703 | 1765530 |
| FACT_UTILITY | 0.462 | 17288 |
| DIM_DATE | 0.083 | 2191 |
| DISCONNECT_DATE | 0.076 | 2191 |
| DIM_DIVISION | 0.018 | 1320 |
| FACT_GAJI_POKOK | 0.017 | 634 |
| FACT_RUPIAH | 0.013 | 668 |
| FACT_TENAGA_KERJA | 0.003 | 668 |

| Potential dictionary/cardinality review candidate | Dictionary MB |
|---|---:|
| FACT_UTILITY_DETAIL, NO_DOKUMEN | 5.744 |
| FACT_UTILITY_DETAIL, NIK | 1.05 |
| DISCONNECT_DATE, StandardDate | 1.049 |
| FACT_UTILITY_DETAIL, NAMA | 1.049 |
| DIM_DATE, StandardDate | 1.049 |
| FACT_UTILITY_DETAIL, KEMANDORAN | 1.019 |
| DIM_DIVISION, DIVISION_NAME_CODE | 1.017 |
| DIM_DATE, LastDateOfMonth | 1.017 |

\* DMV accounting only; not authoritative resident model size. Column candidates require usage and actual cardinality validation.

## Partitions

12 metadata partitions across 12 tables. A large/lightly partitioned screening signal is present. Validate source date fields and refresh history before piloting time partitions.

## Relationships

22 total, 1 inactive, 0 bidirectional indicators and 0 possible many-to-many indicators. Runtime Formula Engine impact is **REQUIRES VALIDATION**.

## Measures / DAX

0 measures; 0 selected static pattern hits. Candidate measures: none by this narrow scan. This is STATIC DAX RISK, not proof of slowness.

## Security

 roles observed. Security effectiveness, membership, RLS selectivity and runtime cost are not fully provable from role metadata alone.

## Findings

### F-020 - Storage

- **Severity / Classification / Confidence:** HIGH / OBSERVED / HIGH
- **Observation:** Fleet-relative storage score 80; USED_SIZE 14.377 MB, dictionary 47.193 MB, maximum recorded storage-table rows 1,765,530.
- **Evidence:** storage/storage_column_segments.csv; storage/storage_table_columns.csv; storage/storage_tables.csv
- **Analysis / Performance impact:** Disproportionate encoded data increases capacity and scan exposure; actual query cost is not proven.
- **Recommendation:** Review top table/column consumers and remove or reshape only after dependency and usage validation.
- **Expected benefit:** Reduced model footprint and potentially faster scans/refresh.
- **Implementation effort:** MEDIUM
- **Validation:** Benchmark representative queries/refresh and verify semantic parity before production.

### F-021 - Partitions

- **Severity / Classification / Confidence:** HIGH / INFERRED / MEDIUM
- **Observation:** Largest storage structure has 1,765,530 rows while metadata shows 12 partitions for 12 tables.
- **Evidence:** metadata/partitions.csv; storage/storage_tables.csv; model/database.tmsl.json
- **Analysis / Performance impact:** Full-table refresh may have avoidable processing duration and transaction footprint.
- **Recommendation:** Validate refresh history and date boundaries, then test time-based incremental partitions.
- **Expected benefit:** Smaller refresh scope and improved operational manageability.
- **Implementation effort:** HIGH
- **Validation:** Benchmark representative queries/refresh and verify semantic parity before production.


## Recommendations

Prioritize evidence collection, then address confirmed storage/partition/relationship/DAX hotspots. Treat apparent unused objects only as **CANDIDATE FOR USAGE VALIDATION**.

## Evidence Gaps

No historical query duration/CPU, FE/SE timing, peak concurrency, refresh duration, memory-pressure series or object usage telemetry.

## Deep-Dive Recommendation

**YES**.
