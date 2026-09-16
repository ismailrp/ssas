# SPARTA_LHA_ENHC - Technical Assessment

## Health Summary

**HIGH - 78/100.** Static fleet-relative prioritization; actual query and refresh performance are **NOT PROVABLE FROM CURRENT EVIDENCE**.

## Key Metrics and Risk Scores
# SPARTA_LHA_ENHC - Technical Assessment
| Tables | Columns | Measures | Relationships | Partitions | Hierarchies | Roles | Max rows | Segment used MB* |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 16 | 166 | 30 | 17 | 16 | 0 |  | 3732958 | 108.371 |

| Complexity | Storage | Partition | Relationship | Static DAX | Overall |
|---:|---:|---:|---:|---:|---:|
| 87 | 94 | 85 | 59 | 52 | **78** |

## Runtime Evidence

No BUSINESS_CANDIDATE query captured. Runtime performance is NOT PROVABLE FROM CURRENT EVIDENCE.

## Model Complexity

Compatibility level: 1200. Calculated tables: 0; calculated columns detected in TMSL: 7. Complexity is interpreted relative to this 54-model fleet.

## Storage

| Top table/dimension storage structure | USED_SIZE MB | Maximum segment rows |
|---|---:|---:|
| FACT_SPARTA_SUMMARY_LHA | 102.669 | 3732958 |
| FACT_DD_TBS_INTERNAL | 4.621 | 1022700 |
| DIM_BLOCK | 0.947 | 38289 |
| DIM_DATE | 0.065 | 1461 |
| DIM_ACTIVITY | 0.025 | 894 |
| DIM_DIVISION | 0.018 | 1320 |
| DIM_ACTIVITY_GROUP | 0.01 | 278 |
| DIM_UNIT_MEASURE | 0.004 | 146 |

| Potential dictionary/cardinality review candidate | Dictionary MB |
|---|---:|
| FACT_SPARTA_SUMMARY_LHA, PROPORSI_TK | 82.155 |
| FACT_SPARTA_SUMMARY_LHA, UPAH_HARIAN | 81.183 |
| FACT_SPARTA_SUMMARY_LHA, PREMI | 39.195 |
| FACT_SPARTA_SUMMARY_LHA, PRESTASI | 9.87 |
| FACT_SPARTA_SUMMARY_LHA, KEYID2 | 6.818 |
| FACT_SPARTA_SUMMARY_LHA, ESTIMASI_HARGA_PEMAKAIAN | 2.484 |
| DIM_BLOCK, BLOCK | 1.189 |
| DIM_BLOCK, BLOCK_ID | 1.146 |

\* DMV accounting only; not authoritative resident model size. Column candidates require usage and actual cardinality validation.

## Partitions

16 metadata partitions across 16 tables. A large/lightly partitioned screening signal is present. Validate source date fields and refresh history before piloting time partitions.

## Relationships

17 total, 0 inactive, 0 bidirectional indicators and 0 possible many-to-many indicators. Runtime Formula Engine impact is **REQUIRES VALIDATION**.

## Measures / DAX

30 measures; 21 selected static pattern hits. Candidate measures: VALUE_BUDGET_PRODUCTION; VALUE_TK_CAPAI_BASIS. This is STATIC DAX RISK, not proof of slowness.

## Security

 roles observed. Security effectiveness, membership, RLS selectivity and runtime cost are not fully provable from role metadata alone.

## Findings

### F-009 - Storage

- **Severity / Classification / Confidence:** HIGH / OBSERVED / HIGH
- **Observation:** Fleet-relative storage score 94; USED_SIZE 108.371 MB, dictionary 267.046 MB, maximum recorded storage-table rows 3,732,958.
- **Evidence:** storage/storage_column_segments.csv; storage/storage_table_columns.csv; storage/storage_tables.csv
- **Analysis / Performance impact:** Disproportionate encoded data increases capacity and scan exposure; actual query cost is not proven.
- **Recommendation:** Review top table/column consumers and remove or reshape only after dependency and usage validation.
- **Expected benefit:** Reduced model footprint and potentially faster scans/refresh.
- **Implementation effort:** MEDIUM
- **Validation:** Benchmark representative queries/refresh and verify semantic parity before production.

### F-010 - Partitions

- **Severity / Classification / Confidence:** HIGH / INFERRED / MEDIUM
- **Observation:** Largest storage structure has 3,732,958 rows while metadata shows 16 partitions for 16 tables.
- **Evidence:** metadata/partitions.csv; storage/storage_tables.csv; model/database.tmsl.json
- **Analysis / Performance impact:** Full-table refresh may have avoidable processing duration and transaction footprint.
- **Recommendation:** Validate refresh history and date boundaries, then test time-based incremental partitions.
- **Expected benefit:** Smaller refresh scope and improved operational manageability.
- **Implementation effort:** HIGH
- **Validation:** Benchmark representative queries/refresh and verify semantic parity before production.

### F-011 - Model Complexity

- **Severity / Classification / Confidence:** MEDIUM / OBSERVED / HIGH
- **Observation:** 16 tables, 166 columns, 30 measures; fleet-relative complexity score 87.
- **Evidence:** metadata/tables.csv; metadata/columns.csv; metadata/measures.csv
- **Analysis / Performance impact:** Broad models increase metadata, refresh, usability, and optimization surface.
- **Recommendation:** Inventory report dependencies and label low-value columns as CANDIDATE FOR USAGE VALIDATION before removal.
- **Expected benefit:** Smaller semantic surface and possible storage/refresh reduction.
- **Implementation effort:** MEDIUM
- **Validation:** Benchmark representative queries/refresh and verify semantic parity before production.


## Recommendations

Prioritize evidence collection, then address confirmed storage/partition/relationship/DAX hotspots. Treat apparent unused objects only as **CANDIDATE FOR USAGE VALIDATION**.

## Evidence Gaps

Representative workload, authoritative FE/SE timing, peak concurrency, refresh duration, memory-pressure series and object usage telemetry remain incomplete.

## Deep-Dive Recommendation

**YES**.

