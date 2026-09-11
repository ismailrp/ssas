[CmdletBinding()]
param(
    [string]$ConfigPath = ".\config.json",
    [string]$AssessmentId = "",
    [string]$OutputRoot = "",
    [string]$AdomdClientPath = "",
    [string]$SourceMapPath = "",
    [string]$SqlServer = "",
    [switch]$Force,
    [switch]$WhatIf
)

$ErrorActionPreference = "Stop"
$script:CollectorVersion = "2.1"
$script:CollectionStartedAtUtc = [DateTime]::UtcNow

function Write-Info($msg) {
    Write-Host "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $msg"
}

function Ensure-Directory([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
    }
}

function Sanitize-Name([string]$Name) {
    return ($Name -replace '[\\/:*?"<>|]', '_')
}

function Protect-SensitiveText([string]$Text) {
    if ($null -eq $Text) { return $Text }
    $protected = $Text
    $protected = $protected -replace '(?i)(password|pwd)\s*=\s*[^;"\r\n]*', '$1=[REDACTED]'
    $protected = $protected -replace '(?i)(user\s*id|uid)\s*=\s*[^;"\r\n]*', '$1=[REDACTED]'
    $protected = $protected -replace '(?i)"(password|pwd|token|secret|credential)"\s*:\s*"[^"]*"', '"$1":"[REDACTED]"'
    return $protected
}

function Import-SSASLibraries([string]$RequestedAdomdPath) {
    Write-Info "Loading SSAS client libraries..."

    $requiredAssemblies = @(
        "Microsoft.AnalysisServices.AdomdClient",
        "Microsoft.AnalysisServices"
    )

    $requestedDirectory = ""
    if ($RequestedAdomdPath) {
        $requestedFullPath = (Resolve-Path -LiteralPath $RequestedAdomdPath -ErrorAction Stop).Path
        $requestedDirectory = Split-Path -Parent $requestedFullPath
        if ($env:Path -notlike ("*" + $requestedDirectory + "*")) {
            $env:Path = $requestedDirectory + ";" + $env:Path
        }
    }

    foreach ($asm in $requiredAssemblies) {
        try {
            $loaded = [System.Reflection.Assembly]::LoadWithPartialName($asm)

            if (($null -eq $loaded) -and $requestedDirectory) {
                $assemblyPath = Join-Path $requestedDirectory ($asm + ".dll")
                if (Test-Path -LiteralPath $assemblyPath) {
                    $loaded = [System.Reflection.Assembly]::LoadFrom($assemblyPath)
                }
            }

            if ($null -eq $loaded) {
                throw "Assembly '$asm' tidak ditemukan. Install SSMS/SSDT atau gunakan -AdomdClientPath."
            }

            Write-Info ("Loaded: " + $loaded.FullName)
        }
        catch {
            throw "Gagal load SSAS assembly '$asm'. $($_.Exception.Message)"
        }
    }

    # TOM diperlukan untuk export TMSL Tabular.
    try {
        $tom = [System.Reflection.Assembly]::LoadWithPartialName(
            "Microsoft.AnalysisServices.Tabular"
        )

        if (($null -eq $tom) -and $requestedDirectory) {
            $tomPath = Join-Path $requestedDirectory "Microsoft.AnalysisServices.Tabular.dll"
            if (Test-Path -LiteralPath $tomPath) {
                $tom = [System.Reflection.Assembly]::LoadFrom($tomPath)
            }
        }

        if ($null -ne $tom) {
            Write-Info ("Loaded: " + $tom.FullName)
            $script:TomAvailable = $true
        }
        else {
            Write-Warning "Microsoft.AnalysisServices.Tabular tidak tersedia. TMSL export akan dilewati."
            $script:TomAvailable = $false
        }
    }
    catch {
        Write-Warning "TOM tidak tersedia. TMSL export akan dilewati."
        $script:TomAvailable = $false
    }
}

function New-AdomdConnection([string]$Server, [string]$Database = "") {
    $cs = "Data Source=$Server;Integrated Security=SSPI;Timeout=60;Application Name=SSAS Evidence Collector;"
    if ($Database) {
        $cs += "Initial Catalog=$Database;"
    }

    try {
        $conn = New-Object Microsoft.AnalysisServices.AdomdClient.AdomdConnection($cs)
        $conn.Open()
        return $conn
    }
    catch {
        throw "Gagal connect ke SSAS '$Server' database '$Database'. $($_.Exception.Message)"
    }
}

function Invoke-SSASQuery {
    param(
        [string]$Server,
        [string]$Database,
        [string]$Query
    )

    $conn = $null
    $cmd = $null
    $adapter = $null
    $ds = $null

    try {
        $conn = New-AdomdConnection -Server $Server -Database $Database

        $cmd = $conn.CreateCommand()
        $cmd.CommandText = $Query

        # Prevent a single DMV from blocking the complete assessment.
        try {
            $cmd.CommandTimeout = $script:QueryTimeoutSeconds
        }
        catch {
            # Older ADOMD versions may ignore this property.
        }

        $adapter = New-Object Microsoft.AnalysisServices.AdomdClient.AdomdDataAdapter($cmd)
        $ds = New-Object System.Data.DataSet

        [void]$adapter.Fill($ds)

        if (($null -eq $ds) -or ($ds.Tables.Count -eq 0)) {
            return $null
        }

        # IMPORTANT for PowerShell 4.0:
        # Prevent DataTable from being enumerated/unrolled into DataRow objects.
        $resultTable = $ds.Tables[0].Copy()
        Write-Output -NoEnumerate $resultTable
    }
    finally {
        if ($null -ne $adapter) {
            try { $adapter.Dispose() } catch {}
        }
        if ($null -ne $cmd) {
            try { $cmd.Dispose() } catch {}
        }
        if ($null -ne $ds) {
            try { $ds.Dispose() } catch {}
        }
        if ($null -ne $conn) {
            try { $conn.Close() } catch {}
            try { $conn.Dispose() } catch {}
        }
    }
}

function Export-TableCsv {
    param(
        $Table,
        [string]$Path
    )

    # Always create an artifact even when the rowset is empty.
    if ($null -eq $Table) {
        "" | Set-Content -LiteralPath $Path -Encoding UTF8
        return 0
    }

    # Defensive normalization for PowerShell 4.0.
    if ($Table -is [System.Data.DataRow]) {
        $dt = $Table.Table.Clone()
        $dt.ImportRow($Table)
        $Table = $dt
    }
    elseif ($Table -is [System.Array] -and $Table.Count -gt 0 -and $Table[0] -is [System.Data.DataRow]) {
        $dt = $Table[0].Table.Clone()
        foreach ($row in $Table) {
            if ($null -ne $row) {
                $dt.ImportRow($row)
            }
        }
        $Table = $dt
    }

    if (-not ($Table -is [System.Data.DataTable])) {
        throw "Unexpected query result type: $($Table.GetType().FullName)"
    }

    # Preserve headers for an empty DataTable.
    if ($Table.Rows.Count -eq 0) {
        $header = @()
        foreach ($c in $Table.Columns) {
            $header += ('"' + ($c.ColumnName -replace '"','""') + '"')
        }

        if ($header.Count -gt 0) {
            ($header -join ",") | Set-Content -LiteralPath $Path -Encoding UTF8
        }
        else {
            "" | Set-Content -LiteralPath $Path -Encoding UTF8
        }

        return 0
    }

    $rows = @()

    foreach ($r in $Table.Rows) {
        if ($null -eq $r) {
            continue
        }

        $obj = New-Object PSObject

        foreach ($c in $Table.Columns) {
            $value = $null

            if ($null -ne $c) {
                try {
                    $value = $r[$c.ColumnName]
                }
                catch {
                    $value = $null
                }

                if ($c.ColumnName -match '(?i)password|pwd|token|secret|credential') {
                    $value = '[REDACTED]'
                }
                elseif ($value -is [string]) {
                    $value = Protect-SensitiveText $value
                }

                $obj | Add-Member `
                    -MemberType NoteProperty `
                    -Name $c.ColumnName `
                    -Value $value
            }
        }

        $rows += $obj
    }

    $rows | Export-Csv -LiteralPath $Path -NoTypeInformation -Encoding UTF8

    return $Table.Rows.Count
}

function Get-DatabaseList([string]$Server) {

    # Primary method: AMO server enumeration.
    # More reliable than DBSCHEMA_CATALOGS for SSAS server-level discovery.
    $amoServer = $null

    try {
        Write-Info "Discovering databases via AMO..."

        $amoServer = New-Object Microsoft.AnalysisServices.Server
        $amoServer.Connect($Server)

        $names = @()

        foreach ($db in $amoServer.Databases) {
            if ($null -ne $db -and $db.Name) {
                $names += [string]$db.Name
            }
        }

        if ($names.Count -gt 0) {
            return $names | Sort-Object -Unique
        }

        Write-Warning "AMO connected but returned 0 databases. Trying DBSCHEMA_CATALOGS fallback..."
    }
    catch {
        Write-Warning "AMO database discovery failed: $($_.Exception.Message)"
        Write-Warning "Trying DBSCHEMA_CATALOGS fallback..."
    }
    finally {
        if ($null -ne $amoServer) {
            try { $amoServer.Disconnect() } catch {}
        }
    }

    # Fallback method.
    try {
        $q = 'SELECT * FROM $SYSTEM.DBSCHEMA_CATALOGS'
        $t = Invoke-SSASQuery -Server $Server -Database "" -Query $q

        $names = @()

        if ($null -ne $t) {
            foreach ($r in $t.Rows) {
                if ($t.Columns.Contains("CATALOG_NAME")) {
                    $name = [string]$r["CATALOG_NAME"]

                    if ($name) {
                        $names += $name
                    }
                }
            }
        }

        return $names | Sort-Object -Unique
    }
    catch {
        throw "Database discovery gagal via AMO dan DBSCHEMA_CATALOGS. $($_.Exception.Message)"
    }
}

function Resolve-Databases($ServerConfig, [string[]]$Discovered) {
    $requested = @($ServerConfig.databases)
    $excluded = @($ServerConfig.exclude_databases)

    if (($requested.Count -eq 0) -or ($requested -contains "*")) {
        $selected = $Discovered
    }
    else {
        $selected = $requested
    }

    if ($excluded.Count -gt 0) {
        $selected = $selected | Where-Object { $excluded -notcontains $_ }
    }

    return $selected | Sort-Object -Unique
}

function Add-ManifestRow {
    param(
        [System.Collections.ArrayList]$Manifest,
        [string]$Server,
        [string]$ServerType,
        [string]$Database,
        [string]$Category,
        [string]$Artifact,
        [string]$Status,
        [string]$Message,
        [string]$Path
    )

    [void]$Manifest.Add((New-Object PSObject -Property @{
        CollectedAt = (Get-Date).ToString("s")
        Server      = $Server
        ServerType  = $ServerType
        Database    = $Database
        Category    = $Category
        Artifact    = $Artifact
        Status      = $Status
        Message     = $Message
        Path        = $Path
    }))
}

function Collect-QueryArtifact {
    param(
        [System.Collections.ArrayList]$Manifest,
        [string]$Server,
        [string]$ServerType,
        [string]$Database,
        [string]$Category,
        [string]$Name,
        [string]$Query,
        [string]$OutputPath
    )

    $t = $null

    if ((-not $Force) -and (Test-Path -LiteralPath $OutputPath)) {
        Add-ManifestRow `
            -Manifest $Manifest -Server $Server -ServerType $ServerType `
            -Database $Database -Category $Category -Artifact $Name `
            -Status "SKIPPED" -Message "Artifact already exists; use -Force only for intentional overwrite." `
            -Path $OutputPath
        Write-Info ("SKIPPED existing " + $Database + " :: " + $Name)
        return
    }

    if ($WhatIf) {
        Add-ManifestRow `
            -Manifest $Manifest -Server $Server -ServerType $ServerType `
            -Database $Database -Category $Category -Artifact $Name `
            -Status "WHATIF" -Message "Query not executed." -Path $OutputPath
        return
    }

    Write-Info ("START " + $Database + " :: " + $Name)

    # Stage 1: query execution
    try {
        $t = Invoke-SSASQuery `
            -Server $Server `
            -Database $Database `
            -Query $Query
    }
    catch {
        $msg = $_.Exception.Message

        $status = "QUERY_FAILED_OR_UNSUPPORTED"

        if ($msg -match '(?i)request type.*not recognized|not recognized.*request type|not supported|unsupported') {
            $msg = "UNSUPPORTED: " + $msg
        }

        if (($msg -match "timeout") -or ($msg -match "timed out") -or ($msg -match "time-out")) {
            $status = "QUERY_TIMEOUT"
        }

        Add-ManifestRow `
            -Manifest $Manifest `
            -Server $Server `
            -ServerType $ServerType `
            -Database $Database `
            -Category $Category `
            -Artifact $Name `
            -Status $status `
            -Message $msg `
            -Path $OutputPath

        Write-Warning "$Database :: $Name :: $status :: $msg"
        return
    }

    # Stage 2: export
    try {
        $rowCount = Export-TableCsv -Table $t -Path $OutputPath

        $status = "SUCCESS"
        $message = "Rows=$rowCount"

        if ($rowCount -eq 0) {
            $status = "SUCCESS_EMPTY"
            $message = "Query succeeded but returned 0 rows."
        }

        Add-ManifestRow `
            -Manifest $Manifest `
            -Server $Server `
            -ServerType $ServerType `
            -Database $Database `
            -Category $Category `
            -Artifact $Name `
            -Status $status `
            -Message $message `
            -Path $OutputPath

        Write-Info "$status $Database :: $Name :: Rows=$rowCount"
    }
    catch {
        $msg = $_.Exception.Message

        Add-ManifestRow `
            -Manifest $Manifest `
            -Server $Server `
            -ServerType $ServerType `
            -Database $Database `
            -Category $Category `
            -Artifact $Name `
            -Status "EXPORT_FAILED" `
            -Message $msg `
            -Path $OutputPath

        Write-Warning "$Database :: $Name :: EXPORT FAILED :: $msg"
    }
}

function Export-CollectionMetadata {
    param(
        [string]$Server,
        [string]$ServerType,
        [string]$Database,
        [string]$Path
    )

    if ((-not $Force) -and (Test-Path -LiteralPath $Path)) { return }
    if ($WhatIf) { return }

    $metadata = New-Object PSObject -Property @{
        collector             = "Collect-SSAS.ps1"
        collector_version     = $script:CollectorVersion
        assessment_id         = $AssessmentId
        server                = $Server
        server_type           = $ServerType
        database              = $Database
        collected_at_utc      = [DateTime]::UtcNow.ToString("o")
        powershell_version    = $PSVersionTable.PSVersion.ToString()
        query_timeout_seconds = $script:QueryTimeoutSeconds
    }
    $metadata | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $Path -Encoding UTF8
}

function Get-AutomaticSourceMappings([string]$Root, [object[]]$DatabaseInventory) {
    $mappings = New-Object System.Collections.ArrayList
    $seen = @{}
    foreach ($databaseRow in $DatabaseInventory) {
        if ($databaseRow.ServerType -ne "TABULAR" -or (-not $databaseRow.Selected)) { continue }
        $safeDatabase = Sanitize-Name ([string]$databaseRow.Database)
        $tmslPath = Join-Path (Join-Path (Join-Path $Root "TABULAR") $safeDatabase) "model\database.tmsl.json"
        if (-not (Test-Path -LiteralPath $tmslPath)) { continue }
        try {
            $json = Get-Content -LiteralPath $tmslPath -Raw | ConvertFrom-Json
            $dataSources = @($json.createOrReplace.database.model.dataSources)
            foreach ($dataSource in $dataSources) {
                $connectionString = [string]$dataSource.connectionString
                if (-not $connectionString) { continue }
                try {
                    $builder = New-Object System.Data.Common.DbConnectionStringBuilder
                    # Use the CLR setter explicitly. PowerShell can otherwise
                    # treat ConnectionString as a dictionary key on this type.
                    $builder.set_ConnectionString($connectionString)
                    $sourceServer = ""
                    $sourceDatabase = ""
                    foreach ($key in @("Data Source","Server","Address","Addr","Network Address")) {
                        if ($builder.ContainsKey($key)) { $sourceServer = [string]$builder[$key]; break }
                    }
                    foreach ($key in @("Initial Catalog","Database")) {
                        if ($builder.ContainsKey($key)) { $sourceDatabase = [string]$builder[$key]; break }
                    }
                    if ((-not $sourceServer) -or (-not $sourceDatabase)) { continue }
                    $mapKey = ([string]$databaseRow.Database) + "|" + $sourceServer + "|" + $sourceDatabase
                    if ($seen.ContainsKey($mapKey)) { continue }
                    $seen[$mapKey] = $true
                    [void]$mappings.Add((New-Object PSObject -Property @{
                        Database = [string]$databaseRow.Database
                        SqlServer = $sourceServer
                        SourceDatabase = $sourceDatabase
                        DataSourceName = [string]$dataSource.name
                        DiscoveryStatus = "AUTO_DISCOVERED_FROM_CURRENT_TMSL"
                    }))
                }
                catch {
                    Write-Warning ("Tidak dapat membaca endpoint data source TMSL untuk " + $databaseRow.Database + " / " + $dataSource.name)
                }
            }
        }
        catch {
            Write-Warning ("Auto source mapping gagal untuk " + $databaseRow.Database + ": " + $_.Exception.Message)
        }
    }
    return $mappings
}

function Collect-SourceSqlEvidence {
    param(
        [System.Collections.ArrayList]$Manifest,
        [string]$MapPath,
        [string]$DefaultSqlServer,
        [string]$Root,
        [object[]]$AutomaticMappings
    )

    $mappings = @()
    if ($MapPath) {
        if (-not (Test-Path -LiteralPath $MapPath)) { throw "Source map tidak ditemukan: $MapPath" }
        $mappings = @(Import-Csv -LiteralPath $MapPath)
    }
    else {
        $mappings = @($AutomaticMappings)
    }
    if ($mappings.Count -eq 0) { return }
    $sourceQueries = @(
        (New-Object PSObject -Property @{ Name='source_columns'; File='columns.csv'; Query="SELECT s.name AS schema_name, t.name AS table_name, c.column_id, c.name AS column_name, ty.name AS data_type, c.max_length, c.precision, c.scale, c.is_nullable, c.is_computed, c.is_identity FROM sys.tables AS t JOIN sys.schemas AS s ON s.schema_id=t.schema_id JOIN sys.columns AS c ON c.object_id=t.object_id JOIN sys.types AS ty ON ty.user_type_id=c.user_type_id ORDER BY s.name,t.name,c.column_id" }),
        (New-Object PSObject -Property @{ Name='source_high_cardinality_candidates'; File='high_cardinality_candidates.csv'; Query="SELECT s.name AS schema_name, t.name AS table_name, c.name AS column_name, ty.name AS data_type, c.max_length, c.is_computed FROM sys.tables AS t JOIN sys.schemas AS s ON s.schema_id=t.schema_id JOIN sys.columns AS c ON c.object_id=t.object_id JOIN sys.types AS ty ON ty.user_type_id=c.user_type_id WHERE ty.name IN ('uniqueidentifier','nvarchar','varchar','ntext','text','datetime','datetime2','float','real') ORDER BY c.max_length DESC,s.name,t.name,c.column_id" }),
        (New-Object PSObject -Property @{ Name='source_modules'; File='modules.csv'; Query="SELECT s.name AS schema_name, o.name AS object_name, o.type_desc, m.definition FROM sys.sql_modules AS m JOIN sys.objects AS o ON o.object_id=m.object_id JOIN sys.schemas AS s ON s.schema_id=o.schema_id WHERE o.type IN ('V','IF','TF','FN','P') ORDER BY s.name,o.name" })
    )

    $uniqueSources = @{}
    foreach ($mapping in $mappings) {
        $sourceDatabase = [string]$mapping.SourceDatabase
        $mappedSqlServer = [string]$mapping.SqlServer
        if (-not $mappedSqlServer) { $mappedSqlServer = $DefaultSqlServer }
        if ((-not $sourceDatabase) -or (-not $mappedSqlServer)) {
            Write-Warning "Source-map row dilewati: SourceDatabase dan SqlServer wajib tersedia."
            continue
        }
        $sourceKey = $mappedSqlServer + "|" + $sourceDatabase
        if (-not $uniqueSources.ContainsKey($sourceKey)) { $uniqueSources[$sourceKey] = $mapping }
    }

    foreach ($mapping in $uniqueSources.Values) {
        $sourceDatabase = [string]$mapping.SourceDatabase
        $mappedSqlServer = [string]$mapping.SqlServer
        if (-not $mappedSqlServer) { $mappedSqlServer = $DefaultSqlServer }

        $sourceDir = Join-Path (Join-Path (Join-Path $Root "SOURCE_SQL") (Sanitize-Name $mappedSqlServer)) (Sanitize-Name $sourceDatabase)
        Ensure-Directory $sourceDir

        foreach ($sourceQuery in $sourceQueries) {
            $path = Join-Path $sourceDir $sourceQuery.File
            if ((-not $Force) -and (Test-Path -LiteralPath $path)) {
                Add-ManifestRow -Manifest $Manifest -Server $mappedSqlServer -ServerType "SOURCE_SQL" -Database $sourceDatabase -Category "SOURCE_SQL" -Artifact $sourceQuery.Name -Status "SKIPPED" -Message "Artifact already exists." -Path $path
                continue
            }
            if ($WhatIf) {
                Add-ManifestRow -Manifest $Manifest -Server $mappedSqlServer -ServerType "SOURCE_SQL" -Database $sourceDatabase -Category "SOURCE_SQL" -Artifact $sourceQuery.Name -Status "WHATIF" -Message "Query not executed." -Path $path
                continue
            }

            $connection = $null
            $command = $null
            $adapter = $null
            $table = $null
            try {
                $connectionString = "Data Source=$mappedSqlServer;Initial Catalog=$sourceDatabase;Integrated Security=True;Application Name=SSAS Evidence Collector;"
                $connection = New-Object System.Data.SqlClient.SqlConnection($connectionString)
                $connection.Open()
                $command = $connection.CreateCommand()
                $command.CommandText = $sourceQuery.Query
                $command.CommandTimeout = $script:QueryTimeoutSeconds
                $adapter = New-Object System.Data.SqlClient.SqlDataAdapter($command)
                $table = New-Object System.Data.DataTable
                [void]$adapter.Fill($table)
                $rows = Export-TableCsv -Table $table -Path $path
                $status = "SUCCESS"
                $message = "Rows=$rows"
                if ($rows -eq 0) { $status = "SUCCESS_EMPTY"; $message = "Query succeeded but returned 0 rows." }
                Add-ManifestRow -Manifest $Manifest -Server $mappedSqlServer -ServerType "SOURCE_SQL" -Database $sourceDatabase -Category "SOURCE_SQL" -Artifact $sourceQuery.Name -Status $status -Message $message -Path $path
            }
            catch {
                Add-ManifestRow -Manifest $Manifest -Server $mappedSqlServer -ServerType "SOURCE_SQL" -Database $sourceDatabase -Category "SOURCE_SQL" -Artifact $sourceQuery.Name -Status "QUERY_FAILED_OR_UNSUPPORTED" -Message $_.Exception.Message -Path $path
            }
            finally {
                if ($null -ne $adapter) { try { $adapter.Dispose() } catch {} }
                if ($null -ne $command) { try { $command.Dispose() } catch {} }
                if ($null -ne $table) { try { $table.Dispose() } catch {} }
                if ($null -ne $connection) { try { $connection.Close() } catch {}; try { $connection.Dispose() } catch {} }
            }
        }
    }
}

function Export-TabularTmsl {
    param(
        [System.Collections.ArrayList]$Manifest,
        [string]$ServerName,
        [string]$DatabaseName,
        [string]$OutputPath
    )

    if ((-not $Force) -and (Test-Path -LiteralPath $OutputPath)) {
        Add-ManifestRow `
            -Manifest $Manifest -Server $ServerName -ServerType "TABULAR" `
            -Database $DatabaseName -Category "MODEL" -Artifact "database.tmsl.json" `
            -Status "SKIPPED" -Message "Artifact already exists; use -Force only for intentional overwrite." `
            -Path $OutputPath
        return
    }

    if ($WhatIf) {
        Add-ManifestRow `
            -Manifest $Manifest -Server $ServerName -ServerType "TABULAR" `
            -Database $DatabaseName -Category "MODEL" -Artifact "database.tmsl.json" `
            -Status "WHATIF" -Message "TMSL not exported." -Path $OutputPath
        return
    }

    if (-not $script:TomAvailable) {
        Add-ManifestRow `
            -Manifest $Manifest `
            -Server $ServerName `
            -ServerType "TABULAR" `
            -Database $DatabaseName `
            -Category "MODEL" `
            -Artifact "database.tmsl.json" `
            -Status "SKIPPED" `
            -Message "TOM assembly tidak tersedia." `
            -Path $OutputPath
        return
    }

    $server = $null

    try {
        $server = New-Object Microsoft.AnalysisServices.Tabular.Server
        $server.Connect($ServerName)

        $db = $server.Databases.FindByName($DatabaseName)

        if ($null -eq $db) {
            throw "Database '$DatabaseName' tidak ditemukan oleh TOM."
        }

        $json = [Microsoft.AnalysisServices.Tabular.JsonScripter]::ScriptCreateOrReplace($db)

        $json = Protect-SensitiveText $json
        $json | Set-Content -LiteralPath $OutputPath -Encoding UTF8

        Add-ManifestRow `
            -Manifest $Manifest `
            -Server $ServerName `
            -ServerType "TABULAR" `
            -Database $DatabaseName `
            -Category "MODEL" `
            -Artifact "database.tmsl.json" `
            -Status "SUCCESS" `
            -Message "" `
            -Path $OutputPath

        Write-Info "SUCCESS $DatabaseName :: TMSL"
    }
    catch {
        Add-ManifestRow `
            -Manifest $Manifest `
            -Server $ServerName `
            -ServerType "TABULAR" `
            -Database $DatabaseName `
            -Category "MODEL" `
            -Artifact "database.tmsl.json" `
            -Status "UNSUPPORTED_OR_FAILED" `
            -Message $_.Exception.Message `
            -Path $OutputPath

        Write-Warning "$DatabaseName :: TMSL :: $($_.Exception.Message)"
    }
    finally {
        if ($null -ne $server) {
            try { $server.Disconnect() } catch {}
        }
    }
}

# ------------------------------------------------------------
# START
# ------------------------------------------------------------

$minimumPowerShell = New-Object Version 4,0
if ($PSVersionTable.PSVersion -lt $minimumPowerShell) {
    throw ("PowerShell 4.0 atau lebih baru diperlukan. Versi aktif: " + $PSVersionTable.PSVersion)
}

$scriptPath = $MyInvocation.MyCommand.Path
$scriptDirectory = ""
if ($scriptPath) { $scriptDirectory = Split-Path -Parent $scriptPath }
if (-not $scriptDirectory) { $scriptDirectory = (Get-Location).Path }
if (-not [System.IO.Path]::IsPathRooted($ConfigPath)) {
    $ConfigPath = Join-Path $scriptDirectory $ConfigPath
}
if ($SourceMapPath -and (-not [System.IO.Path]::IsPathRooted($SourceMapPath))) {
    $SourceMapPath = Join-Path $scriptDirectory $SourceMapPath
}
if ($AdomdClientPath -and (-not [System.IO.Path]::IsPathRooted($AdomdClientPath))) {
    $AdomdClientPath = Join-Path $scriptDirectory $AdomdClientPath
}

Write-Host ("SSAS Evidence Collector v" + $script:CollectorVersion + " (PowerShell 4.0 compatible)")
Import-SSASLibraries -RequestedAdomdPath $AdomdClientPath

if (-not (Test-Path -LiteralPath $ConfigPath)) {
    throw "Config file tidak ditemukan: $ConfigPath"
}

$configFull = (Resolve-Path $ConfigPath).Path
$config = Get-Content -LiteralPath $configFull -Raw | ConvertFrom-Json
$configDir = Split-Path $configFull -Parent

$script:QueryTimeoutSeconds = 60
if ($null -ne $config.query_timeout_seconds) {
    try {
        $script:QueryTimeoutSeconds = [int]$config.query_timeout_seconds
    }
    catch {
        $script:QueryTimeoutSeconds = 60
    }
}

Write-Info ("Query timeout: " + $script:QueryTimeoutSeconds + " seconds")

$configuredAssessmentId = [string]$config.assessment_id
if (-not $AssessmentId) { $AssessmentId = $configuredAssessmentId }
if (-not $AssessmentId) { throw "AssessmentId tidak boleh kosong." }
if ($AssessmentId -match '[\\/:*?\"<>|]') { throw "AssessmentId mengandung karakter path yang tidak valid." }

if (-not $OutputRoot) { $OutputRoot = [string]$config.output_root }
$outputRoot = $OutputRoot

if (-not [System.IO.Path]::IsPathRooted($outputRoot)) {
    $outputRoot = Join-Path $configDir $outputRoot
}

$assessmentRoot = Join-Path $outputRoot $AssessmentId

Ensure-Directory $assessmentRoot
Ensure-Directory (Join-Path $assessmentRoot "MANIFEST")

$manifest = New-Object System.Collections.ArrayList
$dbInventory = New-Object System.Collections.ArrayList

$tabularMetadata = @{
    tables        = 'SELECT * FROM $SYSTEM.TMSCHEMA_TABLES'
    columns       = 'SELECT * FROM $SYSTEM.TMSCHEMA_COLUMNS'
    measures      = 'SELECT * FROM $SYSTEM.TMSCHEMA_MEASURES'
    relationships = 'SELECT * FROM $SYSTEM.TMSCHEMA_RELATIONSHIPS'
    partitions    = 'SELECT * FROM $SYSTEM.TMSCHEMA_PARTITIONS'
    hierarchies   = 'SELECT * FROM $SYSTEM.TMSCHEMA_HIERARCHIES'
    levels        = 'SELECT * FROM $SYSTEM.TMSCHEMA_LEVELS'
    roles         = 'SELECT * FROM $SYSTEM.TMSCHEMA_ROLES'
    refresh_policies = 'SELECT * FROM $SYSTEM.TMSCHEMA_REFRESH_POLICIES'
}

$tabularStorage = @{
    storage_tables          = 'SELECT * FROM $SYSTEM.DISCOVER_STORAGE_TABLES'
    storage_table_columns   = 'SELECT * FROM $SYSTEM.DISCOVER_STORAGE_TABLE_COLUMNS'
    storage_column_segments = 'SELECT * FROM $SYSTEM.DISCOVER_STORAGE_TABLE_COLUMN_SEGMENTS'
    partition_stats         = 'SELECT * FROM $SYSTEM.TMSCHEMA_PARTITION_STATS'
}

$multidimMetadata = @{
    catalogs       = 'SELECT * FROM $SYSTEM.DBSCHEMA_CATALOGS'
    cubes          = 'SELECT * FROM $SYSTEM.MDSCHEMA_CUBES'
    dimensions     = 'SELECT * FROM $SYSTEM.MDSCHEMA_DIMENSIONS'
    hierarchies    = 'SELECT * FROM $SYSTEM.MDSCHEMA_HIERARCHIES'
    levels         = 'SELECT * FROM $SYSTEM.MDSCHEMA_LEVELS'
    measures       = 'SELECT * FROM $SYSTEM.MDSCHEMA_MEASURES'
    measure_groups = 'SELECT * FROM $SYSTEM.MDSCHEMA_MEASUREGROUPS'
    sets           = 'SELECT * FROM $SYSTEM.MDSCHEMA_SETS'
    functions      = 'SELECT * FROM $SYSTEM.MDSCHEMA_FUNCTIONS'
    properties     = 'SELECT * FROM $SYSTEM.MDSCHEMA_PROPERTIES'
    kpis           = 'SELECT * FROM $SYSTEM.MDSCHEMA_KPIS'
}

$multidimStorage = @{}

$serverRuntime = @{
    server_properties = 'SELECT * FROM $SYSTEM.DISCOVER_PROPERTIES'
    sessions          = 'SELECT * FROM $SYSTEM.DISCOVER_SESSIONS'
    connections       = 'SELECT * FROM $SYSTEM.DISCOVER_CONNECTIONS'
    commands          = 'SELECT * FROM $SYSTEM.DISCOVER_COMMANDS'
}

foreach ($srv in $config.servers) {

    $serverName = [string]$srv.name
    $serverType = ([string]$srv.type).ToUpper()
    $safeServer = Sanitize-Name $serverName

    Write-Info "Discover server: $serverName ($serverType)"

    try {
        $discovered = @(Get-DatabaseList -Server $serverName)

        Write-Info ("Database discovered: " + $discovered.Count)
    }
    catch {
        Add-ManifestRow `
            -Manifest $manifest `
            -Server $serverName `
            -ServerType $serverType `
            -Database "" `
            -Category "SERVER" `
            -Artifact "database_discovery" `
            -Status "FAILED" `
            -Message $_.Exception.Message `
            -Path ""

        Write-Warning "Server gagal diakses: $serverName"
        continue
    }

    $selected = @(Resolve-Databases -ServerConfig $srv -Discovered $discovered)

    Write-Info ("Database selected: " + $selected.Count)

    foreach ($db in $discovered) {

        [void]$dbInventory.Add((New-Object PSObject -Property @{
            Server     = $serverName
            ServerType = $serverType
            Database   = $db
            Selected   = ($selected -contains $db)
        }))
    }

    # Runtime hanya satu kali per server.
    if ($config.collect.server_runtime -eq $true) {

        $runtimeDir = Join-Path $assessmentRoot ("SERVER_RUNTIME\" + $safeServer)
        Ensure-Directory $runtimeDir

        foreach ($key in $serverRuntime.Keys) {

            $out = Join-Path $runtimeDir ($key + ".csv")

            Collect-QueryArtifact `
                -Manifest $manifest `
                -Server $serverName `
                -ServerType $serverType `
                -Database "" `
                -Category "SERVER_RUNTIME" `
                -Name $key `
                -Query $serverRuntime[$key] `
                -OutputPath $out
        }

        # DISCOVER_OBJECT_MEMORY_USAGE at server scope can be extremely expensive
        # on large SSAS fleets. Disabled by default.
        if ($config.collect.server_memory_usage -eq $true) {

            Collect-QueryArtifact `
                -Manifest $manifest `
                -Server $serverName `
                -ServerType $serverType `
                -Database "" `
                -Category "SERVER_RUNTIME" `
                -Name "memory_usage" `
                -Query 'SELECT * FROM $SYSTEM.DISCOVER_OBJECT_MEMORY_USAGE' `
                -OutputPath (Join-Path $runtimeDir "memory_usage.csv")
        }
        else {

            Add-ManifestRow `
                -Manifest $manifest `
                -Server $serverName `
                -ServerType $serverType `
                -Database "" `
                -Category "SERVER_RUNTIME" `
                -Artifact "memory_usage" `
                -Status "SKIPPED" `
                -Message "Disabled by default because server-wide DISCOVER_OBJECT_MEMORY_USAGE can be very expensive." `
                -Path (Join-Path $runtimeDir "memory_usage.csv")

            Write-Info "SKIPPED server-wide memory_usage (safe default)"
        }
    }

    foreach ($dbName in $selected) {

        if ($discovered -notcontains $dbName) {

            Add-ManifestRow `
                -Manifest $manifest `
                -Server $serverName `
                -ServerType $serverType `
                -Database $dbName `
                -Category "DATABASE" `
                -Artifact "selection" `
                -Status "FAILED" `
                -Message "Database tidak ditemukan di server." `
                -Path ""

            continue
        }

        $safeDb = Sanitize-Name $dbName

        if ($serverType -eq "TABULAR") {

            $dbRoot = Join-Path $assessmentRoot ("TABULAR\" + $safeDb)
            $metaDir = Join-Path $dbRoot "metadata"
            $storageDir = Join-Path $dbRoot "storage"
            $modelDir = Join-Path $dbRoot "model"

            Ensure-Directory $metaDir
            Ensure-Directory $storageDir
            Ensure-Directory $modelDir
            Export-CollectionMetadata -Server $serverName -ServerType $serverType -Database $dbName -Path (Join-Path $dbRoot "collection_metadata.json")

            if ($config.collect.database_metadata -eq $true) {

                foreach ($key in $tabularMetadata.Keys) {

                    Collect-QueryArtifact `
                        -Manifest $manifest `
                        -Server $serverName `
                        -ServerType $serverType `
                        -Database $dbName `
                        -Category "METADATA" `
                        -Name $key `
                        -Query $tabularMetadata[$key] `
                        -OutputPath (Join-Path $metaDir ($key + ".csv"))
                }
            }

            if ($config.collect.database_storage -eq $true) {

                foreach ($key in $tabularStorage.Keys) {

                    Collect-QueryArtifact `
                        -Manifest $manifest `
                        -Server $serverName `
                        -ServerType $serverType `
                        -Database $dbName `
                        -Category "STORAGE" `
                        -Name $key `
                        -Query $tabularStorage[$key] `
                        -OutputPath (Join-Path $storageDir ($key + ".csv"))
                }
            }

            # DISCOVER_OBJECT_MEMORY_USAGE can be extremely expensive even
            # when Initial Catalog is set. Disabled by default for fleet runs.
            if ($config.collect.database_object_memory_usage -eq $true) {

                Collect-QueryArtifact `
                    -Manifest $manifest `
                    -Server $serverName `
                    -ServerType $serverType `
                    -Database $dbName `
                    -Category "STORAGE" `
                    -Name "object_memory_usage" `
                    -Query 'SELECT * FROM $SYSTEM.DISCOVER_OBJECT_MEMORY_USAGE' `
                    -OutputPath (Join-Path $storageDir "object_memory_usage.csv")
            }
            else {

                Add-ManifestRow `
                    -Manifest $manifest `
                    -Server $serverName `
                    -ServerType $serverType `
                    -Database $dbName `
                    -Category "STORAGE" `
                    -Artifact "object_memory_usage" `
                    -Status "SKIPPED" `
                    -Message "Disabled by default for fleet runs because DISCOVER_OBJECT_MEMORY_USAGE can block for a long time on large models." `
                    -Path (Join-Path $storageDir "object_memory_usage.csv")

                Write-Info "SKIPPED $dbName :: object_memory_usage (safe fleet default)"
            }

            if ($config.collect.tabular_tmsl -eq $true) {

                Export-TabularTmsl `
                    -Manifest $manifest `
                    -ServerName $serverName `
                    -DatabaseName $dbName `
                    -OutputPath (Join-Path $modelDir "database.tmsl.json")
            }
        }
        elseif ($serverType -eq "MULTIDIMENSIONAL") {

            $dbRoot = Join-Path $assessmentRoot ("MULTIDIMENSIONAL\" + $safeDb)
            $metaDir = Join-Path $dbRoot "metadata"
            $storageDir = Join-Path $dbRoot "storage"

            Ensure-Directory $metaDir
            Ensure-Directory $storageDir
            Export-CollectionMetadata -Server $serverName -ServerType $serverType -Database $dbName -Path (Join-Path $dbRoot "collection_metadata.json")

            if ($config.collect.database_metadata -eq $true) {

                foreach ($key in $multidimMetadata.Keys) {

                    Collect-QueryArtifact `
                        -Manifest $manifest `
                        -Server $serverName `
                        -ServerType $serverType `
                        -Database $dbName `
                        -Category "METADATA" `
                        -Name $key `
                        -Query $multidimMetadata[$key] `
                        -OutputPath (Join-Path $metaDir ($key + ".csv"))
                }
            }

            if ($config.collect.database_storage -eq $true) {
                $cubeMetadataPath = Join-Path $metaDir "cubes.csv"
                $cubeNames = @()
                if (Test-Path -LiteralPath $cubeMetadataPath) {
                    # CUBE_SOURCE=1 represents real cubes/perspectives. Exclude
                    # CUBE_SOURCE=2 dimension cubes from partition collection.
                    $cubeNames = @(Import-Csv -LiteralPath $cubeMetadataPath | Where-Object {
                        $_.CUBE_NAME -and ([string]$_.CUBE_SOURCE -eq "1")
                    } | Select-Object -ExpandProperty CUBE_NAME -Unique)
                }

                if ($cubeNames.Count -eq 0) {
                    Add-ManifestRow -Manifest $manifest -Server $serverName -ServerType $serverType `
                        -Database $dbName -Category "STORAGE" -Artifact "partition_stats" `
                        -Status "QUERY_FAILED_OR_UNSUPPORTED" `
                        -Message "Tidak ada CUBE_NAME dari metadata/cubes.csv; partition statistics tidak dapat direstrict dengan aman." `
                        -Path $storageDir
                }
                else {
                    foreach ($cubeName in $cubeNames) {
                        $escapedDatabase = $dbName.Replace("'", "''")
                        $escapedCube = ([string]$cubeName).Replace("'", "''")
                        $safeCube = Sanitize-Name ([string]$cubeName)
                        $partitionQuery = "SELECT * FROM SYSTEMRESTRICTSCHEMA(`$SYSTEM.DISCOVER_PARTITION_STAT, [DATABASE_NAME] = '$escapedDatabase', [CUBE_NAME] = '$escapedCube')"
                        Collect-QueryArtifact -Manifest $manifest -Server $serverName -ServerType $serverType `
                            -Database $dbName -Category "STORAGE" -Name ("partition_stats__" + $safeCube) `
                            -Query $partitionQuery -OutputPath (Join-Path $storageDir ("partition_stats__" + $safeCube + ".csv"))
                    }
                }

                if ($config.collect.database_object_memory_usage -eq $true) {

                    Collect-QueryArtifact `
                        -Manifest $manifest `
                        -Server $serverName `
                        -ServerType $serverType `
                        -Database $dbName `
                        -Category "STORAGE" `
                        -Name "object_memory_usage" `
                        -Query 'SELECT * FROM $SYSTEM.DISCOVER_OBJECT_MEMORY_USAGE' `
                        -OutputPath (Join-Path $storageDir "object_memory_usage.csv")
                }
                else {

                    Add-ManifestRow `
                        -Manifest $manifest `
                        -Server $serverName `
                        -ServerType $serverType `
                        -Database $dbName `
                        -Category "STORAGE" `
                        -Artifact "object_memory_usage" `
                        -Status "SKIPPED" `
                        -Message "Disabled by default for fleet runs because DISCOVER_OBJECT_MEMORY_USAGE can block for a long time." `
                        -Path (Join-Path $storageDir "object_memory_usage.csv")

                    Write-Info "SKIPPED $dbName :: object_memory_usage (safe fleet default)"
                }
            }
        }
        else {

            Add-ManifestRow `
                -Manifest $manifest `
                -Server $serverName `
                -ServerType $serverType `
                -Database $dbName `
                -Category "DATABASE" `
                -Artifact "server_type" `
                -Status "FAILED" `
                -Message "type harus TABULAR atau MULTIDIMENSIONAL" `
                -Path ""
        }
    }
}

$automaticMappings = @(Get-AutomaticSourceMappings -Root $assessmentRoot -DatabaseInventory @($dbInventory))
$automaticMapPath = Join-Path $assessmentRoot "MANIFEST\source_map_auto.csv"
$automaticMappings | Select-Object Database,SqlServer,SourceDatabase,DataSourceName,DiscoveryStatus |
    Export-Csv -LiteralPath $automaticMapPath -NoTypeInformation -Encoding UTF8

if ($config.collect.source_sql -eq $true -or $SourceMapPath) {
    Collect-SourceSqlEvidence -Manifest $manifest -MapPath $SourceMapPath -DefaultSqlServer $SqlServer `
        -Root $assessmentRoot -AutomaticMappings $automaticMappings
}

$dbInventory |
    Select-Object Server,ServerType,Database,Selected |
    Export-Csv `
        -LiteralPath (Join-Path $assessmentRoot "MANIFEST\databases.csv") `
        -NoTypeInformation `
        -Encoding UTF8

$manifestPath = Join-Path $assessmentRoot "MANIFEST\collection_manifest.csv"
$oldManifest = @()
$effectiveManifest = @($manifest | Where-Object {
    -not ($_.Status -eq "SKIPPED" -and $_.Message -match '^Artifact already exists')
})
if ((Test-Path -LiteralPath $manifestPath) -and (-not $Force)) {
    $newKeys = @($effectiveManifest | ForEach-Object { $_.Server + "|" + $_.Database + "|" + $_.Artifact })
    $oldManifest = @(Import-Csv -LiteralPath $manifestPath | Where-Object {
        $oldKey = $_.Server + "|" + $_.Database + "|" + $_.Artifact
        $newKeys -notcontains $oldKey
    })
}
$allManifest = @($oldManifest) + @($effectiveManifest)

$allManifest |
    Select-Object CollectedAt,Server,ServerType,Database,Category,Artifact,Status,Message,Path |
    Export-Csv `
        -LiteralPath $manifestPath `
        -NoTypeInformation `
        -Encoding UTF8

$coverage = @($allManifest | Group-Object Server,ServerType,Database,Category | ForEach-Object {
    $rows = @($_.Group)
    $statuses = @($rows | Select-Object -ExpandProperty Status -Unique)
    $successRows = @($rows | Where-Object { $_.Status -eq "SUCCESS" -or $_.Status -eq "SUCCESS_EMPTY" }).Count
    $coverageStatus = "MISSING"
    if ($successRows -eq $rows.Count) {
        $coverageStatus = "COMPLETE"
    }
    elseif ($successRows -gt 0) {
        $coverageStatus = "PARTIAL"
    }
    elseif (@($rows | Where-Object { $_.Status -eq "SKIPPED" }).Count -eq $rows.Count) {
        $coverageStatus = "SKIPPED"
    }
    elseif (@($rows | Where-Object { $_.Message -match '^UNSUPPORTED:' }).Count -eq $rows.Count) {
        $coverageStatus = "UNSUPPORTED"
    }

    New-Object PSObject -Property @{
        Server = $rows[0].Server
        ServerType = $rows[0].ServerType
        Database = $rows[0].Database
        Category = $rows[0].Category
        Coverage = $coverageStatus
        ArtifactCount = $rows.Count
        Statuses = ($statuses -join ";")
    }
})
$coverage | Select-Object Server,ServerType,Database,Category,Coverage,ArtifactCount,Statuses |
    Export-Csv -LiteralPath (Join-Path $assessmentRoot "MANIFEST\coverage.csv") -NoTypeInformation -Encoding UTF8

$successCount = @($allManifest | Where-Object { ($_.Status -eq "SUCCESS") -or ($_.Status -eq "SUCCESS_EMPTY") }).Count
$skippedCount = @($allManifest | Where-Object { $_.Status -eq "SKIPPED" }).Count
$whatIfCount = @($allManifest | Where-Object { $_.Status -eq "WHATIF" }).Count
$failedCount = @($allManifest | Where-Object { ($_.Status -ne "SUCCESS") -and ($_.Status -ne "SUCCESS_EMPTY") -and ($_.Status -ne "SKIPPED") -and ($_.Status -ne "WHATIF") }).Count
$tabularDatabaseCount = @($dbInventory | Where-Object { $_.ServerType -eq "TABULAR" -and $_.Selected }).Count
$multidimDatabaseCount = @($dbInventory | Where-Object { $_.ServerType -eq "MULTIDIMENSIONAL" -and $_.Selected }).Count

$summary = New-Object PSObject -Property @{
    assessment_id        = $AssessmentId
    collector             = "Collect-SSAS.ps1"
    collector_version     = $script:CollectorVersion
    collection_started_at_utc = $script:CollectionStartedAtUtc.ToString("o")
    collection_finished_at_utc = [DateTime]::UtcNow.ToString("o")
    collected_at         = (Get-Date).ToString("s")
    powershell_version   = $PSVersionTable.PSVersion.ToString()
    tom_available        = $script:TomAvailable
    total_artifacts      = $allManifest.Count
    success              = $successCount
    skipped              = $skippedCount
    whatif               = $whatIfCount
    failed_or_unsupported = $failedCount
    tabular_databases    = $tabularDatabaseCount
    multidimensional_databases = $multidimDatabaseCount
}

$summary |
    ConvertTo-Json -Depth 5 |
    Set-Content `
        -LiteralPath (Join-Path $assessmentRoot "MANIFEST\summary.json") `
        -Encoding UTF8

Write-Host ""
Write-Host "============================================================"
Write-Host "SSAS Collection selesai"
Write-Host "============================================================"
Write-Host "Output   : $assessmentRoot"
Write-Host "Manifest : $(Join-Path $assessmentRoot 'MANIFEST\collection_manifest.csv')"
Write-Host "Success  : $successCount"
Write-Host "Other    : $failedCount"
Write-Host ""
