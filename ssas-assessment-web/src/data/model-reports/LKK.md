# LKK - Technical Assessment

## Health Summary

**CRITICAL - 81/100.** Static fleet-relative prioritization; actual query and refresh performance are **NOT PROVABLE FROM CURRENT EVIDENCE**.

## Key Metrics and Risk Scores
# LKK - Technical Assessment
| Tables | Columns | Measures | Relationships | Partitions | Hierarchies | Roles | Max rows | Segment used MB* |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 11 | 174 | 35 | 11 | 11 | 0 |  | 21568293 | 273.128 |

| Complexity | Storage | Partition | Relationship | Static DAX | Overall |
|---:|---:|---:|---:|---:|---:|
| 84 | 99 | 85 | 52 | 71 | **81** |

## Runtime Evidence

OBSERVED BUSINESS_CANDIDATE subset: 213 executions; total 218499 ms; P50/P95/P99 6/3346/29279 ms; max 39725 ms. Representativeness and root cause are REQUIRES VALIDATION. Evidence: REPORTS/07_RUNTIME_DATABASE_BASELINE.csv and REPORTS/08_RUNTIME_QUERY_HASH_BASELINE.csv.

## Model Complexity

Compatibility level: 1200. Calculated tables: 1; calculated columns detected in TMSL: 10. Complexity is interpreted relative to this 54-model fleet.

## Storage

| Top table/dimension storage structure | USED_SIZE MB | Maximum segment rows |
|---|---:|---:|
| Biaya Tanaman Detail | 163.236 | 8388608 |
| Biaya Tanaman Detail HO | 65.637 | 8793068 |
| Biaya Umum Detail | 29.005 | 3944370 |
| Biaya Umum Detail HO | 10.978 | 1607827 |
| Biaya Kapital Non Tanaman | 4.177 | 865651 |
| Calendar | 0.041 | 2191 |
| USER_METRICS | 0.038 | 15359 |
| Session Access | 0.012 | 4486 |

| Potential dictionary/cardinality review candidate | Dictionary MB |
|---|---:|
| Biaya Tanaman Detail, VALUE | 173.148 |
| Biaya Tanaman Detail HO, VALUE | 85.209 |
| Biaya Umum Detail, VALUE | 73.917 |
| Biaya Umum Detail HO, VALUE | 20.892 |
| USER_METRICS, UserName | 1.045 |
| Session Access, UserName | 1.022 |
| Biaya Kapital Non Tanaman, ACTV | 1.019 |
| Biaya Tanaman Detail HO, ACTV | 1.018 |

\* DMV accounting only; not authoritative resident model size. Column candidates require usage and actual cardinality validation.

## Partitions

11 metadata partitions across 11 tables. A large/lightly partitioned screening signal is present. Validate source date fields and refresh history before piloting time partitions.

## Relationships

11 total, 0 inactive, 0 bidirectional indicators and 0 possible many-to-many indicators. Runtime Formula Engine impact is **REQUIRES VALIDATION**.

## Measures / DAX

35 measures; 48 selected static pattern hits. Candidate measures: BKNT_AKTUAL_SDBI_AS; BKNT_ANGGARAN_SDBI_AS; BTD_ANGGARAN_SDBI; BTD_AKTUAL_SDBI; BTD_ANGGARAN_BI; BTD_AKTUAL_BI; BTD_SDBI; BUD_ANGGARAN_SDBI; BUD_ANGGARAN_BI; BUD_AKTUAL_SDBI; BUD_AKTUAL_BI; BTD_HO_ANGGARAN_SDBI; BTD_HO_ANGGARAN_BI; BTD_HO_AKTUAL_SDBI; BTD_HO_AKTUAL_BI; BUD_HO_ANGGARAN_SDBI; BUD_HO_ANGGARAN_BI; BUD_HO_AKTUAL_SDBI; BUD_HO_AKTUAL_BI. This is STATIC DAX RISK, not proof of slowness.

## Security

 roles observed. Security effectiveness, membership, RLS selectivity and runtime cost are not fully provable from role metadata alone.

## Findings

### F-005 - Storage

- **Severity / Classification / Confidence:** HIGH / OBSERVED / HIGH
- **Observation:** Fleet-relative storage score 99; USED_SIZE 273.128 MB, dictionary 454.277 MB, maximum recorded storage-table rows 21,568,293.
- **Evidence:** storage/storage_column_segments.csv; storage/storage_table_columns.csv; storage/storage_tables.csv
- **Analysis / Performance impact:** Disproportionate encoded data increases capacity and scan exposure; actual query cost is not proven.
- **Recommendation:** Review top table/column consumers and remove or reshape only after dependency and usage validation.
- **Expected benefit:** Reduced model footprint and potentially faster scans/refresh.
- **Implementation effort:** MEDIUM
- **Validation:** Benchmark representative queries/refresh and verify semantic parity before production.

### F-006 - Partitions

- **Severity / Classification / Confidence:** HIGH / INFERRED / MEDIUM
- **Observation:** Largest storage structure has 21,568,293 rows while metadata shows 11 partitions for 11 tables.
- **Evidence:** metadata/partitions.csv; storage/storage_tables.csv; model/database.tmsl.json
- **Analysis / Performance impact:** Full-table refresh may have avoidable processing duration and transaction footprint.
- **Recommendation:** Validate refresh history and date boundaries, then test time-based incremental partitions.
- **Expected benefit:** Smaller refresh scope and improved operational manageability.
- **Implementation effort:** HIGH
- **Validation:** Benchmark representative queries/refresh and verify semantic parity before production.

### F-007 - DAX

- **Severity / Classification / Confidence:** MEDIUM / REQUIRES VALIDATION / MEDIUM
- **Observation:** Static scan found 48 selected risk-pattern occurrences; candidate measures: BKNT_AKTUAL_SDBI_AS; BKNT_ANGGARAN_SDBI_AS; BTD_ANGGARAN_SDBI; BTD_AKTUAL_SDBI; BTD_ANGGARAN_BI; BTD_AKTUAL_BI; BTD_SDBI; BUD_ANGGARAN_SDBI; BUD_ANGGARAN_BI; BUD_AKTUAL_SDBI; BUD_AKTUAL_BI; BTD_HO_ANGGARAN_SDBI; BTD_HO_ANGGARAN_BI; BTD_HO_AKTUAL_SDBI; BTD_HO_AKTUAL_BI; BUD_HO_ANGGARAN_SDBI; BUD_HO_ANGGARAN_BI; BUD_HO_AKTUAL_SDBI; BUD_HO_AKTUAL_BI.
- **Evidence:** metadata/measures.csv; model/database.tmsl.json
- **Analysis / Performance impact:** Iterator/context-transition patterns may increase Formula Engine work; syntax alone does not prove slowness.
- **Recommendation:** Capture representative query plans and Server Timings; refactor only measured hotspots using reusable base measures or reduced iterator input.
- **Expected benefit:** Potentially lower CPU and latency for confirmed hotspots.
- **Implementation effort:** MEDIUM
- **Validation:** Benchmark representative queries/refresh and verify semantic parity before production.

### F-008 - Model Complexity

- **Severity / Classification / Confidence:** MEDIUM / OBSERVED / HIGH
- **Observation:** 11 tables, 174 columns, 35 measures; fleet-relative complexity score 84.
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

