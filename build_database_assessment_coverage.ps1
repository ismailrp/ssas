<# Builds one assessment-coverage row for every inventoried SSAS database. Windows PowerShell 4.0 compatible. #>
[CmdletBinding()]
param(
    [string]$EvidenceRoot = '',
    [string]$ReportRoot = ''
)

$ErrorActionPreference = 'Stop'
$scriptPath = $MyInvocation.MyCommand.Path
$scriptDirectory = if ($scriptPath) { Split-Path -Parent $scriptPath } else { (Get-Location).Path }
if (-not $EvidenceRoot) { $EvidenceRoot = Join-Path $scriptDirectory 'evidence\EVSET-005' }
if (-not $ReportRoot) { $ReportRoot = Join-Path $scriptDirectory 'REPORTS' }
if (-not (Test-Path -LiteralPath $ReportRoot)) { New-Item -ItemType Directory -Path $ReportRoot -Force | Out-Null }

function Csv([string]$Path) { if (Test-Path -LiteralPath $Path) { return @(Import-Csv -LiteralPath $Path) }; return @() }
function Join-Unique($Values) { return (@($Values | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) } | Sort-Object -Unique) -join '; ') }
function Highest-Severity($Rows) {
    foreach ($severity in @('CRITICAL','HIGH','MEDIUM','LOW','INFORMATIONAL')) {
        if (@($Rows | Where-Object { $_.Severity -eq $severity }).Count -gt 0) { return $severity }
    }
    return 'NONE'
}

$inventory=Csv (Join-Path $EvidenceRoot 'MANIFEST\databases.csv')
$manifest=Csv (Join-Path $EvidenceRoot 'MANIFEST\collection_manifest.csv')
$fleet=Csv (Join-Path $ReportRoot '02_FLEET_SCORECARD.csv')
$findings=Csv (Join-Path $ReportRoot '04_FINDINGS.csv')
$runtime=Csv (Join-Path $ReportRoot '07_RUNTIME_DATABASE_BASELINE.csv')
$mdScore=Csv (Join-Path $ReportRoot '12_MULTIDIMENSIONAL_SCORECARD.csv')
$mdMatrix=Csv (Join-Path $ReportRoot '15_MULTIDIMENSIONAL_TUNING_MATRIX.csv')

if ($inventory.Count -eq 0) { throw 'Database inventory kosong atau tidak ditemukan.' }
if ($fleet.Count -eq 0) { throw '02_FLEET_SCORECARD.csv kosong atau tidak ditemukan.' }
if ($findings.Count -eq 0) { throw '04_FINDINGS.csv kosong atau tidak ditemukan.' }

$output=New-Object System.Collections.Generic.List[object]
foreach ($db in @($inventory | Sort-Object ServerType,Database)) {
    $name=[string]$db.Database
    $type=[string]$db.ServerType
    $score=@($fleet | Where-Object { $_.Database -eq $name }) | Select-Object -First 1
    $dbFindings=@($findings | Where-Object { $_.Database -eq $name })
    $dbManifest=@($manifest | Where-Object { $_.Database -eq $name })
    $dbRuntime=@($runtime | Where-Object { $_.Database -eq $name }) | Select-Object -First 1
    $md=@($mdScore | Where-Object { $_.Database -eq $name }) | Select-Object -First 1
    $mdActions=@($mdMatrix | Where-Object { $_.Database -eq $name })

    $successCount=@($dbManifest | Where-Object { $_.Status -eq 'SUCCESS' }).Count
    $emptyCount=@($dbManifest | Where-Object { $_.Status -eq 'SUCCESS_EMPTY' }).Count
    $unsupportedCount=@($dbManifest | Where-Object { $_.Status -eq 'QUERY_FAILED_OR_UNSUPPORTED' }).Count
    $skippedCount=@($dbManifest | Where-Object { $_.Status -eq 'SKIPPED' }).Count
    $evidenceCoverage=if ($type -eq 'MULTIDIMENSIONAL' -and $md) {
        [string]$md.EvidenceCoverage
    } elseif ($dbManifest.Count -eq 0) {
        'MISSING'
    } elseif (($successCount + $emptyCount) -eq 0) {
        'MISSING'
    } elseif ($unsupportedCount -gt 0 -or $skippedCount -gt 0) {
        'PARTIAL'
    } else {
        'COMPLETE'
    }

    $overall=if ($type -eq 'MULTIDIMENSIONAL' -and $md) { $md.OverallScore } elseif ($score) { $score.OverallScore } else { '' }
    $risk=if ($type -eq 'MULTIDIMENSIONAL' -and $md) { $md.RiskLevel } elseif ($score) { $score.RiskLevel } else { 'INFORMATIONAL' }
    $priority=if ($type -eq 'MULTIDIMENSIONAL' -and $md) { $md.Priority } elseif ($score) { $score.Priority } else { 'P3' }
    $runtimeCoverage=if ($type -eq 'MULTIDIMENSIONAL' -and $md) { $md.RuntimeCoverage } elseif ($score) { $score.RuntimeCoverage } else { 'MISSING' }
    $runtimeExecutions=if ($type -eq 'MULTIDIMENSIONAL' -and $md) { $md.BusinessRuntimeExecutions } elseif ($dbRuntime) { $dbRuntime.Executions } else { 0 }

    if ($type -eq 'MULTIDIMENSIONAL') {
        $assessmentStatus='MULTIDIMENSIONAL_SEPARATE_ASSESSMENT'
        $conclusion=("MD-specific assessment produced {0} tuning-matrix actions. Static score is a relative prioritization signal; business-query and processing performance are NOT PROVABLE FROM CURRENT EVIDENCE." -f $mdActions.Count)
        $nextStep='Use the MD tuning matrix; capture representative business MDX and 2-3 normal processing runs before approving model changes.'
        $assessmentFiles='REPORTS/12_MULTIDIMENSIONAL_SCORECARD.csv; REPORTS/13_MULTIDIMENSIONAL_ASSESSMENT.md; REPORTS/15_MULTIDIMENSIONAL_TUNING_MATRIX.csv'
    } elseif ($dbFindings.Count -gt 0) {
        $assessmentStatus='ACTIONABLE_FINDINGS'
        $conclusion=("{0} threshold-based finding(s) were generated. Finding priority is a tuning order, not proof of measured latency." -f $dbFindings.Count)
        $nextStep='Review the cited evidence and execute each finding validation method before implementing changes.'
        $assessmentFiles='REPORTS/02_FLEET_SCORECARD.csv; REPORTS/04_FINDINGS.csv'
    } elseif ($evidenceCoverage -eq 'MISSING') {
        $assessmentStatus='EVIDENCE_GAP'
        $conclusion='No defensible assessment conclusion can be made because database-level evidence is missing. NOT PROVABLE FROM CURRENT EVIDENCE.'
        $nextStep='Collect the missing metadata and supported storage evidence, then regenerate the assessment.'
        $assessmentFiles='MANIFEST/databases.csv; MANIFEST/collection_manifest.csv'
    } else {
        $assessmentStatus='NO_THRESHOLD_FINDING'
        $conclusion='No threshold-based finding was generated from currently available evidence. This does not prove that the database has no performance issue. NOT PROVABLE FROM CURRENT EVIDENCE.'
        $nextStep='Retain as monitored scope; collect representative workload or processing evidence when business impact, change, or incident warrants deeper validation.'
        $assessmentFiles='REPORTS/02_FLEET_SCORECARD.csv; REPORTS/04_FINDINGS.csv; MANIFEST/collection_manifest.csv'
    }

    $gapParts=New-Object System.Collections.Generic.List[string]
    if ($unsupportedCount -gt 0) { $gapParts.Add(('unsupported_or_failed={0}' -f $unsupportedCount)) }
    if ($skippedCount -gt 0) { $gapParts.Add(('skipped={0}' -f $skippedCount)) }
    if ($runtimeCoverage -notmatch 'PARTIAL_BUSINESS_CANDIDATE' -and $runtimeCoverage -ne 'PARTIAL') { $gapParts.Add(('runtime={0}' -f $runtimeCoverage)) }

    $output.Add((New-Object PSObject -Property ([ordered]@{
        Database=$name; Server=$db.Server; ModelType=$type; Selected=$db.Selected
        EvidenceCoverage=$evidenceCoverage; EvidenceSuccessCount=$successCount; EvidenceSuccessEmptyCount=$emptyCount
        EvidenceUnsupportedOrFailedCount=$unsupportedCount; EvidenceSkippedCount=$skippedCount
        OverallScore=$overall; RiskLevel=$risk; Priority=$priority
        FindingCount=$dbFindings.Count; HighestFindingSeverity=(Highest-Severity $dbFindings)
        FindingIDs=(Join-Unique $dbFindings.FindingID); FindingCategories=(Join-Unique $dbFindings.Category)
        RuntimeCoverage=$runtimeCoverage; BusinessRuntimeExecutions=$runtimeExecutions
        AssessmentStatus=$assessmentStatus; AssessmentConclusion=$conclusion
        RecommendedNextStep=$nextStep; EvidenceGapSummary=($gapParts -join '; ')
        AssessmentFiles=$assessmentFiles
    })))
}

$outputPath=Join-Path $ReportRoot '16_DATABASE_ASSESSMENT_COVERAGE.csv'
$output | Export-Csv -LiteralPath $outputPath -NoTypeInformation -Encoding UTF8
Write-Output ("Generated database assessment coverage: rows={0}; path={1}" -f $output.Count,$outputPath)
