
param
(
	[switch]$SCCM,
	[switch]$NetworkShare,
	[string]$NetworkSharePath,
	[switch]$SCCMImport
)
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

function New-WMIClass {

	
	[CmdletBinding()]
	param
	(
		[ValidateNotNullOrEmpty()][string]$Class
	)
	
	$WMITest = Get-WmiObject $Class -ErrorAction SilentlyContinue
	If (($WMITest -ne "") -and ($WMITest -ne $null)) {
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
	$newClass = New-Object System.Management.ManagementClass("root\cimv2", [string]::Empty, $null);
	$newClass["__CLASS"] = $Class;
	$newClass.Qualifiers.Add("Static", $true)
	$newClass.Properties.Add("Error51", [System.Management.CimType]::string, $false)
	$newClass.Properties["Error51"].Qualifiers.Add("key", $true)
	$newClass.Properties["Error51"].Qualifiers.Add("read", $true)
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
		[ValidateNotNullOrEmpty()][string]$Error51,
		[ValidateNotNullOrEmpty()][string]$Class
	)
	
	$Output = "Writing Error 51 information instance to" + [char]32 + $Class + [char]32 + "class....."
	$Return = Set-WmiInstance -Class $Class -Arguments @{ Error51 = $Error51 }
	If ($Return -like "*" + $Error51 + "*") {
		$Output += "Success"
	} else {
		$Output += "Failed"
	}
	Write-Output $Output
}

function Remove-WMIClass {

	
	[CmdletBinding()]
	param
	(
		[ValidateNotNullOrEmpty()][string]$Class
	)
	
	$WMITest = Get-WmiObject $Class -ErrorAction SilentlyContinue
	If (($WMITest -ne "") -and ($WMITest -ne $null)) {
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
}

Clear-Host

[int]$Count = (Get-WinEvent -FilterHashtable @{ logname = 'system'; ID = 51 } -ErrorAction SilentlyContinue).Count
If ($SCCMImport.IsPresent) {
	
	New-WMIClass -Class DriveReporting
	
	New-WMIInstance -Class DriveReporting -Error51 5
} else {
	If ($Count -gt 0) {
		$Output = "Event 51 disk error has occurred $Count times."
		Write-Output $Output
		
		If ($SCCM.IsPresent) {
			
			New-WMIClass -Class DriveReporting
			
			New-WMIInstance -Class DriveReporting -Error51 $Count
			
			Initialize-HardwareInventory
		}
		
		If ($NetworkShare.IsPresent) {
			
			If ($NetworkSharePath[$NetworkSharePath.Length - 1] -ne "\") {
				$NetworkSharePath += "\"
			}
			
			$File = $NetworkSharePath + $env:COMPUTERNAME + ".log"
			
			If ((Test-Path $File) -eq $true) {
				$Output = "Deleting " + $env:COMPUTERNAME + ".log....."
				Remove-Item -Path $File -Force | Out-Null
				If ((Test-Path $File) -eq $false) {
					$Output += "Success"
				} else {
					$Output += "Failed"
				}
				Write-Output $Output
			}
			
			$Output = "Creating " + $env:COMPUTERNAME + ".log....."
			New-Item -Path $File -ItemType File -Force | Out-Null
			Add-Content -Path $File -Value "Event 51 Count: $Count" -Force
			If ((Test-Path $File) -eq $true) {
				$Output += "Success"
			} else {
				$Output += "Failed"
			}
			Write-Output $Output
		}
	} else {
		$Output = "No event 51 disk errors detected."
		Write-Output $Output
		
		If ($SCCM.IsPresent) {
			Remove-WMIClass -Class DriveReporting
		}
		
		If ($NetworkShare.IsPresent) {
			If ($NetworkSharePath[$NetworkSharePath.Length - 1] -ne "\") {
				$NetworkSharePath += "\"
			}
			$File = $NetworkSharePath + $env:COMPUTERNAME + ".log"
			If ((Test-Path $File) -eq $true) {
				$Output = "Deleting " + $env:COMPUTERNAME + ".log....."
				Remove-Item -Path $File -Force | Out-Null
				If ((Test-Path $File) -eq $false) {
					$Output += "Success"
				} else {
					$Output += "Failed"
				}
				Write-Output $Output
			}
		}
	}
}
