param(
    [Parameter(Mandatory=$false)]
    [string]$ConfigPath = ".\config.json"
)

$ErrorActionPreference = "Stop"

function Write-Info($msg) {
    Write-Host "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $msg"
}

function Ensure-Directory([string]$Path) {
    if (-not (Test-Path $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
    }
}

function Sanitize-Name([string]$Name) {
    return ($Name -replace '[\\/:*?"<>|]', '_')
}

function Import-SSASLibraries {
    Write-Info "Loading SSAS client libraries..."

    $requiredAssemblies = @(
        "Microsoft.AnalysisServices.AdomdClient",
        "Microsoft.AnalysisServices"
    )

    foreach ($asm in $requiredAssemblies) {
        try {
            $loaded = [System.Reflection.Assembly]::LoadWithPartialName($asm)

            if ($null -eq $loaded) {
                throw "Assembly '$asm' tidak ditemukan."
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
    $cs = "Data Source=$Server;Integrated Security=SSPI;"
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
        Write-Output -NoEnumerate $ds.Tables[0]
    }
    finally {
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
        "" | Set-Content -Path $Path -Encoding UTF8
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
            ($header -join ",") | Set-Content -Path $Path -Encoding UTF8
        }
        else {
            "" | Set-Content -Path $Path -Encoding UTF8
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

                $obj | Add-Member `
                    -MemberType NoteProperty `
                    -Name $c.ColumnName `
                    -Value $value
            }
        }

        $rows += $obj
    }

    $rows | Export-Csv -Path $Path -NoTypeInformation -Encoding UTF8

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

function Export-TabularTmsl {
    param(
        [System.Collections.ArrayList]$Manifest,
        [string]$ServerName,
        [string]$DatabaseName,
        [string]$OutputPath
    )

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

        $json | Set-Content -Path $OutputPath -Encoding UTF8

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

Write-Host "SSAS Collector v1.6 (PowerShell 4.0 compatible)"
Import-SSASLibraries

if (-not (Test-Path $ConfigPath)) {
    throw "Config file tidak ditemukan: $ConfigPath"
}

$configFull = (Resolve-Path $ConfigPath).Path
$config = Get-Content $configFull -Raw | ConvertFrom-Json
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

$outputRoot = [string]$config.output_root

if (-not [System.IO.Path]::IsPathRooted($outputRoot)) {
    $outputRoot = Join-Path $configDir $outputRoot
}

$assessmentRoot = Join-Path $outputRoot ([string]$config.assessment_id)

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
}

$tabularStorage = @{
    storage_tables          = 'SELECT * FROM $SYSTEM.DISCOVER_STORAGE_TABLES'
    storage_table_columns   = 'SELECT * FROM $SYSTEM.DISCOVER_STORAGE_TABLE_COLUMNS'
    storage_column_segments = 'SELECT * FROM $SYSTEM.DISCOVER_STORAGE_TABLE_COLUMN_SEGMENTS'
    partition_stats         = 'SELECT * FROM $SYSTEM.TMSCHEMA_PARTITION_STATS'
}

$multidimMetadata = @{
    cubes          = 'SELECT * FROM $SYSTEM.MDSCHEMA_CUBES'
    dimensions     = 'SELECT * FROM $SYSTEM.MDSCHEMA_DIMENSIONS'
    hierarchies    = 'SELECT * FROM $SYSTEM.MDSCHEMA_HIERARCHIES'
    levels         = 'SELECT * FROM $SYSTEM.MDSCHEMA_LEVELS'
    measures       = 'SELECT * FROM $SYSTEM.MDSCHEMA_MEASURES'
    measure_groups = 'SELECT * FROM $SYSTEM.MDSCHEMA_MEASUREGROUPS'
    sets           = 'SELECT * FROM $SYSTEM.MDSCHEMA_SETS'
    functions      = 'SELECT * FROM $SYSTEM.MDSCHEMA_FUNCTIONS'
}

$multidimStorage = @{
    storage_tables = 'SELECT * FROM $SYSTEM.DISCOVER_STORAGE_TABLES'
}

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
                -Message "Disabled by default because server-wide DISCOVER_OBJECT_MEMORY_USAGE can be very expensive. Database-level collection remains enabled." `
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

                foreach ($key in $multidimStorage.Keys) {

                    Collect-QueryArtifact `
                        -Manifest $manifest `
                        -Server $serverName `
                        -ServerType $serverType `
                        -Database $dbName `
                        -Category "STORAGE" `
                        -Name $key `
                        -Query $multidimStorage[$key] `
                        -OutputPath (Join-Path $storageDir ($key + ".csv"))
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

$dbInventory |
    Select-Object Server,ServerType,Database,Selected |
    Export-Csv `
        -Path (Join-Path $assessmentRoot "MANIFEST\databases.csv") `
        -NoTypeInformation `
        -Encoding UTF8

$manifest |
    Select-Object CollectedAt,Server,ServerType,Database,Category,Artifact,Status,Message,Path |
    Export-Csv `
        -Path (Join-Path $assessmentRoot "MANIFEST\collection_manifest.csv") `
        -NoTypeInformation `
        -Encoding UTF8

$successCount = @($manifest | Where-Object { ($_.Status -eq "SUCCESS") -or ($_.Status -eq "SUCCESS_EMPTY") }).Count
$failedCount = @($manifest | Where-Object { $_.Status -ne "SUCCESS" }).Count

$summary = New-Object PSObject -Property @{
    assessment_id        = [string]$config.assessment_id
    collected_at         = (Get-Date).ToString("s")
    powershell_version   = $PSVersionTable.PSVersion.ToString()
    tom_available        = $script:TomAvailable
    total_artifacts      = $manifest.Count
    success              = $successCount
    failed_or_unsupported = $failedCount
}

$summary |
    ConvertTo-Json -Depth 5 |
    Set-Content `
        -Path (Join-Path $assessmentRoot "MANIFEST\summary.json") `
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
