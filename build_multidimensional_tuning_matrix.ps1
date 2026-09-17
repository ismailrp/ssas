<# Builds an evidence-driven Multidimensional tuning matrix from the MD scorecard. Windows PowerShell 4.0 compatible. #>
[CmdletBinding()]
param(
    [string]$ScorecardPath = '',
    [string]$ReportRoot = ''
)

$ErrorActionPreference = 'Stop'
$scriptPath = $MyInvocation.MyCommand.Path
$scriptDirectory = if ($scriptPath) { Split-Path -Parent $scriptPath } else { (Get-Location).Path }
if (-not $ReportRoot) { $ReportRoot = Join-Path $scriptDirectory 'REPORTS' }
if (-not $ScorecardPath) { $ScorecardPath = Join-Path $ReportRoot '12_MULTIDIMENSIONAL_SCORECARD.csv' }
if (-not (Test-Path -LiteralPath $ScorecardPath)) { throw "Multidimensional scorecard tidak ditemukan: $ScorecardPath" }
if (-not (Test-Path -LiteralPath $ReportRoot)) { New-Item -ItemType Directory -Path $ReportRoot -Force | Out-Null }

function Num($Value) { $number=0.0; if ([double]::TryParse([string]$Value,[ref]$number)) { return $number }; return 0.0 }
function Add-MatrixRow {
    param($Database,$Area,$Priority,$Tag,$Classification,$Confidence,$Observation,$Impact,$Action,$Benefit,$Effort,$Risk,$Validation,$Evidence)
    $script:sequence++
    $script:matrix.Add((New-Object PSObject -Property ([ordered]@{
        MatrixID=('MD-TUNE-{0:D3}' -f $script:sequence); Database=$Database; TuningArea=$Area
        Priority=$Priority; Tag=$Tag; Classification=$Classification; Confidence=$Confidence
        Observation=$Observation; PerformanceImpact=$Impact; RecommendedAction=$Action
        ExpectedBenefit=$Benefit; Effort=$Effort; Risk=$Risk; ValidationMethod=$Validation
        EvidenceFiles=$Evidence
    })))
}

$scorecard=@(Import-Csv -LiteralPath $ScorecardPath)
$matrix=New-Object System.Collections.Generic.List[object]
$sequence=0
foreach ($m in $scorecard) {
    $db=[string]$m.Database
    $score=Num $m.OverallScore
    $structPriority=if($score -ge 80){'P1'}elseif($score -ge 30){'P2'}else{'P3'}
    $gapPriority=if($score -ge 80){'P1'}else{'P2'}
    $partitionPriority=if((Num $m.PartitionCount) -le 1){'P1'}else{'P2'}
    $calcPriority=if((Num $m.CalculationCommandCount) -gt 0){'P2'}else{'P3'}
    $source='REPORTS/12_MULTIDIMENSIONAL_SCORECARD.csv; MULTIDIMENSIONAL/'+$db+'/metadata_extended'

    Add-MatrixRow $db 'Dimension and hierarchy design' $structPriority 'NEEDS VALIDATION' 'OBSERVED' 'HIGH' `
        ("{0} dimension attributes and {1} user-hierarchy levels; fleet-relative structural score {2}." -f $m.DimensionAttributeCount,$m.UserHierarchyLevelCount,$m.StructuralScore) `
        'A broad or poorly aligned dimension surface can increase processing and query work, but workload impact has not been measured.' `
        'Review attribute usage, hierarchy naturalness, key/name properties, and client dependencies; do not remove attributes solely from counts.' `
        'A simpler, workload-aligned dimension surface and more predictable navigation.' 'MEDIUM' 'MEDIUM - semantic or client regression if attributes/hierarchies change.' `
        'Run dependency review and representative MDX before/after tests; compare results, warm duration, subcube requests, and processing duration.' $source

    Add-MatrixRow $db 'Attribute relationships and dimension usage' $structPriority 'HIGH VALUE' 'OBSERVED' 'HIGH' `
        ("{0} measure-group dimension usages and {1} attribute relationships; fleet-relative relationship score {2}." -f $m.MeasureGroupDimensionUsageCount,$m.AttributeRelationshipCount,$m.RelationshipScore) `
        'Incorrect or incomplete relationships can limit aggregation/navigation efficiency; the current counts alone do not prove a defect.' `
        'Validate relationship type, granularity, rigidity, cardinality, and natural hierarchy paths against dimension keys and business semantics.' `
        'Potentially better aggregation eligibility and lower dimension-processing work where a confirmed design defect exists.' 'MEDIUM' 'HIGH - incorrect relationships can change results.' `
        'Process an isolated approved test model and compare representative MDX results, QuerySubcube behavior, and dimension processing time.' $source

    $partitionObservation=("{0} partitions; estimated-row evidence totals {1}; LastProcessed is known for {2} partitions." -f $m.PartitionCount,$m.TotalPartitionEstimatedRows,$m.LastProcessedKnownCount)
    Add-MatrixRow $db 'Partition strategy' $partitionPriority 'NEEDS VALIDATION' 'INFERRED' 'MEDIUM' $partitionObservation `
        'Low partition count may enlarge processing scope, but row distribution and actual processing duration are unavailable.' `
        'Collect row distribution and 2-3 normal processing runs; pilot time-based partitions only when source predicates and operational boundaries support them.' `
        'Potentially smaller processing scope and safer operational recovery.' 'HIGH' 'HIGH - partition changes affect processing, deployment, and operational procedures.' `
        'Compare approved before/after processing duration, rows, status, errors, query results, and partition elimination behavior.' $source

    Add-MatrixRow $db 'Aggregation design' $gapPriority 'HIGH VALUE' 'OBSERVED' 'HIGH' `
        ("{0} aggregation designs and {1} aggregations; {2} of {3} partitions have no aggregation design." -f $m.AggregationDesignCount,$m.AggregationCount,$m.PartitionsWithoutAggregationDesign,$m.PartitionCount) `
        'Absence of aggregations may increase fact-level scans for some workloads, but aggregations may be unnecessary and no hit-rate evidence is available.' `
        'Capture representative business MDX with QuerySubcube and aggregation/cache events; design a small workload-driven aggregation pilot only for confirmed scan patterns.' `
        'Potentially lower Storage Engine work for repeated high-level queries.' 'HIGH' 'HIGH - aggregations add processing time, storage, and maintenance cost.' `
        'Measure warm-query duration, subcube granularity, aggregation hits, processing duration, storage growth, and semantic equality before/after.' $source

    Add-MatrixRow $db 'MDX calculations' $calcPriority 'NEEDS VALIDATION' 'OBSERVED' 'HIGH' `
        ("{0} calculation commands; fleet-relative calculation score {1}." -f $m.CalculationCommandCount,$m.CalculationScore) `
        'Calculation count does not establish Formula Engine cost; calculation definitions and business-query timings are insufficient.' `
        'Review calculation solve order, scope, repeated expressions, and cell-by-cell patterns only after identifying a measured business-query hotspot.' `
        'Potentially lower Formula Engine work for confirmed hotspots.' 'MEDIUM' 'HIGH - MDX calculation changes can alter values and solve-order semantics.' `
        'Use representative MDX warm runs, query plan/profile evidence, and cell-level semantic regression tests.' $source

    Add-MatrixRow $db 'Business query profiling' $gapPriority 'NEEDS VALIDATION' 'REQUIRES VALIDATION' 'HIGH' `
        ("Runtime coverage is {0}: {1} captured executions, but {2} business executions." -f $m.RuntimeCoverage,$m.RuntimeExecutions,$m.BusinessRuntimeExecutions) `
        'Business latency, cache effectiveness, aggregation hit rate, and query bottlenecks are NOT PROVABLE FROM CURRENT EVIDENCE.' `
        'Capture 3-5 representative business MDX queries, one warm-up and at least three comparable warm runs, with narrowly filtered QuerySubcube and cache/aggregation events.' `
        'Establishes a valid workload baseline and prevents speculative tuning.' 'LOW' 'LOW - read-only trace when narrowly filtered and promptly stopped.' `
        'Record query hash/name, database, cache mode, total duration, subcube activity, errors, and comparable before/after runs.' 'REPORTS/12_MULTIDIMENSIONAL_SCORECARD.csv; REPORTS/14_XEVENT_PARSE_QUALITY.md'

    Add-MatrixRow $db 'Processing profiling' $gapPriority 'NEEDS VALIDATION' 'REQUIRES VALIDATION' 'HIGH' `
        ("Processing event count is {0}; processing-history coverage is {1}." -f $m.ProcessingEventCount,$m.ProcessingHistoryCoverage) `
        'Processing duration, bottleneck stage, rows processed, and refresh reliability are NOT PROVABLE FROM CURRENT EVIDENCE.' `
        'Capture 2-3 normal processing runs using filtered Command, ProgressReport, and Error events without changing the normal process type.' `
        'Creates the baseline needed to prioritize partition, source, aggregation, or dimension-processing changes.' 'LOW' 'LOW - passive trace with database/time filters and retention control.' `
        'Record cube, measure group, partition, process type, start/end, rows, status, and errors for comparable runs.' 'REPORTS/12_MULTIDIMENSIONAL_SCORECARD.csv; REPORTS/14_XEVENT_PARSE_QUALITY.md'
}

$outputPath=Join-Path $ReportRoot '15_MULTIDIMENSIONAL_TUNING_MATRIX.csv'
$matrix | Select-Object MatrixID,Database,TuningArea,Priority,Tag,Classification,Confidence,Observation,PerformanceImpact,RecommendedAction,ExpectedBenefit,Effort,Risk,ValidationMethod,EvidenceFiles |
    Export-Csv -LiteralPath $outputPath -NoTypeInformation -Encoding UTF8
Write-Output ("Generated Multidimensional tuning matrix: rows={0}; path={1}" -f $matrix.Count,$outputPath)
