# MRData - Technical Assessment

## Health Summary

**HIGH - 71/100.** Static fleet-relative prioritization; actual query and refresh performance are **NOT PROVABLE FROM CURRENT EVIDENCE**.

## Key Metrics and Risk Scores
# MRData - Technical Assessment
| Tables | Columns | Measures | Relationships | Partitions | Hierarchies | Roles | Max rows | Segment used MB* |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 18 | 202 | 10 | 45 | 18 |  |  | 988487 | 44.939 |

| Complexity | Storage | Partition | Relationship | Static DAX | Overall |
|---:|---:|---:|---:|---:|---:|
| 85 | 85 | 44 | 78 | 48 | **71** |

## Runtime Evidence

OBSERVED BUSINESS_CANDIDATE subset: 87 executions; total 948 ms; P50/P95/P99 7/33/41 ms; max 41 ms. Representativeness and root cause are REQUIRES VALIDATION. Evidence: REPORTS/07_RUNTIME_DATABASE_BASELINE.csv and REPORTS/08_RUNTIME_QUERY_HASH_BASELINE.csv.

## Model Complexity

Compatibility level: 1200. Calculated tables: 0; calculated columns detected in TMSL: 5. Complexity is interpreted relative to this 54-model fleet.

## Storage

| Top table/dimension storage structure | USED_SIZE MB | Maximum segment rows |
|---|---:|---:|
| FactMRData | 10.84 | 988487 |
| FactMRData_restruktur | 10.25 | 965890 |
| FactMRDataIsolateYTD | 5.676 | 455758 |
| FactMRDataIsolate | 5.416 | 429928 |
| FactMRDataUnaudited | 5.396 | 553050 |
| FactMRDataIsolateYTDUnaudited | 2.623 | 221421 |
| FactMRDataIsolateUnaudited | 2.46 | 207111 |
| FactMRConsolBulanan | 1.913 | 224779 |

| Potential dictionary/cardinality review candidate | Dictionary MB |
|---|---:|
| FactMRData, Amount | 10.346 |
| FactMRData_restruktur, Amount | 10.27 |
| FactMRDataIsolateYTD, Amount | 9.643 |
| FactMRDataIsolate, Amount | 9.592 |
| FactMRDataUnaudited, Amount | 5.249 |
| FactMRDataIsolateYTDUnaudited, Amount | 4.781 |
| FactMRDataIsolateUnaudited, Amount | 4.75 |
| FactMRConsolBulanan, Amount | 1.217 |

\* DMV accounting only; not authoritative resident model size. Column candidates require usage and actual cardinality validation.

## Partitions

18 metadata partitions across 18 tables. No fleet screening rule proves a partition defect. Partition-level size/statistics are unavailable.

## Relationships

45 total, 0 inactive, 1 bidirectional indicators and 0 possible many-to-many indicators. Runtime Formula Engine impact is **REQUIRES VALIDATION**.

## Measures / DAX

10 measures; 11 selected static pattern hits. Candidate measures: MaxValueMonthlyConsol. This is STATIC DAX RISK, not proof of slowness.

## Security

 roles observed. Security effectiveness, membership, RLS selectivity and runtime cost are not fully provable from role metadata alone.

## Findings

### F-015 - Storage

- **Severity / Classification / Confidence:** HIGH / OBSERVED / HIGH
- **Observation:** Fleet-relative storage score 85; USED_SIZE 44.939 MB, dictionary 128.536 MB, maximum recorded storage-table rows 988,487.
- **Evidence:** storage/storage_column_segments.csv; storage/storage_table_columns.csv; storage/storage_tables.csv
- **Analysis / Performance impact:** Disproportionate encoded data increases capacity and scan exposure; actual query cost is not proven.
- **Recommendation:** Review top table/column consumers and remove or reshape only after dependency and usage validation.
- **Expected benefit:** Reduced model footprint and potentially faster scans/refresh.
- **Implementation effort:** MEDIUM
- **Validation:** Benchmark representative queries/refresh and verify semantic parity before production.

### F-016 - Relationships

- **Severity / Classification / Confidence:** MEDIUM / REQUIRES VALIDATION / MEDIUM
- **Observation:** 45 relationships (0 inactive, 1 bidirectional indicators, 0 possible many-to-many), fleet-relative score 78.
- **Evidence:** metadata/relationships.csv; model/database.tmsl.json
- **Analysis / Performance impact:** Complex propagation can increase DAX/Formula Engine work and maintenance risk, but runtime effect is unmeasured.
- **Recommendation:** Diagram cardinality/filter paths; validate ambiguous paths and constrain bidirectional filters where business semantics permit.
- **Expected benefit:** Simpler filter propagation and more predictable calculations.
- **Implementation effort:** MEDIUM
- **Validation:** Benchmark representative queries/refresh and verify semantic parity before production.

### F-017 - Model Complexity

- **Severity / Classification / Confidence:** MEDIUM / OBSERVED / HIGH
- **Observation:** 18 tables, 202 columns, 10 measures; fleet-relative complexity score 85.
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

