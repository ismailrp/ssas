[CmdletBinding()]
param(
    [string]$EvidenceRoot = "",
    [string]$XEventRunRoot = "",
    [string]$StaticReportRoot = "",
    [string]$ReportRoot = ""
)

$ErrorActionPreference = "Stop"
$scriptPath = $MyInvocation.MyCommand.Path
$scriptDirectory = if ($scriptPath) { Split-Path -Parent $scriptPath } else { (Get-Location).Path }
if (-not $EvidenceRoot) { $EvidenceRoot = Join-Path $scriptDirectory "evidence\EVSET-005" }
if (-not $XEventRunRoot) { $XEventRunRoot = Join-Path $scriptDirectory "results\XEvents\FINAL-XEL-20260911-ALL-V2" }
if (-not $StaticReportRoot) { $StaticReportRoot = Join-Path $EvidenceRoot "REPORTS" }
if (-not $ReportRoot) { $ReportRoot = Join-Path $scriptDirectory "REPORTS" }

$staticScorecardPath = Join-Path $StaticReportRoot "02_FLEET_SCORECARD.csv"
$staticFindingsPath = Join-Path $StaticReportRoot "04_FINDINGS.csv"
if ((-not (Test-Path -LiteralPath $staticScorecardPath)) -or (-not (Test-Path -LiteralPath $staticFindingsPath))) {
    $staticBuilder = Join-Path $scriptDirectory "build_assessment.ps1"
    if (-not (Test-Path -LiteralPath $staticBuilder)) { throw "Static assessment builder missing: $staticBuilder" }
    & $staticBuilder -EvidenceRoot $EvidenceRoot | Out-Host
}

function Ensure-Directory([string]$Path) { if (-not (Test-Path -LiteralPath $Path)) { New-Item -ItemType Directory -Path $Path -Force | Out-Null } }
function Csv([string]$Path) { if (Test-Path -LiteralPath $Path) { return @(Import-Csv -LiteralPath $Path) }; return @() }
function Num($Value) { $number = 0.0; if ([double]::TryParse([string]$Value, [Globalization.NumberStyles]::Any, [Globalization.CultureInfo]::InvariantCulture, [ref]$number)) { return $number }; return 0.0 }
function Escape-Markdown([string]$Value) { return $Value.Replace("|", "\|").Replace("`r", " ").Replace("`n", " ") }
function NearestRank([double[]]$Values, [double]$Percentile) { if ($Values.Count -eq 0) { return $null }; $sorted = @($Values | Sort-Object); $index = [Math]::Ceiling($Percentile * $sorted.Count) - 1; if ($index -lt 0) { $index = 0 }; return $sorted[$index] }
function Is-SystemQuery($Row) { return ([string]$Row.QueryText) -match '(?i)\$SYSTEM|DISCOVER_|TMSCHEMA_|MDSCHEMA_|DBSCHEMA_|select\s+1\s+as\s+\[ConnectionCount\]' }

foreach ($required in @(
    (Join-Path $EvidenceRoot "MANIFEST\summary.json"),
    (Join-Path $EvidenceRoot "MANIFEST\databases.csv"),
    (Join-Path $EvidenceRoot "MANIFEST\collection_manifest.csv"),
    (Join-Path $XEventRunRoot "summary.json"),
    (Join-Path $XEventRunRoot "Tabular\queries.csv"),
    (Join-Path $XEventRunRoot "Multidimensional\queries.csv"),
    $staticScorecardPath,
    $staticFindingsPath
)) { if (-not (Test-Path -LiteralPath $required)) { throw "Required input missing: $required" } }

Ensure-Directory $ReportRoot
$databaseReportRoot = Join-Path $ReportRoot "DATABASES"
Ensure-Directory $databaseReportRoot

$evidenceSummary = Get-Content -LiteralPath (Join-Path $EvidenceRoot "MANIFEST\summary.json") -Raw | ConvertFrom-Json
$xelSummary = Get-Content -LiteralPath (Join-Path $XEventRunRoot "summary.json") -Raw | ConvertFrom-Json
$scorecard = Csv $staticScorecardPath
$staticFindings = Csv $staticFindingsPath
$tabularQueries = Csv (Join-Path $XEventRunRoot "Tabular\queries.csv")
$mdQueries = Csv (Join-Path $XEventRunRoot "Multidimensional\queries.csv")

$business = @($tabularQueries | Where-Object { $_.DatabaseName -and -not (Is-SystemQuery $_) })
$systemTabular = @($tabularQueries | Where-Object { Is-SystemQuery $_ })
$unscoped = @($tabularQueries | Where-Object { -not $_.DatabaseName -and -not (Is-SystemQuery $_) })
$systemMd = @($mdQueries | Where-Object { Is-SystemQuery $_ })
$businessMd = @($mdQueries | Where-Object { -not (Is-SystemQuery $_) })

$runtimeRows = New-Object System.Collections.Generic.List[object]
foreach ($group in @($business | Group-Object DatabaseName)) {
    $durations = @($group.Group | ForEach-Object { Num $_.TotalMs })
    $cpuRows = @($group.Group | Where-Object { [string]$_.CpuTimeMs -match '^[0-9]' })
    $runtimeRows.Add((New-Object PSObject -Property @{
        Database = $group.Name
        EngineType = "TABULAR"
        WorkloadClass = "BUSINESS_CANDIDATE"
        Executions = $group.Count
        UniqueQueryHashes = @($group.Group.QueryHashSHA256 | Sort-Object -Unique).Count
        TotalDurationMs = [Math]::Round((($durations | Measure-Object -Sum).Sum), 0)
        P50DurationMs = NearestRank $durations 0.50
        P95DurationMs = NearestRank $durations 0.95
        P99DurationMs = NearestRank $durations 0.99
        MaxDurationMs = ($durations | Measure-Object -Maximum).Maximum
        CpuCoveredRows = $cpuRows.Count
        TotalCpuMs = [Math]::Round((($cpuRows | ForEach-Object { Num $_.CpuTimeMs } | Measure-Object -Sum).Sum), 0)
        MatchedSEQueries = @($group.Group | Where-Object { $_.CorrelationQuality -eq "MATCHED_BY_REQUEST_ID_WITH_ACTIVITY_ID" }).Count
        SEExceedsTotalQueries = @($group.Group | Where-Object { $_.CorrelationQuality -eq "MATCHED_SE_SUM_EXCEEDS_TOTAL" }).Count
        QueryOnlyNoSEQueries = @($group.Group | Where-Object { $_.CorrelationQuality -eq "QUERY_ONLY_NO_SE_EVENT" }).Count
        Representativeness = "REQUIRES VALIDATION"
    }))
}
$runtimeRows = @($runtimeRows | Sort-Object TotalDurationMs -Descending)
$runtimeRows | Select-Object Database,EngineType,WorkloadClass,Executions,UniqueQueryHashes,TotalDurationMs,P50DurationMs,P95DurationMs,P99DurationMs,MaxDurationMs,CpuCoveredRows,TotalCpuMs,MatchedSEQueries,SEExceedsTotalQueries,QueryOnlyNoSEQueries,Representativeness |
    Export-Csv -LiteralPath (Join-Path $ReportRoot "07_RUNTIME_DATABASE_BASELINE.csv") -NoTypeInformation -Encoding UTF8

$hashRows = New-Object System.Collections.Generic.List[object]
foreach ($group in @($business | Group-Object DatabaseName,QueryHashSHA256)) {
    $durations = @($group.Group | ForEach-Object { Num $_.TotalMs })
    $hashRows.Add((New-Object PSObject -Property @{
        Database = $group.Group[0].DatabaseName
        QueryHashSHA256 = $group.Group[0].QueryHashSHA256
        Executions = $group.Count
        TotalDurationMs = [Math]::Round((($durations | Measure-Object -Sum).Sum), 0)
        P50DurationMs = NearestRank $durations 0.50
        P95DurationMs = NearestRank $durations 0.95
        MaxDurationMs = ($durations | Measure-Object -Maximum).Maximum
        CorrelationQuality = (@($group.Group.CorrelationQuality | Sort-Object -Unique) -join ";")
        WorkloadClass = "BUSINESS_CANDIDATE"
    }))
}
$hashRows = @($hashRows | Sort-Object TotalDurationMs -Descending)
$hashRows | Select-Object Database,QueryHashSHA256,Executions,TotalDurationMs,P50DurationMs,P95DurationMs,MaxDurationMs,CorrelationQuality,WorkloadClass |
    Export-Csv -LiteralPath (Join-Path $ReportRoot "08_RUNTIME_QUERY_HASH_BASELINE.csv") -NoTypeInformation -Encoding UTF8

$runtimeByDatabase = @{}
foreach ($row in $runtimeRows) { $runtimeByDatabase[$row.Database] = $row }
foreach ($model in $scorecard) {
    $runtime = $runtimeByDatabase[$model.Database]
    $model | Add-Member NoteProperty RuntimeCoverage $(if ($runtime) { "PARTIAL_BUSINESS_CANDIDATE" } else { "NO_BUSINESS_CANDIDATE" })
    $model | Add-Member NoteProperty RuntimeExecutions $(if ($runtime) { $runtime.Executions } else { 0 })
    $model | Add-Member NoteProperty RuntimeP95Ms $(if ($runtime) { $runtime.P95DurationMs } else { "" })
    $model | Add-Member NoteProperty RuntimeMaxMs $(if ($runtime) { $runtime.MaxDurationMs } else { "" })
    $model | Add-Member NoteProperty RuntimeTotalMs $(if ($runtime) { $runtime.TotalDurationMs } else { "" })
}

$staticRank = @($scorecard | Sort-Object { Num $_.OverallScore } -Descending)
$deepNames = New-Object System.Collections.Generic.List[string]
foreach ($row in @($runtimeRows | Select-Object -First 4)) { if (-not $deepNames.Contains($row.Database)) { $deepNames.Add($row.Database) } }
foreach ($row in $staticRank) { if ($deepNames.Count -ge 8) { break }; if (-not $deepNames.Contains($row.Database)) { $deepNames.Add($row.Database) } }
foreach ($model in $scorecard) { $model.DeepDiveRecommended = [string]($deepNames.Contains($model.Database)) }
$scorecard | Sort-Object { Num $_.OverallScore } -Descending | Export-Csv -LiteralPath (Join-Path $ReportRoot "02_FLEET_SCORECARD.csv") -NoTypeInformation -Encoding UTF8

$findings = New-Object System.Collections.Generic.List[object]
foreach ($item in $staticFindings) {
    $findings.Add((New-Object PSObject -Property @{
        FindingID=$item.FindingID; Database=$item.Database; Category=$item.Category; Severity=$item.Severity
        Classification=$item.Classification; Confidence=$item.Confidence; Observation=$item.Observation
        EvidenceFiles=$item.EvidenceFiles; Analysis=$item.Impact; PerformanceImpact=$item.Impact
        Recommendation=$item.Recommendation; ExpectedBenefit=$item.ExpectedBenefit; Effort=$item.Effort
        Priority=$item.Priority; Risk="MEDIUM - semantic/dependency regression if changed without validation"
        ValidationMethod="Representative before/after query or refresh benchmark plus semantic result regression"
    }))
}
$nextFinding = $findings.Count + 1
foreach ($runtime in @($runtimeRows | Select-Object -First 6)) {
    $severity = if ($runtime.Database -eq "LKK") { "HIGH" } else { "MEDIUM" }
    $priority = if ($runtime.Database -eq "LKK") { "P1" } else { "P2" }
    $findings.Add((New-Object PSObject -Property @{
        FindingID=("F-{0:D3}" -f $nextFinding); Database=$runtime.Database; Category="Runtime workload"
        Severity=$severity; Classification="OBSERVED"; Confidence="HIGH"
        Observation=("Captured BUSINESS_CANDIDATE subset: {0} executions, total {1} ms, P50/P95/P99 {2}/{3}/{4} ms, max {5} ms." -f $runtime.Executions,$runtime.TotalDurationMs,$runtime.P50DurationMs,$runtime.P95DurationMs,$runtime.P99DurationMs,$runtime.MaxDurationMs)
        EvidenceFiles="results/XEvents/FINAL-XEL-20260911-ALL-V2/Tabular/queries.csv; REPORTS/07_RUNTIME_DATABASE_BASELINE.csv; REPORTS/08_RUNTIME_QUERY_HASH_BASELINE.csv"
        Analysis="This database contributes a material share of candidate query duration in the captured window. The trace is collector-contaminated and business-cycle representativeness is not established."
        PerformanceImpact="Measured duration exists for captured query hashes; typical user latency and root cause are NOT PROVABLE FROM CURRENT EVIDENCE."
        Recommendation="Reproduce the highest-total query hashes with business owners; collect at least three comparable warm runs and Server Timings before changing DAX/model design."
        ExpectedBenefit="Focus tuning effort on measured query candidates and avoid speculative rewrites."
        Effort="LOW"; Priority=$priority; Risk="LOW for profiling; MEDIUM for any later model/DAX change"
        ValidationMethod="Map hash to report/owner, one warm-up plus at least three warm runs; compare total/CPU/SE counts and semantic results before/after."
    }))
    $nextFinding++
}
$findings | Select-Object FindingID,Database,Category,Severity,Classification,Confidence,Observation,EvidenceFiles,Analysis,PerformanceImpact,Recommendation,ExpectedBenefit,Effort,Priority,Risk,ValidationMethod |
    Export-Csv -LiteralPath (Join-Path $ReportRoot "04_FINDINGS.csv") -NoTypeInformation -Encoding UTF8

$topStatic = @($staticRank | Select-Object -First 10)
$topRuntime = @($runtimeRows | Select-Object -First 10)
$coverageText = @"
| Area | Coverage | Interpretation |
|---|---|---|
| Inventory | COMPLETE | $($evidenceSummary.tabular_databases) Tabular and $($evidenceSummary.multidimensional_databases) Multidimensional databases. |
| Metadata/TMSL/storage | PARTIAL | Core metadata is broad; unsupported/skipped artifacts remain evidence gaps, not defects. |
| Tabular XEL parsing | COMPLETE | $($xelSummary.tabular_events) events and $($xelSummary.tabular_correlated_queries) correlated QueryEnd rows from 4 files. |
| Multidimensional XEL parsing | COMPLETE | $($xelSummary.multidimensional_events) events and $($xelSummary.multidimensional_correlated_queries) correlated query windows from 4 files. |
| Business workload representativeness | PARTIAL | $($business.Count) Tabular BUSINESS_CANDIDATE rows across $($runtimeRows.Count) databases; $($systemTabular.Count) Tabular and $($systemMd.Count) MD rows classified as system/DMV. |
| MD business workload | MISSING | All $($mdQueries.Count) correlated MD queries are system/DMV. |
| Refresh history / memory pressure | MISSING or SKIPPED | NOT PROVABLE FROM CURRENT EVIDENCE. |
"@

$executive = @"
# SSAS Performance Executive Assessment

**Evidence:** $($evidenceSummary.assessment_id), XEvent run $($xelSummary.run_id) | **Fleet:** $($evidenceSummary.tabular_databases) Tabular + $($evidenceSummary.multidimensional_databases) Multidimensional

## Outcome

The static fleet score remains a relative tuning-priority indicator, not latency. Runtime parsing identified $($business.Count) Tabular BUSINESS_CANDIDATE executions across $($runtimeRows.Count) databases. The XEL is heavily mixed with collector traffic ($($systemTabular.Count) Tabular system/DMV queries), so operational/runtime values are excluded from the overall score instead of being treated as representative fleet workload.

## Coverage

$coverageText

## Highest captured runtime signals

| Database | Executions | Total ms | P50 ms | P95 ms | P99 ms | Max ms |
|---|---:|---:|---:|---:|---:|---:|
$(($topRuntime | ForEach-Object { "| $(Escape-Markdown $_.Database) | $($_.Executions) | $($_.TotalDurationMs) | $($_.P50DurationMs) | $($_.P95DurationMs) | $($_.P99DurationMs) | $($_.MaxDurationMs) |" }) -join "`n")

These are observed values for the captured candidate subset. Typical user experience, SLA breach, peak concurrency, FE/SE dominance, and root cause remain **NOT PROVABLE FROM CURRENT EVIDENCE**.

## Priorities

1. P1: reproduce and profile the top `LKK` query hashes; retain result parity and before/after timings.
2. P1: validate storage and partition candidates from the fleet-relative scorecard using refresh history and dependency evidence.
3. P2: repeat a narrowly filtered trace during an agreed representative business window, excluding assessment collectors.
4. P2: obtain MD business queries and processing history; current MD trace proves only system/DMV activity.
"@
Set-Content -LiteralPath (Join-Path $ReportRoot "01_EXECUTIVE_ASSESSMENT.md") -Encoding UTF8 -Value $executive

$technical = @"
# SSAS Fleet Technical Assessment

## Scope and evidence

$coverageText

Collection metadata: collector $($evidenceSummary.collector_version), PowerShell $($evidenceSummary.powershell_version), started $($evidenceSummary.collection_started_at_utc), finished $($evidenceSummary.collection_finished_at_utc). XEL parsed at $($xelSummary.parsed_at_utc).

## Scoring

**02_FLEET_SCORECARD.csv** preserves the reproducible five-category static model: complexity 22.22%, storage 27.78%, partition 16.67%, relationship 16.67%, and static DAX 16.67%. Runtime is excluded because only $($runtimeRows.Count) databases have BUSINESS_CANDIDATE rows and trace representativeness is unverified. RuntimeCoverage, execution, P95, max, and total columns are signals for prioritization only.

## Static top ten

| Rank | Database | Overall | Level | Storage MB | Tables | Columns | Measures | Relationships | Partitions |
|---:|---|---:|---|---:|---:|---:|---:|---:|---:|
$(($topStatic | ForEach-Object { $rank=[array]::IndexOf($topStatic,$_)+1; "| $rank | $(Escape-Markdown $_.Database) | $($_.OverallScore) | $($_.RiskLevel) | $($_.UsedMB) | $($_.TableCount) | $($_.ColumnCount) | $($_.MeasureCount) | $($_.RelationshipCount) | $($_.PartitionCount) |" }) -join "`n")

## Runtime classification

- Tabular correlated queries: $($tabularQueries.Count).
- SYSTEM_DMV: $($systemTabular.Count); BUSINESS_CANDIDATE: $($business.Count); unscoped non-system: $($unscoped.Count).
- Multidimensional correlated queries: $($mdQueries.Count); SYSTEM_DMV: $($systemMd.Count); BUSINESS_CANDIDATE: $($businessMd.Count).
- Tabular correlation quality: 741 matched with SE, 114 SE-sum-exceeds-total, and 2,959 query-only/no-SE across the full trace. `FEMsDerived` is not authoritative for the latter two classes.

## Runtime database baseline

| Database | Exec | Unique hashes | Total ms | P50 | P95 | P99 | Max | SE matched | SE exceeds total |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
$(($runtimeRows | ForEach-Object { "| $(Escape-Markdown $_.Database) | $($_.Executions) | $($_.UniqueQueryHashes) | $($_.TotalDurationMs) | $($_.P50DurationMs) | $($_.P95DurationMs) | $($_.P99DurationMs) | $($_.MaxDurationMs) | $($_.MatchedSEQueries) | $($_.SEExceedsTotalQueries) |" }) -join "`n")

## Cross-evidence interpretation

**LKK** is the primary runtime deep-dive candidate because it dominates captured candidate duration and includes repeated high-duration hashes. This is measured workload concentration, not proof that its DAX, relationships, storage, or partition design caused the duration. Structural findings remain OBSERVED/INFERRED/REQUIRES VALIDATION as recorded in **04_FINDINGS.csv**.

MD runtime performance and refresh bottlenecks are **NOT PROVABLE FROM CURRENT EVIDENCE** because its trace contains only system/DMV queries and no processing history.

## Safe validation sequence

Map top hashes to business reports, capture a representative filtered window, run one warm-up plus at least three comparable warm runs, record total/CPU/SE query count and Server Timings, then test isolated changes with semantic regression and rollback gates. Cold-cache tests, clear cache, processing, deployment, and model changes require explicit approval/window.
"@
Set-Content -LiteralPath (Join-Path $ReportRoot "03_TECHNICAL_ASSESSMENT.md") -Encoding UTF8 -Value $technical

$backlog = @"
# Optimization Backlog

## P0

No P0 production change is justified by current evidence.

## P1

| Item | Scope | Tag | Benefit | Effort | Risk | Validation |
|---|---|---|---|---|---|---|
| Profile top captured query hashes | LKK | QUICK WIN, HIGH VALUE | Establish measured root cause | LOW | LOW | Owner mapping, 1 warm-up + 3 warm runs, Server Timings and result parity |
| Validate storage/partition candidates | Static top models | HIGH VALUE, NEEDS VALIDATION | Smaller scan/refresh scope if confirmed | MEDIUM-HIGH | MEDIUM | Dependency check, processing history, pilot and before/after metrics |

## P2

| Item | Scope | Tag | Benefit | Effort | Risk | Validation |
|---|---|---|---|---|---|---|
| Capture representative filtered workload | Fleet | QUICK WIN | Remove collector bias and establish reliable percentiles | LOW | LOW | Agreed business window and documented filter/retention |
| Profile next runtime candidates | Segregation, Premi Panen, Saldo Treasury | NEEDS VALIDATION | Confirm repeated workload hotspots | LOW-MEDIUM | LOW | Comparable query runs and semantic results |
| Capture MD business/processing events | 2 MD databases | NEEDS VALIDATION | Close runtime and refresh evidence gap | LOW | LOW | Filtered trace contains business QueryEnd and processing start/end |

## P3

Relationship simplification, DAX refactoring, column removal, and time partitioning remain architectural candidates. Do not deploy or delete objects until usage/dependency, semantic, processing, and runtime validation passes.
"@
Set-Content -LiteralPath (Join-Path $ReportRoot "05_OPTIMIZATION_BACKLOG.md") -Encoding UTF8 -Value $backlog

$deep = "# Deep-Dive Plan`n`nSelected from four highest captured runtime-duration contributors, then static fleet ranking, capped at eight.`n"
foreach ($name in $deepNames) {
    $model = @($scorecard | Where-Object { $_.Database -eq $name })[0]
    $runtime = $runtimeByDatabase[$name]
    $runtimeText = if ($runtime) { "Captured candidate runtime: $($runtime.Executions) executions, P95 $($runtime.P95DurationMs) ms, max $($runtime.MaxDurationMs) ms, total $($runtime.TotalDurationMs) ms." } else { "No BUSINESS_CANDIDATE query was captured; selection is static fleet-relative." }
    $deep += "`n## $(Escape-Markdown $name)`n`n- Why selected: static score $($model.OverallScore)/100 ($($model.RiskLevel)). $runtimeText`n- Evidence needed: report/owner mapping, representative filtered trace, Server Timings for top hashes, processing history by partition, and dependency inventory.`n- Diagnostics: one warm-up plus at least three comparable warm runs; inspect total/CPU/SE count and query plan; correlate only matching database/hash/window.`n- Expected outcome: confirm or reject the candidate cause and produce a semantic-safe before/after benchmark.`n"
}
Set-Content -LiteralPath (Join-Path $ReportRoot "06_DEEP_DIVE_PLAN.md") -Encoding UTF8 -Value $deep

foreach ($name in $deepNames) {
    $source = Join-Path (Join-Path $StaticReportRoot "DATABASES") (([string]::Join('_', $name.Split([IO.Path]::GetInvalidFileNameChars()))) + ".md")
    if (Test-Path -LiteralPath $source) {
        $content = Get-Content -LiteralPath $source -Raw
        $runtime = $runtimeByDatabase[$name]
        $runtimeSection = if ($runtime) { "## Runtime Evidence`n`nOBSERVED BUSINESS_CANDIDATE subset: $($runtime.Executions) executions; total $($runtime.TotalDurationMs) ms; P50/P95/P99 $($runtime.P50DurationMs)/$($runtime.P95DurationMs)/$($runtime.P99DurationMs) ms; max $($runtime.MaxDurationMs) ms. Representativeness and root cause are REQUIRES VALIDATION. Evidence: REPORTS/07_RUNTIME_DATABASE_BASELINE.csv and REPORTS/08_RUNTIME_QUERY_HASH_BASELINE.csv.`n`n" } else { "## Runtime Evidence`n`nNo BUSINESS_CANDIDATE query captured. Runtime performance is NOT PROVABLE FROM CURRENT EVIDENCE.`n`n" }
        $content = $content -replace '(?m)^## Model Complexity', ($runtimeSection + '## Model Complexity')
        $content = $content -replace 'No historical query duration/CPU, FE/SE timing, peak concurrency, refresh duration, memory-pressure series or object usage telemetry\.', 'Representative workload, authoritative FE/SE timing, peak concurrency, refresh duration, memory-pressure series and object usage telemetry remain incomplete.'
        Set-Content -LiteralPath (Join-Path $databaseReportRoot ([IO.Path]::GetFileName($source))) -Encoding UTF8 -Value $content
    }
}

Write-Output ("Finalized assessment: models=" + $scorecard.Count + ", runtime databases=" + $runtimeRows.Count + ", findings=" + $findings.Count + ", deep dives=" + $deepNames.Count)
