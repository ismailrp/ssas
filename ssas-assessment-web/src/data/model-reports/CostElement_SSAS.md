# CostElement_SSAS - Technical Assessment

## Health Summary

**MEDIUM - 34/100.** Static fleet-relative prioritization; actual query and refresh performance are **NOT PROVABLE FROM CURRENT EVIDENCE**.

## Key Metrics and Risk Scores
# CostElement_SSAS - Technical Assessment
| Tables | Columns | Measures | Relationships | Partitions | Hierarchies | Roles | Max rows | Segment used MB* |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 2 | 37 | 4 |  | 2 | 0 | 0 | 477445 | 5.88 |

| Complexity | Storage | Partition | Relationship | Static DAX | Overall |
|---:|---:|---:|---:|---:|---:|
| 28 | 68 | 10 | 9 | 32 | **34** |

## Model Complexity

Compatibility level: 1200. Calculated tables: 1; calculated columns detected in TMSL: 3. Complexity is interpreted relative to this 54-model fleet.

## Storage

| Top table/dimension storage structure | USED_SIZE MB | Maximum segment rows |
|---|---:|---:|
| Cost_element | 5.845 | 477445 |
| Calendar | 0.035 | 1826 |

| Potential dictionary/cardinality review candidate | Dictionary MB |
|---|---:|
| Cost_element, VALUE_AKTUAL | 19.797 |
| Cost_element, ACTV_LEVEL4 | 1.017 |
| Cost_element, UNITN | 1.017 |
| Calendar, Year Month Name | 1.017 |
| Cost_element, ACTV_DESC | 1.017 |
| Cost_element, ACTV | 1.017 |
| Cost_element, CATEGORY_DESC | 1.016 |
| Cost_element, BUKRS | 1.016 |

\* DMV accounting only; not authoritative resident model size. Column candidates require usage and actual cardinality validation.

## Partitions

2 metadata partitions across 2 tables. No fleet screening rule proves a partition defect. Partition-level size/statistics are unavailable.

## Relationships

 total, 0 inactive, 0 bidirectional indicators and 0 possible many-to-many indicators. Runtime Formula Engine impact is **REQUIRES VALIDATION**.

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
