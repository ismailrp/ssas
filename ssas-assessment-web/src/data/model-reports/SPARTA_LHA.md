# SPARTA_LHA - Technical Assessment

## Health Summary

**MEDIUM - 59/100.** Static fleet-relative prioritization; actual query and refresh performance are **NOT PROVABLE FROM CURRENT EVIDENCE**.

## Key Metrics and Risk Scores
# SPARTA_LHA - Technical Assessment
| Tables | Columns | Measures | Relationships | Partitions | Hierarchies | Roles | Max rows | Segment used MB* |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 13 | 126 | 23 | 14 | 13 | 0 |  | 1520301 | 0 |

| Complexity | Storage | Partition | Relationship | Static DAX | Overall |
|---:|---:|---:|---:|---:|---:|
| 79 | 39 | 85 | 57 | 40 | **59** |

## Model Complexity

Compatibility level: 1200. Calculated tables: 0; calculated columns detected in TMSL: 2. Complexity is interpreted relative to this 54-model fleet.

## Storage

| Top table/dimension storage structure | USED_SIZE MB | Maximum segment rows |
|---|---:|---:|
| DIM_SPR_COMPANY | 0 | 44 |
| DIM_PLANT | 0 | 115 |
| DIM_JOB_GRADE | 0 | 51 |
| FACT_SPARTA_SUMMARY_LHA | 0 | 1520298 |
| DIM_UNIT_MEASURE | 0 | 140 |
| DIM_STATUS_PEKERJA | 0 | 2 |
| DIM_GROUP_GRADE | 0 | 4 |
| DIM_AREA | 0 | 14 |

| Potential dictionary/cardinality review candidate | Dictionary MB |
|---|---:|
| DIM_SPR_COMPANY, COMPANY_CODE | 0.016 |
| DIM_DATE, DayOfWeek | 0.016 |
| DIM_PLANT, PLANT_CODE | 0.016 |
| DIM_PLANT, PLANT | 0.016 |
| DIM_DATE, DaySuffix | 0.016 |
| DIM_BLOCK, BLOCK_CODE | 0.016 |
| DIM_STATUS_PEKERJA, STATUS_PEKERJA | 0.016 |
| DIM_SPR_COMPANY, COMPANY | 0.016 |

\* DMV accounting only; not authoritative resident model size. Column candidates require usage and actual cardinality validation.

## Partitions

13 metadata partitions across 13 tables. A large/lightly partitioned screening signal is present. Validate source date fields and refresh history before piloting time partitions.

## Relationships

14 total, 2 inactive, 0 bidirectional indicators and 0 possible many-to-many indicators. Runtime Formula Engine impact is **REQUIRES VALIDATION**.

## Measures / DAX

23 measures; 8 selected static pattern hits. Candidate measures: none by this narrow scan. This is STATIC DAX RISK, not proof of slowness.

## Security

 roles observed. Security effectiveness, membership, RLS selectivity and runtime cost are not fully provable from role metadata alone.

## Findings

### F-029 - Partitions

- **Severity / Classification / Confidence:** HIGH / INFERRED / MEDIUM
- **Observation:** Largest storage structure has 1,520,301 rows while metadata shows 13 partitions for 13 tables.
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

**NO - retain in fleet monitoring unless runtime evidence elevates it**.
