# Harvesting Management Luas Panen - Technical Assessment

## Health Summary

**MEDIUM - 53/100.** Static fleet-relative prioritization; actual query and refresh performance are **NOT PROVABLE FROM CURRENT EVIDENCE**.

## Key Metrics and Risk Scores
# Harvesting Management Luas Panen - Technical Assessment
| Tables | Columns | Measures | Relationships | Partitions | Hierarchies | Roles | Max rows | Segment used MB* |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 3 | 59 | 98 | 2 | 3 | 0 |  | 1386014 | 0 |

| Complexity | Storage | Partition | Relationship | Static DAX | Overall |
|---:|---:|---:|---:|---:|---:|
| 49 | 37 | 85 | 31 | 77 | **53** |

## Model Complexity

Compatibility level: 1200. Calculated tables: 1; calculated columns detected in TMSL: 0. Complexity is interpreted relative to this 54-model fleet.

## Storage

| Top table/dimension storage structure | USED_SIZE MB | Maximum segment rows |
|---|---:|---:|
| Harvest Management Luas Panen Block | 0 | 1386014 |
| Calendar | 0 | 1096 |
| Harvest Management Luas Panen | 0 | 197030 |

| Potential dictionary/cardinality review candidate | Dictionary MB |
|---|---:|
| Harvest Management Luas Panen Block, REGION | 0.016 |
| Harvest Management Luas Panen Block, GROUP_REGION | 0.016 |
| Harvest Management Luas Panen Block, COMPANY | 0.016 |
| Harvest Management Luas Panen Block, AREA | 0.016 |
| Calendar, Month Name Short | 0.016 |
| Calendar, Day Name | 0.016 |
| Calendar, Year Month Name | 0.016 |
| Calendar, Month Name | 0.016 |

\* DMV accounting only; not authoritative resident model size. Column candidates require usage and actual cardinality validation.

## Partitions

3 metadata partitions across 3 tables. A large/lightly partitioned screening signal is present. Validate source date fields and refresh history before piloting time partitions.

## Relationships

2 total, 0 inactive, 0 bidirectional indicators and 0 possible many-to-many indicators. Runtime Formula Engine impact is **REQUIRES VALIDATION**.

## Measures / DAX

98 measures; 134 selected static pattern hits. Candidate measures: AREAL_MONTH_JAN; AREAL_MONTH_FEB; AREAL_MONTH_MAR; AREAL_MONTH_APR; AREAL_MONTH_MAY; AREAL_MONTH_JUN; AREAL_MONTH_JUL; AREAL_MONTH_AUG; AREAL_MONTH_SEP; AREAL_MONTH_OCT; AREAL_MONTH_NOV; AREAL_MONTH_DEC; PLANTED_AREA_MONTH_JAN; PLANTED_AREA_MONTH_FEB; PLANTED_AREA_MONTH_MAR; PLANTED_AREA_MONTH_APR; PLANTED_AREA_MONTH_MAY; PLANTED_AREA_MONTH_JUN; PLANTED_AREA_MONTH_JUL; PLANTED_AREA_MONTH_AUG; PLANTED_AREA_MONTH_SEP; PLANTED_AREA_MONTH_OCT; PLANTED_AREA_MONTH_NOV; PLANTED_AREA_MONTH_DEC; PUS_9_PLANTED_AREA_MONTH_JAN; PUS_9_PLANTED_AREA_MONTH_FEB; PUS_9_PLANTED_AREA_MONTH_MAR; PUS_9_PLANTED_AREA_MONTH_APR; PUS_9_PLANTED_AREA_MONTH_MAY; PUS_9_PLANTED_AREA_MONTH_JUN; PUS_9_PLANTED_AREA_MONTH_JUL; PUS_9_PLANTED_AREA_MONTH_AUG; PUS_9_PLANTED_AREA_MONTH_SEP; PUS_9_PLANTED_AREA_MONTH_OCT; PUS_9_PLANTED_AREA_MONTH_NOV; PUS_9_PLANTED_AREA_MONTH_DEC; HANCAK_TT_MONTH_JAN; HANCAK_TT_MONTH_FEB; HANCAK_TT_MONTH_MAR; HANCAK_TT_MONTH_APR; HANCAK_TT_MONTH_MAY; HANCAK_TT_MONTH_JUN; HANCAK_TT_MONTH_JUL; HANCAK_TT_MONTH_AUG; HANCAK_TT_MONTH_SEP; HANCAK_TT_MONTH_OCT; HANCAK_TT_MONTH_NOV; HANCAK_TT_MONTH_DEC. This is STATIC DAX RISK, not proof of slowness.

## Security

 roles observed. Security effectiveness, membership, RLS selectivity and runtime cost are not fully provable from role metadata alone.

## Findings

### F-037 - Partitions

- **Severity / Classification / Confidence:** HIGH / INFERRED / MEDIUM
- **Observation:** Largest storage structure has 1,386,014 rows while metadata shows 3 partitions for 3 tables.
- **Evidence:** metadata/partitions.csv; storage/storage_tables.csv; model/database.tmsl.json
- **Analysis / Performance impact:** Full-table refresh may have avoidable processing duration and transaction footprint.
- **Recommendation:** Validate refresh history and date boundaries, then test time-based incremental partitions.
- **Expected benefit:** Smaller refresh scope and improved operational manageability.
- **Implementation effort:** HIGH
- **Validation:** Benchmark representative queries/refresh and verify semantic parity before production.

### F-038 - DAX

- **Severity / Classification / Confidence:** MEDIUM / REQUIRES VALIDATION / MEDIUM
- **Observation:** Static scan found 134 selected risk-pattern occurrences; candidate measures: AREAL_MONTH_JAN; AREAL_MONTH_FEB; AREAL_MONTH_MAR; AREAL_MONTH_APR; AREAL_MONTH_MAY; AREAL_MONTH_JUN; AREAL_MONTH_JUL; AREAL_MONTH_AUG; AREAL_MONTH_SEP; AREAL_MONTH_OCT; AREAL_MONTH_NOV; AREAL_MONTH_DEC; PLANTED_AREA_MONTH_JAN; PLANTED_AREA_MONTH_FEB; PLANTED_AREA_MONTH_MAR; PLANTED_AREA_MONTH_APR; PLANTED_AREA_MONTH_MAY; PLANTED_AREA_MONTH_JUN; PLANTED_AREA_MONTH_JUL; PLANTED_AREA_MONTH_AUG; PLANTED_AREA_MONTH_SEP; PLANTED_AREA_MONTH_OCT; PLANTED_AREA_MONTH_NOV; PLANTED_AREA_MONTH_DEC; PUS_9_PLANTED_AREA_MONTH_JAN; PUS_9_PLANTED_AREA_MONTH_FEB; PUS_9_PLANTED_AREA_MONTH_MAR; PUS_9_PLANTED_AREA_MONTH_APR; PUS_9_PLANTED_AREA_MONTH_MAY; PUS_9_PLANTED_AREA_MONTH_JUN; PUS_9_PLANTED_AREA_MONTH_JUL; PUS_9_PLANTED_AREA_MONTH_AUG; PUS_9_PLANTED_AREA_MONTH_SEP; PUS_9_PLANTED_AREA_MONTH_OCT; PUS_9_PLANTED_AREA_MONTH_NOV; PUS_9_PLANTED_AREA_MONTH_DEC; HANCAK_TT_MONTH_JAN; HANCAK_TT_MONTH_FEB; HANCAK_TT_MONTH_MAR; HANCAK_TT_MONTH_APR; HANCAK_TT_MONTH_MAY; HANCAK_TT_MONTH_JUN; HANCAK_TT_MONTH_JUL; HANCAK_TT_MONTH_AUG; HANCAK_TT_MONTH_SEP; HANCAK_TT_MONTH_OCT; HANCAK_TT_MONTH_NOV; HANCAK_TT_MONTH_DEC.
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
