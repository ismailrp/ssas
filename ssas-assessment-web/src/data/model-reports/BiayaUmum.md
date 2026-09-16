# BiayaUmum - Technical Assessment

## Health Summary

**MEDIUM - 41/100.** Static fleet-relative prioritization; actual query and refresh performance are **NOT PROVABLE FROM CURRENT EVIDENCE**.

## Key Metrics and Risk Scores
# BiayaUmum - Technical Assessment
| Tables | Columns | Measures | Relationships | Partitions | Hierarchies | Roles | Max rows | Segment used MB* |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 4 | 58 | 7 | 2 | 4 | 0 | 0 | 54673 | 0.522 |

| Complexity | Storage | Partition | Relationship | Static DAX | Overall |
|---:|---:|---:|---:|---:|---:|
| 48 | 46 | 22 | 31 | 52 | **41** |

## Model Complexity

Compatibility level: 1200. Calculated tables: 1; calculated columns detected in TMSL: 6. Complexity is interpreted relative to this 54-model fleet.

## Storage

| Top table/dimension storage structure | USED_SIZE MB | Maximum segment rows |
|---|---:|---:|
| BiayaUmum | 0.509 | 54673 |
| Calendar | 0.009 | 365 |
| DIM_BIAYA_UMUM_PER_KOMPONEN | 0.003 | 73 |
| DIM_PLANT | 0.002 | 69 |

| Potential dictionary/cardinality review candidate | Dictionary MB |
|---|---:|
| BiayaUmum, VALUE | 1.173 |
| BiayaUmum, JENIS_PEKERJAAN_LV3 | 1.017 |
| DIM_PLANT, PLANT_CODE | 1.017 |
| DIM_BIAYA_UMUM_PER_KOMPONEN, JENIS_PEKERJAAN_LV3 | 1.017 |
| DIM_BIAYA_UMUM_PER_KOMPONEN, ACTCD | 1.017 |
| BiayaUmum, PLANT_CODE | 1.017 |
| BiayaUmum, GL_DESC | 1.017 |
| DIM_PLANT, HPO | 1.016 |

\* DMV accounting only; not authoritative resident model size. Column candidates require usage and actual cardinality validation.

## Partitions

4 metadata partitions across 4 tables. No fleet screening rule proves a partition defect. Partition-level size/statistics are unavailable.

## Relationships

2 total, 0 inactive, 0 bidirectional indicators and 0 possible many-to-many indicators. Runtime Formula Engine impact is **REQUIRES VALIDATION**.

## Measures / DAX

7 measures; 9 selected static pattern hits. Candidate measures: ACTUAL_SDBI; BUDGET_SDBI. This is STATIC DAX RISK, not proof of slowness.

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
