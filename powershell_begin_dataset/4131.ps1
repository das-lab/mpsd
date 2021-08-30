
[CmdletBinding()]
param
(
	[switch]$ActiveDirectory,
	[switch]$NetworkShare,
	[string]$NetworkSharePath,
	[switch]$SCCMBitlockerPassword,
	[switch]$SCCMReporting
)
Import-Module ActiveDirectory

Function Get-BitLockerRecoveryKeyId {
	
		
	
	[cmdletBinding()]
	Param (
			[Parameter(Mandatory = $false, ValueFromPipeLine = $false)][ValidateSet("Alltypes", "TPM", "ExternalKey", "NumericPassword", "TPMAndPin", "TPMAndStartUpdKey", "TPMAndPinAndStartUpKey", "PublicKey", "PassPhrase", "TpmCertificate", "SID")]$KeyProtectorType
	)
	
	$BitLocker = Get-WmiObject -Namespace "Root\cimv2\Security\MicrosoftVolumeEncryption" -Class "Win32_EncryptableVolume"
	switch ($KeyProtectorType) {
		("Alltypes") { $Value = "0" }
		("TPM") { $Value = "1" }
		("ExternalKey") { $Value = "2" }
		("NumericPassword") { $Value = "3" }
		("TPMAndPin") { $Value = "4" }
		("TPMAndStartUpdKey") { $Value = "5" }
		("TPMAndPinAndStartUpKey") { $Value = "6" }
		("PublicKey") { $Value = "7" }
		("PassPhrase") { $Value = "8" }
		("TpmCertificate") { $Value = "9" }
		("SID") { $Value = "10" }
		default { $Value = "0" }
	}
	$Ids = $BitLocker.GetKeyProtectors($Value).volumekeyprotectorID
	return $ids
}

function Get-ADBitlockerRecoveryKeys {

	
	[CmdletBinding()]
	param ()
	
	
	$ComputerName = $env:COMPUTERNAME
	$ADComputer = Get-ADComputer -Filter { Name -eq $ComputerName }
	
	$ADBitLockerRecoveryKeys = Get-ADObject -Filter { objectclass -eq 'msFVE-RecoveryInformation' } -SearchBase $ADComputer.DistinguishedName -Properties 'msFVE-RecoveryPassword'
	Return $ADBitLockerRecoveryKeys
}

function Get-BitlockerPassword {

	
	[CmdletBinding()][OutputType([string])]
	param
	(
		[ValidateNotNullOrEmpty()][string]$ProtectorID
	)
	
	$Password = manage-bde -protectors -get ($env:ProgramFiles).split("\")[0] -id $ProtectorID | Where-Object { $_.trim() -ne "" }
	$Password = $Password[$Password.Length - 1].Trim()
	Return $Password
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

function Invoke-ADBitlockerRecoveryPasswordCleanup {

	
	[CmdletBinding()]
	param
	(
		[ValidateNotNullOrEmpty()][string]$LocalPassword,
		[ValidateNotNullOrEmpty()]$ADPassword
	)
	
	foreach ($Password in $ADPassword) {
		If ($LocalPassword -ne $Password.'msFVE-RecoveryPassword') {
			Remove-ADObject -Identity $Password.DistinguishedName -Confirm:$false
		}
	}
}

function Invoke-EXE {

	
	[CmdletBinding()]
	param
	(
		[String]$DisplayName,
		[String]$Executable,
		[String]$Switches
	)
	
	Write-Host "Uploading"$DisplayName"....." -NoNewline
	
	If ((Test-Path $Executable) -eq $true) {
		
		$ErrCode = (Start-Process -FilePath $Executable -ArgumentList $Switches -Wait -Passthru).ExitCode
	} else {
		$ErrCode = 1
	}
	If (($ErrCode -eq 0) -or ($ErrCode -eq 3010)) {
		Write-Host "Success" -ForegroundColor Yellow
	} else {
		Write-Host "Failed with error code "$ErrCode -ForegroundColor Red
	}
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
	$newClass.Properties.Add("ADBackup", [System.Management.CimType]::Boolean, $false)
	$newClass.Properties["ADBackup"].Qualifiers.Add("key", $true)
	$newClass.Properties["ADBackup"].Qualifiers.Add("read", $true)
	$newClass.Properties.Add("RecoveryPassword", [System.Management.CimType]::string, $false)
	$newClass.Properties["RecoveryPassword"].Qualifiers.Add("key", $true)
	$newClass.Properties["RecoveryPassword"].Qualifiers.Add("read", $true)
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
		[ValidateNotNullOrEmpty()][boolean]$ADBackup,
		[ValidateNotNullOrEmpty()][string]$Class,
		[ValidateNotNullOrEmpty()][string]$RecoveryPassword
	)
	
	$Output = "Writing Bitlocker instance to" + [char]32 + $Class + [char]32 + "class....."
	$Return = Set-WmiInstance -Class $Class -Arguments @{ ADBackup = $ADBackup; RecoveryPassword = $RecoveryPassword }
	If ($Return -like "*" + $ADBackup + "*") {
		$Output += "Success"
	} else {
		$Output += "Failed"
	}
	Write-Output $Output
}

function Publish-RecoveryPasswordToActiveDirectory {

	
	[CmdletBinding()]
	param
	(
		[ValidateNotNullOrEmpty()][string]$BitlockerID
	)
	
	
	$ManageBDE = $env:windir + "\System32\manage-bde.exe"
	
	$Switches = "-protectors -adbackup" + [char]32 + ($env:ProgramFiles).split("\")[0] + [char]32 + "-id" + [char]32 + $BitlockerID
	Invoke-EXE -DisplayName "Backup Recovery Key to AD" -Executable $ManageBDE -Switches $Switches
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

[string]$BitlockerID = Get-BitLockerRecoveryKeyId -KeyProtectorType NumericPassword

[string]$BitlockerPassword = Get-BitlockerPassword -ProtectorID $BitlockerID

If ($ActiveDirectory.IsPresent) {
	
	$ADBitlockerPassword = Get-ADBitlockerRecoveryKeys
	
	If ($ADBitlockerPassword -ne $null) {
		
		If ((($ADBitlockerPassword -is [Microsoft.ActiveDirectory.Management.ADObject]) -and ($ADBitlockerPassword.'msFVE-RecoveryPassword' -ne $BitlockerPassword)) -or ($ADBitlockerPassword -isnot [Microsoft.ActiveDirectory.Management.ADObject])) {
			
			Invoke-ADBitlockerRecoveryPasswordCleanup -LocalPassword $BitlockerPassword -ADPassword $ADBitlockerPassword
			
			$ADBitlockerPassword = Get-ADBitlockerRecoveryKeys
			
			If (($ADBitlockerPassword.'msFVE-RecoveryPassword' -ne $BitlockerPassword) -or ($ADBitlockerPassword -eq $null)) {
				
				Publish-RecoveryPasswordToActiveDirectory -BitlockerID $BitlockerID
				
				$ADBitlockerPassword = $null
				$Count = 1
				
				Do {
					$ADBitlockerPassword = Get-ADBitlockerRecoveryKeys
					Start-Sleep -Seconds 1
					$Count += 1
				} while (($ADBitlockerPassword -eq $null) -or ($Count -lt 30))
			}
		}
	} else {
		Publish-RecoveryPasswordToActiveDirectory -BitlockerID $BitlockerID
		
		$ADBitlockerPassword = $null
		$Count = 1
		
		Do {
			$ADBitlockerPassword = Get-ADBitlockerRecoveryKeys
			Start-Sleep -Seconds 1
			$Count += 1
		} while (($ADBitlockerPassword -eq $null) -and ($Count -lt 30))
	}
}

If ($SCCMReporting.IsPresent) {
	New-WMIClass -Class Bitlocker_Reporting
	If ($ADBitlockerPassword.'msFVE-RecoveryPassword' -eq $BitlockerPassword) {
		If ($SCCMBitlockerPassword.IsPresent) {
			New-WMIInstance -ADBackup $true -Class Bitlocker_Reporting -RecoveryPassword $BitlockerPassword
		} else {
			New-WMIInstance -ADBackup $true -Class Bitlocker_Reporting -RecoveryPassword " "
		}
	} else {
		If ($SCCMBitlockerPassword.IsPresent) {
			New-WMIInstance -ADBackup $false -Class Bitlocker_Reporting -RecoveryPassword $BitlockerPassword
		} else {
			New-WMIInstance -ADBackup $false -Class Bitlocker_Reporting -RecoveryPassword " "
		}
	}
	
	Initialize-HardwareInventory
} else {
	Remove-WMIClass -Class Bitlocker_Reporting
}

If ($NetworkShare.IsPresent) {
	
	If ((Test-Path $NetworkSharePath) -eq $true) {
		
		If ($NetworkSharePath[$NetworkSharePath.Length - 1] -ne "\") {
			$File = $NetworkSharePath + "\" + $env:COMPUTERNAME + ".txt"
		} else {
			$File = $NetworkSharePath + $env:COMPUTERNAME + ".txt"
		}
		
		If ((Test-Path $File) -eq $true) {
			$Output = "Deleting $env:COMPUTERNAME.txt file....."
			Remove-Item -Path $File -Force
			If ((Test-Path $File) -eq $false) {
				$Output += "Success"
			} else {
				$Output += "Failed"
			}
			Write-Output $Output
		}
		
		If ((Test-Path $File) -eq $false) {
			$Output = "Creating $env:COMPUTERNAME.txt file....."
			New-Item -Path $File -ItemType File -Force | Out-Null
			If ((Test-Path $File) -eq $true) {
				Add-Content -Path $File -Value $BitlockerPassword
				$Output += "Success"
			} else {
				$Output += "Failed"
			}
			Write-Output $Output
		}
	}
}

Write-Output " "
$Output = "                  Bitlocker ID: " + $BitlockerID
Write-Output $Output
$Output = "   Bitlocker Recovery Password: " + $BitlockerPassword
Write-Output $Output
$Output = "AD Bitlocker Recovery Password: " + $ADBitlockerPassword.'msFVE-RecoveryPassword' + [char]13
Write-Output $Output
