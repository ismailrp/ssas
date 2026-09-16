# Kecelakaan Kerja Pasien - Technical Assessment

## Health Summary

**LOW - 22/100.** Static fleet-relative prioritization; actual query and refresh performance are **NOT PROVABLE FROM CURRENT EVIDENCE**.

## Key Metrics and Risk Scores
# Kecelakaan Kerja Pasien - Technical Assessment
| Tables | Columns | Measures | Relationships | Partitions | Hierarchies | Roles | Max rows | Segment used MB* |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 3 | 82 | 0 | 2 | 3 | 0 |  | 14477 | 0 |

| Complexity | Storage | Partition | Relationship | Static DAX | Overall |
|---:|---:|---:|---:|---:|---:|
| 37 | 22 | 17 | 31 | 0 | **22** |

## Model Complexity

Compatibility level: 1200. Calculated tables: 0; calculated columns detected in TMSL: 0. Complexity is interpreted relative to this 54-model fleet.

## Storage

| Top table/dimension storage structure | USED_SIZE MB | Maximum segment rows |
|---|---:|---:|
| DIM_DATE | 0 | 1461 |
| FactKecelakaanKerja | 0 | 14477 |
| DIM_REGION | 0 | 8 |

| Potential dictionary/cardinality review candidate | Dictionary MB |
|---|---:|
| FactKecelakaanKerja, DIAGNOSA_ICD10 | 0.016 |
| FactKecelakaanKerja, DIAGNOSA | 0.016 |
| FactKecelakaanKerja, TERAPI | 0.016 |
| FactKecelakaanKerja, JENIS_KECELAKAAN_KERJA | 0.016 |
| FactKecelakaanKerja, TIPE_PLAYANAN | 0.016 |
| FactKecelakaanKerja, ANAMANESIS | 0.016 |
| FactKecelakaanKerja, DIVISI | 0.016 |
| FactKecelakaanKerja, KEMANDORAN | 0.016 |

\* DMV accounting only; not authoritative resident model size. Column candidates require usage and actual cardinality validation.

## Partitions

3 metadata partitions across 3 tables. No fleet screening rule proves a partition defect. Partition-level size/statistics are unavailable.

## Relationships

2 total, 0 inactive, 0 bidirectional indicators and 0 possible many-to-many indicators. Runtime Formula Engine impact is **REQUIRES VALIDATION**.

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
