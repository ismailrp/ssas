# Tax Payment - Technical Assessment

## Health Summary

**LOW - 19/100.** Static fleet-relative prioritization; actual query and refresh performance are **NOT PROVABLE FROM CURRENT EVIDENCE**.

## Key Metrics and Risk Scores
# Tax Payment - Technical Assessment
| Tables | Columns | Measures | Relationships | Partitions | Hierarchies | Roles | Max rows | Segment used MB* |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
|  | 15 | 2 | 0 |  | 0 | 2 | 55728 | 0.219 |

| Complexity | Storage | Partition | Relationship | Static DAX | Overall |
|---:|---:|---:|---:|---:|---:|
| 10 | 40 | 2 | 22 | 10 | **19** |

## Model Complexity

Compatibility level: 1200. Calculated tables: 0; calculated columns detected in TMSL: 0. Complexity is interpreted relative to this 54-model fleet.

## Storage

| Top table/dimension storage structure | USED_SIZE MB | Maximum segment rows |
|---|---:|---:|
| FACT_PAYMENT | 0.219 | 55728 |

| Potential dictionary/cardinality review candidate | Dictionary MB |
|---|---:|
| FACT_PAYMENT, COMPANY_CODE | 1.017 |
| FACT_PAYMENT, COMPANY_NAME | 1.017 |
| FACT_PAYMENT, TAX_GROUP | 1.016 |
| FACT_PAYMENT, TAX_CATEGORY | 1.016 |
| FACT_PAYMENT, TAX_DESC | 1.016 |
| FACT_PAYMENT, TAX_TYPE | 1.016 |
| FACT_PAYMENT, TAX_SUB_GROUP | 1.016 |
| FACT_PAYMENT, VALUE_SDBI_TOTAL | 0.156 |

\* DMV accounting only; not authoritative resident model size. Column candidates require usage and actual cardinality validation.

## Partitions

 metadata partitions across  tables. No fleet screening rule proves a partition defect. Partition-level size/statistics are unavailable.

## Relationships

0 total, 0 inactive, 0 bidirectional indicators and 0 possible many-to-many indicators. Runtime Formula Engine impact is **REQUIRES VALIDATION**.

## Measures / DAX

2 measures; 0 selected static pattern hits. Candidate measures: none by this narrow scan. This is STATIC DAX RISK, not proof of slowness.

## Security

2 roles observed. Security effectiveness, membership, RLS selectivity and runtime cost are not fully provable from role metadata alone.

## Findings

No material fleet-outlier finding generated. This does not prove absence of runtime issues.

## Recommendations

Prioritize evidence collection, then address confirmed storage/partition/relationship/DAX hotspots. Treat apparent unused objects only as **CANDIDATE FOR USAGE VALIDATION**.

## Evidence Gaps

No historical query duration/CPU, FE/SE timing, peak concurrency, refresh duration, memory-pressure series or object usage telemetry.

## Deep-Dive Recommendation

**NO - retain in fleet monitoring unless runtime evidence elevates it**.
