<# Publishes generated SSAS finding DOCX files to the web application. Windows PowerShell 4.0 compatible. #>
[CmdletBinding()]
param(
    [string]$SourceDirectory = '',
    [string]$DestinationDirectory = ''
)

$ErrorActionPreference = 'Stop'
$scriptPath = $MyInvocation.MyCommand.Path
$scriptDirectory = if ($scriptPath) { Split-Path -Parent $scriptPath } else { (Get-Location).Path }
if (-not $SourceDirectory) { $SourceDirectory = Join-Path $scriptDirectory 'REPORTS\SSAS_FINDING_DOCX' }
if (-not $DestinationDirectory) { $DestinationDirectory = Join-Path $scriptDirectory 'ssas-assessment-web\public\findings' }
if (-not (Test-Path -LiteralPath $SourceDirectory)) { throw "Source directory tidak ditemukan: $SourceDirectory" }
if (-not (Test-Path -LiteralPath $DestinationDirectory)) { New-Item -ItemType Directory -Path $DestinationDirectory -Force | Out-Null }

$documents=@(Get-ChildItem -LiteralPath $SourceDirectory -File | Where-Object { $_.Name -like 'SSAS Finding-*.docx' } | Sort-Object Name)
if ($documents.Count -eq 0) { throw "Tidak ada SSAS finding DOCX di: $SourceDirectory" }
foreach ($document in $documents) {
    Copy-Item -LiteralPath $document.FullName -Destination (Join-Path $DestinationDirectory $document.Name) -Force
}

$indexPath=Join-Path $SourceDirectory 'index.csv'
if (Test-Path -LiteralPath $indexPath) { Copy-Item -LiteralPath $indexPath -Destination (Join-Path $DestinationDirectory 'index.csv') -Force }
Write-Output ("Published SSAS finding DOCX files: count={0}; destination={1}" -f $documents.Count,$DestinationDirectory)
