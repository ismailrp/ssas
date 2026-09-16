<#
.SYNOPSIS
Builds one consolidated Markdown document containing every SSAS model report.

.DESCRIPTION
Uses the complete fleet reports as the baseline and overlays finalized database
reports when available. Compatible with Windows PowerShell 4.0.
#>
[CmdletBinding()]
param(
    [string]$FleetReportDirectory = "",
    [string]$FinalReportDirectory = "",
    [string]$OutputPath = ""
)

$ErrorActionPreference = "Stop"
$scriptPath = $MyInvocation.MyCommand.Path
$scriptDirectory = if ($scriptPath) { Split-Path -Parent $scriptPath } else { (Get-Location).Path }

if (-not $FleetReportDirectory) { $FleetReportDirectory = Join-Path $scriptDirectory "evidence\EVSET-005\REPORTS\DATABASES" }
if (-not $FinalReportDirectory) { $FinalReportDirectory = Join-Path $scriptDirectory "REPORTS\DATABASES" }
if (-not $OutputPath) { $OutputPath = Join-Path $scriptDirectory "REPORTS\14_ALL_MODEL_DETAILS.md" }

if (-not (Test-Path -LiteralPath $FleetReportDirectory)) { throw "Fleet report directory not found: $FleetReportDirectory" }
if (-not (Test-Path -LiteralPath $FinalReportDirectory)) { throw "Final report directory not found: $FinalReportDirectory" }

$fleetFiles = @(Get-ChildItem -LiteralPath $FleetReportDirectory -File -Filter "*.md" | Sort-Object Name)
if ($fleetFiles.Count -eq 0) { throw "No model reports found in: $FleetReportDirectory" }

$sections = New-Object System.Collections.Generic.List[string]
$indexLines = New-Object System.Collections.Generic.List[string]
$number = 0

foreach ($fleetFile in $fleetFiles) {
    $number++
    $finalPath = Join-Path $FinalReportDirectory $fleetFile.Name
    $selectedPath = if (Test-Path -LiteralPath $finalPath) { $finalPath } else { $fleetFile.FullName }
    $sourceLabel = if (Test-Path -LiteralPath $finalPath) { "Final report with runtime enrichment" } else { "Fleet technical assessment" }
    $modelName = [IO.Path]::GetFileNameWithoutExtension($fleetFile.Name)
    $anchor = $modelName.ToLowerInvariant() -replace '[^a-z0-9]+', '-'
    $anchor = $anchor.Trim('-')
    $content = Get-Content -LiteralPath $selectedPath -Raw

    # The source reports contain their own H1; demote headings so each model
    # remains a clean subsection of this consolidated document.
    $content = $content -replace '(?m)^### ', '##### '
    $content = $content -replace '(?m)^## ', '#### '
    $content = $content -replace '(?m)^# ', '### '
    $content = $content -replace '(?i)Deep-Dive Recommendation', 'Follow-up Priority'
    $content = $content -replace '(?i)deep[- ]dive', 'follow-up analysis'

    $indexLines.Add(("{0}. [{1}](#{2})" -f $number, $modelName, $anchor))
    $sections.Add(("## {0}`n`n**Source:** {1}`n`n{2}" -f $modelName, $sourceLabel, $content.Trim()))
}

$generatedAt = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss zzz")
$document = @"
# SSAS All Model Technical Details

Dokumen gabungan ini memuat technical assessment untuk seluruh **$($fleetFiles.Count) model** dalam evidence fleet. Laporan final yang tersedia di ``REPORTS\DATABASES`` digunakan sebagai versi utama; model lainnya menggunakan laporan lengkap dari ``evidence\EVSET-005\REPORTS\DATABASES``.

**Generated:** $generatedAt  
**Coverage:** 54 Tabular + 2 Multidimensional  
**Interpretation:** score menunjukkan prioritas relatif. Latency, root cause, dan manfaat tuning tidak dinyatakan terbukti tanpa runtime dan validation evidence yang memadai.

## Daftar model

$($indexLines -join "`n")

---

$($sections -join "`n`n---`n`n")
"@

$outputDirectory = Split-Path -Parent $OutputPath
if (-not (Test-Path -LiteralPath $outputDirectory)) { New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null }
Set-Content -LiteralPath $OutputPath -Encoding UTF8 -Value $document

Write-Output ("Generated consolidated model report: models={0}; output={1}" -f $fleetFiles.Count, $OutputPath)
