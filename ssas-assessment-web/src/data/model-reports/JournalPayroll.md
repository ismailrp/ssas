# JournalPayroll - Technical Assessment

## Health Summary

**MEDIUM - 50/100.** Static fleet-relative prioritization; actual query and refresh performance are **NOT PROVABLE FROM CURRENT EVIDENCE**.

## Key Metrics and Risk Scores
# JournalPayroll - Technical Assessment
| Tables | Columns | Measures | Relationships | Partitions | Hierarchies | Roles | Max rows | Segment used MB* |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 12 | 147 | 71 | 27 | 12 | 0 |  | 6158 | 0.802 |

| Complexity | Storage | Partition | Relationship | Static DAX | Overall |
|---:|---:|---:|---:|---:|---:|
| 81 | 45 | 37 | 67 | 10 | **50** |

## Model Complexity

Compatibility level: 1200. Calculated tables: 0; calculated columns detected in TMSL: 2. Complexity is interpreted relative to this 54-model fleet.

## Storage

| Top table/dimension storage structure | USED_SIZE MB | Maximum segment rows |
|---|---:|---:|
| FACT_ALOKASI_HK | 0.187 | 3762 |
| FACT_ALOKASI_HK_AKTIVITAS | 0.186 | 6158 |
| FACT_PREMI | 0.112 | 3763 |
| DIM_DATE | 0.091 | 2191 |
| DIM_DATE_DUMMY | 0.076 | 2191 |
| FACT_RUPIAH | 0.075 | 2536 |
| FACT_ABSENSI | 0.034 | 3981 |
| FACT_PRODUKSI | 0.026 | 2736 |

| Potential dictionary/cardinality review candidate | Dictionary MB |
|---|---:|
| DIM_DATE, StandardDate | 1.049 |
| DIM_DATE_DUMMY, StandardDate | 1.049 |
| DIM_DATE, LastDateOfMonth | 1.017 |
| DIM_PLANT, PLANT_CODE | 1.017 |
| DIM_PLANT, PLANT | 1.017 |
| DIM_DATE_DUMMY, LastDateOfMonth | 1.017 |
| DIM_DATE, HolidayText | 1.016 |
| DIM_DATE_DUMMY, DaySuffix | 1.016 |

\* DMV accounting only; not authoritative resident model size. Column candidates require usage and actual cardinality validation.

## Partitions

12 metadata partitions across 12 tables. No fleet screening rule proves a partition defect. Partition-level size/statistics are unavailable.

## Relationships

27 total, 0 inactive, 0 bidirectional indicators and 0 possible many-to-many indicators. Runtime Formula Engine impact is **REQUIRES VALIDATION**.

## Measures / DAX

71 measures; 0 selected static pattern hits. Candidate measures: none by this narrow scan. This is STATIC DAX RISK, not proof of slowness.

## Security

 roles observed. Security effectiveness, membership, RLS selectivity and runtime cost are not fully provable from role metadata alone.

## Findings

### F-040 - Model Complexity

- **Severity / Classification / Confidence:** MEDIUM / OBSERVED / HIGH
- **Observation:** 12 tables, 147 columns, 71 measures; fleet-relative complexity score 81.
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

**NO - retain in fleet monitoring unless runtime evidence elevates it**.
