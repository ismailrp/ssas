[CmdletBinding()]
param(
    [string]$EvidenceRoot = "",
    [string]$RulesPath = "",
    [string]$OutputRoot = ""
)

$ErrorActionPreference = "Stop"
$scriptPath = $MyInvocation.MyCommand.Path
$scriptDirectory = if ($scriptPath) { Split-Path -Parent $scriptPath } else { (Get-Location).Path }
if (-not $EvidenceRoot) { $EvidenceRoot = Join-Path $scriptDirectory "evidence\EVSET-005" }
if (-not $RulesPath) { $RulesPath = Join-Path $scriptDirectory "BPArules\BPARules.json" }
if (-not $OutputRoot) { $OutputRoot = Join-Path $scriptDirectory "results\TE_CLI_BPA" }

foreach ($requiredPath in @($EvidenceRoot, $RulesPath)) {
    if (-not (Test-Path -LiteralPath $requiredPath)) { throw "Required path not found: $requiredPath" }
}

$teCommand = Get-Command te -ErrorAction Stop
$tePath = $teCommand.Source
if (-not $tePath) { $tePath = $teCommand.Path }
if (-not $tePath) { throw "Unable to resolve te executable path." }

if (-not (Test-Path -LiteralPath $OutputRoot)) {
    New-Item -ItemType Directory -Path $OutputRoot -Force | Out-Null
}
$rawRoot = Join-Path $OutputRoot "raw"
if (-not (Test-Path -LiteralPath $rawRoot)) {
    New-Item -ItemType Directory -Path $rawRoot -Force | Out-Null
}

function Quote-Argument([string]$Value) {
    if ($null -eq $Value) { return '""' }
    return '"' + $Value.Replace('\', '\').Replace('"', '\"') + '"'
}

function Safe-FileName([string]$Value) {
    $safe = $Value
    foreach ($character in [IO.Path]::GetInvalidFileNameChars()) { $safe = $safe.Replace([string]$character, "_") }
    return $safe
}

function Invoke-TeBpa([string]$ModelPath, [string]$RuleFile) {
    $stdoutPath = [IO.Path]::GetTempFileName()
    $stderrPath = [IO.Path]::GetTempFileName()
    try {
        $arguments = @(
            "bpa", "run", "--model", $ModelPath, "--rules", $RuleFile,
            "--no-defaults", "--no-model-rules", "--output-format", "json",
            "--error-format", "json", "--non-interactive"
        )
        $startInfo = New-Object Diagnostics.ProcessStartInfo
        $startInfo.FileName = $tePath
        $startInfo.Arguments = (($arguments | ForEach-Object { Quote-Argument $_ }) -join " ")
        $startInfo.UseShellExecute = $false
        $startInfo.CreateNoWindow = $true
        $startInfo.RedirectStandardOutput = $true
        $startInfo.RedirectStandardError = $true
        $process = New-Object Diagnostics.Process
        $process.StartInfo = $startInfo
        [void]$process.Start()
        $stdout = $process.StandardOutput.ReadToEnd()
        $stderr = $process.StandardError.ReadToEnd()
        $process.WaitForExit()
        $exitCode = $process.ExitCode
        $process.Dispose()
        return [pscustomobject]@{ ExitCode = $exitCode; StdOut = $stdout; StdErr = $stderr }
    }
    finally {
        Remove-Item -LiteralPath $stdoutPath, $stderrPath -Force -ErrorAction SilentlyContinue
    }
}

$manifestPath = Join-Path $EvidenceRoot "MANIFEST\collection_manifest.csv"
$databasePath = Join-Path $EvidenceRoot "MANIFEST\databases.csv"
$summaryPath = Join-Path $EvidenceRoot "MANIFEST\summary.json"
$manifest = @(Import-Csv -LiteralPath $manifestPath)
$databases = @(Import-Csv -LiteralPath $databasePath)
$summary = Get-Content -LiteralPath $summaryPath -Raw | ConvertFrom-Json
$modelFiles = @(Get-ChildItem -LiteralPath (Join-Path $EvidenceRoot "TABULAR") -Recurse -File | Where-Object {
    $_.Extension -eq ".bim" -and $_.Directory.Name -eq "results"
})

$runs = New-Object Collections.Generic.List[object]
$findings = New-Object Collections.Generic.List[object]
foreach ($modelFile in $modelFiles) {
    $databaseName = $modelFile.Directory.Parent.Name
    $safeName = Safe-FileName $databaseName
    $rawPath = Join-Path $rawRoot ($safeName + ".json")
    $errorPath = Join-Path $rawRoot ($safeName + ".stderr.txt")
    try {
        $result = Invoke-TeBpa -ModelPath $modelFile.FullName -RuleFile $RulesPath
        [IO.File]::WriteAllText($rawPath, $result.StdOut, (New-Object Text.UTF8Encoding($true)))
        if ($result.StdErr) { [IO.File]::WriteAllText($errorPath, $result.StdErr, (New-Object Text.UTF8Encoding($true))) }
        $document = $null
        $parseStatus = "SUCCESS"
        try { $document = $result.StdOut | ConvertFrom-Json } catch { $parseStatus = "INVALID_JSON" }
        if ($document -and $document.findings) {
            foreach ($finding in @($document.findings)) {
                $findings.Add([pscustomobject]@{
                    Database = $databaseName; Severity = $finding.severity; RuleID = $finding.code
                    RuleName = $finding.ruleName; Category = $finding.category; ObjectType = $finding.objectType
                    Object = $finding.object; ObjectPath = $finding.objectPath; Fixable = $finding.fixable
                    Classification = "OBSERVED"; Confidence = "HIGH"
                    EvidenceFile = $rawPath.Substring($scriptDirectory.Length + 1)
                    Message = $finding.message
                })
            }
        }
        $runs.Add([pscustomobject]@{
            Database = $databaseName; ExitCode = $result.ExitCode; ParseStatus = $parseStatus
            Errors = if ($document) { $document.summary.errors } else { "" }
            Warnings = if ($document) { $document.summary.warnings } else { "" }
            Info = if ($document) { $document.summary.info } else { "" }
            Total = if ($document) { $document.summary.total } else { "" }
            RulesEvaluated = if ($document) { $document.rulesEvaluated } else { "" }
            RuleErrors = if ($document) { $document.ruleErrors } else { "" }
            EvidenceStatus = if ($parseStatus -eq "SUCCESS") { "COMPLETE" } else { "PARTIAL" }
            RawOutput = $rawPath.Substring($scriptDirectory.Length + 1)
        })
    }
    catch {
        $runs.Add([pscustomobject]@{
            Database = $databaseName; ExitCode = -1; ParseStatus = "FAILED"; Errors = ""; Warnings = ""
            Info = ""; Total = ""; RulesEvaluated = ""; RuleErrors = ""; EvidenceStatus = "MISSING"
            RawOutput = ""; Error = $_.Exception.Message
        })
    }
}

$runs | Export-Csv -LiteralPath (Join-Path $OutputRoot "bpa_run_manifest.csv") -NoTypeInformation -Encoding UTF8
$findings | Export-Csv -LiteralPath (Join-Path $OutputRoot "bpa_findings.csv") -NoTypeInformation -Encoding UTF8
$rollup = @($findings | Group-Object Database | ForEach-Object {
    [pscustomobject]@{
        Database = $_.Name; Findings = $_.Count
        Errors = @($_.Group | Where-Object { $_.Severity -eq "error" }).Count
        Warnings = @($_.Group | Where-Object { $_.Severity -eq "warning" }).Count
        Info = @($_.Group | Where-Object { $_.Severity -eq "info" }).Count
        DistinctRules = @($_.Group.RuleID | Select-Object -Unique).Count
    }
} | Sort-Object Findings -Descending)
$rollup | Export-Csv -LiteralPath (Join-Path $OutputRoot "bpa_database_rollup.csv") -NoTypeInformation -Encoding UTF8

$coverage = [pscustomobject]@{
    AssessmentId = $summary.assessment_id
    CollectorVersion = $summary.collector_version
    CollectionFinishedAtUtc = $summary.collection_finished_at_utc
    ManifestDatabaseRows = $databases.Count
    SummaryTabularDatabases = $summary.tabular_databases
    BimModelsFound = $modelFiles.Count
    BpaComplete = @($runs | Where-Object { $_.EvidenceStatus -eq "COMPLETE" }).Count
    BpaPartial = @($runs | Where-Object { $_.EvidenceStatus -eq "PARTIAL" }).Count
    BpaMissing = @($runs | Where-Object { $_.EvidenceStatus -eq "MISSING" }).Count
    Findings = $findings.Count
    RulesPath = $RulesPath
    TeVersion = (& $tePath --version | Select-Object -Last 1)
    AuthenticationRequired = $false
    Interpretation = "Static BPA findings are not proof of runtime latency. NOT PROVABLE FROM CURRENT EVIDENCE where runtime linkage is absent."
}
$coverage | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $OutputRoot "summary.json") -Encoding UTF8
Write-Output ("TE CLI BPA complete: models={0}, complete={1}, findings={2}" -f $modelFiles.Count, $coverage.BpaComplete, $findings.Count)
