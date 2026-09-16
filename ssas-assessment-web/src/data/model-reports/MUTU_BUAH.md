# MUTU_BUAH - Technical Assessment

## Health Summary

**MEDIUM - 58/100.** Static fleet-relative prioritization; actual query and refresh performance are **NOT PROVABLE FROM CURRENT EVIDENCE**.

## Key Metrics and Risk Scores
# MUTU_BUAH - Technical Assessment
| Tables | Columns | Measures | Relationships | Partitions | Hierarchies | Roles | Max rows | Segment used MB* |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 2 | 44 | 145 |  | 2 | 0 |  | 1194173 | 26.847 |

| Complexity | Storage | Partition | Relationship | Static DAX | Overall |
|---:|---:|---:|---:|---:|---:|
| 40 | 73 | 85 | 9 | 80 | **58** |

## Model Complexity

Compatibility level: 1200. Calculated tables: 1; calculated columns detected in TMSL: 0. Complexity is interpreted relative to this 54-model fleet.

## Storage

| Top table/dimension storage structure | USED_SIZE MB | Maximum segment rows |
|---|---:|---:|
| FACT_DAYOPR_MUTU_BUAH | 26.813 | 1194173 |
| Calendar | 0.035 | 1826 |

| Potential dictionary/cardinality review candidate | Dictionary MB |
|---|---:|
| FACT_DAYOPR_MUTU_BUAH, UNIT | 1.02 |
| FACT_DAYOPR_MUTU_BUAH, UNIT_TYPE | 1.017 |
| Calendar, Year Month Name | 1.017 |
| Calendar, Day Name | 1.016 |
| Calendar, Day Name Short | 1.016 |
| Calendar, Month Name Short | 1.016 |
| Calendar, Month Name | 1.016 |
| FACT_DAYOPR_MUTU_BUAH, MONTH | 1.016 |

\* DMV accounting only; not authoritative resident model size. Column candidates require usage and actual cardinality validation.

## Partitions

2 metadata partitions across 2 tables. A large/lightly partitioned screening signal is present. Validate source date fields and refresh history before piloting time partitions.

## Relationships

 total, 0 inactive, 0 bidirectional indicators and 0 possible many-to-many indicators. Runtime Formula Engine impact is **REQUIRES VALIDATION**.

## Measures / DAX

145 measures; 200 selected static pattern hits. Candidate measures: RIPE_MONTH_JAN; RIPE_MONTH_FEB; RIPE_MONTH_MAR; RIPE_MONTH_APR; RIPE_MONTH_MAY; RIPE_MONTH_JUN; RIPE_MONTH_JUL; RIPE_MONTH_AUG; RIPE_MONTH_SEP; RIPE_MONTH_OCT; RIPE_MONTH_NOV; RIPE_MONTH_DEC; UNRIPE_MONTH_JAN; UNRIPE_MONTH_FEB; UNRIPE_MONTH_MAR; UNRIPE_MONTH_APR; UNRIPE_MONTH_MAY; UNRIPE_MONTH_JUN; UNRIPE_MONTH_JUL; UNRIPE_MONTH_AUG; UNRIPE_MONTH_SEP; UNRIPE_MONTH_OCT; UNRIPE_MONTH_NOV; UNRIPE_MONTH_DEC; UNDERRIPE_MONTH_JAN; UNDERRIPE_MONTH_FEB; UNDERRIPE_MONTH_MAR; UNDERRIPE_MONTH_APR; UNDERRIPE_MONTH_MAY; UNDERRIPE_MONTH_JUN; UNDERRIPE_MONTH_JUL; UNDERRIPE_MONTH_AUG; UNDERRIPE_MONTH_SEP; UNDERRIPE_MONTH_OCT; UNDERRIPE_MONTH_NOV; UNDERRIPE_MONTH_DEC; OVERRIPE_MONTH_JAN; OVERRIPE_MONTH_FEB; OVERRIPE_MONTH_MAR; OVERRIPE_MONTH_APR; OVERRIPE_MONTH_MAY; OVERRIPE_MONTH_JUN; OVERRIPE_MONTH_JUL; OVERRIPE_MONTH_AUG; OVERRIPE_MONTH_SEP; OVERRIPE_MONTH_OCT; OVERRIPE_MONTH_NOV; OVERRIPE_MONTH_DEC; BRONDOLAN_MONTH_JAN; BRONDOLAN_MONTH_FEB; BRONDOLAN_MONTH_MAR; BRONDOLAN_MONTH_APR; BRONDOLAN_MONTH_MAY; BRONDOLAN_MONTH_JUN; BRONDOLAN_MONTH_JUL; BRONDOLAN_MONTH_AUG; BRONDOLAN_MONTH_SEP; BRONDOLAN_MONTH_OCT; BRONDOLAN_MONTH_NOV; BRONDOLAN_MONTH_DEC; KONTAMINASI_MONTH_JAN; KONTAMINASI_MONTH_FEB; KONTAMINASI_MONTH_MAR; KONTAMINASI_MONTH_APR; KONTAMINASI_MONTH_MAY; KONTAMINASI_MONTH_JUN; KONTAMINASI_MONTH_JUL; KONTAMINASI_MONTH_AUG; KONTAMINASI_MONTH_SEP; KONTAMINASI_MONTH_OCT; KONTAMINASI_MONTH_NOV; KONTAMINASI_MONTH_DEC; TES_MONTLY_RIPE. This is STATIC DAX RISK, not proof of slowness.

## Security

 roles observed. Security effectiveness, membership, RLS selectivity and runtime cost are not fully provable from role metadata alone.

## Findings

### F-030 - Storage

- **Severity / Classification / Confidence:** HIGH / OBSERVED / HIGH
- **Observation:** Fleet-relative storage score 73; USED_SIZE 26.847 MB, dictionary 13.096 MB, maximum recorded storage-table rows 1,194,173.
- **Evidence:** storage/storage_column_segments.csv; storage/storage_table_columns.csv; storage/storage_tables.csv
- **Analysis / Performance impact:** Disproportionate encoded data increases capacity and scan exposure; actual query cost is not proven.
- **Recommendation:** Review top table/column consumers and remove or reshape only after dependency and usage validation.
- **Expected benefit:** Reduced model footprint and potentially faster scans/refresh.
- **Implementation effort:** MEDIUM
- **Validation:** Benchmark representative queries/refresh and verify semantic parity before production.

### F-031 - Partitions

- **Severity / Classification / Confidence:** HIGH / INFERRED / MEDIUM
- **Observation:** Largest storage structure has 1,194,173 rows while metadata shows 2 partitions for 2 tables.
- **Evidence:** metadata/partitions.csv; storage/storage_tables.csv; model/database.tmsl.json
- **Analysis / Performance impact:** Full-table refresh may have avoidable processing duration and transaction footprint.
- **Recommendation:** Validate refresh history and date boundaries, then test time-based incremental partitions.
- **Expected benefit:** Smaller refresh scope and improved operational manageability.
- **Implementation effort:** HIGH
- **Validation:** Benchmark representative queries/refresh and verify semantic parity before production.

### F-032 - DAX

- **Severity / Classification / Confidence:** MEDIUM / REQUIRES VALIDATION / MEDIUM
- **Observation:** Static scan found 200 selected risk-pattern occurrences; candidate measures: RIPE_MONTH_JAN; RIPE_MONTH_FEB; RIPE_MONTH_MAR; RIPE_MONTH_APR; RIPE_MONTH_MAY; RIPE_MONTH_JUN; RIPE_MONTH_JUL; RIPE_MONTH_AUG; RIPE_MONTH_SEP; RIPE_MONTH_OCT; RIPE_MONTH_NOV; RIPE_MONTH_DEC; UNRIPE_MONTH_JAN; UNRIPE_MONTH_FEB; UNRIPE_MONTH_MAR; UNRIPE_MONTH_APR; UNRIPE_MONTH_MAY; UNRIPE_MONTH_JUN; UNRIPE_MONTH_JUL; UNRIPE_MONTH_AUG; UNRIPE_MONTH_SEP; UNRIPE_MONTH_OCT; UNRIPE_MONTH_NOV; UNRIPE_MONTH_DEC; UNDERRIPE_MONTH_JAN; UNDERRIPE_MONTH_FEB; UNDERRIPE_MONTH_MAR; UNDERRIPE_MONTH_APR; UNDERRIPE_MONTH_MAY; UNDERRIPE_MONTH_JUN; UNDERRIPE_MONTH_JUL; UNDERRIPE_MONTH_AUG; UNDERRIPE_MONTH_SEP; UNDERRIPE_MONTH_OCT; UNDERRIPE_MONTH_NOV; UNDERRIPE_MONTH_DEC; OVERRIPE_MONTH_JAN; OVERRIPE_MONTH_FEB; OVERRIPE_MONTH_MAR; OVERRIPE_MONTH_APR; OVERRIPE_MONTH_MAY; OVERRIPE_MONTH_JUN; OVERRIPE_MONTH_JUL; OVERRIPE_MONTH_AUG; OVERRIPE_MONTH_SEP; OVERRIPE_MONTH_OCT; OVERRIPE_MONTH_NOV; OVERRIPE_MONTH_DEC; BRONDOLAN_MONTH_JAN; BRONDOLAN_MONTH_FEB; BRONDOLAN_MONTH_MAR; BRONDOLAN_MONTH_APR; BRONDOLAN_MONTH_MAY; BRONDOLAN_MONTH_JUN; BRONDOLAN_MONTH_JUL; BRONDOLAN_MONTH_AUG; BRONDOLAN_MONTH_SEP; BRONDOLAN_MONTH_OCT; BRONDOLAN_MONTH_NOV; BRONDOLAN_MONTH_DEC; KONTAMINASI_MONTH_JAN; KONTAMINASI_MONTH_FEB; KONTAMINASI_MONTH_MAR; KONTAMINASI_MONTH_APR; KONTAMINASI_MONTH_MAY; KONTAMINASI_MONTH_JUN; KONTAMINASI_MONTH_JUL; KONTAMINASI_MONTH_AUG; KONTAMINASI_MONTH_SEP; KONTAMINASI_MONTH_OCT; KONTAMINASI_MONTH_NOV; KONTAMINASI_MONTH_DEC; TES_MONTLY_RIPE.
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
