<#
.SYNOPSIS
Creates an illustrative, pre-filled copy of one SSAS finding DOCX.

.DESCRIPTION
The inserted validation values are examples only and must not be treated as
assessment evidence. Compatible with Windows PowerShell 4.0.
#>
[CmdletBinding()]
param(
    [string]$SourcePath = '',
    [string]$OutputPath = ''
)

$ErrorActionPreference = 'Stop'
$scriptPath = $MyInvocation.MyCommand.Path
$scriptDirectory = if ($scriptPath) { Split-Path -Parent $scriptPath } else { (Get-Location).Path }
$reportDirectory = Join-Path $scriptDirectory 'REPORTS\SSAS_FINDING_DOCX'
if (-not $SourcePath) { $SourcePath = Join-Path $reportDirectory 'SSAS Finding-001-LKK.docx' }
if (-not $OutputPath) { $OutputPath = Join-Path $reportDirectory 'CONTOH PENGISIAN - SSAS Finding-001-LKK.docx' }

if (-not (Test-Path -LiteralPath $SourcePath)) { throw "Source DOCX not found: $SourcePath" }
Copy-Item -LiteralPath $SourcePath -Destination $OutputPath -Force

Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

$archive = [IO.Compression.ZipFile]::Open($OutputPath,[IO.Compression.ZipArchiveMode]::Update)
try {
    $entry = $archive.GetEntry('word/document.xml')
    if (-not $entry) { throw 'word/document.xml is missing from the DOCX package.' }
    $reader = New-Object IO.StreamReader($entry.Open())
    try { $xml = $reader.ReadToEnd() } finally { $reader.Dispose() }

    $xml = $xml.Replace('Validasi Before / After','Validasi Before / After - CONTOH PENGISIAN (BUKAN HASIL AKTUAL)')
    $xml = $xml.Replace('[isi hasil baseline]','P50 1.250 ms; P95 4.800 ms; P99 8.100 ms')
    $xml = $xml.Replace('[isi setelah tuning]','P50 780 ms; P95 2.900 ms; P99 5.200 ms')
    $xml = $xml.Replace('[isi Server Timings]','FE 820 ms; SE 390 ms; 24 SE query')
    $xml = $xml.Replace('[median 2-3 normal run]','Median 18 menit; 3 normal run')
    $xml = $xml.Replace('[median 2-3 run yang comparable]','Median 12 menit; 3 comparable run')
    $xml = $xml.Replace('[baseline]','1.250.000 baris; checksum hasil A')
    $xml = $xml.Replace('[sesudah]','1.250.000 baris; checksum hasil A')
    $xml = $xml.Replace('[PROMOTE / REVISE / ROLLBACK]','PROMOTE - contoh keputusan setelah seluruh guardrail lulus')

    # The second occurrence belongs to the FE/SE row and needs a distinct value.
    $firstAfter = 'P50 780 ms; P95 2.900 ms; P99 5.200 ms'
    $firstIndex = $xml.IndexOf($firstAfter,[StringComparison]::Ordinal)
    if ($firstIndex -ge 0) {
        $secondIndex = $xml.IndexOf($firstAfter,$firstIndex + $firstAfter.Length,[StringComparison]::Ordinal)
        if ($secondIndex -ge 0) {
            $xml = $xml.Remove($secondIndex,$firstAfter.Length).Insert($secondIndex,'FE 430 ms; SE 300 ms; 16 SE query')
        }
    }

    $entry.Delete()
    $newEntry = $archive.CreateEntry('word/document.xml',[IO.Compression.CompressionLevel]::Optimal)
    $writer = New-Object IO.StreamWriter($newEntry.Open(),(New-Object Text.UTF8Encoding($false)))
    try { $writer.Write($xml) } finally { $writer.Dispose() }
}
finally { $archive.Dispose() }

Write-Output ("Created illustrative DOCX: " + $OutputPath)
