
[CmdletBinding()]
param
(
	[switch]$SCCM
)
function Enable-Reboot {

	
	[CmdletBinding()]
	param ()
	
	If ($SCCM.IsPresent) {
		$TaskSequence = New-Object -ComObject Microsoft.SMS.TSEnvironment
		
		$TaskSequence.Value('SMSTSRetryRequested') = $true
		
		$TaskSequence.Value('SMSTSRebootRequested') = $true
	} else {
		Restart-Computer -Force
	}
}

Import-Module PowerShellGet
Import-Module -Name PSWindowsUpdate -ErrorAction SilentlyContinue

$InstalledVersion = (Get-InstalledModule -Name PSWindowsUpdate).Version.ToString()

$PSGalleryVersion = (Find-Module -Name PSWindowsUpdate).Version.ToString()

If ($InstalledVersion -ne $PSGalleryVersion) {
	Install-Module -Name PSWindowsUpdate -Force
}

$Updates = Get-WindowsUpdate
If ($Updates -ne $null) {
	$NewUpdates = $true
	Do {
		
		Add-LocalGroupMember -Group Administrators -Member ($env:USERDOMAIN + '\' + $env:USERNAME)
		
		Install-WindowsUpdate -AcceptAll -IgnoreReboot -Confirm:$false
		
		Remove-LocalGroupMember -Group Administrators -Member ($env:USERDOMAIN + '\' + $env:USERNAME)
		
		If ((Get-ChildItem "REGISTRY::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending" -ErrorAction SilentlyContinue) -ne $null) {
			Enable-Reboot
			$NewUpdates = $false
		
		} elseif ((Get-Item -Path "REGISTRY::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired" -ErrorAction SilentlyContinue) -ne $null) {
			Enable-Reboot
			$NewUpdates = $false
		
		} elseif ((Get-ItemProperty -Path "REGISTRY::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager" -Name PendingFileRenameOperations -ErrorAction SilentlyContinue) -ne $null) {
			Enable-Reboot
			$NewUpdates = $false
		
		} elseif ((([wmiclass]"\\.\root\ccm\clientsdk:CCM_ClientUtilities").DetermineIfRebootPending().RebootPending) -eq $true) {
			Enable-Reboot
			$NewUpdates = $false
		}
		
		If ($NewUpdates -eq $true) {
			
			$Updates = Get-WindowsUpdate
			
			If ($Updates -eq $null) {
				$NewUpdates -eq $false
			}
		}
	} While ($NewUpdates -eq $true)
} else {
	Exit 0
}
