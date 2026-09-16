# Harvesting Management TK Panen - Technical Assessment

## Health Summary

**MEDIUM - 30/100.** Static fleet-relative prioritization; actual query and refresh performance are **NOT PROVABLE FROM CURRENT EVIDENCE**.

## Key Metrics and Risk Scores
# Harvesting Management TK Panen - Technical Assessment
| Tables | Columns | Measures | Relationships | Partitions | Hierarchies | Roles | Max rows | Segment used MB* |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 2 | 44 | 96 |  | 2 | 0 |  | 40198 | 0 |

| Complexity | Storage | Partition | Relationship | Static DAX | Overall |
|---:|---:|---:|---:|---:|---:|
| 39 | 19 | 10 | 9 | 76 | **30** |

## Model Complexity

Compatibility level: 1200. Calculated tables: 1; calculated columns detected in TMSL: 0. Complexity is interpreted relative to this 54-model fleet.

## Storage

| Top table/dimension storage structure | USED_SIZE MB | Maximum segment rows |
|---|---:|---:|
| Calendar | 0 | 1096 |
| HARVESTING_MANAGEMENT_TK_PANEN | 0 | 40198 |

| Potential dictionary/cardinality review candidate | Dictionary MB |
|---|---:|
| HARVESTING_MANAGEMENT_TK_PANEN, DAY_NAME | 0.016 |
| Calendar, Year Month Name | 0.016 |
| HARVESTING_MANAGEMENT_TK_PANEN, UNIT_TYPE | 0.016 |
| HARVESTING_MANAGEMENT_TK_PANEN, FLAG_DAYOFF | 0.016 |
| HARVESTING_MANAGEMENT_TK_PANEN, UNIT | 0.016 |
| Calendar, Month Name | 0.016 |
| Calendar, Month Name Short | 0.016 |
| Calendar, Day Name Short | 0.016 |

\* DMV accounting only; not authoritative resident model size. Column candidates require usage and actual cardinality validation.

## Partitions

2 metadata partitions across 2 tables. No fleet screening rule proves a partition defect. Partition-level size/statistics are unavailable.

## Relationships

 total, 0 inactive, 0 bidirectional indicators and 0 possible many-to-many indicators. Runtime Formula Engine impact is **REQUIRES VALIDATION**.

## Measures / DAX

96 measures; 132 selected static pattern hits. Candidate measures: PROPORSI_TK_MONTH_JAN; PROPORSI_TK_MONTH_FEB; PROPORSI_TK_MONTH_MAR; PROPORSI_TK_MONTH_APR; PROPORSI_TK_MONTH_MAY; PROPORSI_TK_MONTH_JUN; PROPORSI_TK_MONTH_JUL; PROPORSI_TK_MONTH_AUG; PROPORSI_TK_MONTH_SEP; PROPORSI_TK_MONTH_OCT; PROPORSI_TK_MONTH_NOV; PROPORSI_TK_MONTH_DEC; OUTPUT_MONTH_JAN; OUTPUT_MONTH_FEB; OUTPUT_MONTH_MAR; OUTPUT_MONTH_APR; OUTPUT_MONTH_MAY; OUTPUT_MONTH_JUN; OUTPUT_MONTH_JUL; OUTPUT_MONTH_AUG; OUTPUT_MONTH_SEP; OUTPUT_MONTH_OCT; OUTPUT_MONTH_NOV; OUTPUT_MONTH_DEC; JUMLAH_TK_MONTH_JAN; JUMLAH_TK_MONTH_FEB; JUMLAH_TK_MONTH_MAR; JUMLAH_TK_MONTH_APR; JUMLAH_TK_MONTH_MAY; JUMLAH_TK_MONTH_JUN; JUMLAH_TK_MONTH_JUL; JUMLAH_TK_MONTH_AUG; JUMLAH_TK_MONTH_SEP; JUMLAH_TK_MONTH_OCT; JUMLAH_TK_MONTH_NOV; JUMLAH_TK_MONTH_DEC; KEHADIRAN_MONTH_JAN; KEHADIRAN_MONTH_FEB; KEHADIRAN_MONTH_MAR; KEHADIRAN_MONTH_APR; KEHADIRAN_MONTH_MAY; KEHADIRAN_MONTH_JUN; KEHADIRAN_MONTH_JUL; KEHADIRAN_MONTH_AUG; KEHADIRAN_MONTH_SEP; KEHADIRAN_MONTH_OCT; KEHADIRAN_MONTH_NOV; KEHADIRAN_MONTH_DEC. This is STATIC DAX RISK, not proof of slowness.

## Security

 roles observed. Security effectiveness, membership, RLS selectivity and runtime cost are not fully provable from role metadata alone.

## Findings

### F-050 - DAX

- **Severity / Classification / Confidence:** MEDIUM / REQUIRES VALIDATION / MEDIUM
- **Observation:** Static scan found 132 selected risk-pattern occurrences; candidate measures: PROPORSI_TK_MONTH_JAN; PROPORSI_TK_MONTH_FEB; PROPORSI_TK_MONTH_MAR; PROPORSI_TK_MONTH_APR; PROPORSI_TK_MONTH_MAY; PROPORSI_TK_MONTH_JUN; PROPORSI_TK_MONTH_JUL; PROPORSI_TK_MONTH_AUG; PROPORSI_TK_MONTH_SEP; PROPORSI_TK_MONTH_OCT; PROPORSI_TK_MONTH_NOV; PROPORSI_TK_MONTH_DEC; OUTPUT_MONTH_JAN; OUTPUT_MONTH_FEB; OUTPUT_MONTH_MAR; OUTPUT_MONTH_APR; OUTPUT_MONTH_MAY; OUTPUT_MONTH_JUN; OUTPUT_MONTH_JUL; OUTPUT_MONTH_AUG; OUTPUT_MONTH_SEP; OUTPUT_MONTH_OCT; OUTPUT_MONTH_NOV; OUTPUT_MONTH_DEC; JUMLAH_TK_MONTH_JAN; JUMLAH_TK_MONTH_FEB; JUMLAH_TK_MONTH_MAR; JUMLAH_TK_MONTH_APR; JUMLAH_TK_MONTH_MAY; JUMLAH_TK_MONTH_JUN; JUMLAH_TK_MONTH_JUL; JUMLAH_TK_MONTH_AUG; JUMLAH_TK_MONTH_SEP; JUMLAH_TK_MONTH_OCT; JUMLAH_TK_MONTH_NOV; JUMLAH_TK_MONTH_DEC; KEHADIRAN_MONTH_JAN; KEHADIRAN_MONTH_FEB; KEHADIRAN_MONTH_MAR; KEHADIRAN_MONTH_APR; KEHADIRAN_MONTH_MAY; KEHADIRAN_MONTH_JUN; KEHADIRAN_MONTH_JUL; KEHADIRAN_MONTH_AUG; KEHADIRAN_MONTH_SEP; KEHADIRAN_MONTH_OCT; KEHADIRAN_MONTH_NOV; KEHADIRAN_MONTH_DEC.
- **Evidence:** metadata/measures.csv; model/database.tmsl.json
- **Analysis / Performance impact:** Iterator/context-transition patterns may increase Formula Engine work; syntax alone does not prove slowness.
- **Recommendation:** Capture representative query plans and Server Timings; refactor only measured hotspots using reusable base measures or reduced iterator input.
- **Expected benefit:** Potentially lower CPU and latency for confirmed hotspots.
- **Implementation effort:** MEDIUM
- **Validation:** Benchmark representative queries/refresh and verify semantic parity before production.


## Recommendations

Prioritize evidence collection, then address confirmed storage/partition/relationship/DAX hotspots. Treat apparent unused objects only as **CANDIDATE FOR USAGE VALIDATION**.

## Evidence Gaps

No historical query duration/CPU, FE/SE timing, peak concurrency, refresh duration, memory-pressure series or object usage telemetry.

## Deep-Dive Recommendation

**NO - retain in fleet monitoring unless runtime evidence elevates it**.
