# Saldo Treasury - Technical Assessment

## Health Summary

**MEDIUM - 41/100.** Static fleet-relative prioritization; actual query and refresh performance are **NOT PROVABLE FROM CURRENT EVIDENCE**.

## Key Metrics and Risk Scores
# Saldo Treasury - Technical Assessment
| Tables | Columns | Measures | Relationships | Partitions | Hierarchies | Roles | Max rows | Segment used MB* |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 4 | 114 | 19 |  | 4 | 0 | 0 | 847043 | 8.817 |

| Complexity | Storage | Partition | Relationship | Static DAX | Overall |
|---:|---:|---:|---:|---:|---:|
| 61 | 75 | 22 | 9 | 10 | **41** |

## Runtime Evidence

OBSERVED BUSINESS_CANDIDATE subset: 8 executions; total 2766 ms; P50/P95/P99 311/439/439 ms; max 439 ms. Representativeness and root cause are REQUIRES VALIDATION. Evidence: REPORTS/07_RUNTIME_DATABASE_BASELINE.csv and REPORTS/08_RUNTIME_QUERY_HASH_BASELINE.csv.

## Model Complexity

Compatibility level: 1200. Calculated tables: 0; calculated columns detected in TMSL: 2. Complexity is interpreted relative to this 54-model fleet.

## Storage

| Top table/dimension storage structure | USED_SIZE MB | Maximum segment rows |
|---|---:|---:|
| FACT_SALDO_TRE_DAILY | 8.387 | 847043 |
| DimDate | 0.324 | 8035 |
| FACT_SALDO_TRE_MONTHLY | 0.077 | 8600 |
| FACT_SALDO_TRE_SUMMARY | 0.029 | 5016 |

| Potential dictionary/cardinality review candidate | Dictionary MB |
|---|---:|
| FACT_SALDO_TRE_DAILY, VALUE_BANK | 2.696 |
| FACT_SALDO_TRE_DAILY, VALUE_CASH | 2.477 |
| DimDate, StandardDate | 1.19 |
| FACT_SALDO_TRE_DAILY, DOC_NUMBER | 1.022 |
| FACT_SALDO_TRE_MONTHLY, DOC_NUMBER | 1.022 |
| DimDate, LastDateOfMonth | 1.018 |
| FACT_SALDO_TRE_DAILY, COMPANY | 1.017 |
| FACT_SALDO_TRE_MONTHLY, NO | 1.017 |

\* DMV accounting only; not authoritative resident model size. Column candidates require usage and actual cardinality validation.

## Partitions

4 metadata partitions across 4 tables. No fleet screening rule proves a partition defect. Partition-level size/statistics are unavailable.

## Relationships

 total, 0 inactive, 0 bidirectional indicators and 0 possible many-to-many indicators. Runtime Formula Engine impact is **REQUIRES VALIDATION**.

## Measures / DAX

19 measures; 0 selected static pattern hits. Candidate measures: none by this narrow scan. This is STATIC DAX RISK, not proof of slowness.

## Security

0 roles observed. Security effectiveness, membership, RLS selectivity and runtime cost are not fully provable from role metadata alone.

## Findings

### F-046 - Storage

- **Severity / Classification / Confidence:** HIGH / OBSERVED / HIGH
- **Observation:** Fleet-relative storage score 75; USED_SIZE 8.817 MB, dictionary 62.214 MB, maximum recorded storage-table rows 847,043.
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

