  





  
 


function SQL-Query{
	param([string]$Query,
	[string]$SqlServer = $DEFAULT_SQL_SERVER,
	[string]$DB = $DEFAULT_SQL_DB,
	[string]$RecordSeparator = "`t")

	$conn_options = ("Data Source=$SqlServer; Initial Catalog=$DB;" + "Integrated Security=SSPI")
	$conn = New-Object System.Data.SqlClient.SqlConnection($conn_options)
	$conn.Open()

	$sqlCmd = New-Object System.Data.SqlClient.SqlCommand
	$sqlCmd.CommandTimeout = "300"
	$sqlCmd.CommandText = $Query
	$sqlCmd.Connection = $conn

	$reader = $sqlCmd.ExecuteReader()
	if(-not $?) {
	$lineno = Get-CurrentLineNumber
	./logerror.ps1  $Output $date $lineno $title 
	}
	[array]$serverArray
	$arrayCount = 0
	while($reader.Read()){
		$serverArray += ,($reader.GetValue(0))
		$arrayCount++
	}
	$serverArray
}
   
function SQL-NONQuery{
	param([string]$Statement,
	[string]$SqlServer = $DEFAULT_SQL_SERVER,
	[string]$DB = $DEFAULT_SQL_DB )

	$conn_options = ("Data Source=$SqlServer; Initial Catalog=$DB;" + "Integrated Security=SSPI")
	$conn = New-Object System.Data.SqlClient.SqlConnection($conn_options)
	$conn.Open()

	$cmd = $conn.CreateCommand()
	$cmd.CommandText = $Statement
	$Server = $cmd.ExecuteNonQuery()
	if(-not $?) {

	$lineno = Get-CurrentLineNumber
	
	./logerror.ps1  $Output $date $lineno $title
	}
	$Server
}

function Txt-extract{
	param([string]$txtName)
	$returnArray = Get-Content $txtname
	return $returnArray
}
 
function Get-CurrentLineNumber { 
	$lineno = $MyInvocation.ScriptLineNumber 
	$lineno = $lineno -2
	$lineno
}






$ENV = $args[0]

if ($ENV -eq $null){
    $ENV = "PROD"
    }
    
switch ($ENV) 
	{
	"PA-PROD"{ 	$DBServer 		= 	"XSQLUTIL18"; 
				$ArchiveDrive	=	"E"
				$DB 			= 	"Status"; 
				$ServerQuery	= 	"SELECT server_name
										, [Type] = 
											CASE st.type_name
												WHEN 'BOS-IIS' THEN 'IIS'
												WHEN 'Web-IIS' THEN 'IIS'
												WHEN 'Citrix PVS' THEN 'PVS'
												WHEN 'Citrix XenApp' THEN 'XenApp'
												WHEN 'Opus App' THEN 'App'
												WHEN 'SQL' THEN 'SQL'
												ELSE 'Standard'
											END
										, domain
										, ip_address
										, dns_host_name
										, perfmon_path
										, perfmon_drive
										, perfmon_start_time
										, perfmon_end_time
									FROM t_server s 
										INNER JOIN t_server_properties sp ON s.server_id = sp.server_id
										INNER JOIN t_perfmon_properties pp ON s.server_id = pp.server_id
										INNER JOIN t_server_type_assoc sta ON s.server_id = sta.server_id
										INNER JOIN t_server_type st ON sta.type_id = st.type_id
									WHERE Active = '1'
									ORDER BY server_name
									"; 
    		}
	
	"PA-STAGE"{ $DBServer 		= 	"FINREP01V"; 
				$ArchiveDrive	=	"E"
				$DB 			= 	"Status"; 
				$ServerQuery	= 	"SELECT server_name
										, [Type] = 
											CASE st.type_name
												WHEN 'BOS-IIS' THEN 'IIS'
												WHEN 'Web-IIS' THEN 'IIS'
												WHEN 'Citrix PVS' THEN 'PVS'
												WHEN 'Citrix XenApp' THEN 'XenApp'
												WHEN 'Opus App' THEN 'App'
												WHEN 'SQL' THEN 'SQL'
												ELSE 'Standard'
											END
										, domain
										, ip_address
										, dns_host_name
										, perfmon_path
										, perfmon_drive
										, perfmon_start_time
										, perfmon_end_time
									FROM t_server s 
										INNER JOIN t_server_properties sp ON s.server_id = sp.server_id
										INNER JOIN t_perfmon_properties pp ON s.server_id = pp.server_id
										INNER JOIN t_server_type_assoc sta ON s.server_id = sta.server_id
										INNER JOIN t_server_type st ON sta.type_id = st.type_id
									WHERE Active = '1'
									ORDER BY server_name
									"; 
    		}
	
	"PA-IMP"{ 	$DBServer 		= 	"ISQLDEV610"; 
				$ArchiveDrive	=	"E"
				$DB 			= 	"StatusStage"; 
				$ServerQuery	= 	"SELECT server_name
										, [Type] = 
											CASE st.type_name
												WHEN 'BOS-IIS' THEN 'IIS'
												WHEN 'Web-IIS' THEN 'IIS'
												WHEN 'Citrix PVS' THEN 'PVS'
												WHEN 'Citrix XenApp' THEN 'XenApp'
												WHEN 'Opus App' THEN 'App'
												WHEN 'SQL' THEN 'SQL'
												ELSE 'Standard'
											END
										, domain
										, ip_address
										, dns_host_name
										, perfmon_path
										, perfmon_drive
										, perfmon_start_time
										, perfmon_end_time
									FROM t_server s 
										INNER JOIN t_server_properties sp ON s.server_id = sp.server_id
										INNER JOIN t_perfmon_properties pp ON s.server_id = pp.server_id
										INNER JOIN t_server_type_assoc sta ON s.server_id = sta.server_id
										INNER JOIN t_server_type st ON sta.type_id = st.type_id
									WHERE Active = '1'
									ORDER BY server_name
									"; 
    		}
	
	"PA-QA"{ 	$DBServer 		= 	"ISQLDEV610"; 
				$ArchiveDrive	=	"E"
				$DB 			= 	"StatusIMP"; 
				$ServerQuery	= 	"SELECT server_name
										, [Type] = 
											CASE st.type_name
												WHEN 'BOS-IIS' THEN 'IIS'
												WHEN 'Web-IIS' THEN 'IIS'
												WHEN 'Citrix PVS' THEN 'PVS'
												WHEN 'Citrix XenApp' THEN 'XenApp'
												WHEN 'Opus App' THEN 'App'
												WHEN 'SQL' THEN 'SQL'
												ELSE 'Standard'
											END
										, domain
										, ip_address
										, dns_host_name
										, perfmon_path
										, perfmon_drive
										, perfmon_start_time
										, perfmon_end_time
									FROM t_server s 
										INNER JOIN t_server_properties sp ON s.server_id = sp.server_id
										INNER JOIN t_perfmon_properties pp ON s.server_id = pp.server_id
										INNER JOIN t_server_type_assoc sta ON s.server_id = sta.server_id
										INNER JOIN t_server_type st ON sta.type_id = st.type_id
									WHERE Active = '1'
									ORDER BY server_name
									"; 
    		}
			
	"DEN-PROD"{ $DBServer 		= 	"SQLUTIL01"; 
				$ArchiveDrive	=	"D"
				$DB 			= 	"Status"; 
				$ServerQuery	= 	"SELECT server_name
										, [Type] = 
											CASE st.type_name
												WHEN 'BOS-IIS' THEN 'IIS'
												WHEN 'Web-IIS' THEN 'IIS'
												WHEN 'Citrix PVS' THEN 'PVS'
												WHEN 'Citrix XenApp' THEN 'XenApp'
												WHEN 'Opus App' THEN 'OpusApp'
												WHEN 'Opus Doc' THEN 'OpusDoc'
												WHEN 'SQL' THEN 'SQL'
												ELSE 'Standard'
											END
										, domain
										, ip_address
										, dns_host_name
										, perfmon_path
										, perfmon_drive
										, perfmon_start_time
										, perfmon_end_time
									FROM t_server s 
										INNER JOIN t_server_properties sp ON s.server_id = sp.server_id
										INNER JOIN t_perfmon_properties pp ON s.server_id = pp.server_id
										INNER JOIN t_server_type_assoc sta ON s.server_id = sta.server_id
										INNER JOIN t_server_type st ON sta.type_id = st.type_id
									WHERE Active = '1'
									--AND dns_host_name LIKE 'sql01.generation%'
									--AND server_name LIKE 'SQLUTIL%'
									--OR server_name LIKE 'HOpusSQL%'
									ORDER BY server_name
									";
			}
	
	"LOU-PROD"{ $DBServer 		= 	"SQLUTIL02"; 
				$ArchiveDrive	=	"D"
				$DB 			= 	"Status"; 
				$ServerQuery	= 	"SELECT server_name
										, [Type] = 
											CASE st.type_name
												WHEN 'BOS-IIS' THEN 'IIS'
												WHEN 'Web-IIS' THEN 'IIS'
												WHEN 'Citrix PVS' THEN 'PVS'
												WHEN 'Citrix XenApp' THEN 'XenApp'
												WHEN 'Opus App' THEN 'OpusApp'
												WHEN 'Opus Doc' THEN 'OpusDoc'
												WHEN 'SQL' THEN 'SQL'
												ELSE 'Standard'
											END
										, domain
										, ip_address
										, dns_host_name
										, perfmon_path
										, perfmon_drive
										, perfmon_start_time
										, perfmon_end_time
									FROM t_server s 
										INNER JOIN t_server_properties sp ON s.server_id = sp.server_id
										INNER JOIN t_perfmon_properties pp ON s.server_id = pp.server_id
										INNER JOIN t_server_type_assoc sta ON s.server_id = sta.server_id
										INNER JOIN t_server_type st ON sta.type_id = st.type_id
									WHERE Active = '1'
									--AND server_name LIKE 'SQLUTIL%'
									--OR server_name LIKE 'HOpusCap%'
									ORDER BY server_name
									";  
			}
	
	"FINALE"{ $DBServer 		= 	"FINREP01V"; 
				$ArchiveDrive	=	"C"
				$DB 			= 	"Status"; 
				$ServerQuery	= 	"SELECT server_name
										, [Type] = 
											CASE st.type_name
												WHEN 'BOS-IIS' THEN 'IIS'
												WHEN 'Web-IIS' THEN 'IIS'
												WHEN 'Citrix PVS' THEN 'PVS'
												WHEN 'Citrix XenApp' THEN 'XenApp'
												WHEN 'Opus App' THEN 'OpusApp'
												WHEN 'Opus Doc' THEN 'OpusDoc'
												WHEN 'SQL' THEN 'SQL'
												ELSE 'Standard'
											END
										, domain
										, ip_address
										, dns_host_name
										, perfmon_path
										, perfmon_drive
										, perfmon_start_time
										, perfmon_end_time
									FROM t_server s 
										INNER JOIN t_server_properties sp ON s.server_id = sp.server_id
										INNER JOIN t_perfmon_properties pp ON s.server_id = pp.server_id
										INNER JOIN t_server_type_assoc sta ON s.server_id = sta.server_id
										INNER JOIN t_server_type st ON sta.type_id = st.type_id
									WHERE Active = '1'"; 
    		}
	}

$d = (get-date).toshortdatestring()
$d = $d -replace "`/","-"

$OperationsSharename = "Operations"
$PerfmonLogsShareName = "PerfmonLogsArchive"
$title = "PerfmonCollector"

$Servers = ( Invoke-SQLCmd -query $ServerQuery -Server $DBServer -Database $DB )

$l = $Servers.length
$i = 0

$ArchiveIPQuery = "SELECT ip_address FROM t_server_properties where server_id = (select server_id from t_server where server_name = '$DBServer')"		
$ArchiveIP = ( Invoke-SQLCmd -query $ArchiveIPQuery -Server $DBServer -Database $DB | Select-Object ip_address)
$domain = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain().name

foreach ($Server in $Servers) 
{
	if ($Server -ne $null) 
	{
        
		$ServerName 			= 	$($Server.dns_host_name)	
		$ServerIPAddress		= 	$($Server.ip_address)
		$ServerType 			= 	$($Server.Type)
		$PerfmonDrive			= 	$($Server.perfmon_drive)
		
		$PerfmonLogsArchive		= 	"\\" + $DBServer + "\" + $ArchiveDrive + "$\" + $PerfmonLogsShareName
		$ArchiveDir 			= 	"\\" + $ArchiveIP.ip_address + "\" + $PerfmonLogsShareName + "\" + $ServerName + "\"
		$LogDir 				= 	"\\" + $ArchiveIP.ip_address + "\" + $OperationsSharename + "\logs"
		$Output 				= 	$LogDir + "\PerfmonCollectorLog_$d.txt"

		$PerfmonLogPath 		= 	"\\" + $ServerIPAddress + "\" + $OperationsSharename + "\support\perfmon\"
		$PerfmonLogLocalPath 	= 	$PerfmonDrive + ":\" + $OperationsSharename + "\support\perfmon\"
		$PerfmonCounterList		= 	$ArchiveDrive + ":\" + $OperationsSharename + "\Support\" + $ServerType + "Counters.txt"
		
		Write-Host "----- Begin $ServerName. -----"

		$i++
		Write-Progress -Activity "Stopping Previous SystemHealth Data Collectors..." -Status "Completed: $i of $l Server: $ServerName"
		$StrCMDstop = "C:\Windows\System32\Logman.exe stop SystemHealth -s $ServerName"
		Invoke-Expression $StrCMDstop 
		Write-Progress -Activity "Creating SystemHealth Data Collectors..." -Status "Completed: $i of $l Server: $ServerName"
		$StrCMDcreate = "C:\Windows\System32\Logman.exe create counter SystemHealth -s $ServerName -cf $PerfmonCounterList -si 60 -f csv -v mmddhhmm -o $PerfmonLogLocalPath\$ServerName.csv -b 00:01:00 -e 23:59:00 -y"
		Invoke-Expression $StrCMDcreate 
		Write-Progress -Activity "Starting SystemHealth Data Collectors..." -Status "Completed: $i of $l Server: $ServerName"
		$StrCMDstart = "C:\Windows\System32\Logman.exe start SystemHealth -s $ServerName"       
		Invoke-Expression $StrCMDstart          

            
            if (test-path $PerfmonLogPath) {
				
                If (test-path "ENV:PROGRAMFILES") {
                    $ProgramDir = $ENV:PROGRAMFILES
            		}
				elseif (test-path "ENV:PROGRAMFILES(X86)") {
                	
					$ProgramDir = get-content "env:Programfiles(x86)"
					}
                if (-not (test-path "$ProgramDir\7-Zip\7z.exe")) {throw "$ProgramDir\7-Zip\7z.exe needed"}
                    set-alias sz "$ProgramDir\7-Zip\7z.exe" 
                    foreach ($file in Get-ChildItem -path $PerfmonLogPath "*.csv" | Where-Object {!($_.psiscontainer)}) {
                        Write-Host $file
                        
						if ($file.CreationTime -lt ($(Get-Date).AddHours(-1))) {
                        
                            if (!(Test-Path -path $ArchiveDir)) {
								New-Item $ArchiveDir -type directory
                                }
                            $name = $file.name
                            $name = $name.trim()
                            write-host "Source file: $name"
                            $zipPath = "$ArchiveDir\$name.zip"
                            $FullPath = $PerfmonLogPath + $name 
 
                             sz a -tzip "$ZipPath" "$FullPath" | find "Everything is Ok" 
                             $zipResult = $?
                             write-host "Archive Success: $zipResult"
                             if ($zipResult -match "True") {
                                write-host "Archive operation successful - deleting source file: $FullPath"
                                add-content $output "Archive operation successful - deleting source file: $FullPath"
                                Remove-Item $FullPath 
                                }
							else{
                                write-host "Archive Failure - $FullPath. Local file retained"
                                add-content $output "Archive Failure - $FullPath. Log file not deleted."
                                }
                            } 
                    	}
               }
		Write-Host "----- End $ServerName. -----"
		Write-Host ""
	}
}

