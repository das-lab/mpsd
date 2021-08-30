


$PatchReboot = Get-ChildItem -Path REGISTRY::"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired" -ErrorAction SilentlyContinue

$ComponentBasedReboot = Get-ChildItem -Path REGISTRY::"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending" -ErrorAction SilentlyContinue

$PendingFileRenameOperations = (Get-ItemProperty -Path REGISTRY::"HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager" -ErrorAction SilentlyContinue).PendingFileRenameOperations

$ConfigurationManagerReboot = Invoke-WmiMethod -Namespace "ROOT\ccm\ClientSDK" -Class CCM_ClientUtilities -Name DetermineIfRebootPending | select-object -ExpandProperty "RebootPending"
If (($PatchReboot -eq $null) -and ($ComponentBasedReboot -eq $null) -and ($PendingFileRenameOperations -eq $null) -and ($ConfigurationManagerReboot -eq $false)) {
	Return $false
} else {
	Return $true
}
