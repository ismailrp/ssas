# Premi Panen - Technical Assessment

## Health Summary

**MEDIUM - 47/100.** Static fleet-relative prioritization; actual query and refresh performance are **NOT PROVABLE FROM CURRENT EVIDENCE**.

## Key Metrics and Risk Scores
# Premi Panen - Technical Assessment
| Tables | Columns | Measures | Relationships | Partitions | Hierarchies | Roles | Max rows | Segment used MB* |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 8 | 113 | 0 | 7 | 8 | 0 |  | 684490 | 23.009 |

| Complexity | Storage | Partition | Relationship | Static DAX | Overall |
|---:|---:|---:|---:|---:|---:|
| 59 | 77 | 30 | 46 | 0 | **47** |

## Runtime Evidence

OBSERVED BUSINESS_CANDIDATE subset: 163 executions; total 3723 ms; P50/P95/P99 13/79/163 ms; max 167 ms. Representativeness and root cause are REQUIRES VALIDATION. Evidence: REPORTS/07_RUNTIME_DATABASE_BASELINE.csv and REPORTS/08_RUNTIME_QUERY_HASH_BASELINE.csv.

## Model Complexity

Compatibility level: 1200. Calculated tables: 0; calculated columns detected in TMSL: 6. Complexity is interpreted relative to this 54-model fleet.

## Storage

| Top table/dimension storage structure | USED_SIZE MB | Maximum segment rows |
|---|---:|---:|
| FACT_PREMI_PANEN | 22.85 | 684490 |
| DIM_DATE | 0.085 | 2191 |
| DIM_ACTIVITY | 0.039 | 894 |
| DIM_DIVISION | 0.018 | 1320 |
| DIM_ACTIVITY_GROUP | 0.012 | 278 |
| DIM_PLANT | 0.004 | 116 |
| DIM_AREA | 0.001 | 14 |
| DIM_REGION | 0.001 | 15 |

| Potential dictionary/cardinality review candidate | Dictionary MB |
|---|---:|
| FACT_PREMI_PANEN, PREMI_BAYAR | 9.286 |
| FACT_PREMI_PANEN, PREMI | 9.218 |
| FACT_PREMI_PANEN, LEBIH_BASIS_TEAM | 5.473 |
| FACT_PREMI_PANEN, OUTPUT | 5.309 |
| FACT_PREMI_PANEN, JANJANG | 2.394 |
| DIM_DATE, StandardDate | 1.049 |
| DIM_ACTIVITY, ACTIVITY_CONCAT | 1.023 |
| DIM_ACTIVITY, ACTIVITY_CODE | 1.023 |

\* DMV accounting only; not authoritative resident model size. Column candidates require usage and actual cardinality validation.

## Partitions

8 metadata partitions across 8 tables. No fleet screening rule proves a partition defect. Partition-level size/statistics are unavailable.

## Relationships

7 total, 0 inactive, 0 bidirectional indicators and 0 possible many-to-many indicators. Runtime Formula Engine impact is **REQUIRES VALIDATION**.

## Measures / DAX

0 measures; 0 selected static pattern hits. Candidate measures: none by this narrow scan. This is STATIC DAX RISK, not proof of slowness.

## Security

 roles observed. Security effectiveness, membership, RLS selectivity and runtime cost are not fully provable from role metadata alone.

## Findings

### F-044 - Storage

- **Severity / Classification / Confidence:** HIGH / OBSERVED / HIGH
- **Observation:** Fleet-relative storage score 77; USED_SIZE 23.009 MB, dictionary 58.506 MB, maximum recorded storage-table rows 684,490.
- **Evidence:** storage/storage_column_segments.csv; storage/storage_table_columns.csv; storage/storage_tables.csv
- **Analysis / Performance impact:** Disproportionate encoded data increases capacity and scan exposure; actual query cost is not proven.
- **Recommendation:** Review top table/column consumers and remove or reshape only after dependency and usage validation.
- **Expected benefit:** Reduced model footprint and potentially faster scans/refresh.
- **Implementation effort:** MEDIUM
- **Validation:** Benchmark representative queries/refresh and verify semantic parity before production.


## Recommendations

Prioritize evidence collection, then address confirmed storage/partition/relationship/DAX hotspots. Treat apparent unused objects only as **CANDIDATE FOR USAGE VALIDATION**.

## Evidence Gaps

Representative workload, authoritative FE/SE timing, peak concurrency, refresh duration, memory-pressure series and object usage telemetry remain incomplete.

## Deep-Dive Recommendation

**NO - retain in fleet monitoring unless runtime evidence elevates it**.

