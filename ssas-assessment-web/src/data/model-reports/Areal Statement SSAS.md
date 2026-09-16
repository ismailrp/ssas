# Areal Statement SSAS - Technical Assessment

## Health Summary

**MEDIUM - 56/100.** Static fleet-relative prioritization; actual query and refresh performance are **NOT PROVABLE FROM CURRENT EVIDENCE**.

## Key Metrics and Risk Scores
# Areal Statement SSAS - Technical Assessment
| Tables | Columns | Measures | Relationships | Partitions | Hierarchies | Roles | Max rows | Segment used MB* |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 7 | 71 | 13 | 8 | 7 | 0 |  | 7574110 | 0.735 |

| Complexity | Storage | Partition | Relationship | Static DAX | Overall |
|---:|---:|---:|---:|---:|---:|
| 56 | 63 | 85 | 48 | 26 | **56** |

## Model Complexity

Compatibility level: 1200. Calculated tables: 0; calculated columns detected in TMSL: 2. Complexity is interpreted relative to this 54-model fleet.

## Storage

| Top table/dimension storage structure | USED_SIZE MB | Maximum segment rows |
|---|---:|---:|
| fact_areal_statement | 0.654 | 7574110 |
| DimDate | 0.079 | 1826 |
| dim_company | 0.001 | 43 |
| dim_mature | 0 | 2 |
| dim_inplas | 0 | 3 |
| dim_recon | 0 | 3 |
| fact_recon_areal_statement | 0 | 0 |

| Potential dictionary/cardinality review candidate | Dictionary MB |
|---|---:|
| DimDate, StandardDate | 1.046 |
| DimDate, LastDateOfMonth | 1.017 |
| fact_areal_statement, datesk | 1.017 |
| dim_company, company | 1.017 |
| dim_company, company_code | 1.017 |
| DimDate, DaySuffix | 1.016 |
| dim_recon, RECON | 1.016 |
| dim_mature, MATURED_DESC | 1.016 |

\* DMV accounting only; not authoritative resident model size. Column candidates require usage and actual cardinality validation.

## Partitions

7 metadata partitions across 7 tables. A large/lightly partitioned screening signal is present. Validate source date fields and refresh history before piloting time partitions.

## Relationships

8 total, 0 inactive, 0 bidirectional indicators and 0 possible many-to-many indicators. Runtime Formula Engine impact is **REQUIRES VALIDATION**.

## Measures / DAX

13 measures; 2 selected static pattern hits. Candidate measures: none by this narrow scan. This is STATIC DAX RISK, not proof of slowness.

## Security

 roles observed. Security effectiveness, membership, RLS selectivity and runtime cost are not fully provable from role metadata alone.

## Findings

### F-034 - Partitions

- **Severity / Classification / Confidence:** HIGH / INFERRED / MEDIUM
- **Observation:** Largest storage structure has 7,574,110 rows while metadata shows 7 partitions for 7 tables.
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
