
[CmdletBinding()]
param
(
	[switch]
	$OutputFile,
	[string]
	$TextFileLocation = '\\drfs1\DesktopApplications\ProductionApplications\Waller\MappedDrivesReport\Reports',
	[string]
	$UNCPathExclusionsFile = "\\drfs1\DesktopApplications\ProductionApplications\Waller\MappedDrivesReport\UNCPathExclusions.txt",
	[switch]
	$SCCMReporting
)

function Get-CurrentDate {

	
	[CmdletBinding()][OutputType([string])]
	param ()

	$CurrentDate = Get-Date
	$CurrentDate = $CurrentDate.ToShortDateString()
	$CurrentDate = $CurrentDate -replace "/", "-"
	If ($CurrentDate[2] -ne "-") {
		$CurrentDate = $CurrentDate.Insert(0, "0")
	}
	If ($CurrentDate[5] -ne "-") {
		$CurrentDate = $CurrentDate.Insert(3, "0")
	}
	Return $CurrentDate
}

function Get-MappedDrives {

	
	[CmdletBinding()][OutputType([array])]
	
	
	$UNCExclusions = Get-Content $UNCPathExclusionsFile -Force
	
	[array]$UserSIDS = (Get-ChildItem -Path REGISTRY::HKEY_Users | Where-Object { ($_ -notlike "*Classes*") -and ($_ -like "*S-1-5-21*") }).Name
	
	[array]$ProfileList = (Get-ChildItem -Path REGISTRY::"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList" | Where-Object { $_ -like "*S-1-5-21*" }).Name
	$UserMappedDrives = @()
	
	foreach ($UserSID in $UserSIDS) {
		
		[string]$UserSID = $UserSID.Split("\")[1].Trim()
		
		[string]$UserPROFILE = $ProfileList | Where-Object { $_ -like "*" + $UserSID + "*" }
		
		$Username = ((Get-ItemProperty -Path REGISTRY::$UserPROFILE).ProfileImagePath).Split("\")[2].trim()
		
		[string]$MappedDrives = "HKEY_USERS\" + $UserSID + "\Network"
		
		[array]$MappedDrives = (Get-ChildItem REGISTRY::$MappedDrives | Select-Object name).name
		foreach ($MappedDrive in $MappedDrives) {
			$DriveLetter = (Get-ItemProperty -Path REGISTRY::$MappedDrive | select PSChildName).PSChildName
			$DrivePath = (Get-ItemProperty -Path REGISTRY::$MappedDrive | select RemotePath).RemotePath
			If ($DrivePath -notin $UNCExclusions) {
				$Drives = New-Object System.Management.Automation.PSObject
				$Drives | Add-Member -MemberType NoteProperty -Name ComputerName -Value $env:COMPUTERNAME
				$Drives | Add-Member -MemberType NoteProperty -Name Username -Value $Username
				$Drives | Add-Member -MemberType NoteProperty -Name DriveLetter -Value $DriveLetter
				$Drives | Add-Member -MemberType NoteProperty -Name DrivePath -Value $DrivePath
				$UserMappedDrives += $Drives
			}
		}
	}
	Return $UserMappedDrives
}

function Get-RelativePath {

	
	[CmdletBinding()][OutputType([string])]
	param ()
	
	$Path = (split-path $SCRIPT:MyInvocation.MyCommand.Path -parent) + "\"
	Return $Path
}

function Invoke-SCCMHardwareInventory {

	
	[CmdletBinding()]
	param ()
	
	$ComputerName = $env:COMPUTERNAME
	$SMSCli = [wmiclass] "\\$ComputerName\root\ccm:SMS_Client"
	$SMSCli.TriggerSchedule("{00000000-0000-0000-0000-000000000001}") | Out-Null
}

function New-WMIClass {
	[CmdletBinding()]
	param
	(
		[ValidateNotNullOrEmpty()][string]
		$Class
	)
	
	$WMITest = Get-WmiObject $Class -ErrorAction SilentlyContinue
	If ($WMITest -ne $null) {
		$Output = "Deleting " + $WMITest.__CLASS[0] + " WMI class....."
		Remove-WmiObject $Class
		$WMITest = Get-WmiObject $Class -ErrorAction SilentlyContinue
		If ($WMITest -eq $null) {
			$Output += "success"
		} else {
			$Output += "Failed"
			Exit 1
		}
		Write-Output $Output
	}
	$Output = "Creating " + $Class + " WMI class....."
	$newClass = New-Object System.Management.ManagementClass("root\cimv2", [String]::Empty, $null);
	$newClass["__CLASS"] = $Class;
	$newClass.Qualifiers.Add("Static", $true)
	$newClass.Properties.Add("ComputerName", [System.Management.CimType]::String, $false)
	$newClass.Properties["ComputerName"].Qualifiers.Add("key", $true)
	$newClass.Properties["ComputerName"].Qualifiers.Add("read", $true)
	$newClass.Properties.Add("DriveLetter", [System.Management.CimType]::String, $false)
	$newClass.Properties["DriveLetter"].Qualifiers.Add("key", $false)
	$newClass.Properties["DriveLetter"].Qualifiers.Add("read", $true)
	$newClass.Properties.Add("DrivePath", [System.Management.CimType]::String, $false)
	$newClass.Properties["DrivePath"].Qualifiers.Add("key", $false)
	$newClass.Properties["DrivePath"].Qualifiers.Add("read", $true)
	$newClass.Properties.Add("Username", [System.Management.CimType]::String, $false)
	$newClass.Properties["Username"].Qualifiers.Add("key", $false)
	$newClass.Properties["Username"].Qualifiers.Add("read", $true)
	$newClass.Put() | Out-Null
	$WMITest = Get-WmiObject $Class -ErrorAction SilentlyContinue
	If ($WMITest -eq $null) {
		$Output += "success"
	} else {
		$Output += "Failed"
		Exit 1
	}
	Write-Output $Output
}

function New-WMIInstance {

	
	[CmdletBinding()]
	param
	(
		[ValidateNotNullOrEmpty()][array]
		$MappedDrives,
		[string]
		$Class
	)
	
	foreach ($MappedDrive in $MappedDrives) {
		Set-WmiInstance -Class $Class -Arguments @{ ComputerName = $MappedDrive.ComputerName; DriveLetter = $MappedDrive.DriveLetter; DrivePath = $MappedDrive.DrivePath; Username = $MappedDrive.Username } | Out-Null
	}
}

function Start-ConfigurationManagerClientScan {


	[CmdletBinding()]
	param
	(
		[ValidateSet('00000000-0000-0000-0000-000000000121', '00000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000010', '00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000021', '00000000-0000-0000-0000-000000000022', '00000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000031', '00000000-0000-0000-0000-000000000108', '00000000-0000-0000-0000-000000000113', '00000000-0000-0000-0000-000000000111', '00000000-0000-0000-0000-000000000026', '00000000-0000-0000-0000-000000000027', '00000000-0000-0000-0000-000000000032')]$ScheduleID
	)

	$WMIPath = "\\" + $env:COMPUTERNAME + "\root\ccm:SMS_Client"
	$SMSwmi = [wmiclass]$WMIPath
	$Action = [char]123 + $ScheduleID + [char]125
	[Void]$SMSwmi.TriggerSchedule($Action)
}

cls

$UserMappedDrives = Get-MappedDrives

If ($OutputFile.IsPresent) {
	If (($TextFileLocation -ne $null) -and ($TextFileLocation -ne "")) {
		
		If ($TextFileLocation[$TextFileLocation.Length - 1] -ne "\") {
			$TextFileLocation += "\"
		}
		
		[string]$OutputFile = [string]$TextFileLocation + $env:COMPUTERNAME + ".txt"
	} else {
		
		$RelativePath = Get-RelativePath
		$OutputFile = $RelativePath + $env:COMPUTERNAME + ".txt"
	}
	If ((Test-Path $OutputFile) -eq $true) {
		Remove-Item $OutputFile -Force
	}
	If (($UserMappedDrives -ne $null) -and ($UserMappedDrives -ne "")) {
		$UserMappedDrives | Format-Table -AutoSize | Out-File $OutputFile -Width 255
	}
}
If ($SCCMReporting.IsPresent) {
	
	New-WMIClass -Class "Mapped_Drives"
	
	If ($UserMappedDrives -ne $null) {
		New-WMIInstance -MappedDrives $UserMappedDrives -Class "Mapped_Drives"
	}
	
	Invoke-SCCMHardwareInventory
}

$UserMappedDrives | Format-Table
