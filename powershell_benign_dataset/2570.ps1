param( 
	$SqlServerOne = 'YourDatabaseServer',
	$FirstDatabase = 'FirstDatabaseToCompare', 
	$SqlServerTwo = 'YourDatabaseServer',
	$SecondDatabase = 'SecondDatabaseToCompare',
	[String[]] $DatabaseList,
	$FilePrefix = 'Log',
	[switch]$Log,
	[switch]$Column
	)

$File = $FilePrefix + '{0}-{1}.csv'

$ScriptName = [system.io.path]::GetFilenameWithoutExtension($MyInvocation.InvocationName)


$TableDifferences = @()
$SprocDifferences = @()
$ColumnDifferences = @()


$TableQuery = "
	SELECT name AS TableName
	FROM sys.objects
	WHERE type = 'U'
	AND is_ms_shipped = '0'
	ORDER BY 1"

$SprocQuery = "
	SELECT SPECIFIC_NAME AS SprocName
		, (SELECT CONVERT(NVARCHAR(42),HashBytes('SHA1', ROUTINE_DEFINITION),2)) AS SprocHASH
	FROM INFORMATION_SCHEMA.ROUTINES
	WHERE ROUTINE_TYPE = 'PROCEDURE' 
		AND ROUTINE_NAME NOT LIKE 'dt_%' 
		AND ROUTINE_NAME NOT LIKE '%diagram%' 
		AND ROUTINE_NAME NOT LIKE 'sp_MS%'
	"
	
function write-log([string]$info)
{
    if($loginitialized -eq $false)
	{
        $FileHeader > $logfile            
        $script:loginitialized = $True            
    }            
    $info >> $logfile            
}

function Run-Query()
{
	param (
	$SqlQuery,
	$SqlServer,
	$SqlCatalog, 
	$SqlUser,
	$SqlPass
	)
	
	$SqlConnection = New-Object System.Data.SqlClient.SqlConnection("Data Source=$SqlServer;Integrated Security=SSPI;Initial Catalog=$SqlCatalog;");
	
	$SqlCmd = New-Object System.Data.SqlClient.SqlCommand
	$SqlCmd.CommandText = $SqlQuery
	$SqlCmd.Connection = $SqlConnection
	
	$SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
	$SqlAdapter.SelectCommand = $SqlCmd
	
	$DataSet = New-Object System.Data.DataSet
	$a = $SqlAdapter.Fill($DataSet)
	
	$SqlConnection.Close()
	
	$DataSet.Tables | Select-Object -ExpandProperty Rows
}


            
$script:logfile = "E:\Dexma\Logs\DMartAudit-$SqlServerOne_$FirstDatabase-$(get-date -format MMddyy).log"
$script:Seperator = @"

$("-" * 25)

"@            
$script:loginitialized = $false            
$script:FileHeader = 
@"

Server, SourceDatabase, ComparedDatabase, DifferentDatabase, Table, Column, Type, Length
"@


Write-Log


foreach ($SecondDatabase in $DatabaseList)
{


$TablesDBOne = Run-Query -SqlQuery $TableQuery -SqlServer $SqlServerOne -SqlCatalog $FirstDatabase -SqlUser $SqlUsernameOne -SqlPass $SqlPasswordOne | Select-Object -Property TableName
$TablesDBTwo = Run-Query -SqlQuery $TableQuery -SqlServer $SqlServerTwo -SqlCatalog $SecondDatabase -SqlUser $SqlUsernameTwo -SqlPass $SqlPasswordTwo | Select-Object -Property TableName


$SprocsDBOne = Run-Query -SqlQuery $SprocQuery -SqlServer $SqlServerOne -SqlCatalog $FirstDatabase -SqlUser $SqlUsernameOne -SqlPass $SqlPasswordOne | Select-Object -Property SprocName, SprocHASH
$SprocsDBTwo = Run-Query -SqlQuery $SprocQuery -SqlServer $SqlServerTwo -SqlCatalog $SecondDatabase -SqlUser $SqlUsernameOne -SqlPass $SqlPasswordOne | Select-Object -Property SprocName, SprocHASH


$Server = @{Name='Server';Expression={if ($_.SideIndicator -eq '<='){'{0}' -f $SqlServerOne} else {'{0}' -f $SqlServerTwo}}}
$Database = @{Name='Database';Expression={if ($_.SideIndicator -eq '<='){'{0}' -f $FirstDatabase} else {'{0}' -f $SecondDatabase}}}

$TableDifference = Compare-Object $TablesDBOne $TablesDBTwo -SyncWindow (($TablesDBOne.count + $TablesDBTwo.count)/2) -Property TableName | select TableName, $Server, $Database
$SprocDifference = Compare-Object $SprocsDBOne $SprocsDBTwo -SyncWindow (($SprocsDBOne.count + $SprocsDBTwo.count)/2) -Property SprocName, SprocHASH | select SprocName, SprocHASH, $Server, $Database

if ($log)
{
	if ($TableDifference)
	{
		foreach ( $Row in $TableDifference )
			{
				write-log "$($Row.Server), $FirstDatabase, $SecondDatabase, $($Row.Database), $($Row.TableName)"
				
				$TableDiff = New-Object -TypeName PSObject
					Add-Member -InputObject $TableDiff -type NoteProperty -Name "SQLServerExists" 	-value $SqlServerOne
					Add-Member -InputObject $TableDiff -type NoteProperty -Name "SQLServerMissing" 	-value $SqlServerTwo
					Add-Member -InputObject $TableDiff -type NoteProperty -Name "Database" 			-value $($Row.Database)
					Add-Member -InputObject $TableDiff -type NoteProperty -Name "Schema"			-Value $($Row.Schema)
					Add-Member -InputObject $TableDiff -type NoteProperty -Name "TableName" 		-value $($Row.TableName)
				$TableDifferences += $TableDiff
			}
	}
	if ($SprocDifference)
	{
		foreach ( $Diff in $SprocDifference | Sort-Object SprocName, SprocHash, Server )
			{
				
				write-log "$($Diff.Server), $($Diff.Database), $($Diff.SprocName), $($Diff.SprocHASH)"
				$SprocDiff = New-Object -TypeName Object
					Add-Member -inputobject $SprocDiff -type NoteProperty -name "DifferingServer" -value $($Diff.Server)
					Add-Member -inputobject $SprocDiff -type NoteProperty -name "DifferingDatabase" -value $($Diff.Database)
					Add-Member -inputobject $SprocDiff -type NoteProperty -name "DifferingSprocName" -value $($Diff.SprocName)
					Add-Member -inputobject $SprocDiff -type NoteProperty -name "DifferingSprocHASH" -value $($Diff.SprocHASH)
				$SprocDifferences += $SprocDiff
			}
	}
}





$SprocDiff | Sort-Object -Property SprocName, SprocHASH | Format-Table -AutoSize | Out-Host

if ($Column)
{
	
	$SameTables = Compare-Object $TablesDBOne $TablesDBTwo -SyncWindow (($TablesDBOne.count + $TablesDBTwo.count)/2) -Property TableName -IncludeEqual -ExcludeDifferent 
	
	$ColumnQuery = @"
select sysobjects.name as TableName
	, syscolumns.name as ColumnName 
	, systypes.name as Type
	, systypes.Length
	, systypes.XUserType
from sysobjects, syscolumns, systypes
where sysobjects.xtype like 'U' and --specify only user tables
	sysobjects.name not like 'dtproperties' and --specify only user tables
	syscolumns.xusertype= systypes.xusertype --get data type info
	and sysobjects.id=syscolumns.id 
	and sysobjects.name = '{0}'
order by sysobjects.name, syscolumns.name, syscolumns.type
"@
	
	foreach ($Table in $SameTables)
	{
		$ColumnsDBOne = Run-Query -SqlQuery ($ColumnQuery -f $table.tablename)  -SqlServer $SqlServerOne -SqlCatalog $FirstDatabase -SqlUser $SqlUsernameOne -SqlPass $SqlPasswordOne | Select-Object -Property TableName, ColumnName, Type, Length, XUserType

		$ColumnsDBTwo = Run-Query -SqlQuery ($ColumnQuery -f $table.tablename) -SqlServer $SqlServerTwo -SqlCatalog $SecondDatabase -SqlUser $SqlUsernameTwo -SqlPass $SqlPasswordTwo | Select-Object -Property TableName, ColumnName, Type, Length, XUserType
		
		$ColumnDifference = Compare-Object $ColumnsDBOne $ColumnsDBTwo -SyncWindow (($ColumnsDBOne.count + $ColumnsDBTwo.count)/2) -Property TableName, ColumnName, Type, Length, XUserType, Name | Select-Object TableName, ColumnName, Type, Length, XUserType, $Server, $Database
		
		if ($log -and $ColumnDifference )
		{
			foreach ( $Row in $ColumnDifference )
			{
				write-log "$($Row.Server), $FirstDatabase, $SecondDatabase, $($Row.Database), $($Row.TableName), $($Row.ColumnName), $($Row.Type), $($Row.length)"
				
				$ColumnDiff = New-Object -TypeName PSObject
					
					
					Add-Member -InputObject $ColumnDiff -type NoteProperty -Name "Server" 		-Value $SqlServerTwo 
					Add-Member -InputObject $ColumnDiff -type NoteProperty -Name "Database" 	-Value $($Row.Database)
					Add-Member -InputObject $ColumnDiff -type NoteProperty -Name "TableName" 	-Value $($Row.TableName)
					Add-Member -InputObject $ColumnDiff -type NoteProperty -Name "Schema"		-Value $($Row.Schema)
					Add-Member -InputObject $ColumnDiff -type NoteProperty -Name "ColumnName" 	-Value $($Row.ColumnName)
					Add-Member -InputObject $ColumnDiff -type NoteProperty -Name "Type" 		-Value $($Row.Type)
					Add-Member -InputObject $ColumnDiff -type NoteProperty -Name "Length" 		-Value $($Row.length)
				$ColumnDifferences += $ColumnDiff
			}
		}
		
		
		
	}
}
}
$DBSprocs | Sort-Object -Property DifferingSprocName, DifferingSprocHASH, DifferingServer, DifferingDatabase | Format-Table -AutoSize | Out-Host
Write-Log($DBSprocs | Sort-Object -Property DifferingSprocName, DifferingSprocHASH, DifferingServer, DifferingDatabase | Format-Table -AutoSize)

$TableDifferences | Sort-Object -Property SQLServerTwo, TableName, Database | Export-Csv -Path e:\dexma\logs\TableDiff.$ScriptName.csv -notypeinformation
$SprocDifferences | Sort-Object -Property SQLServerMissing, SprocHASH, SprocName  | Export-Csv -Path e:\dexma\logs\SprocDiff.$ScriptName.csv -notypeinformation
$ColumnDifferences | Sort-Object -Property Server, ColumnName, TableName | Export-Csv -Path e:\dexma\logs\ColDiff.$ScriptName.csv -notypeinformation

