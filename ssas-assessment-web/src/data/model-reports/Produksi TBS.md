# Produksi TBS - Technical Assessment

## Health Summary

**CRITICAL - 82/100.** Static fleet-relative prioritization; actual query and refresh performance are **NOT PROVABLE FROM CURRENT EVIDENCE**.

## Key Metrics and Risk Scores
# Produksi TBS - Technical Assessment
| Tables | Columns | Measures | Relationships | Partitions | Hierarchies | Roles | Max rows | Segment used MB* |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 18 | 167 | 65 | 20 | 18 | 0 |  | 8878506 | 93.406 |

| Complexity | Storage | Partition | Relationship | Static DAX | Overall |
|---:|---:|---:|---:|---:|---:|
| 91 | 91 | 85 | 71 | 61 | **82** |

## Runtime Evidence

No BUSINESS_CANDIDATE query captured. Runtime performance is NOT PROVABLE FROM CURRENT EVIDENCE.

## Model Complexity

Compatibility level: 1200. Calculated tables: 0; calculated columns detected in TMSL: 11. Complexity is interpreted relative to this 54-model fleet.

## Storage

| Top table/dimension storage structure | USED_SIZE MB | Maximum segment rows |
|---|---:|---:|
| KANBAN_TBS_INTERNAL | 38.182 | 8878506 |
| FACT_DD_TBS_INTERNAL | 21.302 | 2211954 |
| KANBAN_TBS_EKSTERNAL | 19.115 | 4937935 |
| FACT_DD_TBS_PER_HOUR | 14.704 | 2896064 |
| DIM_DATE | 0.058 | 1350 |
| DIM_DIVISION | 0.018 | 1320 |
| Section_Access | 0.016 | 2307 |
| DIM_PLANT | 0.004 | 116 |

| Potential dictionary/cardinality review candidate | Dictionary MB |
|---|---:|
| KANBAN_TBS_INTERNAL, VALUE_AKTUAL | 2.435 |
| KANBAN_TBS_EKSTERNAL, VALUE_AKTUAL | 2.435 |
| FACT_DD_TBS_PER_HOUR, VALUE | 1.185 |
| DIM_DATE, StandardDate | 1.028 |
| Section_Access, UserName | 1.021 |
| Section_Access, UserName2 | 1.021 |
| FACT_DD_TBS_INTERNAL, UNIT | 1.02 |
| KANBAN_TBS_INTERNAL, UNIT | 1.019 |

\* DMV accounting only; not authoritative resident model size. Column candidates require usage and actual cardinality validation.

## Partitions

18 metadata partitions across 18 tables. A large/lightly partitioned screening signal is present. Validate source date fields and refresh history before piloting time partitions.

## Relationships

20 total, 0 inactive, 1 bidirectional indicators and 0 possible many-to-many indicators. Runtime Formula Engine impact is **REQUIRES VALIDATION**.

## Measures / DAX

65 measures; 68 selected static pattern hits. Candidate measures: TBS_EXT_ACT_1; TBS_EXT_ACT_2; TBS_EXT_ACT_3; TBS_EXT_ACT_4; TBS_EXT_ACT_5; TBS EXT_ACT_CM; TBS EXT_ACT_LM; TBS INT_ACT_CM; TBS INT_ACT_LM; TBS_INT_ACT_1; TBS_INT_ACT_2; TBS_INT_ACT_3; TBS_INT_ACT_4; TBS_INT_ACT_5. This is STATIC DAX RISK, not proof of slowness.

## Security

 roles observed. Security effectiveness, membership, RLS selectivity and runtime cost are not fully provable from role metadata alone.

## Findings

### F-001 - Storage

- **Severity / Classification / Confidence:** HIGH / OBSERVED / HIGH
- **Observation:** Fleet-relative storage score 91; USED_SIZE 93.406 MB, dictionary 58.448 MB, maximum recorded storage-table rows 8,878,506.
- **Evidence:** storage/storage_column_segments.csv; storage/storage_table_columns.csv; storage/storage_tables.csv
- **Analysis / Performance impact:** Disproportionate encoded data increases capacity and scan exposure; actual query cost is not proven.
- **Recommendation:** Review top table/column consumers and remove or reshape only after dependency and usage validation.
- **Expected benefit:** Reduced model footprint and potentially faster scans/refresh.
- **Implementation effort:** MEDIUM
- **Validation:** Benchmark representative queries/refresh and verify semantic parity before production.

### F-002 - Partitions

- **Severity / Classification / Confidence:** HIGH / INFERRED / MEDIUM
- **Observation:** Largest storage structure has 8,878,506 rows while metadata shows 18 partitions for 18 tables.
- **Evidence:** metadata/partitions.csv; storage/storage_tables.csv; model/database.tmsl.json
- **Analysis / Performance impact:** Full-table refresh may have avoidable processing duration and transaction footprint.
- **Recommendation:** Validate refresh history and date boundaries, then test time-based incremental partitions.
- **Expected benefit:** Smaller refresh scope and improved operational manageability.
- **Implementation effort:** HIGH
- **Validation:** Benchmark representative queries/refresh and verify semantic parity before production.

### F-003 - Relationships

- **Severity / Classification / Confidence:** MEDIUM / REQUIRES VALIDATION / MEDIUM
- **Observation:** 20 relationships (0 inactive, 1 bidirectional indicators, 0 possible many-to-many), fleet-relative score 71.
- **Evidence:** metadata/relationships.csv; model/database.tmsl.json
- **Analysis / Performance impact:** Complex propagation can increase DAX/Formula Engine work and maintenance risk, but runtime effect is unmeasured.
- **Recommendation:** Diagram cardinality/filter paths; validate ambiguous paths and constrain bidirectional filters where business semantics permit.
- **Expected benefit:** Simpler filter propagation and more predictable calculations.
- **Implementation effort:** MEDIUM
- **Validation:** Benchmark representative queries/refresh and verify semantic parity before production.

### F-004 - Model Complexity

- **Severity / Classification / Confidence:** MEDIUM / OBSERVED / HIGH
- **Observation:** 18 tables, 167 columns, 65 measures; fleet-relative complexity score 91.
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

