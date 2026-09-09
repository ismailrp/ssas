<##
.SYNOPSIS
    Collects the read-only SSAS DMV evidence described in
    SSAS_BEST_PRACTICE_GAP_QUERIES.md for the selected Tabular databases.

.DESCRIPTION
    Compatible with Windows PowerShell 4.0+, matching build_assessment.ps1.
    Results are written in the evidence layout consumed by build_assessment.ps1:

      evidence/EVSET-001/TABULAR/<Database>/metadata/*.csv
      evidence/EVSET-001/TABULAR/<Database>/storage/*.csv
      evidence/EVSET-001/SERVER_RUNTIME/*.csv

    The collector is read-only. DMV failures are retained in the manifest as
    QUERY_FAILED_OR_UNSUPPORTED and do not become empty/zero evidence.
##>

[CmdletBinding()]
param(
    [string]$Server = 'BGASVR-DWH-DEV\SQLTABULAR',
    [string]$EvidenceRoot = (Join-Path $PSScriptRoot 'evidence\EVSET-001'),
    [string]$DatabaseListPath = '',
    [string]$AdomdClientPath = '',
    [switch]$SkipRuntimeSnapshot,
    [string]$SourceMapPath = '',
    [string]$SqlServer = '',
    [switch]$SkipExisting,
    [switch]$WhatIf
)

$ErrorActionPreference = 'Stop'
$minimumPowerShell = New-Object Version 4,0
if ($PSVersionTable.PSVersion -lt $minimumPowerShell) {
    throw ('PowerShell 4.0 atau lebih baru diperlukan. Versi aktif: {0}' -f $PSVersionTable.PSVersion)
}
$script:StartedUtc = [DateTime]::UtcNow
$script:Rows = New-Object System.Collections.Generic.List[object]
$script:AdomdConnectionType = $null
$script:AdomdCommandType = $null

function Write-Log([string]$Message) {
    Write-Host ('[{0}] {1}' -f [DateTime]::Now.ToString('yyyy-MM-dd HH:mm:ss'), $Message)
}

function SafeName([string]$Name) {
    $invalid = [IO.Path]::GetInvalidFileNameChars()
    $result = $Name
    foreach ($char in $invalid) { $result = $result.Replace([string]$char, '_') }
    if ([string]::IsNullOrWhiteSpace($result)) { return '_unnamed_' }
    return $result
}

function Add-ManifestRow {
    param([string]$ServerName, [string]$Database, [string]$ServerType,
          [string]$Artifact, [string]$Status, [string]$Path,
          [int]$RowCount = 0, [string]$ErrorMessage = '')
    $script:Rows.Add([pscustomobject]@{
        CollectedAt = [DateTime]::Now.ToString('s')
        Server = $ServerName
        ServerType = $ServerType
        Database = $Database
        Category = $ServerType
        Artifact = $Artifact
        Status = $Status
        Message = if ($ErrorMessage) { $ErrorMessage } else { 'Rows={0}' -f $RowCount }
        Path = $Path
    })
}

function Ensure-Directory([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path)) {
        New-Item -ItemType Directory -Force -Path $Path | Out-Null
    }
}

function Find-AdomdAssembly([string]$RequestedPath) {
    $candidates = New-Object System.Collections.Generic.List[string]
    if ($RequestedPath) { $candidates.Add($RequestedPath) }
    $programFiles = @($env:ProgramFiles, ${env:ProgramFiles(x86)}) | Where-Object { $_ }
    foreach ($root in $programFiles) {
        $candidates.Add((Join-Path $root 'Microsoft SQL Server\160\SDK\Assemblies\Microsoft.AnalysisServices.AdomdClient.dll'))
        $candidates.Add((Join-Path $root 'Microsoft SQL Server\150\SDK\Assemblies\Microsoft.AnalysisServices.AdomdClient.dll'))
        $candidates.Add((Join-Path $root 'Microsoft SQL Server\140\SDK\Assemblies\Microsoft.AnalysisServices.AdomdClient.dll'))
        $candidates.Add((Join-Path $root 'Microsoft SQL Server\130\SDK\Assemblies\Microsoft.AnalysisServices.AdomdClient.dll'))
    }
    foreach ($candidate in $candidates) {
        if (Test-Path -LiteralPath $candidate) { return (Resolve-Path -LiteralPath $candidate).Path }
    }
    try {
        $assembly = [Reflection.Assembly]::LoadWithPartialName('Microsoft.AnalysisServices.AdomdClient')
        if ($assembly) { return $assembly.Location }
    } catch { }
    throw 'Microsoft.AnalysisServices.AdomdClient.dll tidak ditemukan. Install SSMS/SSDT atau gunakan -AdomdClientPath <path DLL>.'
}

function Initialize-Adomd([string]$RequestedPath) {
    $path = Find-AdomdAssembly $RequestedPath
    if ($path) { Add-Type -Path $path -ErrorAction Stop }
    $script:AdomdConnectionType = [Type]::GetType('Microsoft.AnalysisServices.AdomdClient.AdomdConnection, Microsoft.AnalysisServices.AdomdClient', $true)
    $script:AdomdCommandType = [Type]::GetType('Microsoft.AnalysisServices.AdomdClient.AdomdCommand, Microsoft.AnalysisServices.AdomdClient', $true)
    Write-Log ('ADOMD.NET loaded: {0}' -f $path)
}

function New-AdomdConnection([string]$Database) {
    $connection = [Activator]::CreateInstance($script:AdomdConnectionType)
    if ([string]::IsNullOrEmpty($Database)) {
        $connection.ConnectionString = 'Data Source={0};Integrated Security=SSPI;Timeout=300;' -f $Server
    } else {
        $connection.ConnectionString = 'Data Source={0};Initial Catalog={1};Integrated Security=SSPI;Timeout=300;' -f $Server, $Database
    }
    return $connection
}

function Export-AdomdQuery {
    param([string]$Database, [string]$Artifact, [string]$RelativePath, [string]$Query)
    $absolutePath = Join-Path (Join-Path $EvidenceRoot 'TABULAR') (Join-Path (SafeName $Database) $RelativePath)
    Ensure-Directory (Split-Path -Parent $absolutePath)
    if ($SkipExisting -and (Test-Path -LiteralPath $absolutePath)) {
        Add-ManifestRow $Server $Database 'TABULAR' $Artifact 'SKIPPED' $absolutePath 0 'File already exists; use without -SkipExisting to recollect.'
        return
    }
    if ($WhatIf) {
        Add-ManifestRow $Server $Database 'TABULAR' $Artifact 'WHATIF' $absolutePath 0 ''
        return
    }
    $connection = $null
    $reader = $null
    try {
        $connection = New-AdomdConnection $Database
        $connection.Open()
        $command = [Activator]::CreateInstance($script:AdomdCommandType)
        $command.Connection = $connection
        $command.CommandText = $Query
        $command.CommandTimeout = 300
        $reader = $command.ExecuteReader()
        $table = New-Object System.Data.DataTable
        $table.Load($reader)
        $table | Export-Csv -LiteralPath $absolutePath -NoTypeInformation -Encoding UTF8
        Add-ManifestRow $Server $Database 'TABULAR' $Artifact 'SUCCESS' $absolutePath $table.Rows.Count ''
        Write-Log ('{0} / {1}: SUCCESS ({2} rows)' -f $Database, $Artifact, $table.Rows.Count)
    } catch {
        $message = $_.Exception.Message
        Add-ManifestRow $Server $Database 'TABULAR' $Artifact 'QUERY_FAILED_OR_UNSUPPORTED' $absolutePath 0 $message
        Write-Warning ('{0} / {1}: {2}' -f $Database, $Artifact, $message)
    } finally {
        if ($reader) { $reader.Dispose() }
        if ($connection) { $connection.Dispose() }
    }
}

function Export-RuntimeQuery {
    param([string]$Artifact, [string]$FileName, [string]$Query)
    $runtimeRoot = Join-Path (Join-Path $EvidenceRoot 'SERVER_RUNTIME') (SafeName $Server)
    Ensure-Directory $runtimeRoot
    $path = Join-Path $runtimeRoot $FileName
    if ($WhatIf) { Add-ManifestRow $Server '' 'SERVER' $Artifact 'WHATIF' $path 0 ''; return }
    $connection = $null; $reader = $null
    try {
        $connection = New-AdomdConnection ''
        $connection.Open()
        $command = [Activator]::CreateInstance($script:AdomdCommandType)
        $command.Connection = $connection; $command.CommandText = $Query; $command.CommandTimeout = 300
        $reader = $command.ExecuteReader()
        $table = New-Object System.Data.DataTable; $table.Load($reader)
        $table | Export-Csv -LiteralPath $path -NoTypeInformation -Encoding UTF8
        Add-ManifestRow $Server '' 'SERVER' $Artifact 'SUCCESS' $path $table.Rows.Count ''
        Write-Log ('SERVER / {0}: SUCCESS ({1} rows)' -f $Artifact, $table.Rows.Count)
    } catch {
        Add-ManifestRow $Server '' 'SERVER' $Artifact 'QUERY_FAILED_OR_UNSUPPORTED' $path 0 $_.Exception.Message
        Write-Warning ('SERVER / {0}: {1}' -f $Artifact, $_.Exception.Message)
    } finally {
        if ($reader) { $reader.Dispose() }; if ($connection) { $connection.Dispose() }
    }
}

function Get-DatabaseList([string]$Path) {
    if (-not $Path) { $Path = Join-Path $EvidenceRoot 'MANIFEST\databases.csv' }
    if (-not (Test-Path -LiteralPath $Path)) { throw "Database list tidak ditemukan: $Path" }
    $items = @(Import-Csv -LiteralPath $Path | Where-Object { $_.Selected -ne 'False' -and $_.Database })
    if ($items.Count -eq 0) { throw 'Database list kosong.' }
    return $items
}

Ensure-Directory $EvidenceRoot
Initialize-Adomd $AdomdClientPath
$databases = @(Get-DatabaseList $DatabaseListPath)
Write-Log ('Target database: {0}' -f $databases.Count)

# The query text is deliberately single-quoted so PowerShell does not expand $SYSTEM.
$queries = @(
    [pscustomobject]@{ Artifact='tables'; RelativePath='metadata\tables.csv'; Query='SELECT * FROM $SYSTEM.TMSCHEMA_TABLES' }
    [pscustomobject]@{ Artifact='columns'; RelativePath='metadata\columns.csv'; Query='SELECT * FROM $SYSTEM.TMSCHEMA_COLUMNS' }
    [pscustomobject]@{ Artifact='relationships'; RelativePath='metadata\relationships.csv'; Query='SELECT * FROM $SYSTEM.TMSCHEMA_RELATIONSHIPS' }
    [pscustomobject]@{ Artifact='storage_table_columns'; RelativePath='storage\storage_table_columns.csv'; Query='SELECT * FROM $SYSTEM.DISCOVER_STORAGE_TABLE_COLUMNS' }
    [pscustomobject]@{ Artifact='storage_column_segments'; RelativePath='storage\storage_column_segments.csv'; Query='SELECT * FROM $SYSTEM.DISCOVER_STORAGE_TABLE_COLUMN_SEGMENTS' }
    [pscustomobject]@{ Artifact='storage_tables'; RelativePath='storage\storage_tables.csv'; Query='SELECT * FROM $SYSTEM.DISCOVER_STORAGE_TABLES' }
    [pscustomobject]@{ Artifact='partitions'; RelativePath='metadata\partitions.csv'; Query='SELECT * FROM $SYSTEM.TMSCHEMA_PARTITIONS' }
    [pscustomobject]@{ Artifact='refresh_policies'; RelativePath='metadata\refresh_policies.csv'; Query='SELECT * FROM $SYSTEM.TMSCHEMA_REFRESH_POLICIES' }
    [pscustomobject]@{ Artifact='measures'; RelativePath='metadata\measures.csv'; Query='SELECT * FROM $SYSTEM.TMSCHEMA_MEASURES' }
)

foreach ($database in $databases) {
    foreach ($item in $queries) {
        Export-AdomdQuery $database.Database $item.Artifact $item.RelativePath $item.Query
    }
    $metadata = Join-Path (Join-Path (Join-Path $EvidenceRoot 'TABULAR') (SafeName $database.Database)) 'collection_metadata.json'
    if (-not $WhatIf) {
        [pscustomobject]@{
            Server = $Server; Database = $database.Database; ServerType = 'TABULAR'
            CollectedUtc = [DateTime]::UtcNow.ToString('o'); PowerShellVersion = $PSVersionTable.PSVersion.ToString()
            Collector = $MyInvocation.MyCommand.Name; Source = 'SSAS_BEST_PRACTICE_GAP_QUERIES.md'
        } | ConvertTo-Json | Set-Content -LiteralPath $metadata -Encoding UTF8
    }
}

if (-not $SkipRuntimeSnapshot) {
    Export-RuntimeQuery 'sessions' 'sessions.csv' 'SELECT * FROM $SYSTEM.DISCOVER_SESSIONS'
    Export-RuntimeQuery 'connections' 'connections.csv' 'SELECT * FROM $SYSTEM.DISCOVER_CONNECTIONS'
    Export-RuntimeQuery 'commands' 'commands.csv' 'SELECT * FROM $SYSTEM.DISCOVER_COMMANDS'
}

if ($SourceMapPath) {
    if (-not $SqlServer) { throw '-SqlServer wajib diisi jika -SourceMapPath digunakan.' }
    $sourceRows = @(Import-Csv -LiteralPath $SourceMapPath)
    foreach ($source in $sourceRows) {
        if (-not $source.Database -or -not $source.SourceDatabase) { continue }
        $sourceRoot = Join-Path (Join-Path $EvidenceRoot 'TABULAR') (SafeName $source.Database)
        $sourceDir = Join-Path $sourceRoot 'source_sql'
        Ensure-Directory $sourceDir
        # Source SQL checks are opt-in because the guide requires a source mapping.
        $sqlQueries = @(
            [pscustomobject]@{ Artifact='source_columns'; File='columns.csv'; Query="SELECT s.name AS schema_name, t.name AS table_name, c.column_id, c.name AS column_name, ty.name AS data_type, c.max_length, c.precision, c.scale, c.is_nullable, c.is_computed, c.is_identity FROM sys.tables AS t JOIN sys.schemas AS s ON s.schema_id=t.schema_id JOIN sys.columns AS c ON c.object_id=t.object_id JOIN sys.types AS ty ON ty.user_type_id=c.user_type_id ORDER BY s.name,t.name,c.column_id" }
            [pscustomobject]@{ Artifact='source_high_cardinality_candidates'; File='high_cardinality_candidates.csv'; Query="SELECT s.name AS schema_name, t.name AS table_name, c.name AS column_name, ty.name AS data_type, c.max_length, c.is_computed FROM sys.tables AS t JOIN sys.schemas AS s ON s.schema_id=t.schema_id JOIN sys.columns AS c ON c.object_id=t.object_id JOIN sys.types AS ty ON ty.user_type_id=c.user_type_id WHERE ty.name IN ('uniqueidentifier','nvarchar','varchar','ntext','text','datetime','datetime2','float','real') ORDER BY c.max_length DESC,s.name,t.name,c.column_id" }
            [pscustomobject]@{ Artifact='source_modules'; File='modules.csv'; Query="SELECT s.name AS schema_name, o.name AS object_name, o.type_desc, m.definition FROM sys.sql_modules AS m JOIN sys.objects AS o ON o.object_id=m.object_id JOIN sys.schemas AS s ON s.schema_id=o.schema_id WHERE o.type IN ('V','IF','TF','FN','P') ORDER BY s.name,o.name" }
        )
        foreach ($sql in $sqlQueries) {
            $path = Join-Path $sourceDir $sql.File
            try {
                $cs = 'Data Source={0};Initial Catalog={1};Integrated Security=True;Application Name=SSAS gap evidence;' -f $SqlServer, $source.SourceDatabase
                $conn = New-Object System.Data.SqlClient.SqlConnection $cs; $conn.Open()
                $cmd = $conn.CreateCommand(); $cmd.CommandText = $sql.Query; $cmd.CommandTimeout = 300
                $adapter = New-Object System.Data.SqlClient.SqlDataAdapter $cmd; $table = New-Object System.Data.DataTable
                [void]$adapter.Fill($table); $table | Export-Csv -LiteralPath $path -NoTypeInformation -Encoding UTF8
                Add-ManifestRow $SqlServer $source.Database 'SOURCE_SQL' $sql.Artifact 'SUCCESS' $path $table.Rows.Count ''
            } catch {
                Add-ManifestRow $SqlServer $source.Database 'SOURCE_SQL' $sql.Artifact 'QUERY_FAILED_OR_UNSUPPORTED' $path 0 $_.Exception.Message
            } finally {
                if ($conn) { $conn.Dispose() }
            }
        }
    }
}

$manifestDir = Join-Path $EvidenceRoot 'MANIFEST'; Ensure-Directory $manifestDir
$manifestPath = Join-Path $manifestDir 'collection_manifest.csv'
$oldRows = @()
$newKeys = @($script:Rows | ForEach-Object { '{0}|{1}|{2}' -f $_.Server,$_.Database,$_.Artifact })
if (Test-Path -LiteralPath $manifestPath) {
    $oldRows = @(Import-Csv -LiteralPath $manifestPath | Where-Object {
        $oldKey = '{0}|{1}|{2}' -f $_.Server,$_.Database,$_.Artifact
        $newKeys -notcontains $oldKey
    })
}
$allRows = @($oldRows) + @($script:Rows)
$allRows | Select-Object CollectedAt,Server,ServerType,Database,Category,Artifact,Status,Message,Path |
    Export-Csv -LiteralPath $manifestPath -NoTypeInformation -Encoding UTF8
Write-Log ('Selesai. Manifest: {0}' -f $manifestPath)
Write-Output ('Collected DMV evidence for {0} databases; manifest rows={1}' -f $databases.Count, $script:Rows.Count)
