






[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMO') | out-null



function getwmiinfo ($svr) {
	
	gwmi -query "select * from
		 Win32_ComputerSystem" -computername $svr | select Name,
		 Model, Manufacturer, Description, DNSHostName,
		 Domain, DomainRole, PartOfDomain, NumberOfProcessors,
		 SystemType, TotalPhysicalMemory, UserName, Workgroup | export-csv -path .\$svr\BOX_ComputerSystem.csv -noType

	
	gwmi -query "select * from
		 Win32_OperatingSystem" -computername $svr | select Name,
		 Version, FreePhysicalMemory, OSLanguage, OSProductSuite,
		 OSType, ServicePackMajorVersion, ServicePackMinorVersion | export-csv -path .\$svr\BOX_OperatingSystem.csv -noType

	
	gwmi -query "select * from
		 Win32_PhysicalMemory" -computername $svr | select Name, Capacity, DeviceLocator,
		 Tag | export-csv -path .\$svr\BOX_PhysicalMemory.csv -noType

	
	gwmi -query "select * from Win32_LogicalDisk
		 where DriveType=3" -computername $svr | select Name, FreeSpace,
		 Size | export-csv -path .\$svr\BOX_LogicalDisk.csv -noType

}

function getsqlinfo {
	param (
		[string]$svr,
		[string]$inst
		)
	
	
	$cn = new-object system.data.SqlClient.SqlConnection("Data Source=$inst;Integrated Security=SSPI;Initial Catalog=master");

	
	$s = new-object ('Microsoft.SqlServer.Management.Smo.Server') $inst

	
	$nm = $inst.Split("\")
	if ($nm.Length -eq 1) {
		$instnm = "MSSQLSERVER"
	} else {
		$instnm = $nm[1]
	}

	
	$outnm = ".\" + $svr + "\" + $instnm + "_GEN_Information.csv"
	$s.Information | export-csv -path $outnm -noType
	
	
	$ds = new-object "System.Data.DataSet" "dsConfigData"

	
	$s.Configuration.ShowAdvancedOptions.ConfigValue = 1
	$s.Configuration.Alter()

	
	$q = "exec sp_configure;
"
	$q = $q + "exec sp_who;
"
	$q = $q + "exec sp_lock;
"
	$da = new-object "System.Data.SqlClient.SqlDataAdapter" ($q, $cn)
	$da.Fill($ds)

	
	$dtConfig = new-object "System.Data.DataTable" "dtConfigData"
	$dtWho = new-object "System.Data.DataTable" "dtWhoData"
	$dtLock = new-object "System.Data.DataTable" "dtLockData"
	$dtConfig = $ds.Tables[0]
	$dtWho = $ds.Tables[1]
	$dtLock = $ds.Tables[2]
	$outnm = ".\" + $svr + "\" + $instnm + "_GEN_Configure.csv"
	$dtConfig | select name, minimum, maximum, config_value, run_value | export-csv -path $outnm -noType
	$outnm = ".\" + $svr + "\" + $instnm + "_GEN_Who.csv"
	$dtWho | select spid, ecid, status, loginame, hostname, blk, dbname, cmd, request_id | export-csv -path $outnm -noType
	$outnm = ".\" + $svr + "\" + $instnm + "_GEN_Lock.csv"
	$dtLock | select spid, dbid, ObjId, IndId, Type,Resource, Mode, Status | export-csv -path $outnm -noType

	
	$s.Configuration.ShowAdvancedOptions.ConfigValue = 0
	$s.Configuration.Alter()

	
	$outnm = ".\" + $svr + "\" + $instnm + "_GEN_Logins.csv"
	$s.Logins | select Name, DefaultDatabase | export-csv -path $outnm -noType

	
	$outnm = ".\" + $svr + "\" + $instnm + "_GEN_Databases.csv"
	$dbs = $s.Databases
	$dbs | select Name, Collation, CompatibilityLevel, AutoShrink, RecoveryModel, Size, SpaceAvailable | export-csv -path $outnm -noType
	foreach ($db in $dbs) {
		
		$dbname = $db.Name
		if ($db.IsSystemObject) {
			$dbtype = "_SDB"
		} else {
			$dbtype = "_UDB"
		}
		$users = $db.Users
		$outnm = ".\" + $svr + "\" + $instnm + $dbtype + "_" + $dbname + "_Users.csv"
		$users | select $dbname, Name, Login, LoginType, UserType, CreateDate | export-csv -path $outnm -noType
		$fgs = $db.FileGroups
		foreach ($fg in $fgs) {
			$files = $fg.Files
			$outnm = ".\" + $svr + "\" + $instnm + $dbtype + "_" + $dbname + "_DataFiles.csv"
			$files | select $db.Name, Name, FileName, Size, UsedSpace | export-csv -path $outnm -noType
			}
		$logs = $db.LogFiles
		$outnm = ".\" + $svr + "\" + $instnm + $dbtype + "_" + $dbname + "_LogFiles.csv"
		$logs | select $db.Name, Name, FileName, Size, UsedSpace | export-csv -path $outnm -noType
		}
	
	
	$outnm = ".\" + $svr + "\" + $instnm + "_ERL_ErrorLog.csv"
	$s.ReadErrorLog() | export-csv -path $outnm -noType
	$outnm = ".\" + $svr + "\" + $instnm + "_ERL_ErrorLog_1.csv"
	$s.ReadErrorLog(1) | export-csv -path $outnm -noType
	$outnm = ".\" + $svr + "\" + $instnm + "_ERL_ErrorLog_2.csv"
	$s.ReadErrorLog(2) | export-csv -path $outnm -noType
	$outnm = ".\" + $svr + "\" + $instnm + "_ERL_ErrorLog_3.csv"
	$s.ReadErrorLog(3) | export-csv -path $outnm -noType
	$outnm = ".\" + $svr + "\" + $instnm + "_ERL_ErrorLog_4.csv"
	$s.ReadErrorLog(4) | export-csv -path $outnm -noType
	$outnm = ".\" + $svr + "\" + $instnm + "_ERL_ErrorLog_5.csv"
	$s.ReadErrorLog(5) | export-csv -path $outnm -noType
	$outnm = ".\" + $svr + "\" + $instnm + "_ERL_ErrorLog_6.csv"
	$s.ReadErrorLog(6) | export-csv -path $outnm -noType
}


$servers = get-content 'servers.txt'

foreach ($prcs in $servers) {
	
	$srvc = $prcs.Split(",")
	$server = $srvc[0]
	$instance = $srvc[1]
	
	
	$results = gwmi -query "select StatusCode from Win32_PingStatus where Address = '$server'" 
	$responds = $false	
	foreach ($result in $results) {
		
		if ($result.statuscode -eq 0) {
			$responds = $true
			break
		}
	}

	if ($responds) {
		
		if (!(Test-Path -path .\$server)) {
			New-Item .\$server\ -type directory
		}
		
		
		getwmiinfo $server
		getsqlinfo $server $instance
	} else {
		
		Write-Output "$server does not respond"
	}
}
