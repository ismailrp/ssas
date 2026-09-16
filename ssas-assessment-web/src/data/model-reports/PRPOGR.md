# PRPOGR - Technical Assessment

## Health Summary

**MEDIUM - 47/100.** Static fleet-relative prioritization; actual query and refresh performance are **NOT PROVABLE FROM CURRENT EVIDENCE**.

## Key Metrics and Risk Scores
# PRPOGR - Technical Assessment
| Tables | Columns | Measures | Relationships | Partitions | Hierarchies | Roles | Max rows | Segment used MB* |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 2 | 99 | 15 |  | 2 | 0 |  | 1274014 | 0 |

| Complexity | Storage | Partition | Relationship | Static DAX | Overall |
|---:|---:|---:|---:|---:|---:|
| 47 | 40 | 85 | 19 | 50 | **47** |

## Model Complexity

Compatibility level: 1200. Calculated tables: 1; calculated columns detected in TMSL: 2. Complexity is interpreted relative to this 54-model fleet.

## Storage

| Top table/dimension storage structure | USED_SIZE MB | Maximum segment rows |
|---|---:|---:|
| Calendar | 0 | 2557 |
| fact_pr_po_gr_new | 0 | 1274014 |

| Potential dictionary/cardinality review candidate | Dictionary MB |
|---|---:|
| fact_pr_po_gr_new, No GR Central | 0.016 |
| fact_pr_po_gr_new, Tgl SJ Central | 0.016 |
| fact_pr_po_gr_new, No SJ PWK | 0.016 |
| fact_pr_po_gr_new, Tgl GR (SJ HO) di Central | 0.016 |
| fact_pr_po_gr_new, Unit | 0.016 |
| fact_pr_po_gr_new, Status Progress PR | 0.016 |
| fact_pr_po_gr_new, No SJ Central | 0.016 |
| fact_pr_po_gr_new, Tgl GR Unit/User | 0.016 |

\* DMV accounting only; not authoritative resident model size. Column candidates require usage and actual cardinality validation.

## Partitions

2 metadata partitions across 2 tables. A large/lightly partitioned screening signal is present. Validate source date fields and refresh history before piloting time partitions.

## Relationships

 total, 0 inactive, 1 bidirectional indicators and 0 possible many-to-many indicators. Runtime Formula Engine impact is **REQUIRES VALIDATION**.

## Measures / DAX

15 measures; 12 selected static pattern hits. Candidate measures: EndLastYear PO Release; GR Franco. This is STATIC DAX RISK, not proof of slowness.

## Security

 roles observed. Security effectiveness, membership, RLS selectivity and runtime cost are not fully provable from role metadata alone.

## Findings

### F-045 - Partitions

- **Severity / Classification / Confidence:** HIGH / INFERRED / MEDIUM
- **Observation:** Largest storage structure has 1,274,014 rows while metadata shows 2 partitions for 2 tables.
- **Evidence:** metadata/partitions.csv; storage/storage_tables.csv; model/database.tmsl.json
- **Analysis / Performance impact:** Full-table refresh may have avoidable processing duration and transaction footprint.
- **Recommendation:** Validate refresh history and date boundaries, then test time-based incremental partitions.
- **Expected benefit:** Smaller refresh scope and improved operational manageability.
- **Implementation effort:** HIGH
- **Validation:** Benchmark representative queries/refresh and verify semantic parity before production.


## Recommendations

Prioritize evidence collection, then address confirmed storage/partition/relationship/DAX hotspots. Treat apparent unused objects only as **CANDIDATE FOR USAGE VALIDATION**.

## Evidence Gaps

No historical query duration/CPU, FE/SE timing, peak concurrency, refresh duration, memory-pressure series or object usage telemetry.

## Deep-Dive Recommendation

**NO - retain in fleet monitoring unless runtime evidence elevates it**.
