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
function Translate-Category([string]$Text) {
    $map=@{
        'Storage'='Storage'; 'Partitions'='Partisi'; 'Relationships'='Relationship';
        'Model Complexity'='Kompleksitas Model'; 'Runtime workload'='Beban Kerja Runtime';
        'Evidence collection / validation'='Pengumpulan / validasi evidence'
    }
    if ($map.ContainsKey($Text)) { return $map[$Text] }
    return $Text
}
function Translate-Classification([string]$Text) {
    $map=@{
        'OBSERVED'='OBSERVED (teramati langsung)';
        'INFERRED'='INFERRED (disimpulkan dari evidence)';
        'REQUIRES VALIDATION'='REQUIRES VALIDATION (memerlukan validasi)'
    }
    if ($map.ContainsKey($Text)) { return $map[$Text] }
    return $Text
}
function Translate-Level([string]$Text) {
    $map=@{'CRITICAL'='KRITIS';'HIGH'='TINGGI';'MEDIUM'='SEDANG';'LOW'='RENDAH';'INFORMATIONAL'='INFORMASIONAL'}
    if ($map.ContainsKey($Text)) { return $map[$Text] }
    return $Text
}
function Translate-FindingText([string]$Text) {
    if (-not $Text) { return '' }
    $result=$Text
    $pairs=@(
        @('Fleet-relative storage score','Skor storage relatif terhadap fleet'),
        @('maximum recorded storage-table rows','jumlah baris maksimum yang tercatat pada storage table'),
        @('Largest storage structure has','Struktur storage terbesar memiliki'),
        @('rows while metadata shows','baris, sedangkan metadata menunjukkan'),
        @('partitions for','partisi untuk'),
        @('tables','tabel'),
        @('relationships','relationship'),
        @('inactive','inactive'),
        @('bidirectional indicators','indikator bidirectional'),
        @('possible many-to-many','kemungkinan many-to-many'),
        @('fleet-relative score','skor relatif terhadap fleet'),
        @('columns','kolom'),
        @('measures','measure'),
        @('fleet-relative complexity score','skor kompleksitas relatif terhadap fleet'),
        @('Static scan found','Pemindaian statis menemukan'),
        @('selected risk-pattern occurrences; candidate measures:','kemunculan pola berisiko yang dipilih; measure kandidat:'),
        @('Captured BUSINESS_CANDIDATE subset:','Subset BUSINESS_CANDIDATE yang terekam:'),
        @('executions, total','eksekusi, total durasi'),
        @('max','maksimum'),
        @('Disproportionate encoded data increases capacity and scan exposure; actual query cost is not proven.','Data ter-encode yang tidak proporsional meningkatkan penggunaan kapasitas dan potensi volume scan; biaya query aktual belum terbukti.'),
        @('Full-table refresh may have avoidable processing duration and transaction footprint.','Full-table refresh berpotensi memiliki durasi processing dan transaction footprint yang sebenarnya dapat dikurangi.'),
        @('Complex propagation can increase DAX/Formula Engine work and maintenance risk, but runtime effect is unmeasured.','Propagasi filter yang kompleks dapat menambah beban DAX/Formula Engine dan risiko pemeliharaan, tetapi dampaknya pada runtime belum diukur.'),
        @('Broad models increase metadata, refresh, usability, and optimization surface.','Model yang luas menambah cakupan metadata, refresh, usability, dan area yang perlu dioptimalkan.'),
        @('Iterator/context-transition patterns may increase Formula Engine work; syntax alone does not prove slowness.','Pola iterator/context transition dapat menambah beban Formula Engine; syntax saja tidak membuktikan bahwa query lambat.'),
        @('Measured duration exists for captured query hashes; typical user latency and root cause are NOT PROVABLE FROM CURRENT EVIDENCE.','Durasi untuk query hash yang terekam telah tersedia; latency tipikal pengguna dan root cause TIDAK DAPAT DIBUKTIKAN DARI EVIDENCE SAAT INI (NOT PROVABLE FROM CURRENT EVIDENCE).'),
        @('Review top table/column consumers and remove or reshape only after dependency and usage validation.','Tinjau tabel/kolom dengan konsumsi storage terbesar. Hapus atau ubah strukturnya hanya setelah dependency dan penggunaan divalidasi.'),
        @('Validate refresh history and date boundaries, then test time-based incremental partitions.','Validasi riwayat refresh dan batas tanggal, lalu uji incremental partition berbasis waktu.'),
        @('Diagram cardinality/filter paths; validate ambiguous paths and constrain bidirectional filters where business semantics permit.','Petakan cardinality dan jalur filter; validasi jalur yang ambigu dan batasi bidirectional filter jika semantic bisnis memungkinkan.'),
        @('Inventory report dependencies and label low-value columns as CANDIDATE FOR USAGE VALIDATION before removal.','Inventarisasi dependency report dan tandai kolom bernilai rendah sebagai CANDIDATE FOR USAGE VALIDATION sebelum dihapus.'),
        @('Capture representative query plans and Server Timings; refactor only measured hotspots using reusable base measures or reduced iterator input.','Ambil query plan dan Server Timings yang representatif; lakukan refactor hanya pada hotspot yang terukur menggunakan base measure yang dapat digunakan kembali atau input iterator yang lebih kecil.'),
        @('Reproduce the highest-total query hashes with business owners; collect at least three comparable warm runs and Server Timings before changing DAX/model design.','Reproduksi query hash dengan total durasi tertinggi bersama business owner; ambil minimal tiga warm run yang comparable dan Server Timings sebelum mengubah desain DAX/model.'),
        @('Reduced model footprint and potentially faster scans/refresh.','Model footprint lebih kecil dan potensi scan/refresh yang lebih cepat.'),
        @('Smaller refresh scope and improved operational manageability.','Cakupan refresh lebih kecil dan pengelolaan operasional lebih baik.'),
        @('Simpler filter propagation and more predictable calculations.','Propagasi filter lebih sederhana dan hasil kalkulasi lebih mudah diprediksi.'),
        @('Smaller semantic surface and possible storage/refresh reduction.','Cakupan semantic model lebih kecil serta potensi pengurangan storage dan waktu refresh.'),
        @('Potentially lower CPU and latency for confirmed hotspots.','Potensi penurunan CPU dan latency pada hotspot yang telah dikonfirmasi.'),
        @('Focus tuning effort on measured query candidates and avoid speculative rewrites.','Fokuskan tuning pada query kandidat yang telah terukur dan hindari penulisan ulang yang bersifat spekulatif.'),
        @('Representative before/after query or refresh benchmark plus semantic result regression','Benchmark query atau refresh before/after yang representatif, disertai semantic regression test'),
        @('Map hash to report/owner, one warm-up plus at least three warm runs; compare total/CPU/SE counts and semantic results before/after.','Petakan hash ke report/owner, lakukan satu warm-up dan minimal tiga warm run; bandingkan total durasi, CPU, SE query count, serta hasil semantic before/after.'),
        @('semantic/dependency regression if changed without validation','risiko regresi semantic/dependency jika perubahan dilakukan tanpa validasi'),
        @('LOW for profiling; MEDIUM for any later model/DAX change','RENDAH untuk profiling; SEDANG untuk perubahan model/DAX berikutnya')
    )
    # Replace full sentences before individual words so a generic translation
    # does not prevent a more natural sentence-level translation.
    foreach ($pair in @($pairs | Sort-Object { ([string]$_[0]).Length } -Descending)) {
        $result=$result.Replace([string]$pair[0],[string]$pair[1])
    }
    $result=$result.Replace('MEDIUM - ','SEDANG - ').Replace('HIGH - ','TINGGI - ').Replace('LOW - ','RENDAH - ')
    return $result
}
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
        @('Metrik','Sebelum','Sesudah','Kriteria penerimaan / guardrail'),
        @('Total query / P50 / P95 / P99','[isi hasil baseline]','[isi setelah tuning]','Query, filter, cache mode, dan workload window harus comparable'),
        @('FE / SE / SE query count','[isi Server Timings]','[isi setelah tuning]','Hotspot terukur membaik dan tidak ada regresi material'),
        @('Refresh / processing','[median 2-3 normal run]','[median 2-3 run yang comparable]','Durasi/scope membaik; status dan retry tidak memburuk'),
        @('Baris / hasil semantic','[baseline]','[sesudah]','Row reconciliation dan nilai bisnis tetap sama'),
        @('Keputusan','-','[PROMOTE / REVISE / ROLLBACK]','Lakukan rollback jika correctness berubah atau target yang disepakati tidak tercapai')
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
        $coreXml='<?xml version="1.0" encoding="UTF-8" standalone="yes"?><cp:coreProperties xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:dcterms="http://purl.org/dc/terms/" xmlns:dcmitype="http://purl.org/dc/dcmitype/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"><dc:title>'+(Xml-Escape $Title)+'</dc:title><dc:subject>Assessment performa SSAS berbasis evidence</dc:subject><dc:creator>SSAS Assessment</dc:creator><cp:lastModifiedBy>SSAS Assessment</cp:lastModifiedBy><cp:revision>1</cp:revision><dcterms:created xsi:type="dcterms:W3CDTF">'+$modified+'</dcterms:created><dcterms:modified xsi:type="dcterms:W3CDTF">'+$modified+'</dcterms:modified></cp:coreProperties>'
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
    $categories=if($dbFindings.Count){@($dbFindings.Category|Select-Object -Unique|ForEach-Object {Translate-Category $_})-join', '}else{'Pengumpulan / validasi evidence'}
    $runtimeSummary=if($dbRuntime){"$($dbRuntime.Executions) eksekusi; total durasi $($dbRuntime.TotalDurationMs) ms; P50/P95/P99 $($dbRuntime.P50DurationMs)/$($dbRuntime.P95DurationMs)/$($dbRuntime.P99DurationMs) ms; maksimum $($dbRuntime.MaxDurationMs) ms"}else{'Tidak ada query BUSINESS_CANDIDATE yang terekam'}
    $findingIds=if($dbFindings.Count){$dbFindings.FindingID-join', '}else{'-'}

    $body=''
    $body+=Paragraph ("Temuan SSAS-{0:D3}-{1}" -f $number,$database) 'NoSpacing'
    $body+=Paragraph $categories 'NoSpacing'
    $body+=Paragraph '' ''
    $body+=TwoColumnTable @(
        @('No.',('{0:D3}'-f $number)),@('Database',$database),@('Tipe Model',$model.ModelType),
        @('Compatibility Level',$model.CompatibilityLevel),@('ID Temuan',$findingIds),
        @('Risiko Statis',("$($model.OverallScore)/100 - $(Translate-Level $model.RiskLevel) / $($model.Priority)")),
        @('Profil Model',("$($model.TableCount) tabel; $($model.ColumnCount) kolom; $($model.MeasureCount) measure; $($model.RelationshipCount) relationship; $($model.PartitionCount) partisi")),
        @('Runtime yang Terekam',$runtimeSummary),@('Status Tindakan','INVESTIGASI / VALIDASI SEBELUM PERUBAHAN')
    )
    $body+=Paragraph 'Temuan' 'Heading1'
    if ($dbFindings.Count -eq 0) {
        $body+=Paragraph 'Belum tersedia temuan terstruktur. Kondisi runtime dan performa TIDAK DAPAT DIBUKTIKAN DARI EVIDENCE SAAT INI (NOT PROVABLE FROM CURRENT EVIDENCE).' 'ListParagraph'
    }
    foreach ($finding in $dbFindings) {
        $body+=BoldParagraph ("$($finding.FindingID) - $(Translate-Category $finding.Category): ") ("[$(Translate-Classification $finding.Classification); confidence $(Translate-Level $finding.Confidence)] $(Translate-FindingText $finding.Observation)") 'ListParagraph'
        $body+=BoldParagraph 'Potensi dampak: ' (Translate-FindingText ([string]$finding.PerformanceImpact)) 'ListParagraph'
        $body+=BoldParagraph 'Evidence: ' ([string]$finding.EvidenceFiles) 'ListParagraph'
        $body+=Paragraph '' 'ListParagraph'
    }
    $body+=BoldParagraph 'Batas interpretasi: ' 'Korelasi structural/static bukan bukti root cause pada query atau refresh. Nilai runtime hanya menggambarkan subset BUSINESS_CANDIDATE yang terekam. Workload tipikal, CPU pressure, dan memory pressure TIDAK DAPAT DIBUKTIKAN DARI EVIDENCE SAAT INI (NOT PROVABLE FROM CURRENT EVIDENCE).' 'ListParagraph'
    $body+=Paragraph 'Rencana Tindakan dan Solusi' 'Heading1'
    foreach ($finding in $dbFindings) {
        $body+=BoldParagraph ("$(Translate-Category $finding.Category) - ") (Translate-FindingText ([string]$finding.Recommendation)) 'ListParagraph'
        $body+=BoldParagraph 'Manfaat yang diharapkan: ' (Translate-FindingText ([string]$finding.ExpectedBenefit)) 'ListParagraph'
        $body+=BoldParagraph 'Effort / risiko: ' ("$(Translate-Level $finding.Effort) / $(Translate-FindingText ([string]$finding.Risk))") 'ListParagraph'
        $body+=BoldParagraph 'Metode validasi: ' (Translate-FindingText ([string]$finding.ValidationMethod)) 'ListParagraph'
        $body+=Paragraph '' 'ListParagraph'
    }
    $body+=Paragraph 'Tahap Implementasi dan Validasi' 'Heading1'
    $body+=Paragraph '1. Petakan query hash dan object model ke Power BI, Excel, atau report bisnis pemiliknya.' 'ListParagraph'
    $body+=Paragraph '2. Jalankan 3-5 query bisnis yang representatif: satu warm-up, kemudian minimal tiga warm run yang comparable.' 'ListParagraph'
    $body+=Paragraph '3. Ambil 2-3 normal run refresh/processing untuk setiap kandidat, termasuk waktu mulai/selesai, partisi, process type, jumlah baris, status, dan error.' 'ListParagraph'
    $body+=Paragraph '4. Terapkan hanya perubahan yang telah disetujui dan dapat di-rollback pada test environment; jangan melakukan clear cache atau processing hanya untuk assessment tanpa window yang disetujui.' 'ListParagraph'
    $body+=Paragraph '5. Validasi kesetaraan hasil semantic, row reconciliation, metrik query, metrik processing, downstream output, dan kesiapan rollback.' 'ListParagraph'
    $body+=Paragraph 'Target persentase atau durasi tidak ditetapkan sebelum tersedia baseline yang comparable dan business acceptance threshold yang disepakati.' 'ListParagraph'
    $body+=Paragraph 'Validasi Before / After' 'Heading1'
    $body+=ValidationTable
    $body+='<w:sectPr><w:pgSz w:w="11906" w:h="16838"/><w:pgMar w:top="1440" w:right="1440" w:bottom="1440" w:left="1440" w:header="708" w:footer="708" w:gutter="0"/></w:sectPr>'
    $document='<?xml version="1.0" encoding="UTF-8" standalone="yes"?><w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"><w:body>'+$body+'</w:body></w:document>'
    $fileName=('SSAS Finding-{0:D3}-{1}.docx' -f $number,(Safe-FileName $database))
    $outputPath=Join-Path $OutputDirectory $fileName
    Write-Docx $TemplatePath $outputPath $document ("SSAS Finding-{0:D3}-{1}" -f $number,$database)
    $indexRows.Add([pscustomobject]@{No=('{0:D3}'-f $number);Database=$database;NamaFile=$fileName;IDTemuan=$findingIds;SkorStatis=$model.OverallScore;Risiko=(Translate-Level $model.RiskLevel);Prioritas=$model.Priority;Runtime=$runtimeSummary})
}

$indexRows | Export-Csv -LiteralPath (Join-Path $OutputDirectory 'index.csv') -NoTypeInformation -Encoding UTF8
Write-Output ("Generated editable SSAS finding DOCX reports: " + $indexRows.Count + "; output=" + $OutputDirectory)
