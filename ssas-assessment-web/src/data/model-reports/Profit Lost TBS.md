# Profit Lost TBS - Technical Assessment

## Health Summary

**MEDIUM - 45/100.** Static fleet-relative prioritization; actual query and refresh performance are **NOT PROVABLE FROM CURRENT EVIDENCE**.

## Key Metrics and Risk Scores
# Profit Lost TBS - Technical Assessment
| Tables | Columns | Measures | Relationships | Partitions | Hierarchies | Roles | Max rows | Segment used MB* |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 8 | 119 | 10 | 12 | 8 | 0 |  | 830696 | 0 |

| Complexity | Storage | Partition | Relationship | Static DAX | Overall |
|---:|---:|---:|---:|---:|---:|
| 61 | 35 | 30 | 55 | 44 | **45** |

## Model Complexity

Compatibility level: 1200. Calculated tables: 0; calculated columns detected in TMSL: 0. Complexity is interpreted relative to this 54-model fleet.

## Storage

| Top table/dimension storage structure | USED_SIZE MB | Maximum segment rows |
|---|---:|---:|
| FactMRDummy | 0 | 25004 |
| DimDate | 0 | 7305 |
| FACT_PROFIT_LOST_TBS_YEARLY | 0 | 107140 |
| PL_TBS_DIM | 0 | 2 |
| CompanyDim | 0 | 100 |
| FACT_PROFIT_LOST_TBS | 0 | 830696 |
| ReportHierarcy | 0 | 183 |
| V_DimCompany | 0 | 43 |

| Potential dictionary/cardinality review candidate | Dictionary MB |
|---|---:|
| ReportHierarcy, Hdr3 | 0.016 |
| ReportHierarcy, Hdr2Code | 0.016 |
| ReportHierarcy, FieldName | 0.016 |
| ReportHierarcy, Hdr3Code | 0.016 |
| ReportHierarcy, Hdr1 | 0.016 |
| ReportHierarcy, BeginBalance | 0.016 |
| ReportHierarcy, Hdr2 | 0.016 |
| ReportHierarcy, Hdr1Code | 0.016 |

\* DMV accounting only; not authoritative resident model size. Column candidates require usage and actual cardinality validation.

## Partitions

8 metadata partitions across 8 tables. No fleet screening rule proves a partition defect. Partition-level size/statistics are unavailable.

## Relationships

12 total, 0 inactive, 0 bidirectional indicators and 0 possible many-to-many indicators. Runtime Formula Engine impact is **REQUIRES VALIDATION**.

## Measures / DAX

10 measures; 10 selected static pattern hits. Candidate measures: none by this narrow scan. This is STATIC DAX RISK, not proof of slowness.

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
