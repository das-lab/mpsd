
[CmdletBinding()]
param
(
	[Switch]$SCCM,
	[switch]$TextFile,
	[string]$TextFileLocation
)

function Find-RegistryKey {

	
	[CmdletBinding()][OutputType([string])]
	param
	(
		[ValidateNotNullOrEmpty()][string]$Value,
		[ValidateNotNullOrEmpty()][string]$SID
	)
	
	$Version = Get-OfficeVersion
	switch ($Version) {
		"Office 14" { $Key = "HKEY_USERS\" + $SID + "\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Windows Messaging Subsystem\Profiles" }
		"Office 16" { $Key = "HKEY_USERS\" + $SID + "\SOFTWARE\Microsoft\Office\16.0\Outlook\Profiles" }
	}
	If ((Test-Path REGISTRY::$Key) -eq $true) {
		[string]$CachedMode = get-childitem REGISTRY::$Key -recurse -ErrorAction SilentlyContinue | where-object { $_.property -eq "00036601" }
		If ($CachedMode -ne $null) {
			[string]$CachedModeValue = (Get-ItemProperty REGISTRY::$CachedMode).'00036601'
			switch ($Version) {
				"Office 14" {
					switch ($CachedModeValue) {
						
						'128 25 0 0' { Return "Enabled" } 
						'0 16 0 0' { Return "Disabled" } 
						default { Return "Unknown" }
					}
				}
				"Office 16" {
					switch ($CachedModeValue) {
						
						'132 25 0 0' { Return "Enabled" } 
						'4 16 0 0' { Return "Disabled" } 
						default { Return "Unknown" }
					}
				}
			}
			Return $CachedModeValue
		} else {
			Return $null
		}
	} else {
		Return $null
	}
}

function Get-HKEY_USERS_List {

	
	[CmdletBinding()][OutputType([array])]
	param ()
	
	
	$HKEY_USERS = Get-ChildItem REGISTRY::HKEY_USERS | where-object { ($_.Name -like "*S-1-5-21*") -and ($_.Name -notlike "*_Classes") }
	$Users = @()
	foreach ($User in $HKEY_USERS) {
		
		$PROFILESID = Get-ChildItem REGISTRY::"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList" | Where-Object { $_.name -like "*" + $USER.PSChildName + "*" }
		$SID = $PROFILESID.PSChildName
		
		$CachedMode = Find-RegistryKey -Value "00036601" -SID $SID
		If ($CachedMode -ne $null) {
			
			$ProfileName = ((Get-ItemProperty REGISTRY::$PROFILESID).ProfileImagePath).Split("\")[2]
			
			$SystemInfo = New-Object -TypeName System.Management.Automation.PSObject
			Add-Member -InputObject $SystemInfo -MemberType NoteProperty -Name Profile -Value $ProfileName
			Add-Member -InputObject $SystemInfo -MemberType NoteProperty -Name Status -Value $CachedMode
			$Users += $SystemInfo
		}
	}
	Return $Users
}

function New-WMIClass {
	[CmdletBinding()]
	param
	(
		[ValidateNotNullOrEmpty()][string]$Class
	)
	
	$WMITest = Get-WmiObject $Class -ErrorAction SilentlyContinue
	If ($WMITest -ne "") {
		$Output = "Deleting " + $Class + " WMI class....."
		Remove-WmiObject $Class
		$WMITest = Get-WmiObject $Class -ErrorAction SilentlyContinue
		If ($WMITest -eq $null) {
			$Output += "Success"
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
	$newClass.Properties.Add("Profile", [System.Management.CimType]::String, $false)
	$newClass.Properties["Profile"].Qualifiers.Add("key", $true)
	$newClass.Properties["Profile"].Qualifiers.Add("read", $true)
	$newClass.Properties.Add("Status", [System.Management.CimType]::String, $false)
	$newClass.Properties["Status"].Qualifiers.Add("key", $true)
	$newClass.Properties["Status"].Qualifiers.Add("read", $true)
	$newClass.Put() | Out-Null
	$WMITest = Get-WmiObject $Class -ErrorAction SilentlyContinue
	If ($WMITest -eq $null) {
		$Output += "Success"
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
		[ValidateNotNullOrEmpty()][string]$Username,
		[ValidateNotNullOrEmpty()][string]$CachedModeStatus,
		[ValidateNotNullOrEmpty()][string]$Class
	)
	
	$Output = "Writing Cached Exchange information instance to" + [char]32 + $Class + [char]32 + "class....."
	$Return = Set-WmiInstance -Class $Class -Arguments @{ Profile = $Username; Status = $CachedModeStatus }
	If ($Return -like "*" + $Username + "*") {
		$Output += "Success"
	} else {
		$Output += "Failed"
	}
	Write-Output $Output
}

function Get-OfficeVersion {

	
	[CmdletBinding()][OutputType([string])]
	param ()
	
	If ((Test-Path $env:ProgramFiles"\Microsoft Office") -eq $true) {
		$File = get-childitem -path $env:ProgramFiles"\Microsoft Office" -filter ospp.vbs -recurse
	}
	If ((Test-Path ${env:ProgramFiles(x86)}"\Microsoft Office") -eq $true) {
		$File = get-childitem -path ${env:ProgramFiles(x86)}"\Microsoft Office" -filter ospp.vbs -recurse
	}
	
	$Version = (cscript.exe $File.Fullname /dstatus | where-object { $_ -like "LICENSE NAME:*" }).split(":")[1].Trim().Split(",")[0]
	Return $Version
}

function Initialize-HardwareInventory {

	
	[CmdletBinding()]
	param ()
	
	$Output = "Initiate SCCM Hardware Inventory....."
	$SMSCli = [wmiclass] "\\localhost\root\ccm:SMS_Client"
	$ErrCode = ($SMSCli.TriggerSchedule("{00000000-0000-0000-0000-000000000001}")).ReturnValue
	If ($ErrCode -eq $null) {
		$Output += "Success"
	} else {
		$Output += "Failed"
	}
	Write-Output $Output
}

Clear-Host

$Users = Get-HKEY_USERS_List
If ($SCCM.IsPresent) {
	
	New-WMIClass -Class "Cached_Exchange_Mode"
	
	foreach ($User in $Users) {
		New-WMIInstance -Username $User.Profile -CachedModeStatus $User.Status -Class "Cached_Exchange_Mode"
	}
	Initialize-HardwareInventory
}
If ($TextFile.IsPresent) {
	
	If (($TextFileLocation -ne "") -and ($TextFileLocation -ne $null)) {
		
		If ((Test-Path $TextFileLocation) -eq $true) {
			
			If ($TextFileLocation.Length - 1 -ne '\') {
				$File = $TextFileLocation + '\' + $env:COMPUTERNAME + ".log"
			} else {
				$File = $TextFileLocation + $env:COMPUTERNAME + ".log"
			}
			
			If ((Test-Path $File) -eq $true) {
				Remove-Item $File -Force
			}
			
			$Users | Out-File $File -Encoding UTF8 -Force
		} else {
			Write-Host "Text file location does not exist"
		}
	} else {
		Write-Host "No text file location was defined."
	}
}

$Users
