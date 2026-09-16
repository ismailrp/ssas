# Segregation - Technical Assessment

## Health Summary

**MEDIUM - 59/100.** Static fleet-relative prioritization; actual query and refresh performance are **NOT PROVABLE FROM CURRENT EVIDENCE**.

## Key Metrics and Risk Scores
# Segregation - Technical Assessment
| Tables | Columns | Measures | Relationships | Partitions | Hierarchies | Roles | Max rows | Segment used MB* |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 3 | 72 | 8 | 2 | 3 | 0 |  | 1167904 | 21.757 |

| Complexity | Storage | Partition | Relationship | Static DAX | Overall |
|---:|---:|---:|---:|---:|---:|
| 48 | 80 | 85 | 31 | 38 | **59** |

## Runtime Evidence

OBSERVED BUSINESS_CANDIDATE subset: 157 executions; total 19807 ms; P50/P95/P99 11/384/1756 ms; max 8186 ms. Representativeness and root cause are REQUIRES VALIDATION. Evidence: REPORTS/07_RUNTIME_DATABASE_BASELINE.csv and REPORTS/08_RUNTIME_QUERY_HASH_BASELINE.csv.

## Model Complexity

Compatibility level: 1200. Calculated tables: 1; calculated columns detected in TMSL: 6. Complexity is interpreted relative to this 54-model fleet.

## Storage

| Top table/dimension storage structure | USED_SIZE MB | Maximum segment rows |
|---|---:|---:|
| FACT_SEGREGATION | 21.726 | 1167904 |
| Calender | 0.027 | 1461 |
| MAP_UNIT | 0.004 | 158 |

| Potential dictionary/cardinality review candidate | Dictionary MB |
|---|---:|
| FACT_SEGREGATION, FINAL_VALUE | 19.585 |
| FACT_SEGREGATION, SGTXT | 9.756 |
| FACT_SEGREGATION, NEW_IO | 1.089 |
| FACT_SEGREGATION, NEW_IO_KONSOLIDASI | 1.018 |
| FACT_SEGREGATION, GROUP_ACTV_OLD | 1.018 |
| FACT_SEGREGATION, GROUP_ACCT | 1.017 |
| MAP_UNIT, PERUSAHAAN  | 1.017 |
| FACT_SEGREGATION, ACCT_DESC | 1.017 |

\* DMV accounting only; not authoritative resident model size. Column candidates require usage and actual cardinality validation.

## Partitions

3 metadata partitions across 3 tables. A large/lightly partitioned screening signal is present. Validate source date fields and refresh history before piloting time partitions.

## Relationships

2 total, 0 inactive, 0 bidirectional indicators and 0 possible many-to-many indicators. Runtime Formula Engine impact is **REQUIRES VALIDATION**.

## Measures / DAX

8 measures; 6 selected static pattern hits. Candidate measures: none by this narrow scan. This is STATIC DAX RISK, not proof of slowness.

## Security

 roles observed. Security effectiveness, membership, RLS selectivity and runtime cost are not fully provable from role metadata alone.

## Findings

### F-027 - Storage

- **Severity / Classification / Confidence:** HIGH / OBSERVED / HIGH
- **Observation:** Fleet-relative storage score 80; USED_SIZE 21.757 MB, dictionary 74.284 MB, maximum recorded storage-table rows 1,167,904.
- **Evidence:** storage/storage_column_segments.csv; storage/storage_table_columns.csv; storage/storage_tables.csv
- **Analysis / Performance impact:** Disproportionate encoded data increases capacity and scan exposure; actual query cost is not proven.
- **Recommendation:** Review top table/column consumers and remove or reshape only after dependency and usage validation.
- **Expected benefit:** Reduced model footprint and potentially faster scans/refresh.
- **Implementation effort:** MEDIUM
- **Validation:** Benchmark representative queries/refresh and verify semantic parity before production.

### F-028 - Partitions

- **Severity / Classification / Confidence:** HIGH / INFERRED / MEDIUM
- **Observation:** Largest storage structure has 1,167,904 rows while metadata shows 3 partitions for 3 tables.
- **Evidence:** metadata/partitions.csv; storage/storage_tables.csv; model/database.tmsl.json
- **Analysis / Performance impact:** Full-table refresh may have avoidable processing duration and transaction footprint.
- **Recommendation:** Validate refresh history and date boundaries, then test time-based incremental partitions.
- **Expected benefit:** Smaller refresh scope and improved operational manageability.
- **Implementation effort:** HIGH
- **Validation:** Benchmark representative queries/refresh and verify semantic parity before production.


## Recommendations

Prioritize evidence collection, then address confirmed storage/partition/relationship/DAX hotspots. Treat apparent unused objects only as **CANDIDATE FOR USAGE VALIDATION**.

## Evidence Gaps

Representative workload, authoritative FE/SE timing, peak concurrency, refresh duration, memory-pressure series and object usage telemetry remain incomplete.

## Deep-Dive Recommendation

**NO - retain in fleet monitoring unless runtime evidence elevates it**.

