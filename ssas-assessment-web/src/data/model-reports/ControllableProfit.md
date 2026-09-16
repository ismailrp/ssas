# ControllableProfit - Technical Assessment

## Health Summary

**MEDIUM - 58/100.** Static fleet-relative prioritization; actual query and refresh performance are **NOT PROVABLE FROM CURRENT EVIDENCE**.

## Key Metrics and Risk Scores
# ControllableProfit - Technical Assessment
| Tables | Columns | Measures | Relationships | Partitions | Hierarchies | Roles | Max rows | Segment used MB* |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 9 | 121 | 147 | 9 | 9 | 0 |  | 92232 | 4.202 |

| Complexity | Storage | Partition | Relationship | Static DAX | Overall |
|---:|---:|---:|---:|---:|---:|
| 74 | 62 | 32 | 49 | 64 | **58** |

## Model Complexity

Compatibility level: 1200. Calculated tables: 0; calculated columns detected in TMSL: 0. Complexity is interpreted relative to this 54-model fleet.

## Storage

| Top table/dimension storage structure | USED_SIZE MB | Maximum segment rows |
|---|---:|---:|
| Controllable Cost Company | 2.239 | 92232 |
| Controllable Cost | 1.618 | 62856 |
| Controllable Cost Ranking | 0.182 | 3744 |
| DIM_DATE | 0.091 | 2191 |
| Controllable Cost MDO Ranking | 0.066 | 1449 |
| Dummy Data | 0.004 | 805 |
| dim_company | 0.001 | 44 |
| DIM_REGION | 0.001 | 15 |

| Potential dictionary/cardinality review candidate | Dictionary MB |
|---|---:|
| Controllable Cost Company, ANGGARAN_SDBI_AMOUNT | 2.533 |
| Controllable Cost Company, AKTUAL_SDBI_AMOUNT | 2.506 |
| Controllable Cost Company, AKTUAL_BI_AMOUNT | 2.501 |
| Controllable Cost, ANGGARAN_SDBI_AMOUNT | 2.359 |
| Controllable Cost, AKTUAL_SDBI_AMOUNT | 2.34 |
| Controllable Cost, AKTUAL_BI_AMOUNT | 2.337 |
| Controllable Cost Company, ANGGARAN_BI_AMOUNT | 2.328 |
| Controllable Cost, ANGGARAN_BI_AMOUNT | 1.279 |

\* DMV accounting only; not authoritative resident model size. Column candidates require usage and actual cardinality validation.

## Partitions

9 metadata partitions across 9 tables. No fleet screening rule proves a partition defect. Partition-level size/statistics are unavailable.

## Relationships

9 total, 0 inactive, 0 bidirectional indicators and 0 possible many-to-many indicators. Runtime Formula Engine impact is **REQUIRES VALIDATION**.

## Measures / DAX

147 measures; 144 selected static pattern hits. Candidate measures: Total Aktual BI Amount; Total Aktual SDBI Amount; Total Anggaran BI Amount; Total Anggaran SDBI Amount; Total Aktual BI Amount Company; Total Aktual SDBI Amount Company; Total Anggaran BI Amount Company; Total Anggaran SDBI Amount Company; SDBI RANK; BI RANK MDO; SDBI RANK MDO; SDBI RANK MDO V1. This is STATIC DAX RISK, not proof of slowness.

## Security

 roles observed. Security effectiveness, membership, RLS selectivity and runtime cost are not fully provable from role metadata alone.

## Findings

No material fleet-outlier finding generated. This does not prove absence of runtime issues.

## Recommendations

Prioritize evidence collection, then address confirmed storage/partition/relationship/DAX hotspots. Treat apparent unused objects only as **CANDIDATE FOR USAGE VALIDATION**.

## Evidence Gaps

No historical query duration/CPU, FE/SE timing, peak concurrency, refresh duration, memory-pressure series or object usage telemetry.

## Deep-Dive Recommendation

**NO - retain in fleet monitoring unless runtime evidence elevates it**.
