# Komparasi Overhead Metro - Technical Assessment

## Health Summary

**HIGH - 60/100.** Static fleet-relative prioritization; actual query and refresh performance are **NOT PROVABLE FROM CURRENT EVIDENCE**.

## Key Metrics and Risk Scores
# Komparasi Overhead Metro - Technical Assessment
| Tables | Columns | Measures | Relationships | Partitions | Hierarchies | Roles | Max rows | Segment used MB* |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 13 | 135 | 27 | 21 | 13 | 0 |  | 110052 | 12.532 |

| Complexity | Storage | Partition | Relationship | Static DAX | Overall |
|---:|---:|---:|---:|---:|---:|
| 78 | 69 | 40 | 73 | 26 | **60** |

## Model Complexity

Compatibility level: 1200. Calculated tables: 0; calculated columns detected in TMSL: 1. Complexity is interpreted relative to this 54-model fleet.

## Storage

| Top table/dimension storage structure | USED_SIZE MB | Maximum segment rows |
|---|---:|---:|
| fact_comparison_overhead_metro_monthly | 6.024 | 109017 |
| fact_comparison_overhead_metro_ytd | 4.437 | 110052 |
| fact_comparison_overhead_metro_quarter | 1.204 | 43278 |
| fact_comparison_overhead_metro_half_year | 0.709 | 25071 |
| dim_cost_element | 0.081 | 2444 |
| DimDate | 0.073 | 1826 |
| fact_dummy_data_monthly | 0.001 | 9 |
| dim_company | 0.001 | 43 |

| Potential dictionary/cardinality review candidate | Dictionary MB |
|---|---:|
| fact_comparison_overhead_metro_monthly, ytd_diff_idr | 4.932 |
| fact_comparison_overhead_metro_monthly, diff_idr | 4.859 |
| fact_comparison_overhead_metro_monthly, ytd_value_ly | 4.602 |
| fact_comparison_overhead_metro_monthly, ytd_value | 4.602 |
| fact_comparison_overhead_metro_ytd, ytd_value | 2.645 |
| fact_comparison_overhead_metro_monthly, value | 2.638 |
| fact_comparison_overhead_metro_monthly, value_ly | 2.638 |
| fact_comparison_overhead_metro_ytd, value | 2.572 |

\* DMV accounting only; not authoritative resident model size. Column candidates require usage and actual cardinality validation.

## Partitions

13 metadata partitions across 13 tables. No fleet screening rule proves a partition defect. Partition-level size/statistics are unavailable.

## Relationships

21 total, 0 inactive, 1 bidirectional indicators and 0 possible many-to-many indicators. Runtime Formula Engine impact is **REQUIRES VALIDATION**.

## Measures / DAX

27 measures; 2 selected static pattern hits. Candidate measures: none by this narrow scan. This is STATIC DAX RISK, not proof of slowness.

## Security

 roles observed. Security effectiveness, membership, RLS selectivity and runtime cost are not fully provable from role metadata alone.

## Findings

### F-022 - Relationships

- **Severity / Classification / Confidence:** MEDIUM / REQUIRES VALIDATION / MEDIUM
- **Observation:** 21 relationships (0 inactive, 1 bidirectional indicators, 0 possible many-to-many), fleet-relative score 73.
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

**YES**.
