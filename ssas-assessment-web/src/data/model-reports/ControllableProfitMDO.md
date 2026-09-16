# ControllableProfitMDO - Technical Assessment

## Health Summary

**MEDIUM - 46/100.** Static fleet-relative prioritization; actual query and refresh performance are **NOT PROVABLE FROM CURRENT EVIDENCE**.

## Key Metrics and Risk Scores
# ControllableProfitMDO - Technical Assessment
| Tables | Columns | Measures | Relationships | Partitions | Hierarchies | Roles | Max rows | Segment used MB* |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 8 | 114 | 144 | 8 | 8 | 0 |  | 63501 | 0 |

| Complexity | Storage | Partition | Relationship | Static DAX | Overall |
|---:|---:|---:|---:|---:|---:|
| 70 | 26 | 30 | 48 | 59 | **46** |

## Model Complexity

Compatibility level: 1200. Calculated tables: 0; calculated columns detected in TMSL: 0. Complexity is interpreted relative to this 54-model fleet.

## Storage

| Top table/dimension storage structure | USED_SIZE MB | Maximum segment rows |
|---|---:|---:|
| Controllable Cost Ranking | 0 | 3048 |
| dim_company | 0 | 44 |
| DIM_HPO | 0 | 4 |
| Controllable Cost MDO Ranking | 0 | 960 |
| DIM_REGION | 0 | 14 |
| DIM_DATE | 0 | 1826 |
| Controllable Cost Company | 0 | 63501 |
| Controllable Cost | 0 | 45380 |

| Potential dictionary/cardinality review candidate | Dictionary MB |
|---|---:|
| Controllable Cost Ranking, PALM_PRODUCT | 0.016 |
| Controllable Cost MDO Ranking, PALM_PRODUCT | 0.016 |
| DIM_REGION, REGION | 0.016 |
| DIM_REGION, REGION_CODE | 0.016 |
| DIM_DATE, LastDateOfMonth | 0.016 |
| Controllable Cost, REPORT_ITEM_LEVEL_0 | 0.016 |
| DIM_DATE, StandardDate | 0.016 |
| DIM_DATE, HolidayText | 0.016 |

\* DMV accounting only; not authoritative resident model size. Column candidates require usage and actual cardinality validation.

## Partitions

8 metadata partitions across 8 tables. No fleet screening rule proves a partition defect. Partition-level size/statistics are unavailable.

## Relationships

8 total, 0 inactive, 0 bidirectional indicators and 0 possible many-to-many indicators. Runtime Formula Engine impact is **REQUIRES VALIDATION**.

## Measures / DAX

144 measures; 116 selected static pattern hits. Candidate measures: Total Aktual BI Amount; Total Aktual SDBI Amount; Total Anggaran BI Amount; Total Anggaran SDBI Amount; Total Aktual BI Amount Company; Total Aktual SDBI Amount Company; Total Anggaran BI Amount Company; Total Anggaran SDBI Amount Company. This is STATIC DAX RISK, not proof of slowness.

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
