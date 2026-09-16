# LKK_DEV - Technical Assessment

## Health Summary

**MEDIUM - 55/100.** Static fleet-relative prioritization; actual query and refresh performance are **NOT PROVABLE FROM CURRENT EVIDENCE**.

## Key Metrics and Risk Scores
# LKK_DEV - Technical Assessment
| Tables | Columns | Measures | Relationships | Partitions | Hierarchies | Roles | Max rows | Segment used MB* |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 11 | 174 | 35 | 11 | 11 | 0 |  | 835416 | 0 |

| Complexity | Storage | Partition | Relationship | Static DAX | Overall |
|---:|---:|---:|---:|---:|---:|
| 84 | 37 | 35 | 52 | 71 | **55** |

## Model Complexity

Compatibility level: 1200. Calculated tables: 1; calculated columns detected in TMSL: 10. Complexity is interpreted relative to this 54-model fleet.

## Storage

| Top table/dimension storage structure | USED_SIZE MB | Maximum segment rows |
|---|---:|---:|
| Map Unit | 0 | 121 |
| Biaya Umum Detail HO | 0 | 627339 |
| Session Access | 0 | 3565 |
| DIM_REGION | 0 | 14 |
| USER_METRICS | 0 | 12237 |
| Biaya Tanaman Detail HO | 0 | 495929 |
| Biaya Kapital Non Tanaman | 0 | 835416 |
| Calendar | 0 | 2191 |

| Potential dictionary/cardinality review candidate | Dictionary MB |
|---|---:|
| Biaya Tanaman Detail, REGION | 0.016 |
| Biaya Tanaman Detail, PERUSAHAAN | 0.016 |
| Biaya Tanaman Detail, MONTH_NAME | 0.016 |
| Biaya Umum Detail HO, ACTV_LEVEL1 | 0.016 |
| Biaya Tanaman Detail, DESC_WILAYAH | 0.016 |
| Biaya Tanaman Detail, CATEGORY_DESC | 0.016 |
| Biaya Umum Detail HO, INPLS | 0.016 |
| Biaya Umum Detail, DESC_WILAYAH | 0.016 |

\* DMV accounting only; not authoritative resident model size. Column candidates require usage and actual cardinality validation.

## Partitions

11 metadata partitions across 11 tables. No fleet screening rule proves a partition defect. Partition-level size/statistics are unavailable.

## Relationships

11 total, 0 inactive, 0 bidirectional indicators and 0 possible many-to-many indicators. Runtime Formula Engine impact is **REQUIRES VALIDATION**.

## Measures / DAX

35 measures; 48 selected static pattern hits. Candidate measures: BKNT_AKTUAL_SDBI_AS; BKNT_ANGGARAN_SDBI_AS; BTD_ANGGARAN_SDBI; BTD_AKTUAL_SDBI; BTD_ANGGARAN_BI; BTD_AKTUAL_BI; BTD_SDBI; BUD_ANGGARAN_SDBI; BUD_ANGGARAN_BI; BUD_AKTUAL_SDBI; BUD_AKTUAL_BI; BTD_HO_ANGGARAN_SDBI; BTD_HO_ANGGARAN_BI; BTD_HO_AKTUAL_SDBI; BTD_HO_AKTUAL_BI; BUD_HO_ANGGARAN_SDBI; BUD_HO_ANGGARAN_BI; BUD_HO_AKTUAL_SDBI; BUD_HO_AKTUAL_BI. This is STATIC DAX RISK, not proof of slowness.

## Security

 roles observed. Security effectiveness, membership, RLS selectivity and runtime cost are not fully provable from role metadata alone.

## Findings

### F-035 - DAX

- **Severity / Classification / Confidence:** MEDIUM / REQUIRES VALIDATION / MEDIUM
- **Observation:** Static scan found 48 selected risk-pattern occurrences; candidate measures: BKNT_AKTUAL_SDBI_AS; BKNT_ANGGARAN_SDBI_AS; BTD_ANGGARAN_SDBI; BTD_AKTUAL_SDBI; BTD_ANGGARAN_BI; BTD_AKTUAL_BI; BTD_SDBI; BUD_ANGGARAN_SDBI; BUD_ANGGARAN_BI; BUD_AKTUAL_SDBI; BUD_AKTUAL_BI; BTD_HO_ANGGARAN_SDBI; BTD_HO_ANGGARAN_BI; BTD_HO_AKTUAL_SDBI; BTD_HO_AKTUAL_BI; BUD_HO_ANGGARAN_SDBI; BUD_HO_ANGGARAN_BI; BUD_HO_AKTUAL_SDBI; BUD_HO_AKTUAL_BI.
- **Evidence:** metadata/measures.csv; model/database.tmsl.json
- **Analysis / Performance impact:** Iterator/context-transition patterns may increase Formula Engine work; syntax alone does not prove slowness.
- **Recommendation:** Capture representative query plans and Server Timings; refactor only measured hotspots using reusable base measures or reduced iterator input.
- **Expected benefit:** Potentially lower CPU and latency for confirmed hotspots.
- **Implementation effort:** MEDIUM
- **Validation:** Benchmark representative queries/refresh and verify semantic parity before production.

### F-036 - Model Complexity

- **Severity / Classification / Confidence:** MEDIUM / OBSERVED / HIGH
- **Observation:** 11 tables, 174 columns, 35 measures; fleet-relative complexity score 84.
- **Evidence:** metadata/tables.csv; metadata/columns.csv; metadata/measures.csv
- **Analysis / Performance impact:** Broad models increase metadata, refresh, usability, and optimization surface.
- **Recommendation:** Inventory report dependencies and label low-value columns as CANDIDATE FOR USAGE VALIDATION before removal.
- **Expected benefit:** Smaller semantic surface and possible storage/refresh reduction.
- **Implementation effort:** MEDIUM
- **Validation:** Benchmark representative queries/refresh and verify semantic parity before production.


## Recommendations

Prioritize evidence collection, then address confirmed storage/partition/relationship/DAX hotspots. Treat apparent unused objects only as **CANDIDATE FOR USAGE VALIDATION**.

## Evidence Gaps

No historical query duration/CPU, FE/SE timing, peak concurrency, refresh duration, memory-pressure series or object usage telemetry.

## Deep-Dive Recommendation

**NO - retain in fleet monitoring unless runtime evidence elevates it**.
