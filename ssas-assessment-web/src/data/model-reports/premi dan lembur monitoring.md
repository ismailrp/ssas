# premi dan lembur monitoring - Technical Assessment

## Health Summary

**HIGH - 72/100.** Static fleet-relative prioritization; actual query and refresh performance are **NOT PROVABLE FROM CURRENT EVIDENCE**.

## Key Metrics and Risk Scores
# premi dan lembur monitoring - Technical Assessment
| Tables | Columns | Measures | Relationships | Partitions | Hierarchies | Roles | Max rows | Segment used MB* |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 13 | 177 | 35 | 20 | 13 | 0 | 0 | 14976234 | 174.922 |

| Complexity | Storage | Partition | Relationship | Static DAX | Overall |
|---:|---:|---:|---:|---:|---:|
| 84 | 97 | 85 | 61 | 10 | **72** |

## Runtime Evidence

OBSERVED BUSINESS_CANDIDATE subset: 14 executions; total 1946 ms; P50/P95/P99 6/1835/1835 ms; max 1835 ms. Representativeness and root cause are REQUIRES VALIDATION. Evidence: REPORTS/07_RUNTIME_DATABASE_BASELINE.csv and REPORTS/08_RUNTIME_QUERY_HASH_BASELINE.csv.

## Model Complexity

Compatibility level: 1200. Calculated tables: 0; calculated columns detected in TMSL: 1. Complexity is interpreted relative to this 54-model fleet.

## Storage

| Top table/dimension storage structure | USED_SIZE MB | Maximum segment rows |
|---|---:|---:|
| FACT_PREMI_PIVOT | 99.063 | 2019413 |
| FACT_PREMI | 70.364 | 14976234 |
| DIM_EMPLOYEE | 5.224 | 57961 |
| DIM_PERIODE_CLOSING | 0.134 | 8035 |
| DIM_DATE | 0.091 | 2191 |
| DIM_DIVISION | 0.021 | 1320 |
| DIM_JOB_TITLE | 0.011 | 388 |
| DIM_ACTIVITY | 0.01 | 374 |

| Potential dictionary/cardinality review candidate | Dictionary MB |
|---|---:|
| FACT_PREMI_PIVOT, Total | 20.835 |
| FACT_PREMI, PREMI | 19.922 |
| FACT_PREMI_PIVOT, 20 | 9.294 |
| FACT_PREMI_PIVOT, 4 | 5.242 |
| FACT_PREMI_PIVOT, 13 | 5.237 |
| FACT_PREMI_PIVOT, 24 | 5.196 |
| FACT_PREMI_PIVOT, 15 | 5.183 |
| FACT_PREMI_PIVOT, 6 | 5.172 |

\* DMV accounting only; not authoritative resident model size. Column candidates require usage and actual cardinality validation.

## Partitions

13 metadata partitions across 13 tables. A large/lightly partitioned screening signal is present. Validate source date fields and refresh history before piloting time partitions.

## Relationships

20 total, 0 inactive, 0 bidirectional indicators and 0 possible many-to-many indicators. Runtime Formula Engine impact is **REQUIRES VALIDATION**.

## Measures / DAX

35 measures; 0 selected static pattern hits. Candidate measures: none by this narrow scan. This is STATIC DAX RISK, not proof of slowness.

## Security

0 roles observed. Security effectiveness, membership, RLS selectivity and runtime cost are not fully provable from role metadata alone.

## Findings

### F-012 - Storage

- **Severity / Classification / Confidence:** HIGH / OBSERVED / HIGH
- **Observation:** Fleet-relative storage score 97; USED_SIZE 174.922 MB, dictionary 269.579 MB, maximum recorded storage-table rows 14,976,234.
- **Evidence:** storage/storage_column_segments.csv; storage/storage_table_columns.csv; storage/storage_tables.csv
- **Analysis / Performance impact:** Disproportionate encoded data increases capacity and scan exposure; actual query cost is not proven.
- **Recommendation:** Review top table/column consumers and remove or reshape only after dependency and usage validation.
- **Expected benefit:** Reduced model footprint and potentially faster scans/refresh.
- **Implementation effort:** MEDIUM
- **Validation:** Benchmark representative queries/refresh and verify semantic parity before production.

### F-013 - Partitions

- **Severity / Classification / Confidence:** HIGH / INFERRED / MEDIUM
- **Observation:** Largest storage structure has 14,976,234 rows while metadata shows 13 partitions for 13 tables.
- **Evidence:** metadata/partitions.csv; storage/storage_tables.csv; model/database.tmsl.json
- **Analysis / Performance impact:** Full-table refresh may have avoidable processing duration and transaction footprint.
- **Recommendation:** Validate refresh history and date boundaries, then test time-based incremental partitions.
- **Expected benefit:** Smaller refresh scope and improved operational manageability.
- **Implementation effort:** HIGH
- **Validation:** Benchmark representative queries/refresh and verify semantic parity before production.

### F-014 - Model Complexity

- **Severity / Classification / Confidence:** MEDIUM / OBSERVED / HIGH
- **Observation:** 13 tables, 177 columns, 35 measures; fleet-relative complexity score 84.
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

