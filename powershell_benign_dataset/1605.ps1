














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