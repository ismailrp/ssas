# Selling Expenses - Technical Assessment

## Health Summary

**MEDIUM - 52/100.** Static fleet-relative prioritization; actual query and refresh performance are **NOT PROVABLE FROM CURRENT EVIDENCE**.

## Key Metrics and Risk Scores
# Selling Expenses - Technical Assessment
| Tables | Columns | Measures | Relationships | Partitions | Hierarchies | Roles | Max rows | Segment used MB* |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 10 | 81 | 154 | 10 | 10 | 0 | 0 | 2194 | 0.116 |

| Complexity | Storage | Partition | Relationship | Static DAX | Overall |
|---:|---:|---:|---:|---:|---:|
| 72 | 34 | 33 | 51 | 76 | **52** |

## Model Complexity

Compatibility level: 1200. Calculated tables: 0; calculated columns detected in TMSL: 3. Complexity is interpreted relative to this 54-model fleet.

## Storage

| Top table/dimension storage structure | USED_SIZE MB | Maximum segment rows |
|---|---:|---:|
| DIM_DATE | 0.091 | 2191 |
| FACT_SELLING_EXPENSES_CONTROL_ZSD | 0.006 | 536 |
| FACT_SELLING_EXPENSES_KOMPOSISI | 0.005 | 216 |
| FACT_SELLING_EXPENSES | 0.005 | 570 |
| FACT_SELLING_EXPENSES_TREND_QUARTER | 0.005 | 180 |
| FACT_SELLING_EXPENSES_TREND | 0.001 | 180 |
| DIM_REPORT_SELLING_EXPENSES | 0.001 | 43 |
| DIM_REPORT_SELLING_EXPENSES_CONTROL_ZDS | 0 | 11 |

| Potential dictionary/cardinality review candidate | Dictionary MB |
|---|---:|
| DIM_DATE, StandardDate | 1.049 |
| DIM_DATE, LastDateOfMonth | 1.017 |
| DIM_REPORT_SELLING_EXPENSES_TREND, Satuan | 1.016 |
| DIM_REPORT_SELLING_EXPENSES, Satuan | 1.016 |
| DIM_DATE, CalendarMonthName | 1.016 |
| DIM_REPORT_SELLING_EXPENSES_TREND, Dimensi | 1.016 |
| DIM_REPORT_SELLING_EXPENSES_CONTROL_ZDS, Dimensi ZSD2 | 1.016 |
| DIM_REPORT_SELLING_EXPENSES, Header | 1.016 |

\* DMV accounting only; not authoritative resident model size. Column candidates require usage and actual cardinality validation.

## Partitions

10 metadata partitions across 10 tables. No fleet screening rule proves a partition defect. Partition-level size/statistics are unavailable.

## Relationships

10 total, 0 inactive, 0 bidirectional indicators and 0 possible many-to-many indicators. Runtime Formula Engine impact is **REQUIRES VALIDATION**.

## Measures / DAX

154 measures; 257 selected static pattern hits. Candidate measures: Total Q1; Total Q2; Total Q3; Total Q4; Total H1; Total 9M; Total H2; Total H1 ZDS; Total Q1 ZDS; Total 9M ZDS; Total Q2 ZDS; Total H2 ZDS; Total Q3 ZDS; Total Q4 ZDS; Total Q1 Trend; Total Q2 Trend; Total Q3 Trend; Total Q4 Trend; Total H1 Trend; Total 9M Trend; Total H2 Trend; Total Q1 Komposisi Quantity; Total Q2 Komposisi Quantity; Total Q3 Komposisi Quantity; Total Q4 Komposisi Quantity; Total H1 Komposisi Quantity; Total 9M Komposisi Quantity; Total H2 Komposisi Quantity; Total Q1 Komposisi Quantity Filtered; Total Q2 Komposisi Quantity Filtered; Total Q3 Komposisi Quantity Filtered; Total Q4 Komposisi Quantity Filtered; Total H1 Komposisi Quantity Filtered; Total 9M Komposisi Quantity Filtered; Total H2 Komposisi Quantity Filtered; Total Q1 Quarter Amount; Total Q1 Quarter Quantity; Total Q1 Quarter Bal Consol; Total Q2 Quarter Amount; Total Q2 Quarter Quantity; Total Q2 Quarter Bal Consol; Total Q3 Quarter Amount; Total Q3 Quarter Quantity; Total Q3 Quarter Bal Consol; Total Q4 Quarter Amount; Total Q4 Quarter Quantity; Total Q4 Quarter Bal Consol; Total H1 Quarter Amount; Total H1 Quarter Quantity; Total H1 Quarter Bal Consol; Total 9M Quarter Amount; Total 9M Quarter Quantity; Total 9M Quarter Bal Consol; Total H2 Quarter Amount; Total H2 Quarter Quantity; Total H2 Quarter Bal Consol. This is STATIC DAX RISK, not proof of slowness.

## Security

0 roles observed. Security effectiveness, membership, RLS selectivity and runtime cost are not fully provable from role metadata alone.

## Findings

### F-039 - DAX

- **Severity / Classification / Confidence:** MEDIUM / REQUIRES VALIDATION / MEDIUM
- **Observation:** Static scan found 257 selected risk-pattern occurrences; candidate measures: Total Q1; Total Q2; Total Q3; Total Q4; Total H1; Total 9M; Total H2; Total H1 ZDS; Total Q1 ZDS; Total 9M ZDS; Total Q2 ZDS; Total H2 ZDS; Total Q3 ZDS; Total Q4 ZDS; Total Q1 Trend; Total Q2 Trend; Total Q3 Trend; Total Q4 Trend; Total H1 Trend; Total 9M Trend; Total H2 Trend; Total Q1 Komposisi Quantity; Total Q2 Komposisi Quantity; Total Q3 Komposisi Quantity; Total Q4 Komposisi Quantity; Total H1 Komposisi Quantity; Total 9M Komposisi Quantity; Total H2 Komposisi Quantity; Total Q1 Komposisi Quantity Filtered; Total Q2 Komposisi Quantity Filtered; Total Q3 Komposisi Quantity Filtered; Total Q4 Komposisi Quantity Filtered; Total H1 Komposisi Quantity Filtered; Total 9M Komposisi Quantity Filtered; Total H2 Komposisi Quantity Filtered; Total Q1 Quarter Amount; Total Q1 Quarter Quantity; Total Q1 Quarter Bal Consol; Total Q2 Quarter Amount; Total Q2 Quarter Quantity; Total Q2 Quarter Bal Consol; Total Q3 Quarter Amount; Total Q3 Quarter Quantity; Total Q3 Quarter Bal Consol; Total Q4 Quarter Amount; Total Q4 Quarter Quantity; Total Q4 Quarter Bal Consol; Total H1 Quarter Amount; Total H1 Quarter Quantity; Total H1 Quarter Bal Consol; Total 9M Quarter Amount; Total 9M Quarter Quantity; Total 9M Quarter Bal Consol; Total H2 Quarter Amount; Total H2 Quarter Quantity; Total H2 Quarter Bal Consol.
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
