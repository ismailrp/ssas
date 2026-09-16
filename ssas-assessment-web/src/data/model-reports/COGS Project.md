# COGS Project - Technical Assessment

## Health Summary

**MEDIUM - 40/100.** Static fleet-relative prioritization; actual query and refresh performance are **NOT PROVABLE FROM CURRENT EVIDENCE**.

## Key Metrics and Risk Scores
# COGS Project - Technical Assessment
| Tables | Columns | Measures | Relationships | Partitions | Hierarchies | Roles | Max rows | Segment used MB* |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 5 | 52 | 3 | 4 | 5 | 0 |  | 170540 | 2.251 |

| Complexity | Storage | Partition | Relationship | Static DAX | Overall |
|---:|---:|---:|---:|---:|---:|
| 38 | 56 | 25 | 41 | 29 | **40** |

## Model Complexity

Compatibility level: 1200. Calculated tables: 0; calculated columns detected in TMSL: 0. Complexity is interpreted relative to this 54-model fleet.

## Storage

| Top table/dimension storage structure | USED_SIZE MB | Maximum segment rows |
|---|---:|---:|
| fact_cogs | 2.005 | 170540 |
| dim_date | 0.243 | 7305 |
| dim_cogs_report | 0.002 | 68 |
| dim_company | 0.001 | 43 |
| dim_cogs_measure | 0 | 3 |

| Potential dictionary/cardinality review candidate | Dictionary MB |
|---|---:|
| fact_cogs, Amount | 2.627 |
| fact_cogs, Amount_ly | 2.493 |
| fact_cogs, Change_percent | 2.476 |
| dim_date, StandardDate | 1.183 |
| dim_date, LastDateOfMonth | 1.018 |
| dim_company, CompanySelection | 1.017 |
| dim_cogs_report, Report | 1.017 |
| dim_company, Company | 1.017 |

\* DMV accounting only; not authoritative resident model size. Column candidates require usage and actual cardinality validation.

## Partitions

5 metadata partitions across 5 tables. No fleet screening rule proves a partition defect. Partition-level size/statistics are unavailable.

## Relationships

4 total, 0 inactive, 0 bidirectional indicators and 0 possible many-to-many indicators. Runtime Formula Engine impact is **REQUIRES VALIDATION**.

## Measures / DAX

3 measures; 3 selected static pattern hits. Candidate measures: none by this narrow scan. This is STATIC DAX RISK, not proof of slowness.

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
