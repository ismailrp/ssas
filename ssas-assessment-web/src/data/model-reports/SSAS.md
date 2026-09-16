# SSAS - Technical Assessment

## Health Summary

**MEDIUM - 41/100.** Static fleet-relative prioritization; actual query and refresh performance are **NOT PROVABLE FROM CURRENT EVIDENCE**.

## Key Metrics and Risk Scores
# SSAS - Technical Assessment
| Tables | Columns | Measures | Relationships | Partitions | Hierarchies | Roles | Max rows | Segment used MB* |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 6 | 65 | 4 | 3 | 6 | 0 | 0 | 53427 | 1.202 |

| Complexity | Storage | Partition | Relationship | Static DAX | Overall |
|---:|---:|---:|---:|---:|---:|
| 49 | 50 | 27 | 37 | 32 | **41** |

## Model Complexity

Compatibility level: 1200. Calculated tables: 0; calculated columns detected in TMSL: 2. Complexity is interpreted relative to this 54-model fleet.

## Storage

| Top table/dimension storage structure | USED_SIZE MB | Maximum segment rows |
|---|---:|---:|
| fact_summary_pl | 0.687 | 53427 |
| dim_date | 0.257 | 7305 |
| fact_ebitda | 0.255 | 21291 |
| dim_company_summary_pl | 0.002 | 51 |
| dim_coa_summary_pl | 0.001 | 25 |
| dim_code_ebitda | 0 | 12 |

| Potential dictionary/cardinality review candidate | Dictionary MB |
|---|---:|
| dim_date, StandardDate | 1.183 |
| dim_date, MonthYear | 1.018 |
| dim_date, LastDateOfMonth | 1.018 |
| dim_company_summary_pl, sub_company | 1.017 |
| dim_company_summary_pl, sub_company_code | 1.016 |
| dim_company_summary_pl, company | 1.016 |
| dim_company_summary_pl, level | 1.016 |
| fact_ebitda, Month | 1.016 |

\* DMV accounting only; not authoritative resident model size. Column candidates require usage and actual cardinality validation.

## Partitions

6 metadata partitions across 6 tables. No fleet screening rule proves a partition defect. Partition-level size/statistics are unavailable.

## Relationships

3 total, 0 inactive, 0 bidirectional indicators and 0 possible many-to-many indicators. Runtime Formula Engine impact is **REQUIRES VALIDATION**.

## Measures / DAX

4 measures; 4 selected static pattern hits. Candidate measures: none by this narrow scan. This is STATIC DAX RISK, not proof of slowness.

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
