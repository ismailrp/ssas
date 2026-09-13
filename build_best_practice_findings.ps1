[CmdletBinding()]
param([string]$EvidenceRoot="",[string]$ReportRoot="")
$ErrorActionPreference="Stop"
$scriptPath=$MyInvocation.MyCommand.Path
$scriptDirectory=if($scriptPath){Split-Path -Parent $scriptPath}else{(Get-Location).Path}
if(-not $EvidenceRoot){$EvidenceRoot=Join-Path $scriptDirectory "evidence\EVSET-005"}
if(-not $ReportRoot){$ReportRoot=Join-Path $scriptDirectory "REPORTS"}
function Csv([string]$p){if(Test-Path -LiteralPath $p){return @(Import-Csv -LiteralPath $p)};return @()}
function Num($v){$n=0.0;if([double]::TryParse([string]$v,[Globalization.NumberStyles]::Any,[Globalization.CultureInfo]::InvariantCulture,[ref]$n)){return $n};return 0.0}
function Escape-Markdown([string]$v){if($null-eq$v){return ""};return $v.Replace("|","\|").Replace("`r"," ").Replace("`n"," ")}
function JoinText($items){return (@($items|Where-Object{$_})-join "; ")}
function SafeName([string]$v){return [string]::Join('_',$v.Split([IO.Path]::GetInvalidFileNameChars()))}
if(-not(Test-Path -LiteralPath $ReportRoot)){New-Item -ItemType Directory -Path $ReportRoot -Force|Out-Null}
$dbs=Csv (Join-Path $EvidenceRoot "MANIFEST\databases.csv")
$fleetScore=Csv (Join-Path $ReportRoot "02_FLEET_SCORECARD.csv")
$runtime=Csv (Join-Path $ReportRoot "07_RUNTIME_DATABASE_BASELINE.csv")
$runtimeMap=@{};foreach($r in $runtime){$runtimeMap[$r.Database]=$r}
$scoreMap=@{};foreach($r in $fleetScore){$scoreMap[$r.Database]=$r}
$raw=New-Object System.Collections.Generic.List[object]

foreach($db in $dbs){
  $name=$db.Database;$type=$db.ServerType;$base=Join-Path (Join-Path $EvidenceRoot $type) $name
  if($type-ne"TABULAR"){
    $raw.Add([pscustomobject]@{Database=$name;ModelType=$type;CompatibilityLevel="";LargeSinglePartitionTables=0;LargestSinglePartitionRows=0;TopDictionaryMB=0;TopDictionaryColumn="";BidirectionalRelationships=0;InactiveRelationships=0;SelectStarPartitions=0;ComplexSourcePartitions=0;CalculatedColumns=0;CalculatedTables=0;DateTimeColumns=0;CurrencyTypeCandidates=0;FilterAllMeasures=0;IteratorPatternHits=0;RuntimeExecutions=0;RuntimeP95Ms="";RuntimeMaxMs="";StaticOverallScore="";GuideApplicability="LIMITED";EvidenceFiles="MANIFEST/databases.csv"})
    continue
  }
  $meta=Join-Path $base "metadata";$storage=Join-Path $base "storage"
  $tables=Csv (Join-Path $meta "tables.csv");$parts=Csv (Join-Path $meta "partitions.csv");$rels=Csv (Join-Path $meta "relationships.csv");$measures=Csv (Join-Path $meta "measures.csv");$columns=Csv (Join-Path $meta "columns.csv");$sts=Csv (Join-Path $storage "storage_tables.csv");$stc=Csv (Join-Path $storage "storage_table_columns.csv")
  $tableNames=@{};foreach($t in $tables){$tableNames[[string]$t.ID]=$t.Name}
  $partCount=@{};foreach($p in $parts){$tn=$tableNames[[string]$p.TableID];if($tn){if(-not$partCount.ContainsKey($tn)){$partCount[$tn]=0};$partCount[$tn]++}}
  $rowByTable=@{};foreach($s in $sts){$tn=[string]$s.DIMENSION_NAME;$rows=Num $s.ROWS_COUNT;if((-not$rowByTable.ContainsKey($tn))-or$rows-gt$rowByTable[$tn]){$rowByTable[$tn]=$rows}}
  $largeSingle=@();foreach($tn in $rowByTable.Keys){if($rowByTable[$tn]-ge 1000000-and([int]$partCount[$tn])-le1){$largeSingle+=$tn}}
  $largest=0;if($largeSingle.Count){$largest=($largeSingle|ForEach-Object{$rowByTable[$_]}|Measure-Object -Maximum).Maximum}
  $dictGroups=@($stc|Group-Object DIMENSION_NAME,ATTRIBUTE_NAME|ForEach-Object{[pscustomobject]@{Name=$_.Name;Bytes=(($_.Group|Measure-Object DICTIONARY_SIZE -Sum).Sum)}}|Sort-Object Bytes -Descending)
  $topDict=if($dictGroups.Count){$dictGroups[0]}else{$null}
  $selectStar=@($parts|Where-Object{[string]$_.QueryDefinition-match'(?im)\bselect\s+(?:[A-Za-z_][A-Za-z0-9_]*\.)?\*'}).Count
  $complexSource=@($parts|Where-Object{[string]$_.QueryDefinition-match'(?im)\bWITH\b|\bUNION(?:\s+ALL)?\b|\bJOIN\b|\bORDER\s+BY\b|\bCROSS\s+APPLY\b'}).Count
  $calcColumns=@($columns|Where-Object{$_.Expression}).Count
  $calcTables=@($parts|Where-Object{$_.Type-eq'2'}).Count
  $dateTime=@($columns|Where-Object{$_.ExplicitDataType-in@('9','DateTime')-or$_.InferredDataType-in@('9','DateTime')}).Count
  $currencyNames='(?i)amount|value|nilai|harga|cost|price|saldo|budget|anggaran|realisasi|profit|loss|debit|credit'
  $currencyCandidates=@($columns|Where-Object{($_.ExplicitName-match$currencyNames-or$_.InferredName-match$currencyNames)-and($_.ExplicitDataType-in@('3','Double','Decimal')-or$_.InferredDataType-in@('3','Double','Decimal'))}).Count
  $bidir=@($rels|Where-Object{$_.CrossFilteringBehavior-in@('2','BothDirections','Both')}).Count
  $inactive=@($rels|Where-Object{$_.IsActive-ne'True'}).Count
  $filterAll=0;$iterHits=0;foreach($m in $measures){if([string]$m.Expression-match'(?is)FILTER\s*\(\s*ALL\s*\('){$filterAll++};$iterHits+=([regex]::Matches([string]$m.Expression,'(?i)\b(?:SUMX|AVERAGEX|COUNTX|RANKX|FILTER|CROSSJOIN|GENERATE)\s*\(')).Count}
  $rt=$runtimeMap[$name];$fs=$scoreMap[$name]
  $raw.Add([pscustomobject]@{Database=$name;ModelType=$type;CompatibilityLevel=$fs.CompatibilityLevel;LargeSinglePartitionTables=$largeSingle.Count;LargestSinglePartitionRows=[long]$largest;LargeSinglePartitionTableNames=(JoinText $largeSingle);TopDictionaryMB=if($topDict){[math]::Round($topDict.Bytes/1MB,3)}else{0};TopDictionaryColumn=if($topDict){$topDict.Name}else{""};BidirectionalRelationships=$bidir;InactiveRelationships=$inactive;SelectStarPartitions=$selectStar;ComplexSourcePartitions=$complexSource;CalculatedColumns=$calcColumns;CalculatedTables=$calcTables;DateTimeColumns=$dateTime;CurrencyTypeCandidates=$currencyCandidates;FilterAllMeasures=$filterAll;IteratorPatternHits=$iterHits;RuntimeExecutions=if($rt){$rt.Executions}else{0};RuntimeP95Ms=if($rt){$rt.P95DurationMs}else{""};RuntimeMaxMs=if($rt){$rt.MaxDurationMs}else{""};StaticOverallScore=if($fs){$fs.OverallScore}else{""};GuideApplicability="APPLICABLE";EvidenceFiles="metadata/partitions.csv; metadata/columns.csv; metadata/relationships.csv; metadata/measures.csv; storage/storage_tables.csv; storage/storage_table_columns.csv; model/database.tmsl.json"})
}

$tab=@($raw|Where-Object{$_.ModelType-eq"TABULAR"})
$dictValues=@($tab.TopDictionaryMB|ForEach-Object{Num $_}|Sort-Object)
function RankPct($values,$value){if($values.Count-le1){return 50};return [math]::Round(100*(@($values|Where-Object{$_-lt$value}).Count+.5*@($values|Where-Object{$_-eq$value}).Count)/$values.Count,1)}
$rows=New-Object System.Collections.Generic.List[object]
foreach($m in $raw){
  if($m.ModelType-ne"TABULAR"){$rows.Add([pscustomobject]@{Database=$m.Database;ModelType=$m.ModelType;Priority="P2";TuningScore="";PrimaryTuningArea="MD-specific profiling required";TuningAreas="Runtime/processing evidence gap";Observed="Model is Multidimensional; VertiPaq-focused guide is not directly applicable.";RecommendedAction="Use MD query subcube, aggregation/cache, calculation, and processing traces with representative business MDX.";Classification="REQUIRES VALIDATION";Confidence="HIGH";ExpectedBenefit="Establish valid MD-specific tuning scope.";Effort="LOW";Risk="LOW";ValidationMethod="Capture filtered business MDX and processing events; compare warm runs and semantic results.";EvidenceFiles=$m.EvidenceFiles});continue}
  $dictPct=RankPct $dictValues (Num $m.TopDictionaryMB);$areas=@();$actions=@();$observed=@();$score=0
  if($m.LargeSinglePartitionTables-gt0){$score+=25;$areas+="Partition/refresh";$observed+=("{0} table(s) >=1M rows with <=1 partition; largest {1:N0} rows"-f$m.LargeSinglePartitionTables,$m.LargestSinglePartitionRows);$actions+="Validate refresh history/date boundaries, then pilot non-overlapping sliding-window partitions"}
  if($dictPct-ge90-and$m.TopDictionaryMB-gt0){$score+=20;$areas+="Storage/dictionary";$observed+=("Top dictionary {0} MB at fleet percentile {1}: {2}"-f$m.TopDictionaryMB,$dictPct,$m.TopDictionaryColumn);$actions+="Validate dependency/cardinality for top dictionary columns; prune or reshape only confirmed low-value columns"}
  if($m.BidirectionalRelationships-gt0-or$m.InactiveRelationships-ge5){$score+=15;$areas+="Relationships";$observed+=("{0} bidirectional and {1} inactive relationships"-f$m.BidirectionalRelationships,$m.InactiveRelationships);$actions+="Review filter paths/cardinality and semantic need; prefer single direction where parity permits"}
  if($m.SelectStarPartitions-gt0-or$m.ComplexSourcePartitions-gt0){$score+=15;$areas+="Source query";$observed+=("{0} SELECT-star and {1} complex partition source queries"-f$m.SelectStarPartitions,$m.ComplexSourcePartitions);$actions+="Use explicit projection and test moving repeated CTE/UNION/JOIN logic to governed SQL views"}
  if($m.CalculatedColumns-gt0-or$m.CalculatedTables-gt0){$score+=10;$areas+="Calculated objects";$observed+=("{0} calculated columns and {1} calculated tables"-f$m.CalculatedColumns,$m.CalculatedTables);$actions+="Review fact calculated columns for shift-left or measure replacement; validate storage and semantics"}
  if($m.FilterAllMeasures-gt0-or$m.IteratorPatternHits-ge10){$score+=15;$areas+="DAX";$observed+=("{0} FILTER(ALL()) candidate measures and {1} iterator/filter pattern hits"-f$m.FilterAllMeasures,$m.IteratorPatternHits);$actions+="Profile only captured business hashes with Server Timings; refactor measured hotspots"}
  if($m.DateTimeColumns-gt0){$areas+="Data types";$observed+=("{0} DateTime metadata columns; time-granularity/cardinality not yet proven"-f$m.DateTimeColumns);$actions+="Measure cardinality/dictionary before deciding whether Date/Time split is beneficial"}
  if($m.CurrencyTypeCandidates-gt0){$areas+="Numeric types";$observed+=("{0} name/type currency candidates"-f$m.CurrencyTypeCandidates);$actions+="Confirm business scale/precision before testing Fixed Decimal/Currency conversion"}
  if($m.RuntimeExecutions-gt0){$observed+=("Captured BUSINESS_CANDIDATE runtime: {0} executions, P95 {1} ms, max {2} ms"-f$m.RuntimeExecutions,$m.RuntimeP95Ms,$m.RuntimeMaxMs);$actions+="Map top query hashes to owners and reproduce with 1 warm-up plus >=3 warm runs"}
  if(-not$areas){$areas+="No material guide signal";$actions+="Retain monitoring; do not tune solely to satisfy a checklist";$observed+="No material threshold hit in available evidence"}
  if($score-gt100){$score=100};$priority=if($score-ge70){"P1"}elseif($score-ge40){"P2"}else{"P3"}
  $primary=$areas[0];if($m.RuntimeP95Ms-ne""-and(Num $m.RuntimeP95Ms)-ge1000){$priority="P1";$primary="Runtime query profiling"}
  $rows.Add([pscustomobject]@{Database=$m.Database;ModelType=$m.ModelType;Priority=$priority;TuningScore=$score;PrimaryTuningArea=$primary;TuningAreas=(JoinText ($areas|Select-Object -Unique));Observed=(JoinText $observed);RecommendedAction=(JoinText ($actions|Select-Object -Unique));Classification="OBSERVED + REQUIRES VALIDATION";Confidence="MEDIUM";ExpectedBenefit="Reduced refresh/scan/model complexity only where validation confirms the candidate.";Effort=if($score-ge70){"MEDIUM-HIGH"}elseif($score-ge40){"MEDIUM"}else{"LOW"};Risk="MEDIUM; semantic, refresh, and dependency regression possible";ValidationMethod="Dependency/usage check; semantic regression; representative before/after query and refresh measurement; rollback plan.";EvidenceFiles=$m.EvidenceFiles})
}
$rows=@($rows|Sort-Object @{Expression={if($_.Priority-eq'P1'){1}elseif($_.Priority-eq'P2'){2}else{3}}},@{Expression={Num $_.TuningScore};Descending=$true},Database)
$rows|Export-Csv -LiteralPath (Join-Path $ReportRoot "09_BEST_PRACTICE_TUNING_MATRIX.csv") -NoTypeInformation -Encoding UTF8

$p1=@($rows|Where-Object{$_.Priority-eq"P1"});$p2=@($rows|Where-Object{$_.Priority-eq"P2"});$areaCounts=@($rows|Where-Object{$_.ModelType-eq"TABULAR"}|ForEach-Object{$_.TuningAreas-split'; '}|Group-Object|Sort-Object Count -Descending)
$top=@($rows|Where-Object{$_.ModelType-eq"TABULAR"}|Select-Object -First 20)
$report=@"
# SSAS Best-Practice Tuning Findings

## Kesimpulan

Panduan dipetakan ke seluruh 54 model Tabular dan 2 model Multidimensional. Hasilnya adalah daftar kandidat tuning, bukan instruksi perubahan langsung. Score bersifat heuristic dan reproducible: partition 25, storage/dictionary 20, relationship 15, source query 15, calculated objects 10, dan static DAX 15. Runtime tidak menambah score karena representativitas trace belum terbukti; P95 kandidat >=1 detik hanya menaikkan prioritas profiling ke P1.

Jumlah prioritas: **P1=$($p1.Count), P2=$($p2.Count), P3=$(@($rows|Where-Object{$_.Priority-eq'P3'}).Count)**.

## Model yang harus ditangani lebih dahulu

| Rank | Database | Priority | Score | Bagian utama | Sinyal evidence | Tindakan pertama |
|---:|---|---|---:|---|---|---|
$(($top|ForEach-Object{$i=[array]::IndexOf($top,$_)+1;"| $i | $(Escape-Markdown $_.Database) | $($_.Priority) | $($_.TuningScore) | $(Escape-Markdown $_.PrimaryTuningArea) | $(Escape-Markdown $_.Observed) | $(Escape-Markdown $_.RecommendedAction) |"})-join"`n")

## Konsentrasi area tuning

| Area | Jumlah model |
|---|---:|
$(($areaCounts|ForEach-Object{"| $(Escape-Markdown $_.Name) | $($_.Count) |"})-join"`n")

## Cara membaca rekomendasi

- **Partition/refresh:** jumlah partition rendah pada tabel besar adalah OBSERVED; durasi refresh dan manfaat sliding window tetap REQUIRES VALIDATION.
- **Storage/dictionary:** ranking dictionary adalah indikator encoding/storage, bukan authoritative resident memory. Jangan menghapus key/GUID tanpa dependency dan usage validation.
- **Relationship:** bidirectional/inactive relationship adalah kandidat review; dampak Formula Engine belum terbukti tanpa Server Timings.
- **Source query:** SELECT-star dan query kompleks adalah OBSERVED; materialisasi SQL hanya dilakukan setelah plan, duration, freshness, dan ownership divalidasi.
- **Calculated objects/DAX:** syntax adalah static risk. Jangan menyatakan query lambat karena FILTER/iterator tanpa query plan dan Server Timings.
- **DateTime/numeric type:** metadata type/name hanya screening. Cardinality, precision, semantics, dan before/after storage wajib diukur.
- **Multidimensional:** guide berorientasi VertiPaq, sehingga dua model MD memerlukan jalur profiling MD-specific.

## Urutan tuning aman

1. Map top runtime hashes ke report dan owner; ulangi query dengan satu warm-up dan minimal tiga warm runs.
2. Untuk P1 partition/storage, ambil processing history dan top-column cardinality/dependency.
3. Pilot satu perubahan terisolasi di non-production: explicit source projection, partition window, relationship direction, atau DAX hotspot.
4. Luluskan semantic regression, refresh comparison, P50/P95/max query comparison, dan rollback test sebelum deployment.

Detail seluruh model dan tindakan terdapat di **09_BEST_PRACTICE_TUNING_MATRIX.csv**. Bila evidence tidak mendukung dampak aktual: **NOT PROVABLE FROM CURRENT EVIDENCE**.
"@
Set-Content -LiteralPath (Join-Path $ReportRoot "10_BEST_PRACTICE_TUNING_FINDINGS.md") -Encoding UTF8 -Value $report
Write-Output("Best-practice matrix generated: models="+$rows.Count+", P1="+$p1.Count+", P2="+$p2.Count)
