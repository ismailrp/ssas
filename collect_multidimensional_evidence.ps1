<#
.SYNOPSIS
Collects read-only, Multidimensional-specific SSAS metadata by using AMO.

.DESCRIPTION
This add-on complements Collect-SSAS.ps1. It does not process objects, clear
cache, deploy changes, or start traces. Existing artifacts are skipped unless
-Force is supplied. Connection strings and account names are never exported.

Compatible with Windows PowerShell 4.0.
#>
param(
    [string]$EvidenceRoot = '',
    [string]$ConfigPath = '',
    [string]$Server = '',
    [string[]]$Database = @('*'),
    [string]$AmoPath = '',
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
$scriptPath = $MyInvocation.MyCommand.Path
$scriptDirectory = if ($scriptPath) { Split-Path -Parent $scriptPath } else { (Get-Location).Path }
if (-not $ConfigPath) { $ConfigPath = Join-Path $scriptDirectory 'config.json' }
if (-not (Test-Path -LiteralPath $ConfigPath)) { throw "Config tidak ditemukan: $ConfigPath" }
$config = Get-Content -LiteralPath $ConfigPath -Raw | ConvertFrom-Json

if (-not $EvidenceRoot) {
    $outputRoot = [string]$config.output_root
    if (-not [IO.Path]::IsPathRooted($outputRoot)) { $outputRoot = Join-Path $scriptDirectory $outputRoot }
    $EvidenceRoot = Join-Path $outputRoot ([string]$config.assessment_id)
}
$EvidenceRoot = [IO.Path]::GetFullPath($EvidenceRoot)

if (-not $Server) {
    $serverConfig = @($config.servers | Where-Object { $_.type -eq 'MULTIDIMENSIONAL' } | Select-Object -First 1)
    if ($serverConfig.Count -eq 0) { throw 'Server MULTIDIMENSIONAL tidak ditemukan pada config.' }
    $Server = [string]$serverConfig[0].name
}

function Ensure-Directory([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path)) { New-Item -ItemType Directory -Path $Path -Force | Out-Null }
}

function Safe-Name([string]$Name) {
    if (-not $Name) { return '_' }
    return [string]::Join('_', $Name.Split([IO.Path]::GetInvalidFileNameChars()))
}

function Get-Value($Object, [string]$Property, $Default = '') {
    if ($null -eq $Object) { return $Default }
    $p = $Object.PSObject.Properties[$Property]
    if ($null -eq $p -or $null -eq $p.Value) { return $Default }
    return $p.Value
}

function Get-ObjectType($Object) {
    if ($null -eq $Object) { return '' }
    return $Object.GetType().FullName
}

function Get-Sha256([string]$Text) {
    if ($null -eq $Text) { $Text = '' }
    $sha = [Security.Cryptography.SHA256]::Create()
    try {
        $bytes = [Text.Encoding]::UTF8.GetBytes($Text)
        return ([BitConverter]::ToString($sha.ComputeHash($bytes))).Replace('-', '').ToLowerInvariant()
    }
    finally { $sha.Dispose() }
}

function Import-Amo([string]$RequestedPath) {
    $loaded = [Reflection.Assembly]::LoadWithPartialName('Microsoft.AnalysisServices')
    if ($loaded) { return }
    if ($RequestedPath -and (Test-Path -LiteralPath $RequestedPath)) {
        [Reflection.Assembly]::LoadFrom((Resolve-Path -LiteralPath $RequestedPath).Path) | Out-Null
        return
    }
    $candidates = @()
    foreach ($root in @(${env:ProgramFiles}, ${env:ProgramFiles(x86)})) {
        if (-not $root) { continue }
        foreach ($version in @('160', '150', '140', '130', '120', '110')) {
            $candidates += Join-Path $root ("Microsoft SQL Server\$version\SDK\Assemblies\Microsoft.AnalysisServices.dll")
        }
    }
    foreach ($candidate in $candidates) {
        if (Test-Path -LiteralPath $candidate) {
            [Reflection.Assembly]::LoadFrom($candidate) | Out-Null
            return
        }
    }
    throw 'Microsoft.AnalysisServices.dll tidak ditemukan. Install SSMS/SSDT atau gunakan -AmoPath.'
}

$manifest = New-Object Collections.Generic.List[object]
$collectedDatabases = New-Object Collections.Generic.List[object]
function Add-Manifest([string]$DatabaseName, [string]$Artifact, [string]$Status, [int]$Rows, [string]$Message, [string]$Path) {
    $manifest.Add([pscustomobject]@{
        CollectedAt = (Get-Date).ToString('s')
        Server = $Server
        ServerType = 'MULTIDIMENSIONAL'
        Database = $DatabaseName
        Category = 'MULTIDIMENSIONAL_EXTENDED'
        Artifact = $Artifact
        Status = $Status
        RowCount = $Rows
        Message = $Message
        Path = $Path
    })
}

function Export-Rows([string]$DatabaseName, [string]$Artifact, [string]$Directory, [object[]]$Rows) {
    Ensure-Directory $Directory
    $path = Join-Path $Directory ($Artifact + '.csv')
    if ((Test-Path -LiteralPath $path) -and -not $Force) {
        Add-Manifest $DatabaseName $Artifact 'SKIPPED' 0 'Artifact already exists; use -Force for intentional overwrite.' $path
        return
    }
    try {
        $items = @($Rows)
        if ($items.Count -eq 0) {
            Set-Content -LiteralPath $path -Encoding UTF8 -Value ''
            Add-Manifest $DatabaseName $Artifact 'SUCCESS_EMPTY' 0 'Collection succeeded but returned 0 rows.' $path
        }
        else {
            $items | Export-Csv -LiteralPath $path -NoTypeInformation -Encoding UTF8
            Add-Manifest $DatabaseName $Artifact 'SUCCESS' $items.Count ("Rows=" + $items.Count) $path
        }
    }
    catch {
        Add-Manifest $DatabaseName $Artifact 'QUERY_FAILED_OR_UNSUPPORTED' 0 ("UNSUPPORTED: " + $_.Exception.Message) $path
    }
}

function Is-SelectedDatabase([string]$Name) {
    if ($Database -contains '*') { return $true }
    return $Database -contains $Name
}

Import-Amo $AmoPath
Ensure-Directory $EvidenceRoot
Ensure-Directory (Join-Path $EvidenceRoot 'MANIFEST')

$amoServer = New-Object Microsoft.AnalysisServices.Server
try {
    $amoServer.Connect($Server)
    foreach ($db in @($amoServer.Databases)) {
        if (-not (Is-SelectedDatabase ([string]$db.Name))) { continue }
        $dbName = [string]$db.Name
        $collectedDatabases.Add([pscustomobject]@{Server=$Server;ServerType='MULTIDIMENSIONAL';Database=$dbName;Selected=$true})
        $base = Join-Path (Join-Path $EvidenceRoot 'MULTIDIMENSIONAL') (Safe-Name $dbName)
        $metadata = Join-Path $base 'metadata_extended'

        $partitionRows = New-Object Collections.Generic.List[object]
        $partitionSourceRows = New-Object Collections.Generic.List[object]
        $dimensionUsageRows = New-Object Collections.Generic.List[object]
        $aggregationDesignRows = New-Object Collections.Generic.List[object]
        $aggregationRows = New-Object Collections.Generic.List[object]
        $calculationRows = New-Object Collections.Generic.List[object]
        $cubePermissionRows = New-Object Collections.Generic.List[object]

        foreach ($cube in @($db.Cubes)) {
            foreach ($mg in @($cube.MeasureGroups)) {
                foreach ($partition in @($mg.Partitions)) {
                    $source = Get-Value $partition 'Source' $null
                    $sourceText = [string](Get-Value $source 'QueryDefinition' '')
                    $partitionRows.Add([pscustomobject]@{
                        Database=$dbName; Cube=$cube.Name; MeasureGroup=$mg.Name; Partition=$partition.Name
                        PartitionID=$partition.ID; StorageMode=(Get-Value $partition 'StorageMode'); ProcessingMode=(Get-Value $partition 'ProcessingMode')
                        State=(Get-Value $partition 'State'); EstimatedRows=(Get-Value $partition 'EstimatedRows'); LastProcessed=(Get-Value $partition 'LastProcessed')
                        AggregationDesignID=(Get-Value $partition 'AggregationDesignID'); SourceType=(Get-ObjectType $source)
                    })
                    $partitionSourceRows.Add([pscustomobject]@{
                        Database=$dbName; Cube=$cube.Name; MeasureGroup=$mg.Name; Partition=$partition.Name
                        SourceType=(Get-ObjectType $source); DataSourceID=(Get-Value $source 'DataSourceID'); DataSourceViewID=(Get-Value $source 'DataSourceViewID')
                        TableID=(Get-Value $source 'TableID'); QueryHash=(Get-Sha256 $sourceText); QueryLength=$sourceText.Length
                        QueryDefinition='REDACTED; retrieve from secured model source only when approved'
                    })
                }
                foreach ($usage in @($mg.Dimensions)) {
                    $dimensionUsageRows.Add([pscustomobject]@{
                        Database=$dbName; Cube=$cube.Name; MeasureGroup=$mg.Name; UsageType=(Get-ObjectType $usage)
                        CubeDimensionID=(Get-Value $usage 'CubeDimensionID'); DimensionID=(Get-Value $usage 'DimensionID')
                        GranularityAttributeID=(Get-Value $usage 'GranularityAttributeID'); IntermediateCubeDimensionID=(Get-Value $usage 'IntermediateCubeDimensionID')
                        Materialization=(Get-Value $usage 'Materialization')
                    })
                }
                foreach ($design in @($mg.AggregationDesigns)) {
                    $aggregationDesignRows.Add([pscustomobject]@{
                        Database=$dbName; Cube=$cube.Name; MeasureGroup=$mg.Name; AggregationDesign=$design.Name
                        AggregationDesignID=$design.ID; AggregationCount=@($design.Aggregations).Count; EstimatedRows=(Get-Value $design 'EstimatedRows')
                    })
                    foreach ($agg in @($design.Aggregations)) {
                        $dimensionCount=0; $attributeCount=0
                        foreach ($aggDimension in @($agg.Dimensions)) { $dimensionCount++; $attributeCount += @($aggDimension.Attributes).Count }
                        $aggregationRows.Add([pscustomobject]@{
                            Database=$dbName; Cube=$cube.Name; MeasureGroup=$mg.Name; AggregationDesign=$design.Name
                            Aggregation=$agg.Name; AggregationID=$agg.ID; DimensionCount=$dimensionCount; AttributeCount=$attributeCount
                        })
                    }
                }
            }
            foreach ($script in @($cube.MdxScripts)) {
                foreach ($command in @($script.Commands)) {
                    $text = [string](Get-Value $command 'Text' '')
                    $calculationRows.Add([pscustomobject]@{
                        Database=$dbName; Cube=$cube.Name; Script=$script.Name; ScriptID=$script.ID
                        CommandIndex=$calculationRows.Count; CommandHash=(Get-Sha256 $text); CommandLength=$text.Length
                        Definition='REDACTED; static review requires separately approved secured export'
                    })
                }
            }
            foreach ($permission in @($cube.CubePermissions)) {
                $cubePermissionRows.Add([pscustomobject]@{
                    Database=$dbName; Cube=$cube.Name; Permission=$permission.Name; RoleID=$permission.RoleID
                    Read=(Get-Value $permission 'Read'); Process=(Get-Value $permission 'Process'); ReadSourceData=(Get-Value $permission 'ReadSourceData')
                })
            }
        }

        $dimensionAttributeRows = New-Object Collections.Generic.List[object]
        $attributeRelationshipRows = New-Object Collections.Generic.List[object]
        $hierarchyRows = New-Object Collections.Generic.List[object]
        foreach ($dimension in @($db.Dimensions)) {
            foreach ($attribute in @($dimension.Attributes)) {
                $dimensionAttributeRows.Add([pscustomobject]@{
                    Database=$dbName; Dimension=$dimension.Name; Attribute=$attribute.Name; AttributeID=$attribute.ID
                    Usage=(Get-Value $attribute 'Usage'); EstimatedCount=(Get-Value $attribute 'EstimatedCount')
                    AttributeHierarchyEnabled=(Get-Value $attribute 'AttributeHierarchyEnabled'); AttributeHierarchyOptimizedState=(Get-Value $attribute 'AttributeHierarchyOptimizedState')
                    IsAggregatable=(Get-Value $attribute 'IsAggregatable'); KeyColumnCount=@($attribute.KeyColumns).Count
                })
                foreach ($relationship in @($attribute.AttributeRelationships)) {
                    $attributeRelationshipRows.Add([pscustomobject]@{
                        Database=$dbName; Dimension=$dimension.Name; Attribute=$attribute.Name
                        RelatedAttributeID=(Get-Value $relationship 'AttributeID'); RelationshipType=(Get-Value $relationship 'RelationshipType')
                        Cardinality=(Get-Value $relationship 'Cardinality'); OverrideBehavior=(Get-Value $relationship 'OverrideBehavior')
                    })
                }
            }
            foreach ($hierarchy in @($dimension.Hierarchies)) {
                $ordinal=0
                foreach ($level in @($hierarchy.Levels)) {
                    $ordinal++
                    $hierarchyRows.Add([pscustomobject]@{
                        Database=$dbName; Dimension=$dimension.Name; Hierarchy=$hierarchy.Name; HierarchyID=$hierarchy.ID
                        LevelOrdinal=$ordinal; Level=$level.Name; SourceAttributeID=(Get-Value $level 'SourceAttributeID')
                        HideMemberIf=(Get-Value $level 'HideMemberIf')
                    })
                }
            }
        }

        $roleRows = @($db.Roles | ForEach-Object { [pscustomobject]@{Database=$dbName; Role=$_.Name; RoleID=$_.ID; Description=(Get-Value $_ 'Description')} })
        $dataSourceRows = @($db.DataSources | ForEach-Object {
            [pscustomobject]@{
                Database=$dbName; DataSource=$_.Name; DataSourceID=$_.ID; Type=(Get-ObjectType $_)
                Timeout=(Get-Value $_ 'Timeout'); Isolation=(Get-Value $_ 'Isolation'); ImpersonationMode=(Get-Value $_.ImpersonationInfo 'ImpersonationMode')
                Account='REDACTED'; ConnectionString='REDACTED'
            }
        })

        $dsvTableRows = New-Object Collections.Generic.List[object]
        $dsvRelationshipRows = New-Object Collections.Generic.List[object]
        foreach ($dsv in @($db.DataSourceViews)) {
            $schema = Get-Value $dsv 'Schema' $null
            if ($schema) {
                foreach ($table in @($schema.Tables)) {
                    $dsvTableRows.Add([pscustomobject]@{Database=$dbName; DataSourceView=$dsv.Name; Table=$table.TableName; ColumnCount=@($table.Columns).Count})
                }
                foreach ($relation in @($schema.Relations)) {
                    $dsvRelationshipRows.Add([pscustomobject]@{
                        Database=$dbName; DataSourceView=$dsv.Name; Relationship=$relation.RelationName
                        ParentTable=$relation.ParentTable.TableName; ChildTable=$relation.ChildTable.TableName; ColumnPairCount=@($relation.ParentColumns).Count
                    })
                }
            }
        }

        Export-Rows $dbName 'partitions' $metadata @($partitionRows)
        Export-Rows $dbName 'partition_sources' $metadata @($partitionSourceRows)
        Export-Rows $dbName 'dimension_usage' $metadata @($dimensionUsageRows)
        Export-Rows $dbName 'dimension_attributes' $metadata @($dimensionAttributeRows)
        Export-Rows $dbName 'attribute_relationships' $metadata @($attributeRelationshipRows)
        Export-Rows $dbName 'user_hierarchies' $metadata @($hierarchyRows)
        Export-Rows $dbName 'aggregation_designs' $metadata @($aggregationDesignRows)
        Export-Rows $dbName 'aggregations' $metadata @($aggregationRows)
        Export-Rows $dbName 'calculations' $metadata @($calculationRows)
        Export-Rows $dbName 'roles' $metadata @($roleRows)
        Export-Rows $dbName 'cube_permissions' $metadata @($cubePermissionRows)
        Export-Rows $dbName 'data_sources_redacted' $metadata @($dataSourceRows)
        Export-Rows $dbName 'dsv_tables' $metadata @($dsvTableRows)
        Export-Rows $dbName 'dsv_relationships' $metadata @($dsvRelationshipRows)
    }
}
finally {
    if ($amoServer.Connected) { $amoServer.Disconnect() }
    $amoServer.Dispose()
}

$manifestPath = Join-Path (Join-Path $EvidenceRoot 'MANIFEST') 'multidimensional_collection_manifest.csv'
$existing = @()
if ((Test-Path -LiteralPath $manifestPath) -and -not $Force) { $existing = @(Import-Csv -LiteralPath $manifestPath) }
@($existing + @($manifest)) | Export-Csv -LiteralPath $manifestPath -NoTypeInformation -Encoding UTF8
$inventoryPath = Join-Path (Join-Path $EvidenceRoot 'MANIFEST') 'databases.csv'
$inventory = @()
if (Test-Path -LiteralPath $inventoryPath) { $inventory = @(Import-Csv -LiteralPath $inventoryPath) }
foreach ($entry in @($collectedDatabases)) {
    if (@($inventory | Where-Object { $_.Server -eq $entry.Server -and $_.Database -eq $entry.Database }).Count -eq 0) {
        $inventory += $entry
    }
}
$inventory | Export-Csv -LiteralPath $inventoryPath -NoTypeInformation -Encoding UTF8
Write-Output ("Multidimensional evidence collected: databases=" + @($manifest.Database | Select-Object -Unique).Count + "; artifacts=" + $manifest.Count)
