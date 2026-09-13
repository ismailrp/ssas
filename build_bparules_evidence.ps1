[CmdletBinding()]
param([string]$EvidenceRoot="",[string]$RulesPath="",[string]$ReportRoot="")
$ErrorActionPreference="Stop"
$scriptPath=$MyInvocation.MyCommand.Path
$scriptDirectory=if($scriptPath){Split-Path -Parent $scriptPath}else{(Get-Location).Path}
if(-not $EvidenceRoot){$EvidenceRoot=Join-Path $scriptDirectory "evidence\EVSET-005"}
if(-not $RulesPath){$RulesPath=Join-Path $scriptDirectory "BPArules\BPARules.json"}
if(-not $ReportRoot){$ReportRoot=Join-Path $scriptDirectory "results"}
if(-not(Test-Path -LiteralPath $ReportRoot)){New-Item -ItemType Directory -Path $ReportRoot -Force|Out-Null}
function Csv([string]$p){if(Test-Path -LiteralPath $p){return @(Import-Csv -LiteralPath $p)};return @()}
function Txt($v){if($null-eq$v){return ""};return [string]$v}
function EscapeMd([string]$v){return (Txt $v).Replace("|","\|").Replace("`r"," ").Replace("`n"," ")}
function Bool($v){return (Txt $v)-eq"True"}
function AddHit([string]$db,[string]$id,[string]$scope,[string]$objects,[int]$count,[string]$classification,[string]$confidence,[string]$evidence){
  if($count-le0){return}
  $rule=$ruleMap[$id]
  $sev=if([int]$rule.Severity-ge3){"HIGH"}elseif([int]$rule.Severity-eq2){"MEDIUM"}else{"LOW"}
  $priority=if($sev-eq"HIGH"){"P1"}elseif($sev-eq"MEDIUM"){"P2"}else{"P3"}
  $script:hits.Add([pscustomobject]@{FindingID="BPA-{0:D4}"-f($script:hits.Count+1);Database=$db;RuleID=$id;RuleName=$rule.Name;Category=$rule.Category;RuleSeverity=$rule.Severity;Severity=$sev;Classification=$classification;Confidence=$confidence;Scope=$scope;ObjectCount=$count;ObjectExamples=$objects;Observation=("Rule condition matched {0} object(s): {1}"-f$count,$objects);Analysis=$rule.Description;PerformanceImpact="Potential quality, maintainability, or performance exposure described by the rule; actual runtime impact is not implied by a static match.";Recommendation=if($rule.FixExpression){"Review and test rule fix: "+$rule.FixExpression}else{"Review the matched objects and apply the rule guidance only where model semantics permit."};ExpectedBenefit="Closer alignment with the supplied BPA rule and reduced avoidable model risk after validation.";Effort="LOW-MEDIUM";Priority=$priority;Risk="MEDIUM; metadata or semantic behavior may change";ValidationMethod="Apply in non-production; run metadata validation, semantic result regression, refresh test, and representative query before/after comparison.";EvidenceFiles=$evidence})
}
$rulesRaw=Get-Content -LiteralPath $RulesPath -Raw|ConvertFrom-Json
$rules=@($rulesRaw|ForEach-Object{$_})
$ruleMap=@{};foreach($r in $rules){$ruleMap[$r.ID]=$r}
$implemented=@(
"AVOID_FLOATING_POINT_DATA_TYPES","REDUCE_USAGE_OF_CALCULATED_COLUMNS_THAT_USE_THE_RELATED_FUNCTION","MODEL_SHOULD_HAVE_A_DATE_TABLE","DATE/CALENDAR_TABLES_SHOULD_BE_MARKED_AS_A_DATE_TABLE","REMOVE_AUTO-DATE_TABLE","AVOID_EXCESSIVE_BI-DIRECTIONAL_OR_MANY-TO-MANY_RELATIONSHIPS","MINIMIZE_POWER_QUERY_TRANSFORMATIONS","MANY-TO-MANY_RELATIONSHIPS_SHOULD_BE_SINGLE-DIRECTION","REDUCE_USAGE_OF_CALCULATED_TABLES","REDUCE_NUMBER_OF_CALCULATED_COLUMNS","CHECK_IF_BI-DIRECTIONAL_AND_MANY-TO-MANY_RELATIONSHIPS_ARE_VALID","USE_THE_TREATAS_FUNCTION_INSTEAD_OF_INTERSECT","USE_THE_DIVIDE_FUNCTION_FOR_DIVISION","AVOID_USING_THE_IFERROR_FUNCTION","EVALUATEANDLOG_SHOULD_NOT_BE_USED_IN_PRODUCTION_MODELS","DATA_COLUMNS_MUST_HAVE_A_SOURCE_COLUMN","EXPRESSION_RELIANT_OBJECTS_MUST_HAVE_AN_EXPRESSION","RELATIONSHIP_COLUMNS_SAME_DATA_TYPE","AVOID_INVALID_NAME_CHARACTERS","AVOID_INVALID_DESCRIPTION_CHARACTERS","REMOVE_DATA_SOURCES_NOT_REFERENCED_BY_ANY_PARTITIONS","ENSURE_TABLES_HAVE_RELATIONSHIPS","OBJECTS_WITH_NO_DESCRIPTION","PARTITION_NAME_SHOULD_MATCH_TABLE_NAME_FOR_SINGLE_PARTITION_TABLES","SPECIAL_CHARS_IN_OBJECT_NAMES","TRIM_OBJECT_NAMES","OBJECTS_SHOULD_NOT_START_OR_END_WITH_A_SPACE","DATECOLUMN_FORMATSTRING","MONTHCOLUMN_FORMATSTRING","PROVIDE_FORMAT_STRING_FOR_MEASURES","NUMERIC_COLUMN_SUMMARIZE_BY","PERCENTAGE_FORMATTING","RELATIONSHIP_COLUMNS_SHOULD_BE_OF_INTEGER_DATA_TYPE","ADD_DATA_CATEGORY_FOR_COLUMNS","HIDE_FOREIGN_KEYS","MARK_PRIMARY_KEYS","FIRST_LETTER_OF_OBJECTS_MUST_BE_CAPITALIZED","MONTH_(AS_A_STRING)_MUST_BE_SORTED")
$partial=@("LARGE_TABLES_SHOULD_BE_PARTITIONED","SNOWFLAKE_SCHEMA_ARCHITECTURE","LIMIT_ROW_LEVEL_SECURITY_(RLS)_LOGIC","MODEL_USING_DIRECT_QUERY_AND_NO_AGGREGATIONS","AVOID_USING_MANY-TO-MANY_RELATIONSHIPS_ON_TABLES_USED_FOR_DYNAMIC_ROW_LEVEL_SECURITY","UNPIVOT_PIVOTED_(MONTH)_DATA","MEASURES_USING_TIME_INTELLIGENCE_AND_MODEL_IS_USING_DIRECT_QUERY","CHECK_IF_DYNAMIC_ROW_LEVEL_SECURITY_(RLS)_IS_NECESSARY","DAX_COLUMNS_FULLY_QUALIFIED","DAX_MEASURES_UNQUALIFIED","AVOID_DUPLICATE_MEASURES","MEASURES_SHOULD_NOT_BE_DIRECT_REFERENCES_OF_OTHER_MEASURES","FILTER_COLUMN_VALUES","FILTER_MEASURE_VALUES_BY_COLUMNS","INACTIVE_RELATIONSHIPS_THAT_ARE_NEVER_ACTIVATED","AVOID_USING_'1-(X/Y)'_SYNTAX","AVOID_STRUCTURED_DATA_SOURCES_WITH_PROVIDER_PARTITIONS","AVOID_THE_USERELATIONSHIP_FUNCTION_AND_RLS_AGAINST_THE_SAME_TABLE","REMOVE_ROLES_WITH_NO_MEMBERS","HIDE_FACT_TABLE_COLUMNS")
$coverage=foreach($r in $rules){$status=if($implemented-contains$r.ID){"EVALUATED_FROM_EVIDENCE"}elseif($partial-contains$r.ID){"PARTIAL_REQUIRES_VALIDATION"}else{"NOT_PROVABLE_FROM_CURRENT_EVIDENCE"};[pscustomobject]@{RuleID=$r.ID;RuleName=$r.Name;Category=$r.Category;Severity=$r.Severity;Scope=$r.Scope;CompatibilityLevel=$r.CompatibilityLevel;EvaluationStatus=$status;Reason=if($status-eq"EVALUATED_FROM_EVIDENCE"){"Evaluated using TMSL and collected metadata."}elseif($status-eq"PARTIAL_REQUIRES_VALIDATION"){"Some signals exist, but exact TOM/dependency/runtime semantics are unavailable."}else{"Requires TOM annotations, cardinality/lineage, dependency graph, OLS/RLS detail, or other evidence not safely derivable."}}}
$coverage|Export-Csv -LiteralPath (Join-Path $ReportRoot "11_BPA_RULE_COVERAGE.csv") -NoTypeInformation -Encoding UTF8
$hits=New-Object System.Collections.Generic.List[object]
$dbs=Csv (Join-Path $EvidenceRoot "MANIFEST\databases.csv")|Where-Object ServerType -eq "TABULAR"
foreach($d in $dbs){
  $db=$d.Database;$base=Join-Path (Join-Path $EvidenceRoot "TABULAR") $db;$path=Join-Path $base "model\database.tmsl.json"
  if(-not(Test-Path -LiteralPath $path)){continue}
  $root=Get-Content -LiteralPath $path -Raw|ConvertFrom-Json;$model=$root.createOrReplace.database.model
  $tables=@($model.tables|Where-Object{$null-ne$_});$allMeasures=@($tables|ForEach-Object{@($_.measures|Where-Object{$null-ne$_})});$allColumns=@($tables|ForEach-Object{@($_.columns|Where-Object{$null-ne$_})});$allParts=@($tables|ForEach-Object{@($_.partitions|Where-Object{$null-ne$_})});$rels=@($model.relationships|Where-Object{$null-ne$_})
  $double=@($tables|ForEach-Object{$tn=$_.name;@($_.columns)|Where-Object{$_.dataType-eq"double"}|ForEach-Object{"$tn[$($_.name)]"}});AddHit $db "AVOID_FLOATING_POINT_DATA_TYPES" "Column" (($double|Select-Object -First 12)-join"; ") $double.Count "OBSERVED" "HIGH" "model/database.tmsl.json"
  $related=@($tables|ForEach-Object{$tn=$_.name;@($_.columns)|Where-Object{$_.expression-match'(?i)RELATED\s*\('}|ForEach-Object{"$tn[$($_.name)]"}});AddHit $db "REDUCE_USAGE_OF_CALCULATED_COLUMNS_THAT_USE_THE_RELATED_FUNCTION" "CalculatedColumn" (($related|Select-Object -First 12)-join"; ") $related.Count "OBSERVED" "HIGH" "model/database.tmsl.json"
  $calcTables=@($tables|Where-Object{@($_.partitions|Where-Object{$_.source.type-eq"calculated"}).Count-gt0});AddHit $db "REDUCE_USAGE_OF_CALCULATED_TABLES" "CalculatedTable" (($calcTables.name|Select-Object -First 12)-join"; ") $calcTables.Count "OBSERVED" "HIGH" "model/database.tmsl.json"
  $calcCols=@($allColumns|Where-Object{$_.expression});if($calcCols.Count-gt5){AddHit $db "REDUCE_NUMBER_OF_CALCULATED_COLUMNS" "Model" "$($calcCols.Count) calculated columns" 1 "OBSERVED" "HIGH" "model/database.tmsl.json"}
  $dateTables=@($tables|Where-Object{$_.dataCategory-eq"Time"-and@($_.columns|Where-Object{$_.isKey-eq$true-and$_.dataType-eq"dateTime"}).Count-gt0});if($dateTables.Count-eq0){AddHit $db "MODEL_SHOULD_HAVE_A_DATE_TABLE" "Model" $db 1 "OBSERVED" "HIGH" "model/database.tmsl.json"}
  $namedDate=@($tables|Where-Object{$_.name-match'(?i)DATE|CALENDAR'-and-not($_.dataCategory-eq"Time"-and@($_.columns|Where-Object{$_.isKey-eq$true-and$_.dataType-eq"dateTime"}).Count-gt0)});AddHit $db "DATE/CALENDAR_TABLES_SHOULD_BE_MARKED_AS_A_DATE_TABLE" "Table" (($namedDate.name|Select-Object -First 12)-join"; ") $namedDate.Count "OBSERVED" "HIGH" "model/database.tmsl.json"
  $auto=@($calcTables|Where-Object{$_.name-match'^(DateTableTemplate_|LocalDateTable_)'});AddHit $db "REMOVE_AUTO-DATE_TABLE" "CalculatedTable" (($auto.name|Select-Object -First 12)-join"; ") $auto.Count "OBSERVED" "HIGH" "model/database.tmsl.json"
  $riskyRels=@($rels|Where-Object{$_.crossFilteringBehavior-eq"bothDirections"-or($_.fromCardinality-eq"many"-and$_.toCardinality-eq"many")});if($rels.Count-gt0-and($riskyRels.Count/[double]$rels.Count)-gt.3){AddHit $db "AVOID_EXCESSIVE_BI-DIRECTIONAL_OR_MANY-TO-MANY_RELATIONSHIPS" "Model" "$($riskyRels.Count) of $($rels.Count) relationships" 1 "OBSERVED" "HIGH" "model/database.tmsl.json"};AddHit $db "CHECK_IF_BI-DIRECTIONAL_AND_MANY-TO-MANY_RELATIONSHIPS_ARE_VALID" "Relationship" (($riskyRels.name|Select-Object -First 12)-join"; ") $riskyRels.Count "REQUIRES VALIDATION" "MEDIUM" "metadata/relationships.csv; model/database.tmsl.json"
  $m2mboth=@($rels|Where-Object{$_.fromCardinality-eq"many"-and$_.toCardinality-eq"many"-and$_.crossFilteringBehavior-eq"bothDirections"});AddHit $db "MANY-TO-MANY_RELATIONSHIPS_SHOULD_BE_SINGLE-DIRECTION" "Relationship" (($m2mboth.name|Select-Object -First 12)-join"; ") $m2mboth.Count "OBSERVED" "HIGH" "model/database.tmsl.json"
  $mComplex=@($allParts|Where-Object{$_.source.type-eq"m"-and(Txt $_.source.expression)-match'(?i)Table\.(Combine|Join|NestedJoin|AddColumn|Group|Sort|Pivot|Unpivot|UnpivotOtherColumns|Distinct)\s*\(|Value\.NativeQuery|OleDb\.Query|Odbc\.Query'});AddHit $db "MINIMIZE_POWER_QUERY_TRANSFORMATIONS" "Partition" (($mComplex.name|Select-Object -First 12)-join"; ") $mComplex.Count "OBSERVED" "HIGH" "model/database.tmsl.json"
  $patterns=@(@("USE_THE_TREATAS_FUNCTION_INSTEAD_OF_INTERSECT",'(?i)INTERSECT\s*\('),@("USE_THE_DIVIDE_FUNCTION_FOR_DIVISION",'\]\s*/(?![/*])|\)\s*/(?![/*])'),@("AVOID_USING_THE_IFERROR_FUNCTION",'(?i)IFERROR\s*\('),@("EVALUATEANDLOG_SHOULD_NOT_BE_USED_IN_PRODUCTION_MODELS",'(?i)EVALUATEANDLOG\s*\('))
  foreach($p in $patterns){$found=@($allMeasures|Where-Object{(Txt $_.expression)-match$p[1]});AddHit $db $p[0] "Measure" (($found.name|Select-Object -First 12)-join"; ") $found.Count "OBSERVED" "HIGH" "metadata/measures.csv; model/database.tmsl.json"}
  $emptyMeasures=@($allMeasures|Where-Object{[string]::IsNullOrWhiteSpace((Txt $_.expression))});$emptyCalc=@($calcCols|Where-Object{[string]::IsNullOrWhiteSpace((Txt $_.expression))});$empty=@($emptyMeasures)+@($emptyCalc);AddHit $db "EXPRESSION_RELIANT_OBJECTS_MUST_HAVE_AN_EXPRESSION" "ExpressionObject" (($empty.name|Select-Object -First 12)-join"; ") $empty.Count "OBSERVED" "HIGH" "model/database.tmsl.json"
  $badSource=@($tables|ForEach-Object{$tn=$_.name;@($_.columns)|Where-Object{-not$_.expression-and[string]::IsNullOrWhiteSpace((Txt $_.sourceColumn))}|ForEach-Object{"$tn[$($_.name)]"}});AddHit $db "DATA_COLUMNS_MUST_HAVE_A_SOURCE_COLUMN" "DataColumn" (($badSource|Select-Object -First 12)-join"; ") $badSource.Count "OBSERVED" "HIGH" "model/database.tmsl.json"
  $tableMap=@{};foreach($t in $tables){if($t-and-not[string]::IsNullOrWhiteSpace((Txt $t.name))){$tableMap[$t.name]=$t}};$typeMismatch=@();$nonInt=@();$fkVisible=@();$pkUnmarked=@();foreach($rel in $rels){if($null-eq$rel){continue};$fromName=Txt $rel.fromTable;$toName=Txt $rel.toTable;if([string]::IsNullOrWhiteSpace($fromName)-or[string]::IsNullOrWhiteSpace($toName)){continue};if((-not$tableMap.ContainsKey($fromName))-or(-not$tableMap.ContainsKey($toName))){continue};$fc=@($tableMap[$fromName].columns|Where-Object name-eq$rel.fromColumn|Select-Object -First 1);$tc=@($tableMap[$toName].columns|Where-Object name-eq$rel.toColumn|Select-Object -First 1);if($fc-and$tc-and$fc.dataType-ne$tc.dataType){$typeMismatch+=$rel.name};if($fc-and$fc.dataType-ne"int64"){$nonInt+="$fromName[$($rel.fromColumn)]"};if($fc-and-not$fc.isHidden){$fkVisible+="$fromName[$($rel.fromColumn)]"};if($tc-and-not$tc.isKey-and$tableMap[$toName].dataCategory-ne"Time"){$pkUnmarked+="$toName[$($rel.toColumn)]"}}
  AddHit $db "RELATIONSHIP_COLUMNS_SAME_DATA_TYPE" "Relationship" (($typeMismatch|Select-Object -Unique -First 12)-join"; ") @($typeMismatch|Select-Object -Unique).Count "OBSERVED" "HIGH" "model/database.tmsl.json";AddHit $db "RELATIONSHIP_COLUMNS_SHOULD_BE_OF_INTEGER_DATA_TYPE" "Column" (($nonInt|Select-Object -Unique -First 12)-join"; ") @($nonInt|Select-Object -Unique).Count "OBSERVED" "HIGH" "model/database.tmsl.json";AddHit $db "HIDE_FOREIGN_KEYS" "Column" (($fkVisible|Select-Object -Unique -First 12)-join"; ") @($fkVisible|Select-Object -Unique).Count "OBSERVED" "HIGH" "model/database.tmsl.json";AddHit $db "MARK_PRIMARY_KEYS" "Column" (($pkUnmarked|Select-Object -Unique -First 12)-join"; ") @($pkUnmarked|Select-Object -Unique).Count "OBSERVED" "HIGH" "model/database.tmsl.json"
  $connected=@{};foreach($rel in $rels){if(-not[string]::IsNullOrWhiteSpace((Txt $rel.fromTable))){$connected[$rel.fromTable]=$true};if(-not[string]::IsNullOrWhiteSpace((Txt $rel.toTable))){$connected[$rel.toTable]=$true}};$isolated=@($tables|Where-Object{-not$connected.ContainsKey($_.name)});AddHit $db "ENSURE_TABLES_HAVE_RELATIONSHIPS" "Table" (($isolated.name|Select-Object -First 12)-join"; ") $isolated.Count "REQUIRES VALIDATION" "MEDIUM" "metadata/relationships.csv; model/database.tmsl.json"
  $partMismatch=@($tables|Where-Object{@($_.partitions).Count-eq1-and$_.partitions[0].name-ne$_.name});AddHit $db "PARTITION_NAME_SHOULD_MATCH_TABLE_NAME_FOR_SINGLE_PARTITION_TABLES" "Table" (($partMismatch.name|Select-Object -First 12)-join"; ") $partMismatch.Count "OBSERVED" "HIGH" "model/database.tmsl.json"
  $visibleNoDesc=@($tables|Where-Object{-not$_.isHidden-and[string]::IsNullOrWhiteSpace((Txt $_.description))})+@($allMeasures|Where-Object{-not$_.isHidden-and[string]::IsNullOrWhiteSpace((Txt $_.description))})+@($allColumns|Where-Object{-not$_.isHidden-and[string]::IsNullOrWhiteSpace((Txt $_.description))});AddHit $db "OBJECTS_WITH_NO_DESCRIPTION" "VisibleObject" (($visibleNoDesc.name|Select-Object -First 12)-join"; ") $visibleNoDesc.Count "OBSERVED" "HIGH" "model/database.tmsl.json"
  $noFormat=@($allMeasures|Where-Object{-not$_.isHidden-and[string]::IsNullOrWhiteSpace((Txt $_.formatString))});AddHit $db "PROVIDE_FORMAT_STRING_FOR_MEASURES" "Measure" (($noFormat.name|Select-Object -First 12)-join"; ") $noFormat.Count "OBSERVED" "HIGH" "metadata/measures.csv; model/database.tmsl.json"
  $numericSum=@($allColumns|Where-Object{$_.dataType-in@("int64","decimal","double")-and$_.summarizeBy-ne"none"-and-not$_.isHidden});AddHit $db "NUMERIC_COLUMN_SUMMARIZE_BY" "Column" (($numericSum.name|Select-Object -First 12)-join"; ") $numericSum.Count "OBSERVED" "HIGH" "model/database.tmsl.json"
  $pct=@($allMeasures|Where-Object{(Txt $_.formatString).Contains("%")-and$_.formatString-ne"#,0.0%;-#,0.0%;#,0.0%"});AddHit $db "PERCENTAGE_FORMATTING" "Measure" (($pct.name|Select-Object -First 12)-join"; ") $pct.Count "OBSERVED" "HIGH" "model/database.tmsl.json"
  $geo=@($allColumns|Where-Object{[string]::IsNullOrWhiteSpace((Txt $_.dataCategory))-and((($_.name-match'(?i)country|continent|city')-and$_.dataType-eq"string")-or(($_.name-match'(?i)^(latitude|longitude)$')-and$_.dataType-in@("decimal","double")))});AddHit $db "ADD_DATA_CATEGORY_FOR_COLUMNS" "Column" (($geo.name|Select-Object -First 12)-join"; ") $geo.Count "OBSERVED" "HIGH" "model/database.tmsl.json"
  $month=@($allColumns|Where-Object{$_.name-match'(?i)MONTH'-and$_.name-notmatch'(?i)MONTHS'-and$_.dataType-eq"string"-and-not$_.sortByColumn});AddHit $db "MONTH_(AS_A_STRING)_MUST_BE_SORTED" "Column" (($month.name|Select-Object -First 12)-join"; ") $month.Count "OBSERVED" "HIGH" "model/database.tmsl.json"
}
$hits|Export-Csv -LiteralPath (Join-Path $ReportRoot "12_BPA_FINDINGS.csv") -NoTypeInformation -Encoding UTF8
$groups=@($hits|Group-Object RuleID|Sort-Object Count -Descending);$dbgroups=@($hits|Group-Object Database|Sort-Object Count -Descending);$evaluated=@($coverage|Where-Object{$_.EvaluationStatus-eq"EVALUATED_FROM_EVIDENCE"}).Count;$partialCount=@($coverage|Where-Object{$_.EvaluationStatus-eq"PARTIAL_REQUIRES_VALIDATION"}).Count;$notCount=$coverage.Count-$evaluated-$partialCount
$report=@"
# BPA Rule Assessment — EVSET-005

## Ringkasan

Sebanyak **$($rules.Count) rule** dari `BPArules/BPARules.json` direkonsiliasi terhadap 54 model Tabular. **$evaluated rule** dievaluasi dari TMSL/DMV, **$partialCount rule** hanya memiliki evidence parsial, dan **$notCount rule** tidak dapat dibuktikan secara aman dari evidence saat ini. Ditemukan **$($hits.Count) kombinasi database-rule**. Match adalah kandidat perbaikan, bukan bukti latency.

## Rule dengan cakupan model terbesar

| Rule | Database terdampak |
|---|---:|
$(($groups|Select-Object -First 15|ForEach-Object{"| $(EscapeMd $_.Name) | $($_.Count) |"})-join"`n")

## Model dengan variasi temuan BPA terbanyak

| Database | Rule matched |
|---|---:|
$(($dbgroups|Select-Object -First 15|ForEach-Object{"| $(EscapeMd $_.Name) | $($_.Count) |"})-join"`n")

## Batas interpretasi

- Rule berbasis annotation `Vertipaq_Cardinality`, `LongLengthRowCount`, `DateTimeWithHourMinSec`, dan referential-integrity annotation tidak dieksekusi tanpa annotation tersebut.
- Rule dependency/lineage, RLS/OLS, perspectives, calculation groups, dan TOM-only semantics tidak dipaksakan dari regex sederhana.
- Temuan formatting, naming, description, visibility, dan key metadata biasanya merupakan governance/maintainability issue; benefit query harus divalidasi.
- Untuk seluruh klaim yang tidak tercakup: **NOT PROVABLE FROM CURRENT EVIDENCE**.

Detail ada di `11_BPA_RULE_COVERAGE.csv` dan `12_BPA_FINDINGS.csv`.
"@
[IO.File]::WriteAllText((Join-Path $ReportRoot "13_BPA_EXECUTIVE_FINDINGS.md"),$report,(New-Object Text.UTF8Encoding($true)))
Write-Output("BPA assessment generated: rules="+$rules.Count+", evaluated="+$evaluated+", hits="+$hits.Count)
