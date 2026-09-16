# End to End CAPEX - Technical Assessment

## Health Summary

**MEDIUM - 49/100.** Static fleet-relative prioritization; actual query and refresh performance are **NOT PROVABLE FROM CURRENT EVIDENCE**.

## Key Metrics and Risk Scores
# End to End CAPEX - Technical Assessment
| Tables | Columns | Measures | Relationships | Partitions | Hierarchies | Roles | Max rows | Segment used MB* |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 6 | 109 | 29 | 6 | 6 | 0 | 0 | 80352 | 2.893 |

| Complexity | Storage | Partition | Relationship | Static DAX | Overall |
|---:|---:|---:|---:|---:|---:|
| 62 | 59 | 27 | 74 | 10 | **49** |

## Model Complexity

Compatibility level: 1200. Calculated tables: 0; calculated columns detected in TMSL: 1. Complexity is interpreted relative to this 54-model fleet.

## Storage

| Top table/dimension storage structure | USED_SIZE MB | Maximum segment rows |
|---|---:|---:|
| FACT_END_TO_END_CAPEX | 2.841 | 80352 |
| DIM_DATE | 0.045 | 1096 |
| DIM_PLANT | 0.004 | 116 |
| DIM_AREA | 0.001 | 14 |
| DIM_SPR_COMPANY | 0.001 | 44 |
| DIM_REGION | 0.001 | 15 |

| Potential dictionary/cardinality review candidate | Dictionary MB |
|---|---:|
| FACT_END_TO_END_CAPEX, KODE_WBS | 1.172 |
| FACT_END_TO_END_CAPEX, ACT_VS_COMMITPC | 1.026 |
| DIM_DATE, StandardDate | 1.025 |
| FACT_END_TO_END_CAPEX, KODE_WBS_2 | 1.021 |
| FACT_END_TO_END_CAPEX, WBS | 1.02 |
| FACT_END_TO_END_CAPEX, COMMIT_MTDPC | 1.018 |
| FACT_END_TO_END_CAPEX, COMMIT_FYPC | 1.018 |
| FACT_END_TO_END_CAPEX, WBS_DESC | 1.018 |

\* DMV accounting only; not authoritative resident model size. Column candidates require usage and actual cardinality validation.

## Partitions

6 metadata partitions across 6 tables. No fleet screening rule proves a partition defect. Partition-level size/statistics are unavailable.

## Relationships

6 total, 1 inactive, 3 bidirectional indicators and 0 possible many-to-many indicators. Runtime Formula Engine impact is **REQUIRES VALIDATION**.

## Measures / DAX

29 measures; 0 selected static pattern hits. Candidate measures: none by this narrow scan. This is STATIC DAX RISK, not proof of slowness.

## Security

0 roles observed. Security effectiveness, membership, RLS selectivity and runtime cost are not fully provable from role metadata alone.

## Findings

### F-041 - Relationships

- **Severity / Classification / Confidence:** MEDIUM / REQUIRES VALIDATION / MEDIUM
- **Observation:** 6 relationships (1 inactive, 3 bidirectional indicators, 0 possible many-to-many), fleet-relative score 74.
- **Evidence:** metadata/relationships.csv; model/database.tmsl.json
- **Analysis / Performance impact:** Complex propagation can increase DAX/Formula Engine work and maintenance risk, but runtime effect is unmeasured.
- **Recommendation:** Diagram cardinality/filter paths; validate ambiguous paths and constrain bidirectional filters where business semantics permit.
- **Expected benefit:** Simpler filter propagation and more predictable calculations.
- **Implementation effort:** MEDIUM
- **Validation:** Benchmark representative queries/refresh and verify semantic parity before production.


## Recommendations

Prioritize evidence collection, then address confirmed storage/partition/relationship/DAX hotspots. Treat apparent unused objects only as **CANDIDATE FOR USAGE VALIDATION**.

## Evidence Gaps

No historical query duration/CPU, FE/SE timing, peak concurrency, refresh duration, memory-pressure series or object usage telemetry.

## Deep-Dive Recommendation

**NO - retain in fleet monitoring unless runtime evidence elevates it**.
