
[CmdletBinding()]
param ()

function Enable-Reboot {

	
	[CmdletBinding()]
	param ()
	
	$TaskSequence = New-Object -ComObject Microsoft.SMS.TSEnvironment
	
	$TaskSequence.Value('SMSTSRebootRequested') = $true
	
	
}


If ((Get-ChildItem "REGISTRY::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending" -ErrorAction SilentlyContinue) -ne $null) {
	Enable-Reboot

} elseif ((Get-Item -Path "REGISTRY::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired" -ErrorAction SilentlyContinue) -ne $null) {
	Enable-Reboot

} elseif ((Get-ItemProperty -Path "REGISTRY::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager" -Name PendingFileRenameOperations -ErrorAction SilentlyContinue) -ne $null) {
	Enable-Reboot

} elseif ((([wmiclass]"\\.\root\ccm\clientsdk:CCM_ClientUtilities").DetermineIfRebootPending().RebootPending) -eq $true) {
	Enable-Reboot
} else {
	Exit 0
}
