# Actual vs Anggaran - Technical Assessment

## Health Summary

**MEDIUM - 42/100.** Static fleet-relative prioritization; actual query and refresh performance are **NOT PROVABLE FROM CURRENT EVIDENCE**.

## Key Metrics and Risk Scores
# Actual vs Anggaran - Technical Assessment
| Tables | Columns | Measures | Relationships | Partitions | Hierarchies | Roles | Max rows | Segment used MB* |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 11 | 99 | 0 | 22 | 11 | 0 |  | 7804 | 0.909 |

| Complexity | Storage | Partition | Relationship | Static DAX | Overall |
|---:|---:|---:|---:|---:|---:|
| 57 | 45 | 35 | 65 | 0 | **42** |

## Model Complexity

Compatibility level: 1200. Calculated tables: 0; calculated columns detected in TMSL: 2. Complexity is interpreted relative to this 54-model fleet.

## Storage

| Top table/dimension storage structure | USED_SIZE MB | Maximum segment rows |
|---|---:|---:|
| FACT_ACTUAL_GAJI | 0.416 | 7803 |
| FACT_BUDGET_GAJI | 0.235 | 4920 |
| FACT_ACTUAL_PRODUKSI | 0.086 | 4527 |
| DIM_DATE | 0.086 | 2191 |
| FACT_BUDGET_PRODUKSI | 0.05 | 2472 |
| FACT_BUDGET_TK | 0.02 | 1644 |
| FACT_ACTUAL_TK | 0.013 | 1302 |
| DIM_PLANT | 0.002 | 69 |

| Potential dictionary/cardinality review candidate | Dictionary MB |
|---|---:|
| DIM_DATE, StandardDate | 1.049 |
| DIM_DATE, LastDateOfMonth | 1.017 |
| DIM_PLANT, PLANT | 1.017 |
| DIM_PLANT, PLANT_CODE | 1.017 |
| FACT_ACTUAL_PRODUKSI, DATE_ID | 1.016 |
| DIM_REGION, GROUP_REGION | 1.016 |
| FACT_BUDGET_TK, DATE_ID | 1.016 |
| DIM_DATE, CalendarQuarterName | 1.016 |

\* DMV accounting only; not authoritative resident model size. Column candidates require usage and actual cardinality validation.

## Partitions

11 metadata partitions across 11 tables. No fleet screening rule proves a partition defect. Partition-level size/statistics are unavailable.

## Relationships

22 total, 0 inactive, 0 bidirectional indicators and 0 possible many-to-many indicators. Runtime Formula Engine impact is **REQUIRES VALIDATION**.

## Measures / DAX

0 measures; 0 selected static pattern hits. Candidate measures: none by this narrow scan. This is STATIC DAX RISK, not proof of slowness.

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
