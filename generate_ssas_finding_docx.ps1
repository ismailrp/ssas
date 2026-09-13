<#
.SYNOPSIS
Generates one editable DOCX finding report per SSAS deep-dive database.

.DESCRIPTION
Uses the supplied SSIS DOCX only as an OpenXML style/template container. All
report content is sourced from the SSAS assessment CSV/Markdown files.
Compatible with Windows PowerShell 4.0.
#>
[CmdletBinding()]
param(
    [string]$TemplatePath = '',
    [string]$ReportRoot = '',
    [string]$OutputDirectory = ''
)

$ErrorActionPreference = 'Stop'
$scriptPath = $MyInvocation.MyCommand.Path
$scriptDirectory = if ($scriptPath) { Split-Path -Parent $scriptPath } else { (Get-Location).Path }
if (-not $TemplatePath) { $TemplatePath = Join-Path $scriptDirectory 'SSIS Finding-002-Seq_Staging_SIGAP_dtsx-Sequence Table Sigap v1.0a.docx' }
if (-not $ReportRoot) { $ReportRoot = Join-Path $scriptDirectory 'REPORTS' }
if (-not $OutputDirectory) { $OutputDirectory = Join-Path $ReportRoot 'SSAS_FINDING_DOCX' }

foreach ($required in @($TemplatePath,(Join-Path $ReportRoot '02_FLEET_SCORECARD.csv'),(Join-Path $ReportRoot '04_FINDINGS.csv'),(Join-Path $ReportRoot '06_DEEP_DIVE_PLAN.md'))) {
    if (-not (Test-Path -LiteralPath $required)) { throw "Required input missing: $required" }
}
if (-not (Test-Path -LiteralPath $OutputDirectory)) { New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null }

Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

function Xml-Escape([string]$Text) {
    if ($null -eq $Text) { return '' }
    return [Security.SecurityElement]::Escape($Text)
}
function Safe-FileName([string]$Name) { return [string]::Join('_', $Name.Split([IO.Path]::GetInvalidFileNameChars())) }
function Paragraph([string]$Text, [string]$Style) {
    $styleXml = if ($Style) { '<w:pPr><w:pStyle w:val="' + (Xml-Escape $Style) + '"/></w:pPr>' } else { '' }
    return '<w:p>' + $styleXml + '<w:r><w:t xml:space="preserve">' + (Xml-Escape $Text) + '</w:t></w:r></w:p>'
}
function BoldParagraph([string]$Label, [string]$Text, [string]$Style) {
    $styleXml = if ($Style) { '<w:pPr><w:pStyle w:val="' + (Xml-Escape $Style) + '"/></w:pPr>' } else { '' }
    return '<w:p>' + $styleXml + '<w:r><w:rPr><w:b/></w:rPr><w:t xml:space="preserve">' + (Xml-Escape $Label) + '</w:t></w:r><w:r><w:t xml:space="preserve">' + (Xml-Escape $Text) + '</w:t></w:r></w:p>'
}
function TableCell([string]$Text, [bool]$Header, [int]$Width) {
    $shade = if ($Header) { '<w:shd w:fill="D9EAF7"/>' } else { '' }
    $bold = if ($Header) { '<w:rPr><w:b/></w:rPr>' } else { '' }
    return '<w:tc><w:tcPr><w:tcW w:w="' + $Width + '" w:type="dxa"/>' + $shade + '</w:tcPr><w:p><w:r>' + $bold + '<w:t xml:space="preserve">' + (Xml-Escape $Text) + '</w:t></w:r></w:p></w:tc>'
}
function TwoColumnTable([object[]]$Rows) {
    $xml='<w:tbl><w:tblPr><w:tblW w:w="0" w:type="auto"/><w:tblBorders><w:top w:val="single" w:sz="4" w:color="B7B7B7"/><w:left w:val="single" w:sz="4" w:color="B7B7B7"/><w:bottom w:val="single" w:sz="4" w:color="B7B7B7"/><w:right w:val="single" w:sz="4" w:color="B7B7B7"/><w:insideH w:val="single" w:sz="4" w:color="D9D9D9"/><w:insideV w:val="single" w:sz="4" w:color="D9D9D9"/></w:tblBorders></w:tblPr><w:tblGrid><w:gridCol w:w="2600"/><w:gridCol w:w="6500"/></w:tblGrid>'
    foreach ($row in $Rows) { $xml += '<w:tr>' + (TableCell ([string]$row[0]) $true 2600) + (TableCell ([string]$row[1]) $false 6500) + '</w:tr>' }
    return $xml + '</w:tbl>'
}
function ValidationTable() {
    $rows=@(
        @('Metric','Before','After','Acceptance / guardrail'),
        @('Query total / P50 / P95 / P99','[isi hasil baseline]','[isi setelah tuning]','Comparable query, filter, cache mode, dan workload window'),
        @('FE / SE / SE query count','[isi Server Timings]','[isi setelah tuning]','Perbaikan pada hotspot terukur; tidak ada regresi material'),
        @('Refresh / processing','[median 2-3 normal runs]','[median 2-3 comparable runs]','Durasi/scope membaik; status dan retry tidak memburuk'),
        @('Rows / semantic result','[baseline]','[after]','Row reconciliation dan nilai bisnis tetap parity'),
        @('Decision','-','[PROMOTE / REVISE / ROLLBACK]','Rollback bila correctness berubah atau target yang disepakati tidak tercapai')
    )
    $xml='<w:tbl><w:tblPr><w:tblW w:w="0" w:type="auto"/><w:tblBorders><w:top w:val="single" w:sz="4" w:color="B7B7B7"/><w:left w:val="single" w:sz="4" w:color="B7B7B7"/><w:bottom w:val="single" w:sz="4" w:color="B7B7B7"/><w:right w:val="single" w:sz="4" w:color="B7B7B7"/><w:insideH w:val="single" w:sz="4" w:color="D9D9D9"/><w:insideV w:val="single" w:sz="4" w:color="D9D9D9"/></w:tblBorders></w:tblPr><w:tblGrid><w:gridCol w:w="1800"/><w:gridCol w:w="2100"/><w:gridCol w:w="2100"/><w:gridCol w:w="3100"/></w:tblGrid>'
    for ($i=0;$i-lt$rows.Count;$i++) {
        $xml+='<w:tr>'
        foreach ($cell in $rows[$i]) { $xml+=TableCell ([string]$cell) ($i-eq0) $(if($i-eq0){2200}else{2200}) }
        $xml+='</w:tr>'
    }
    return $xml+'</w:tbl>'
}
function Write-Docx([string]$Template, [string]$OutputPath, [string]$DocumentXml, [string]$Title) {
    Copy-Item -LiteralPath $Template -Destination $OutputPath -Force
    $archive=[IO.Compression.ZipFile]::Open($OutputPath,[IO.Compression.ZipArchiveMode]::Update)
    try {
        $old=$archive.GetEntry('word/document.xml')
        if ($old) { $old.Delete() }
        $entry=$archive.CreateEntry('word/document.xml',[IO.Compression.CompressionLevel]::Optimal)
        $writer=New-Object IO.StreamWriter($entry.Open(),(New-Object Text.UTF8Encoding($false)))
        try { $writer.Write($DocumentXml) } finally { $writer.Dispose() }
        $oldCore=$archive.GetEntry('docProps/core.xml')
        if ($oldCore) { $oldCore.Delete() }
        $core=$archive.CreateEntry('docProps/core.xml',[IO.Compression.CompressionLevel]::Optimal)
        $coreWriter=New-Object IO.StreamWriter($core.Open(),(New-Object Text.UTF8Encoding($false)))
        $modified=[DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ssZ')
        $coreXml='<?xml version="1.0" encoding="UTF-8" standalone="yes"?><cp:coreProperties xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:dcterms="http://purl.org/dc/terms/" xmlns:dcmitype="http://purl.org/dc/dcmitype/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"><dc:title>'+(Xml-Escape $Title)+'</dc:title><dc:subject>Evidence-driven SSAS performance assessment</dc:subject><dc:creator>SSAS Assessment</dc:creator><cp:lastModifiedBy>SSAS Assessment</cp:lastModifiedBy><cp:revision>1</cp:revision><dcterms:created xsi:type="dcterms:W3CDTF">'+$modified+'</dcterms:created><dcterms:modified xsi:type="dcterms:W3CDTF">'+$modified+'</dcterms:modified></cp:coreProperties>'
        try { $coreWriter.Write($coreXml) } finally { $coreWriter.Dispose() }
    }
    finally { $archive.Dispose() }
}

$scorecard=@(Import-Csv -LiteralPath (Join-Path $ReportRoot '02_FLEET_SCORECARD.csv'))
$findings=@(Import-Csv -LiteralPath (Join-Path $ReportRoot '04_FINDINGS.csv'))
$runtime=@()
$runtimePath=Join-Path $ReportRoot '07_RUNTIME_DATABASE_BASELINE.csv'
if (Test-Path -LiteralPath $runtimePath) { $runtime=@(Import-Csv -LiteralPath $runtimePath) }
$deepDiveText=Get-Content -LiteralPath (Join-Path $ReportRoot '06_DEEP_DIVE_PLAN.md')
$databases=@($deepDiveText | Where-Object {$_ -match '^## (.+)$'} | ForEach-Object {$matches[1]})

$indexRows=New-Object Collections.Generic.List[object]
$number=0
foreach ($database in $databases) {
    $number++
    $model=$scorecard | Where-Object {$_.Database -eq $database} | Select-Object -First 1
    if (-not $model) { continue }
    $dbFindings=@($findings | Where-Object {$_.Database -eq $database})
    $dbRuntime=$runtime | Where-Object {$_.Database -eq $database} | Select-Object -First 1
    $categories=if($dbFindings.Count){@($dbFindings.Category|Select-Object -Unique)-join', '}else{'Evidence collection / validation'}
    $runtimeSummary=if($dbRuntime){"$($dbRuntime.Executions) exec; total $($dbRuntime.TotalDurationMs) ms; P50/P95/P99 $($dbRuntime.P50DurationMs)/$($dbRuntime.P95DurationMs)/$($dbRuntime.P99DurationMs) ms; max $($dbRuntime.MaxDurationMs) ms"}else{'No BUSINESS_CANDIDATE query captured'}
    $findingIds=if($dbFindings.Count){$dbFindings.FindingID-join', '}else{'-'}

    $body=''
    $body+=Paragraph ("SSAS Finding-{0:D3}-{1}" -f $number,$database) 'NoSpacing'
    $body+=Paragraph $categories 'NoSpacing'
    $body+=Paragraph '' ''
    $body+=TwoColumnTable @(
        @('No',('{0:D3}'-f $number)),@('Database',$database),@('Model Type',$model.ModelType),
        @('Compatibility Level',$model.CompatibilityLevel),@('Finding ID',$findingIds),
        @('Static Risk',("$($model.OverallScore)/100 - $($model.RiskLevel) / $($model.Priority)")),
        @('Model Profile',("$($model.TableCount) tables; $($model.ColumnCount) columns; $($model.MeasureCount) measures; $($model.RelationshipCount) relationships; $($model.PartitionCount) partitions")),
        @('Captured Runtime',$runtimeSummary),@('Action Status','INVESTIGATE / VALIDATE BEFORE CHANGE')
    )
    $body+=Paragraph 'Finding' 'Heading1'
    if ($dbFindings.Count -eq 0) {
        $body+=Paragraph 'No structured finding is available. Runtime and performance remain NOT PROVABLE FROM CURRENT EVIDENCE.' 'ListParagraph'
    }
    foreach ($finding in $dbFindings) {
        $body+=BoldParagraph ("$($finding.FindingID) - $($finding.Category): ") ("[$($finding.Classification); confidence $($finding.Confidence)] $($finding.Observation)") 'ListParagraph'
        $body+=BoldParagraph 'Potential impact: ' ([string]$finding.PerformanceImpact) 'ListParagraph'
        $body+=BoldParagraph 'Evidence: ' ([string]$finding.EvidenceFiles) 'ListParagraph'
    }
    $body+=BoldParagraph 'Interpretation boundary: ' 'Structural/static correlation is not proof of query or refresh root cause. Runtime values describe only the captured BUSINESS_CANDIDATE subset. Typical workload, CPU or memory pressure remain NOT PROVABLE FROM CURRENT EVIDENCE.' 'ListParagraph'
    $body+=Paragraph 'Action Plan and Solution' 'Heading1'
    foreach ($finding in $dbFindings) {
        $body+=BoldParagraph ("$($finding.Category) - ") ([string]$finding.Recommendation) 'ListParagraph'
        $body+=BoldParagraph 'Expected benefit: ' ([string]$finding.ExpectedBenefit) 'ListParagraph'
        $body+=BoldParagraph 'Effort / risk: ' ("$($finding.Effort) / $($finding.Risk)") 'ListParagraph'
        $body+=BoldParagraph 'Validation: ' ([string]$finding.ValidationMethod) 'ListParagraph'
    }
    $body+=Paragraph 'Implementation and validation gate' 'Heading1'
    $body+=Paragraph '1. Map query hashes and model objects to the owning Power BI, Excel, or business report.' 'ListParagraph'
    $body+=Paragraph '2. Run 3-5 representative business queries: one warm-up followed by at least three comparable warm runs.' 'ListParagraph'
    $body+=Paragraph '3. Capture 2-3 normal refresh/processing runs per candidate, including start/end, partition, process type, rows, status, and error.' 'ListParagraph'
    $body+=Paragraph '4. Apply only an approved, reversible change in a test environment; do not clear cache or process solely for assessment without an approved window.' 'ListParagraph'
    $body+=Paragraph '5. Validate semantic-result parity, row reconciliation, query metrics, processing metrics, downstream output, and rollback.' 'ListParagraph'
    $body+=Paragraph 'No fixed percentage or duration target is asserted before a comparable baseline and business acceptance threshold are agreed.' 'ListParagraph'
    $body+=Paragraph 'Before / After Validation' 'Heading1'
    $body+=ValidationTable
    $body+='<w:sectPr><w:pgSz w:w="11906" w:h="16838"/><w:pgMar w:top="1440" w:right="1440" w:bottom="1440" w:left="1440" w:header="708" w:footer="708" w:gutter="0"/></w:sectPr>'
    $document='<?xml version="1.0" encoding="UTF-8" standalone="yes"?><w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"><w:body>'+$body+'</w:body></w:document>'
    $fileName=('SSAS Finding-{0:D3}-{1}.docx' -f $number,(Safe-FileName $database))
    $outputPath=Join-Path $OutputDirectory $fileName
    Write-Docx $TemplatePath $outputPath $document ("SSAS Finding-{0:D3}-{1}" -f $number,$database)
    $indexRows.Add([pscustomobject]@{No=('{0:D3}'-f $number);Database=$database;File=$fileName;Findings=$findingIds;StaticScore=$model.OverallScore;Risk=$model.RiskLevel;Priority=$model.Priority;Runtime=$runtimeSummary})
}

$indexRows | Export-Csv -LiteralPath (Join-Path $OutputDirectory 'index.csv') -NoTypeInformation -Encoding UTF8
Write-Output ("Generated editable SSAS finding DOCX reports: " + $indexRows.Count + "; output=" + $OutputDirectory)
