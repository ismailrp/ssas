# LKK Per Divisi - Technical Assessment

## Health Summary

**MEDIUM - 34/100.** Static fleet-relative prioritization; actual query and refresh performance are **NOT PROVABLE FROM CURRENT EVIDENCE**.

## Key Metrics and Risk Scores
# LKK Per Divisi - Technical Assessment
| Tables | Columns | Measures | Relationships | Partitions | Hierarchies | Roles | Max rows | Segment used MB* |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 2 | 43 | 10 |  | 2 | 0 |  | 154987 | 5.029 |

| Complexity | Storage | Partition | Relationship | Static DAX | Overall |
|---:|---:|---:|---:|---:|---:|
| 35 | 62 | 10 | 9 | 35 | **34** |

## Runtime Evidence

OBSERVED BUSINESS_CANDIDATE subset: 2 executions; total 14085 ms; P50/P95/P99 7/14078/14078 ms; max 14078 ms. Representativeness and root cause are REQUIRES VALIDATION. Evidence: REPORTS/07_RUNTIME_DATABASE_BASELINE.csv and REPORTS/08_RUNTIME_QUERY_HASH_BASELINE.csv.

## Model Complexity

Compatibility level: 1200. Calculated tables: 1; calculated columns detected in TMSL: 4. Complexity is interpreted relative to this 54-model fleet.

## Storage

| Top table/dimension storage structure | USED_SIZE MB | Maximum segment rows |
|---|---:|---:|
| FACT_LKK_BIAYA_UPAH_PANEN_PENGENDALIAN_GULMA | 4.995 | 154987 |
| Calender | 0.035 | 1826 |

| Potential dictionary/cardinality review candidate | Dictionary MB |
|---|---:|
| FACT_LKK_BIAYA_UPAH_PANEN_PENGENDALIAN_GULMA, VALUE_SDBI_ANGGARAN | 5.122 |
| FACT_LKK_BIAYA_UPAH_PANEN_PENGENDALIAN_GULMA, VALUE_SDBI_AKTUAL | 4.784 |
| FACT_LKK_BIAYA_UPAH_PANEN_PENGENDALIAN_GULMA, VALUE_AKTUAL | 4.767 |
| FACT_LKK_BIAYA_UPAH_PANEN_PENGENDALIAN_GULMA, VALUE_ANGGARAN | 4.645 |
| FACT_LKK_BIAYA_UPAH_PANEN_PENGENDALIAN_GULMA, UNIT_DIV | 1.018 |
| FACT_LKK_BIAYA_UPAH_PANEN_PENGENDALIAN_GULMA, UNITN | 1.017 |
| Calender, Year Month Name | 1.017 |
| Calender, Day Name Short | 1.016 |

\* DMV accounting only; not authoritative resident model size. Column candidates require usage and actual cardinality validation.

## Partitions

2 metadata partitions across 2 tables. No fleet screening rule proves a partition defect. Partition-level size/statistics are unavailable.

## Relationships

 total, 0 inactive, 0 bidirectional indicators and 0 possible many-to-many indicators. Runtime Formula Engine impact is **REQUIRES VALIDATION**.

## Measures / DAX

10 measures; 5 selected static pattern hits. Candidate measures: none by this narrow scan. This is STATIC DAX RISK, not proof of slowness.

## Security

 roles observed. Security effectiveness, membership, RLS selectivity and runtime cost are not fully provable from role metadata alone.

## Findings

No material fleet-outlier finding generated. This does not prove absence of runtime issues.

## Recommendations

Prioritize evidence collection, then address confirmed storage/partition/relationship/DAX hotspots. Treat apparent unused objects only as **CANDIDATE FOR USAGE VALIDATION**.

## Evidence Gaps

Representative workload, authoritative FE/SE timing, peak concurrency, refresh duration, memory-pressure series and object usage telemetry remain incomplete.

## Deep-Dive Recommendation

**NO - retain in fleet monitoring unless runtime evidence elevates it**.

