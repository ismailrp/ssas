# Payment Realization - Technical Assessment

## Health Summary

**LOW - 25/100.** Static fleet-relative prioritization; actual query and refresh performance are **NOT PROVABLE FROM CURRENT EVIDENCE**.

## Key Metrics and Risk Scores
# Payment Realization - Technical Assessment
| Tables | Columns | Measures | Relationships | Partitions | Hierarchies | Roles | Max rows | Segment used MB* |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 2 | 17 |  | 0 | 2 | 0 | 0 | 139057 | 1.058 |

| Complexity | Storage | Partition | Relationship | Static DAX | Overall |
|---:|---:|---:|---:|---:|---:|
| 18 | 49 | 10 | 22 | 10 | **25** |

## Model Complexity

Compatibility level: 1200. Calculated tables: 0; calculated columns detected in TMSL: 2. Complexity is interpreted relative to this 54-model fleet.

## Storage

| Top table/dimension storage structure | USED_SIZE MB | Maximum segment rows |
|---|---:|---:|
| FACT_PAYMENT_REALIZATION | 1.052 | 139057 |
| DIM_WEEK | 0.007 | 1095 |

| Potential dictionary/cardinality review candidate | Dictionary MB |
|---|---:|
| FACT_PAYMENT_REALIZATION, VALUE | 2.514 |
| FACT_PAYMENT_REALIZATION, BUDAT | 1.022 |
| FACT_PAYMENT_REALIZATION, CF_DESC | 1.017 |
| FACT_PAYMENT_REALIZATION, COMPANY | 1.017 |
| FACT_PAYMENT_REALIZATION, MONTH | 1.016 |
| FACT_PAYMENT_REALIZATION, YEAR | 1.016 |
| FACT_PAYMENT_REALIZATION, MONTHNAME | 1.016 |
| DIM_WEEK, WEEK | 1.016 |

\* DMV accounting only; not authoritative resident model size. Column candidates require usage and actual cardinality validation.

## Partitions

2 metadata partitions across 2 tables. No fleet screening rule proves a partition defect. Partition-level size/statistics are unavailable.

## Relationships

0 total, 0 inactive, 0 bidirectional indicators and 0 possible many-to-many indicators. Runtime Formula Engine impact is **REQUIRES VALIDATION**.

## Measures / DAX

 measures; 0 selected static pattern hits. Candidate measures: none by this narrow scan. This is STATIC DAX RISK, not proof of slowness.

## Security

0 roles observed. Security effectiveness, membership, RLS selectivity and runtime cost are not fully provable from role metadata alone.

## Findings

No material fleet-outlier finding generated. This does not prove absence of runtime issues.

## Recommendations

Prioritize evidence collection, then address confirmed storage/partition/relationship/DAX hotspots. Treat apparent unused objects only as **CANDIDATE FOR USAGE VALIDATION**.

## Evidence Gaps

No historical query duration/CPU, FE/SE timing, peak concurrency, refresh duration, memory-pressure series or object usage telemetry.

## Deep-Dive Recommendation

**NO - retain in fleet monitoring unless runtime evidence elevates it**.
