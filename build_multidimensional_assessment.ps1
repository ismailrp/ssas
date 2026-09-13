<# Generates a separate Multidimensional scorecard and assessment. Windows PowerShell 4.0 compatible. #>
param(
    [string]$EvidenceRoot = '',
    [string]$ReportRoot = '',
    [string]$RuntimeRoot = ''
)

$ErrorActionPreference = 'Stop'
$scriptPath = $MyInvocation.MyCommand.Path
$scriptDirectory = if ($scriptPath) { Split-Path -Parent $scriptPath } else { (Get-Location).Path }
if (-not $EvidenceRoot) { $EvidenceRoot = Join-Path $scriptDirectory 'evidence\EVSET-005' }
if (-not $ReportRoot) {
    $ReportRoot = if ($env:SSAS_ASSESSMENT_REPORT_ROOT) { $env:SSAS_ASSESSMENT_REPORT_ROOT } else { Join-Path $EvidenceRoot 'REPORTS' }
}
if (-not (Test-Path -LiteralPath $EvidenceRoot)) { throw "EvidenceRoot tidak ditemukan: $EvidenceRoot" }
if (-not (Test-Path -LiteralPath $ReportRoot)) { New-Item -ItemType Directory -Path $ReportRoot -Force | Out-Null }

function Csv([string]$Path) { if (Test-Path -LiteralPath $Path) { return @(Import-Csv -LiteralPath $Path) }; return @() }
function Safe-Name([string]$Name) { return [string]::Join('_', $Name.Split([IO.Path]::GetInvalidFileNameChars())) }
function Escape-Md([string]$Value) { return $Value.Replace('|', '\|').Replace("`r", ' ').Replace("`n", ' ') }
function Number($Value) { $result=0.0; if ([double]::TryParse([string]$Value, [ref]$result)) { return $result }; return 0.0 }
function Score-Level([int]$Score) { if ($Score -ge 80) { 'CRITICAL' } elseif ($Score -ge 60) { 'HIGH' } elseif ($Score -ge 30) { 'MEDIUM' } else { 'LOW' } }
function Priority([int]$Score) { if ($Score -ge 80) { 'P0' } elseif ($Score -ge 60) { 'P1' } elseif ($Score -ge 30) { 'P2' } else { 'P3' } }
function Rank-Percentile([object[]]$Values, [double]$Value) {
    if ($Values.Count -le 1) { return 50 }
    $below=@($Values | Where-Object {[double]$_ -lt $Value}).Count
    $equal=@($Values | Where-Object {[double]$_ -eq $Value}).Count
    return [math]::Round(100 * ($below + (0.5 * $equal)) / $Values.Count)
}
function Percentile([object[]]$Values, [double]$Fraction) {
    $sorted=@($Values | ForEach-Object {[double]$_} | Sort-Object)
    if ($sorted.Count -eq 0) { return '' }
    $index=[math]::Ceiling($Fraction*$sorted.Count)-1
    if ($index -lt 0) { $index=0 }
    return $sorted[$index]
}

if (-not $RuntimeRoot) {
    $runtimeBase=Join-Path $EvidenceRoot 'RUNTIME'
    if (Test-Path -LiteralPath $runtimeBase) {
        $candidate=Get-ChildItem -LiteralPath $runtimeBase -Directory | Sort-Object LastWriteTime -Descending | Where-Object {
            Test-Path -LiteralPath (Join-Path $_.FullName 'Multidimensional\queries.csv')
        } | Select-Object -First 1
        if ($candidate) { $RuntimeRoot=$candidate.FullName }
    }
}
$runtimeQueries=@()
$runtimeEvents=@()
if ($RuntimeRoot) {
    $runtimeQueries=Csv (Join-Path $RuntimeRoot 'Multidimensional\queries.csv')
    $runtimeEvents=Csv (Join-Path $RuntimeRoot 'Multidimensional\events.csv')
}

$inventory = Csv (Join-Path $EvidenceRoot 'MANIFEST\databases.csv')
$multi = @($inventory | Where-Object { $_.ServerType -eq 'MULTIDIMENSIONAL' })
$rows = @()
foreach ($item in $multi) {
    $name=[string]$item.Database
    $base=Join-Path (Join-Path (Join-Path $EvidenceRoot 'MULTIDIMENSIONAL') (Safe-Name $name)) 'metadata_extended'
    $partitions=@(Csv (Join-Path $base 'partitions.csv'))
    $usage=@(Csv (Join-Path $base 'dimension_usage.csv'))
    $attributes=@(Csv (Join-Path $base 'dimension_attributes.csv'))
    $relationships=@(Csv (Join-Path $base 'attribute_relationships.csv'))
    $hierarchies=@(Csv (Join-Path $base 'user_hierarchies.csv'))
    $designs=@(Csv (Join-Path $base 'aggregation_designs.csv'))
    $aggregations=@(Csv (Join-Path $base 'aggregations.csv'))
    $calculations=@(Csv (Join-Path $base 'calculations.csv'))
    $roles=@(Csv (Join-Path $base 'roles.csv'))
    $required=@('partitions.csv','dimension_usage.csv','dimension_attributes.csv','attribute_relationships.csv','user_hierarchies.csv','aggregation_designs.csv','aggregations.csv','calculations.csv')
    $missingRequired=@($required | Where-Object {-not (Test-Path -LiteralPath (Join-Path $base $_))})
    $estimated=@($partitions | ForEach-Object { Number $_.EstimatedRows } | Where-Object {$_ -gt 0})
    $maxEstimated=if($estimated.Count){($estimated | Measure-Object -Maximum).Maximum}else{0}
    $totalEstimated=if($estimated.Count){($estimated | Measure-Object -Sum).Sum}else{0}
    $withoutDesign=@($partitions | Where-Object {-not $_.AggregationDesignID}).Count
    $metadataPresent=(Test-Path -LiteralPath $base)
    $dbRuntime=@($runtimeQueries | Where-Object {$_.DatabaseName -eq $name})
    $dbBusinessRuntime=@($dbRuntime | Where-Object {
        $text=[string]$_.QueryText
        $text -notmatch '(?i)DISCOVER_|MDSCHEMA_|DBSCHEMA_|SYSTEMRESTRICTSCHEMA'
    })
    $dbRuntimeEvents=@($runtimeEvents | Where-Object {$_.DatabaseName -eq $name})
    $durations=@($dbRuntime | ForEach-Object {Number $_.TotalMs})
    $runtimeCoverage=if($dbRuntime.Count -eq 0){'MISSING'}elseif($dbBusinessRuntime.Count -eq 0){'METADATA_ONLY'}else{'PARTIAL'}
    $rows += [pscustomobject]@{
        Database=$name; EvidenceCoverage=$(if(-not $metadataPresent){'MISSING'}elseif($missingRequired.Count){'PARTIAL'}else{'COMPLETE'})
        PartitionCount=$partitions.Count; MeasureGroupDimensionUsageCount=$usage.Count
        DimensionAttributeCount=$attributes.Count; AttributeRelationshipCount=$relationships.Count
        UserHierarchyLevelCount=$hierarchies.Count; AggregationDesignCount=$designs.Count
        AggregationCount=$aggregations.Count; CalculationCommandCount=$calculations.Count; RoleCount=$roles.Count
        MaxPartitionEstimatedRows=[long]$maxEstimated; TotalPartitionEstimatedRows=[long]$totalEstimated
        PartitionsWithoutAggregationDesign=$withoutDesign
        LastProcessedKnownCount=@($partitions | Where-Object {$_.LastProcessed}).Count
        RuntimeCoverage=$runtimeCoverage; RuntimeExecutions=$dbRuntime.Count; BusinessRuntimeExecutions=$dbBusinessRuntime.Count
        RuntimeDistinctHashes=@($dbRuntime.QueryHashSHA256 | Where-Object {$_} | Select-Object -Unique).Count
        RuntimeTotalMs=$(if($durations.Count){[math]::Round(($durations|Measure-Object -Sum).Sum,2)}else{''})
        RuntimeP50Ms=$(Percentile $durations 0.50); RuntimeP95Ms=$(Percentile $durations 0.95); RuntimeP99Ms=$(Percentile $durations 0.99)
        RuntimeMaxMs=$(if($durations.Count){($durations|Measure-Object -Maximum).Maximum}else{''})
        RuntimeStart=$(if($dbRuntime.Count){($dbRuntime|Sort-Object QueryEndTimestamp|Select-Object -First 1).QueryEndTimestamp}else{''})
        RuntimeEnd=$(if($dbRuntime.Count){($dbRuntime|Sort-Object QueryEndTimestamp|Select-Object -Last 1).QueryEndTimestamp}else{''})
        RuntimeErrorEvents=@($dbRuntimeEvents | Where-Object {$_.EventName -eq 'Error'}).Count
        ProcessingEventCount=@($dbRuntimeEvents | Where-Object {$_.EventName -match '^(Command|ProgressReport)'}).Count
        ProcessingHistoryCoverage=$(if(@($dbRuntimeEvents | Where-Object {$_.EventName -match '^(Command|ProgressReport)'}).Count){'PARTIAL'}else{'MISSING'})
    }
}

if ($rows.Count -gt 0) {
    foreach ($m in $rows) {
        if ($m.EvidenceCoverage -eq 'MISSING') {
            $m | Add-Member NoteProperty StructuralScore ''
            $m | Add-Member NoteProperty PartitionScore ''
            $m | Add-Member NoteProperty RelationshipScore ''
            $m | Add-Member NoteProperty AggregationScore ''
            $m | Add-Member NoteProperty CalculationScore ''
            $m | Add-Member NoteProperty OverallScore ''
            $m | Add-Member NoteProperty RiskLevel 'INFORMATIONAL'
            $m | Add-Member NoteProperty Priority 'P3'
            continue
        }
        $struct=[math]::Round((Rank-Percentile @($rows.DimensionAttributeCount) $m.DimensionAttributeCount)*0.6 + (Rank-Percentile @($rows.UserHierarchyLevelCount) $m.UserHierarchyLevelCount)*0.4)
        $part=''
        if ($m.TotalPartitionEstimatedRows -gt 0) {
            $concentration=100*[double]$m.MaxPartitionEstimatedRows/[double]$m.TotalPartitionEstimatedRows
            $part=[math]::Round(0.6*(Rank-Percentile @($rows.MaxPartitionEstimatedRows) $m.MaxPartitionEstimatedRows)+0.4*$concentration)
        }
        $rel=[math]::Round((Rank-Percentile @($rows.MeasureGroupDimensionUsageCount) $m.MeasureGroupDimensionUsageCount)*0.6 + (Rank-Percentile @($rows.AttributeRelationshipCount) $m.AttributeRelationshipCount)*0.4)
        $agg=''
        if ($m.PartitionCount -gt 0) { $agg=[math]::Round(100*[double]$m.PartitionsWithoutAggregationDesign/[double]$m.PartitionCount) }
        $calc=[math]::Round((Rank-Percentile @($rows.CalculationCommandCount) $m.CalculationCommandCount))
        # Missing categories are excluded; weights are normalized across available static dimensions.
        $available=@(@($struct,$part,$rel,$agg,$calc) | Where-Object {$_ -ne ''})
        $overall=[math]::Round(($available | Measure-Object -Average).Average)
        $m | Add-Member NoteProperty StructuralScore $struct
        $m | Add-Member NoteProperty PartitionScore $part
        $m | Add-Member NoteProperty RelationshipScore $rel
        $m | Add-Member NoteProperty AggregationScore $agg
        $m | Add-Member NoteProperty CalculationScore $calc
        $m | Add-Member NoteProperty OverallScore $overall
        $m | Add-Member NoteProperty RiskLevel (Score-Level $overall)
        $m | Add-Member NoteProperty Priority (Priority $overall)
    }
}

$scorePath=Join-Path $ReportRoot '12_MULTIDIMENSIONAL_SCORECARD.csv'
$rows | Sort-Object OverallScore -Descending | Export-Csv -LiteralPath $scorePath -NoTypeInformation -Encoding UTF8

$manifest=Csv (Join-Path $EvidenceRoot 'MANIFEST\multidimensional_collection_manifest.csv')
$manifestSummary=if($manifest.Count){($manifest | Group-Object Status | ForEach-Object { $_.Name+'='+$_.Count }) -join ', '}else{'extended collector has not been run'}
$tableRows = if ($rows.Count) {
    ($rows | Sort-Object OverallScore -Descending | ForEach-Object {
        "| $(Escape-Md $_.Database) | $($_.EvidenceCoverage) | $($_.RuntimeCoverage) | $($_.RuntimeExecutions) | $($_.BusinessRuntimeExecutions) | $($_.PartitionCount) | $($_.DimensionAttributeCount) | $($_.AggregationCount) | $($_.OverallScore) | $($_.RiskLevel)/$($_.Priority) |"
    }) -join "`n"
} else { '| — | MISSING | MISSING | — | — | — | — | — | — | INFORMATIONAL |' }
$runtimeRows = if ($rows.Count) {
    ($rows | Sort-Object Database | ForEach-Object {
        "| $(Escape-Md $_.Database) | $($_.RuntimeCoverage) | $($_.RuntimeExecutions) | $($_.RuntimeDistinctHashes) | $($_.RuntimeTotalMs) | $($_.RuntimeP50Ms) | $($_.RuntimeP95Ms) | $($_.RuntimeP99Ms) | $($_.RuntimeMaxMs) | $($_.RuntimeErrorEvents) | $($_.ProcessingEventCount) |"
    }) -join "`n"
} else { '| — | MISSING | — | — | — | — | — | — | — | — | — |' }

$report=@"
# SSAS Multidimensional Assessment

## Scope and evidence coverage

This assessment is separate from the Tabular/VertiPaq score. It covers $($rows.Count) Multidimensional databases. Extended collector manifest: **$manifestSummary**.

| Database | Static coverage | Runtime coverage | Captured queries | Business queries | Partitions | Dimension attributes | Aggregations | Score | Risk/Priority |
|---|---|---|---:|---:|---:|---:|---:|---:|---|
$tableRows

The score is a fleet-relative prioritization signal across Multidimensional models, not measured latency. With only $($rows.Count) models, percentile separation is directional and must not be treated as an absolute health rating.

## Parsed XEvent runtime

| Database | Coverage | Queries | Hashes | Total ms | P50 | P95 | P99 | Max | Error events | Processing events |
|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
$runtimeRows

The captured durations above describe metadata/schema discovery traffic when coverage is `METADATA_ONLY`. They must not be presented as business-query latency. No `Command*` or `ProgressReport*` event means processing duration remains unavailable.

## Methodology

- Structural: dimension-attribute and user-hierarchy-level percentile.
- Partition: maximum estimated partition rows plus row concentration, only when estimated-row evidence exists. Count alone is not scored as a defect.
- Relationship: measure-group dimension usage and attribute-relationship percentile.
- Aggregation: proportion of partitions without an aggregation design. This is only a review signal; aggregation may be unnecessary for a workload.
- Calculation: MDX command-count percentile. Definitions are stored only as hash/length by the collector.
- Runtime, processing, and any unavailable static category are excluded; weights are normalized across categories supported for each database.

## Current conclusions

- Static metadata can identify candidates for dimension, partition, aggregation, and MDX review.
- `METADATA_ONLY` runtime means XEvent queries were DMV/schema discovery calls, not representative MDX business workload.
- Query latency, cache effectiveness, aggregation hit rate, processing bottlenecks, CPU pressure, and memory pressure are **NOT PROVABLE FROM CURRENT EVIDENCE**.
- No partition, aggregation, hierarchy, calculation, role, or source object should be changed from this report alone.

## Required next evidence

1. Capture 3-5 representative MDX queries per selected cube, with one warm-up and at least three comparable warm runs.
2. Capture 2-3 normal processing runs with Command, ProgressReport, and Error events scoped to database and time window.
3. Record cube, measure group, partition, process type, start/end, rows, status, and errors.
4. Validate report/client dependencies before simplifying dimensions, hierarchies, calculations, or aggregations.
5. Compare semantic results and query/processing measurements before and after every approved change.
"@
Set-Content -LiteralPath (Join-Path $ReportRoot '13_MULTIDIMENSIONAL_ASSESSMENT.md') -Encoding UTF8 -Value $report
Write-Output "Generated Multidimensional reports: databases=$($rows.Count); reportRoot=$ReportRoot"
