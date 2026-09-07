param([string]$EvidenceRoot = (Join-Path $PSScriptRoot 'evidence\EVSET-001'))
$ErrorActionPreference = 'Stop'
$inv = [Globalization.CultureInfo]::InvariantCulture
$reportRoot = Join-Path $EvidenceRoot 'REPORTS'
$dbReportRoot = Join-Path $reportRoot 'DATABASES'
New-Item -ItemType Directory -Force -Path $dbReportRoot | Out-Null

function Csv($p) { if (Test-Path -LiteralPath $p) { @(Import-Csv -LiteralPath $p) } else { @() } }
function N($v) { $x=0.0; if ([double]::TryParse([string]$v,[Globalization.NumberStyles]::Any,$inv,[ref]$x)){$x}else{0} }
function Q($s) { '"' + ([string]$s).Replace('"','""').Replace("`r",' ').Replace("`n",' ') + '"' }
function EscapeMd($s) { ([string]$s).Replace('|','\|').Replace("`r",' ').Replace("`n",' ') }
function SafeName($s) { [string]::Join('_',([string]$s).Split([IO.Path]::GetInvalidFileNameChars())) }
function PercentileRank($arr,$value) { if($arr.Count -le 1){return 50}; [math]::Round(100*(($arr|Where-Object{$_ -lt $value}).Count + .5*($arr|Where-Object{$_ -eq $value}).Count)/$arr.Count,1) }
function RiskLevel($s) { if($s-ge 80){'CRITICAL'}elseif($s-ge 60){'HIGH'}elseif($s-ge 30){'MEDIUM'}else{'LOW'} }
function Pri($s) { if($s-ge 80){'P0'}elseif($s-ge 60){'P1'}elseif($s-ge 30){'P2'}else{'P3'} }
function StatusClass($rows,$artifact) {
  $x=@($rows|Where-Object Artifact -eq $artifact)
  if(!$x){return 'MISSING'}
  if($x.Status -contains 'SUCCESS' -or $x.Status -contains 'SUCCESS_EMPTY'){return 'COMPLETE'}
  if($x.Status -contains 'QUERY_FAILED_OR_UNSUPPORTED'){return 'UNSUPPORTED'}
  if($x.Status -contains 'SKIPPED'){return 'SKIPPED'}
  'PARTIAL'
}

$manifest=Csv (Join-Path $EvidenceRoot 'MANIFEST\collection_manifest.csv')
$dbList=Csv (Join-Path $EvidenceRoot 'MANIFEST\databases.csv')
$models=@()
foreach($d in $dbList){
  $name=$d.Database; $dir=Join-Path (Join-Path $EvidenceRoot $d.ServerType) $name
  $meta=Join-Path $dir 'metadata'; $stor=Join-Path $dir 'storage'
  $tables=Csv (Join-Path $meta 'tables.csv'); $cols=Csv (Join-Path $meta 'columns.csv'); $meas=Csv (Join-Path $meta 'measures.csv')
  $rels=Csv (Join-Path $meta 'relationships.csv'); $parts=Csv (Join-Path $meta 'partitions.csv'); $hiers=Csv (Join-Path $meta 'hierarchies.csv'); $roles=Csv (Join-Path $meta 'roles.csv')
  $segs=Csv (Join-Path $stor 'storage_column_segments.csv'); $stc=Csv (Join-Path $stor 'storage_table_columns.csv'); $sts=Csv (Join-Path $stor 'storage_tables.csv')
  $tmslPath=Join-Path $dir 'model\database.tmsl.json'; $compat=''; $calcCols=0; $calcTables=0
  if(Test-Path -LiteralPath $tmslPath){ try{$j=Get-Content -Raw -LiteralPath $tmslPath|ConvertFrom-Json; $model=$j.createOrReplace.database.model; $compat=$j.createOrReplace.database.compatibilityLevel; $calcTables=@($model.tables|Where-Object{$_.partitions.source.type -eq 'calculated'}).Count; $calcCols=@($model.tables.columns|Where-Object{$null-ne$_.expression}).Count}catch{} }
  $used=[math]::Round((($segs|Measure-Object USED_SIZE -Sum).Sum/1MB),3)
  $alloc=[math]::Round((($segs|Measure-Object ALLOCATED_SIZE -Sum).Sum/1MB),3)
  $dict=[math]::Round((($stc|Measure-Object DICTIONARY_SIZE -Sum).Sum/1MB),3)
  $maxRows=[long](($sts|Measure-Object ROWS_COUNT -Maximum).Maximum)
  $inactive=@($rels|Where-Object IsActive -ne 'True').Count
  $bidir=@($rels|Where-Object{ $_.CrossFilteringBehavior -notin @('1','OneDirection','') }).Count
  $m2m=@($rels|Where-Object{ $_.FromCardinality -eq '2' -and $_.ToCardinality -eq '2' }).Count
  $expr=($meas.Expression -join "`n"); $tokens=@('FILTER','SUMX','AVERAGEX','COUNTX','DISTINCTCOUNT','CALCULATE','CALCULATETABLE','ALLSELECTED','CROSSJOIN','GENERATE','RANKX','SWITCH')
  $hits=0; $risky=@(); foreach($m in $meas){$h=0;foreach($tok in $tokens){$h+=([regex]::Matches([string]$m.Expression,"(?i)\b$tok\s*\(")).Count};if($h-ge 2){$risky+=$m.Name};$hits+=$h}
  $singleLarge=($maxRows-ge 1000000 -and $parts.Count -le $tables.Count)
  $models += [pscustomobject]@{Database=$name;ModelType=$d.ServerType;CompatibilityLevel=$compat;TableCount=$tables.Count;ColumnCount=$cols.Count;MeasureCount=$meas.Count;RelationshipCount=$rels.Count;PartitionCount=$parts.Count;HierarchyCount=$hiers.Count;RoleCount=$roles.Count;UsedMB=$used;AllocatedMB=$alloc;DictionaryMB=$dict;MaxRows=$maxRows;InactiveRelationships=$inactive;BidirectionalRelationships=$bidir;ManyToManyRelationships=$m2m;CalculatedColumns=$calcCols;CalculatedTables=$calcTables;DAXPatternHits=$hits;RiskyMeasures=($risky -join '; ');SinglePartitionLarge=$singleLarge;Dir=$dir;Manifest=@($manifest|Where-Object Database -eq $name)}
}

# Fleet-relative category scores. Storage is based on supported USED_SIZE plus dictionary and row-count ranks.
$metrics=@('TableCount','ColumnCount','MeasureCount','RelationshipCount','PartitionCount','UsedMB','DictionaryMB','MaxRows','DAXPatternHits')
foreach($m in $models){
  foreach($x in $metrics){$m|Add-Member -Force NoteProperty ("P_$x") (PercentileRank @($models.$x) $m.$x)}
  $complex=[math]::Round(.35*$m.P_TableCount+.35*$m.P_ColumnCount+.2*$m.P_MeasureCount+.1*(PercentileRank @($models.CalculatedColumns) $m.CalculatedColumns))
  $storage=[math]::Round(.45*$m.P_UsedMB+.25*$m.P_DictionaryMB+.3*$m.P_MaxRows)
  $partBase=if($m.SinglePartitionLarge){85}elseif($m.PartitionCount -gt 2*$m.TableCount){70}elseif($m.PartitionCount -eq 0){50}else{[math]::Min(55,[math]::Round($m.P_PartitionCount*.45))}
  $relationship=[math]::Round(.7*$m.P_RelationshipCount + [math]::Min(30,10*$m.BidirectionalRelationships+10*$m.ManyToManyRelationships))
  $dax=if($m.MeasureCount-eq 0){0}else{[math]::Min(100,[math]::Round(.65*$m.P_DAXPatternHits+.35*(100*$m.RiskyMeasures.Split(';',[StringSplitOptions]::RemoveEmptyEntries).Count/[math]::Max(1,$m.MeasureCount))))}
  # Operational category is unavailable per database; weights renormalized across five evidenced dimensions (22.22/27.78/16.67/16.67/16.67).
  $overall=[math]::Round(.2222*$complex+.2778*$storage+.1667*$partBase+.1667*$relationship+.1667*$dax)
  $m|Add-Member NoteProperty ComplexityScore $complex; $m|Add-Member NoteProperty StorageScore $storage; $m|Add-Member NoteProperty PartitionScore $partBase; $m|Add-Member NoteProperty RelationshipScore $relationship; $m|Add-Member NoteProperty DAXRiskScore $dax; $m|Add-Member NoteProperty OverallScore $overall; $m|Add-Member NoteProperty RiskLevel (RiskLevel $overall); $m|Add-Member NoteProperty Priority (Pri $overall)
}
$ranked=@($models|Sort-Object OverallScore -Descending); $deep=@($ranked|Select-Object -First ([math]::Min(8,$ranked.Count)))
foreach($m in $models){$m|Add-Member NoteProperty DeepDiveRecommended ($deep.Database -contains $m.Database)}
$fleetScore=[math]::Round(($models.OverallScore|Measure-Object -Average).Average); $fleetRisk=RiskLevel $fleetScore

$scoreHeaders='Database','ModelType','CompatibilityLevel','TableCount','ColumnCount','MeasureCount','RelationshipCount','PartitionCount','HierarchyCount','RoleCount','UsedMB','AllocatedMB','DictionaryMB','MaxRows','InactiveRelationships','BidirectionalRelationships','ManyToManyRelationships','CalculatedColumns','CalculatedTables','DAXPatternHits','OverallScore','RiskLevel','ComplexityScore','StorageScore','PartitionScore','RelationshipScore','DAXRiskScore','Priority','DeepDiveRecommended'
$models|Select-Object $scoreHeaders|Sort-Object OverallScore -Descending|Export-Csv -NoTypeInformation -Encoding UTF8 (Join-Path $reportRoot '02_FLEET_SCORECARD.csv')

$findings=New-Object Collections.Generic.List[object]; $fid=0
function AddFinding($m,$cat,$sev,$class,$conf,$obs,$impact,$rec,$benefit,$effort,$priority,$files){$script:fid++;$script:findings.Add([pscustomobject]@{FindingID=('F-{0:D3}'-f$script:fid);Database=$m.Database;Category=$cat;Severity=$sev;Classification=$class;Confidence=$conf;Observation=$obs;Impact=$impact;Recommendation=$rec;ExpectedBenefit=$benefit;Effort=$effort;Priority=$priority;EvidenceFiles=$files})}
foreach($m in $ranked){
  if($m.StorageScore-ge 70){AddFinding $m 'Storage' 'HIGH' 'OBSERVED' 'HIGH' ("Fleet-relative storage score {0}; USED_SIZE {1} MB, dictionary {2} MB, maximum recorded storage-table rows {3:N0}."-f$m.StorageScore,$m.UsedMB,$m.DictionaryMB,$m.MaxRows) 'Disproportionate encoded data increases capacity and scan exposure; actual query cost is not proven.' 'Review top table/column consumers and remove or reshape only after dependency and usage validation.' 'Reduced model footprint and potentially faster scans/refresh.' 'MEDIUM' 'P1' 'storage/storage_column_segments.csv; storage/storage_table_columns.csv; storage/storage_tables.csv'}
  if($m.SinglePartitionLarge){AddFinding $m 'Partitions' 'HIGH' 'INFERRED' 'MEDIUM' ("Largest storage structure has {0:N0} rows while metadata shows {1} partitions for {2} tables."-f$m.MaxRows,$m.PartitionCount,$m.TableCount) 'Full-table refresh may have avoidable processing duration and transaction footprint.' 'Validate refresh history and date boundaries, then test time-based incremental partitions.' 'Smaller refresh scope and improved operational manageability.' 'HIGH' 'P1' 'metadata/partitions.csv; storage/storage_tables.csv; model/database.tmsl.json'}
  if($m.RelationshipScore-ge 70){AddFinding $m 'Relationships' 'MEDIUM' 'REQUIRES VALIDATION' 'MEDIUM' ("{0} relationships ({1} inactive, {2} bidirectional indicators, {3} possible many-to-many), fleet-relative score {4}."-f$m.RelationshipCount,$m.InactiveRelationships,$m.BidirectionalRelationships,$m.ManyToManyRelationships,$m.RelationshipScore) 'Complex propagation can increase DAX/Formula Engine work and maintenance risk, but runtime effect is unmeasured.' 'Diagram cardinality/filter paths; validate ambiguous paths and constrain bidirectional filters where business semantics permit.' 'Simpler filter propagation and more predictable calculations.' 'MEDIUM' 'P2' 'metadata/relationships.csv; model/database.tmsl.json'}
  if($m.DAXRiskScore-ge 65){AddFinding $m 'DAX' 'MEDIUM' 'REQUIRES VALIDATION' 'MEDIUM' ("Static scan found {0} selected risk-pattern occurrences; candidate measures: {1}."-f$m.DAXPatternHits,($(if($m.RiskyMeasures){$m.RiskyMeasures}else{'none identified'}))) 'Iterator/context-transition patterns may increase Formula Engine work; syntax alone does not prove slowness.' 'Capture representative query plans and Server Timings; refactor only measured hotspots using reusable base measures or reduced iterator input.' 'Potentially lower CPU and latency for confirmed hotspots.' 'MEDIUM' 'P2' 'metadata/measures.csv; model/database.tmsl.json'}
  if($m.ComplexityScore-ge 80){AddFinding $m 'Model Complexity' 'MEDIUM' 'OBSERVED' 'HIGH' ("{0} tables, {1} columns, {2} measures; fleet-relative complexity score {3}."-f$m.TableCount,$m.ColumnCount,$m.MeasureCount,$m.ComplexityScore) 'Broad models increase metadata, refresh, usability, and optimization surface.' 'Inventory report dependencies and label low-value columns as CANDIDATE FOR USAGE VALIDATION before removal.' 'Smaller semantic surface and possible storage/refresh reduction.' 'MEDIUM' 'P2' 'metadata/tables.csv; metadata/columns.csv; metadata/measures.csv'}
}
$findings|Export-Csv -NoTypeInformation -Encoding UTF8 (Join-Path $reportRoot '04_FINDINGS.csv')

$status=$manifest|Group-Object Status|Sort-Object Name
$coverage=@(
  @('Database inventory','COMPLETE','All 54 selected databases are represented by manifest/database inventory.'),
  @('Tabular metadata','COMPLETE','Tables, columns, measures, relationships, partitions, roles and hierarchy rowsets succeeded or succeeded empty.'),
  @('TMSL model definitions',(StatusClass $manifest 'database.tmsl.json'),'Cross-check supports model structure, expressions and compatibility analysis.'),
  @('VertiPaq storage','COMPLETE','Storage tables, columns and segments succeeded; values are DMV accounting, not object-memory model size.'),
  @('Partition statistics','UNSUPPORTED','TMSCHEMA_PARTITION_STATS was not recognized; partition row/size attribution is limited.'),
  @('Object/server memory','SKIPPED','Expensive object-memory rowset intentionally disabled; no memory-pressure conclusion is safe.'),
  @('Runtime snapshot','COMPLETE','Sessions, connections, commands and properties succeeded, but represent one collection instant.'),
  @('Multidimensional environment','MISSING','Database discovery failed because the configured SQLMULTIDIM instance was not found; no Multidimensional health conclusion is safe.'),
  @('Historical workload','MISSING','No query timings, FE/SE profiles, processing history, percentiles or usage telemetry.')
)
$top=$ranked|Select-Object -First 10
$topStorage=$models|Sort-Object UsedMB -Descending|Select-Object -First 10
$topRows=$models|Sort-Object MaxRows -Descending|Select-Object -First 10
$runtimeDir=Get-ChildItem (Join-Path $EvidenceRoot 'SERVER_RUNTIME') -Directory|Select-Object -First 1
$sessions=if($runtimeDir){Csv (Join-Path $runtimeDir.FullName 'sessions.csv')}else{@()};$connections=if($runtimeDir){Csv (Join-Path $runtimeDir.FullName 'connections.csv')}else{@()};$commands=if($runtimeDir){Csv (Join-Path $runtimeDir.FullName 'commands.csv')}else{@()}

$exec=@"
# SSAS Performance Executive Assessment

**Evidence set:** EVSET-001 | **Collected:** 2026-09-02 | **Fleet:** $($models.Count) Tabular databases | **Fleet risk score:** $fleetScore/100 ($fleetRisk)

## Overall health

The fleet is **$fleetRisk by the documented fleet-relative static risk model**. This is a prioritization signal, not measured user experience. Core metadata and VertiPaq evidence are broad enough to rank structural and storage risks. Historical query, processing, CPU, memory-pressure and usage claims are **NOT PROVABLE FROM CURRENT EVIDENCE**.

## Assessment coverage

| Area | Coverage | Executive meaning |
|---|---:|---|
$(($coverage|ForEach-Object{"| $($_[0]) | $($_[1]) | $($_[2]) |"})-join"`n")

## Top 10 databases for attention

| Rank | Database | Score | Risk | Storage MB* | Tables | Columns | Measures | Relationships | Partitions |
|---:|---|---:|---|---:|---:|---:|---:|---:|---:|
$(($top|ForEach-Object{$i=[array]::IndexOf($top,$_)+1;"| $i | $(EscapeMd $_.Database) | $($_.OverallScore) | $($_.RiskLevel) | $($_.UsedMB) | $($_.TableCount) | $($_.ColumnCount) | $($_.MeasureCount) | $($_.RelationshipCount) | $($_.PartitionCount) |"})-join"`n")

\* `USED_SIZE` summed from column-segment DMV rows; useful for relative ranking, not an authoritative total model-memory value.

## Key risks and quick wins

- **P1 - Storage concentration:** validate dependencies for the highest-cost tables and columns, then remove or reshape confirmed low-value attributes.
- **P1 - Processing design:** collect refresh duration/history for large, lightly partitioned tables and pilot time-based incremental processing where source dates permit.
- **P2 - Relationship review:** inspect the most relationship-heavy models for ambiguous/bidirectional paths; actual FE impact requires traces.
- **P2 - DAX validation:** use representative queries and Server Timings on static-risk measures before rewriting them.
- **Quick win:** establish workload/refresh telemetry and an owner/retention review for GUID-suffixed apparent model copies; deletion requires usage validation.

## Strategic next steps

1. Deep-dive the eight selected models in 06_DEEP_DIVE_PLAN.md.
2. Capture one representative business cycle of Extended Events plus refresh logs.
3. Baseline P50/P95/P99 duration, CPU, FE/SE timings, concurrency and processing durations.
4. Execute storage, relationship and partition changes in a test environment with result-parity and performance gates.
"@
Set-Content -Encoding UTF8 -LiteralPath (Join-Path $reportRoot '01_EXECUTIVE_ASSESSMENT.md') -Value $exec

$method=@"
# SSAS Fleet Technical Assessment

## 1. Assessment Scope

Evidence-driven assessment of all $($models.Count) selected Tabular databases on **BGASVR-DWH-DEV\SQLTABULAR**. The configured Multidimensional instance could not be reached, so Multidimensional coverage is MISSING rather than evidence that no such databases exist. Collection is a point-in-time snapshot dated 2026-09-02.

## 2. Evidence Coverage

| Category | Classification | Safe conclusion / limitation |
|---|---|---|
$(($coverage|ForEach-Object{"| $($_[0]) | **$($_[1])** | $($_[2]) |"})-join"`n")

Manifest status totals: $(($status|ForEach-Object{"$($_.Name)=$($_.Count)"})-join', '). The one `FAILED` item is retained as a coverage limitation, not interpreted as a model defect.

## 3. Methodology

Scores rank **static tuning exposure**, not measured performance. Percentile rank is `(count below + 0.5 x count equal) / fleet count x 100`. Category formulae:

- Complexity = 35% table percentile + 35% column percentile + 20% measure percentile + 10% calculated-column percentile.
- Storage = 45% segment USED_SIZE percentile + 25% dictionary-size percentile + 30% maximum storage-row percentile.
- Partition = 85 for a model with a >=1M-row storage structure and no more partitions than tables; 70 for partitions >2x tables; otherwise capped fleet-relative value.
- Relationship = 70% relationship-count percentile + up to 30 points for bidirectional/many-to-many indicators.
- DAX = 65% selected-pattern percentile + 35% proportion of measures with at least two selected syntax hits; zero where no measures exist.
- Overall = 22.22% Complexity + 27.78% Storage + 16.67% Partition + 16.67% Relationship + 16.67% DAX. The unavailable 10% operational dimension was removed and the original five weights renormalized. No unavailable category is fabricated.
- Levels: 0-29 LOW; 30-59 MEDIUM; 60-79 HIGH; 80-100 CRITICAL.

## 4. Fleet Architecture

| Metric | Fleet total / observation |
|---|---:|
| Databases | $($models.Count) |
| Tables | $(($models.TableCount|Measure-Object -Sum).Sum) |
| Columns | $(($models.ColumnCount|Measure-Object -Sum).Sum) |
| Measures | $(($models.MeasureCount|Measure-Object -Sum).Sum) |
| Relationships | $(($models.RelationshipCount|Measure-Object -Sum).Sum) |
| Partitions | $(($models.PartitionCount|Measure-Object -Sum).Sum) |
| Segment USED_SIZE (MB)* | $([math]::Round(($models.UsedMB|Measure-Object -Sum).Sum,2)) |

## 5. Fleet Risk Ranking

| Rank | Database | Overall | Level | Complexity | Storage | Partition | Relationship | DAX |
|---:|---|---:|---|---:|---:|---:|---:|---:|
$(($ranked|ForEach-Object{$i=[array]::IndexOf($ranked,$_)+1;"| $i | $(EscapeMd $_.Database) | $($_.OverallScore) | $($_.RiskLevel) | $($_.ComplexityScore) | $($_.StorageScore) | $($_.PartitionScore) | $($_.RelationshipScore) | $($_.DAXRiskScore) |"})-join"`n")

## 6. Storage Analysis

The ranking uses supported segment and dictionary rowsets. It does **not** sum shrinkable and non-shrinkable object memory and does not claim live resident model size.

### Top storage consumers

| Database | USED_SIZE MB | Allocated MB | Dictionary MB | Maximum rows |
|---|---:|---:|---:|---:|
$(($topStorage|ForEach-Object{"| $(EscapeMd $_.Database) | $($_.UsedMB) | $($_.AllocatedMB) | $($_.DictionaryMB) | $($_.MaxRows) |"})-join"`n")

### Top row-count exposure / potential cardinality review

| Database | Maximum recorded rows | Dictionary MB | Interpretation |
|---|---:|---:|---|
$(($topRows|ForEach-Object{"| $(EscapeMd $_.Database) | $($_.MaxRows) | $($_.DictionaryMB) | Candidate high-cardinality review; column cardinality itself is not directly proven. |"})-join"`n")

Detailed table/column candidates are listed in each database report. High dictionary size and row exposure are **potential** high-cardinality signals, not proof of cardinality.

## 7. Partition Analysis

Metadata partitions are available, but partition statistics are unsupported. $(@($models|Where-Object SinglePartitionLarge).Count) models match the reproducible screening signal of a >=1M-row storage structure with no more partitions than tables. This suggests refresh-scope risk; refresh duration and source time boundaries must be validated before changing design. Expected benefit is smaller processing transactions and targeted refresh. Implementation idea: introduce non-overlapping time partitions, archive immutable history, and process only changed periods.

## 8. Relationship Analysis

Relationship counts and flags are observed. Effects on Formula Engine workload are **REQUIRES VALIDATION**. Review high-ranked models for filter ambiguity, unnecessary bidirectionality, many-to-many semantics and snowflaking; preserve business semantics and validate result parity.

## 9. DAX Static Analysis

Static scanning counted FILTER, iterator, DISTINCTCOUNT, CALCULATE/CALCULATETABLE, ALLSELECTED, CROSSJOIN, GENERATE, RANKX and SWITCH calls. These are legitimate constructs and are labelled **STATIC DAX RISK** only. The most important candidates appear in findings and database reports. Rewrites require representative query Server Timings and semantic regression tests.

## 10. Runtime Snapshot

Observed at collection: **$($sessions.Count) session rows, $($connections.Count) connection rows, and $($commands.Count) command rows**. This is a snapshot and cannot establish peak concurrency, typical workload, queueing, CPU pressure or duration percentiles.

## 11. Cross-Evidence Findings

Findings receive higher confidence when storage/row rank aligns with broad models, limited partitioning, relationship complexity or static DAX exposure. See 04_FINDINGS.csv for $($findings.Count) structured findings. No syntax or structural signal is represented as measured query slowness.

## 12. Optimization Opportunities

- Reduce confirmed unnecessary columns at source to lower dictionaries, segments and refresh transfer.
- Partition large time-oriented facts after refresh-history validation.
- Simplify filter paths and use one-direction relationships by default where semantics allow.
- Consolidate repeated DAX into base measures only for profiled hotspots.
- Review apparent GUID-suffixed duplicate/deployment models as **CANDIDATE FOR USAGE VALIDATION**.

## 13. Quick Wins

- Enable low-overhead workload and refresh telemetry with database/query correlation.
- Assign owners and retention decisions to apparent deployment copies; do not delete without usage evidence.
- Hide technical keys and unused navigation attributes only after report dependency validation.

## 14. Structural Improvements

Time partitioning, source-side column pruning, star-schema simplification and measured DAX redesign are high-value but require engineering, test data and rollback plans.

## 15. Deep-Dive Candidates

$(($deep|ForEach-Object{"- **$(EscapeMd $_.Database)** - score $($_.OverallScore). See deep-dive plan for correlated category scores."})-join"`n")

## 16. Missing Evidence - Performance Questions We Cannot Yet Answer

| Question | Status | Evidence needed |
|---|---|---|
| Which queries consume most CPU and duration? | NOT PROVABLE FROM CURRENT EVIDENCE | Extended Events QueryBegin/QueryEnd with database, text/hash, duration and CPU. |
| Which measures have highest FE cost / FE:SE ratio? | NOT PROVABLE FROM CURRENT EVIDENCE | Representative DAX, Server Timings and query plans. |
| What are P50/P95/P99 durations and peak concurrency? | NOT PROVABLE FROM CURRENT EVIDENCE | Timestamped workload trace covering representative peak/business cycles. |
| Which models have processing bottlenecks? | NOT PROVABLE FROM CURRENT EVIDENCE | Process events, refresh orchestration logs, partition durations and failures. |
| Is the server under memory pressure? | NOT PROVABLE FROM CURRENT EVIDENCE | Time-series counters, memory limit properties and eviction/VertiPaq paging events. |
| Which objects are unused? | NOT PROVABLE FROM CURRENT EVIDENCE | Report dependency inventory plus query/field usage telemetry over an agreed retention window. |

## 17. Recommended Next Collection

Capture Extended Events and processing telemetry for an agreed representative cycle; analyze database/query hash, duration, CPU, cache status, FE/SE evidence where available, errors and concurrency. Collect VertiPaq Analyzer cardinality statistics for the selected deep dives. Each item directly closes a question above.

## 18. Prioritized Action Plan

Use 05_OPTIMIZATION_BACKLOG.md. Sequence measurement first, then low-risk storage hygiene, validated relationship/DAX changes, and finally partition/schema redesign. Every production change needs semantic-result, refresh-duration, query-duration and rollback gates.
"@
Set-Content -Encoding UTF8 -LiteralPath (Join-Path $reportRoot '03_TECHNICAL_ASSESSMENT.md') -Value $method

$backlog=@"
# Optimization Backlog

## P0 - Immediate / critical

No P0 remediation is justified by snapshot/static evidence alone. Escalate only if runtime telemetry confirms user-impacting incidents or capacity pressure.

## P1 - High-value optimization

| Item | Scope | Tag | Impact | Effort | Risk | Acceptance evidence |
|---|---|---|---|---|---|---|
| Establish query/processing baseline | Fleet | QUICK WIN, HIGH VALUE | HIGH | LOW | LOW | Representative trace produces query and refresh percentiles by database. |
| Review top storage consumers | Top 10 storage models | HIGH VALUE | HIGH | MEDIUM | MEDIUM | Dependency-approved column changes reduce supported storage metrics with result parity. |
| Pilot incremental partitions | Large/lightly partitioned candidates | HIGH VALUE, HIGH EFFORT | HIGH | HIGH | MEDIUM | Refresh scope/duration improves without overlap, gaps or semantic change. |

## P2 - Medium-term improvement

| Item | Scope | Tag | Impact | Effort | Risk | Acceptance evidence |
|---|---|---|---|---|---|---|
| Relationship path review | High relationship-score models | NEEDS VALIDATION | MEDIUM | MEDIUM | MEDIUM | Diagrammed paths, no ambiguity, unchanged calculation results. |
| Profile static DAX candidates | High DAX-risk models | NEEDS VALIDATION | MEDIUM | MEDIUM | LOW | Server Timings identifies actual hotspots; optimized versions pass regression tests. |
| Validate duplicate/deployment copies | GUID/admin-suffixed models | QUICK WIN, NEEDS VALIDATION | MEDIUM | LOW | LOW | Owner, dependencies and usage window establish retention decision. |

## P3 - Optional / architectural improvement

| Item | Scope | Tag | Impact | Effort | Risk | Acceptance evidence |
|---|---|---|---|---|---|---|
| Star-schema simplification | Selected complex models | HIGH EFFORT | MEDIUM | HIGH | HIGH | Simplified model passes semantic and workload benchmarks. |
| Semantic-model governance | Fleet | HIGH VALUE | MEDIUM | MEDIUM | LOW | Ownership, naming, deployment cleanup and evidence-based review cadence adopted. |

No object should be deleted because metadata merely looks redundant; every such item is a **CANDIDATE FOR USAGE VALIDATION**.
"@
Set-Content -Encoding UTF8 -LiteralPath (Join-Path $reportRoot '05_OPTIMIZATION_BACKLOG.md') -Value $backlog

$dd="# Deep-Dive Plan`n`nSelected by overall correlated fleet-relative risk, not size alone.`n"
foreach($m in $deep){$dd+=@"

## $(EscapeMd $m.Database)

- **Why selected:** Overall $($m.OverallScore)/100 ($($m.RiskLevel)); complexity $($m.ComplexityScore), storage $($m.StorageScore), partition $($m.PartitionScore), relationship $($m.RelationshipScore), DAX $($m.DAXRiskScore).
- **Primary unresolved questions:** Which queries/measures dominate CPU and duration? Does refresh scan avoidable history? Are filter paths or large dictionaries material at runtime?
- **Additional evidence:** Extended Events scoped to this database; representative DAX and Server Timings; refresh/processing history by partition; VertiPaq Analyzer cardinality and size; report dependency/usage inventory.
- **Suggested diagnostics:** QueryBegin/QueryEnd and progress events with database/query correlation; capture cold/warm representative queries; compare FE/SE timings; record process start/end, rows and duration per partition; map top fields to reports.
- **Expected outcome:** Confirm or reject static risks, identify measured hotspots, and create benchmarked changes with semantic-result and rollback gates.
"@}
Set-Content -Encoding UTF8 -LiteralPath (Join-Path $reportRoot '06_DEEP_DIVE_PLAN.md') -Value $dd

foreach($m in $models){
  $seg=Csv (Join-Path $m.Dir 'storage\storage_column_segments.csv');$stc=Csv (Join-Path $m.Dir 'storage\storage_table_columns.csv')
  $topT=$seg|Group-Object DIMENSION_NAME|ForEach-Object{[pscustomobject]@{Name=$_.Name;MB=[math]::Round((($_.Group|Measure-Object USED_SIZE -Sum).Sum/1MB),3);Rows=[long](($_.Group|Measure-Object RECORDS_COUNT -Maximum).Maximum)}}|Sort-Object MB -Descending|Select-Object -First 8
  $topC=$stc|Group-Object DIMENSION_NAME,ATTRIBUTE_NAME|ForEach-Object{[pscustomobject]@{Name=$_.Name;DictMB=[math]::Round((($_.Group|Measure-Object DICTIONARY_SIZE -Sum).Sum/1MB),3)}}|Sort-Object DictMB -Descending|Select-Object -First 8
  $ff=@($findings|Where-Object Database -eq $m.Database)
  $page=@"
# $(EscapeMd $m.Database) - Technical Assessment

## Health Summary

**$($m.RiskLevel) - $($m.OverallScore)/100.** Static fleet-relative prioritization; actual query and refresh performance are **NOT PROVABLE FROM CURRENT EVIDENCE**.

## Key Metrics and Risk Scores
# $(EscapeMd $m.Database) - Technical Assessment
| Tables | Columns | Measures | Relationships | Partitions | Hierarchies | Roles | Max rows | Segment used MB* |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| $($m.TableCount) | $($m.ColumnCount) | $($m.MeasureCount) | $($m.RelationshipCount) | $($m.PartitionCount) | $($m.HierarchyCount) | $($m.RoleCount) | $($m.MaxRows) | $($m.UsedMB) |

| Complexity | Storage | Partition | Relationship | Static DAX | Overall |
|---:|---:|---:|---:|---:|---:|
| $($m.ComplexityScore) | $($m.StorageScore) | $($m.PartitionScore) | $($m.RelationshipScore) | $($m.DAXRiskScore) | **$($m.OverallScore)** |

## Model Complexity

Compatibility level: $($m.CompatibilityLevel). Calculated tables: $($m.CalculatedTables); calculated columns detected in TMSL: $($m.CalculatedColumns). Complexity is interpreted relative to this 54-model fleet.

## Storage

| Top table/dimension storage structure | USED_SIZE MB | Maximum segment rows |
|---|---:|---:|
$(($topT|ForEach-Object{"| $(EscapeMd $_.Name) | $($_.MB) | $($_.Rows) |"})-join"`n")

| Potential dictionary/cardinality review candidate | Dictionary MB |
|---|---:|
$(($topC|ForEach-Object{"| $(EscapeMd $_.Name) | $($_.DictMB) |"})-join"`n")

\* DMV accounting only; not authoritative resident model size. Column candidates require usage and actual cardinality validation.

## Partitions

$($m.PartitionCount) metadata partitions across $($m.TableCount) tables. $(if($m.SinglePartitionLarge){'A large/lightly partitioned screening signal is present. Validate source date fields and refresh history before piloting time partitions.'}else{'No fleet screening rule proves a partition defect. Partition-level size/statistics are unavailable.'})

## Relationships

$($m.RelationshipCount) total, $($m.InactiveRelationships) inactive, $($m.BidirectionalRelationships) bidirectional indicators and $($m.ManyToManyRelationships) possible many-to-many indicators. Runtime Formula Engine impact is **REQUIRES VALIDATION**.

## Measures / DAX

$($m.MeasureCount) measures; $($m.DAXPatternHits) selected static pattern hits. Candidate measures: $(if($m.RiskyMeasures){EscapeMd $m.RiskyMeasures}else{'none by this narrow scan'}). This is STATIC DAX RISK, not proof of slowness.

## Security

$($m.RoleCount) roles observed. Security effectiveness, membership, RLS selectivity and runtime cost are not fully provable from role metadata alone.

## Findings

$(if($ff){($ff|ForEach-Object{"### $($_.FindingID) - $($_.Category)`n`n- **Severity / Classification / Confidence:** $($_.Severity) / $($_.Classification) / $($_.Confidence)`n- **Observation:** $($_.Observation)`n- **Evidence:** $($_.EvidenceFiles)`n- **Analysis / Performance impact:** $($_.Impact)`n- **Recommendation:** $($_.Recommendation)`n- **Expected benefit:** $($_.ExpectedBenefit)`n- **Implementation effort:** $($_.Effort)`n- **Validation:** Benchmark representative queries/refresh and verify semantic parity before production.`n"})-join"`n"}else{'No material fleet-outlier finding generated. This does not prove absence of runtime issues.'})

## Recommendations

Prioritize evidence collection, then address confirmed storage/partition/relationship/DAX hotspots. Treat apparent unused objects only as **CANDIDATE FOR USAGE VALIDATION**.

## Evidence Gaps

No historical query duration/CPU, FE/SE timing, peak concurrency, refresh duration, memory-pressure series or object usage telemetry.

## Deep-Dive Recommendation

**$(if($m.DeepDiveRecommended){'YES'}else{'NO - retain in fleet monitoring unless runtime evidence elevates it'})**.
"@
  Set-Content -Encoding UTF8 -LiteralPath (Join-Path $dbReportRoot ((SafeName $m.Database)+'.md')) -Value $page
}

Write-Output "Generated reports for $($models.Count) databases; findings=$($findings.Count); fleet score=$fleetScore $fleetRisk"





