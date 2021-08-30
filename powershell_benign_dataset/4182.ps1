
[CmdletBinding()]
param ()
function Get-RelativePath {

	
	[CmdletBinding()][OutputType([string])]
	param ()
	
	$Path = (split-path $SCRIPT:MyInvocation.MyCommand.Path -parent) + "\"
	Return $Path
}

$RelativePath = Get-RelativePath
$InstalledVersion = [string]((Get-WmiObject Win32_BIOS).SMBIOSBIOSVersion)
$Model = ((Get-WmiObject Win32_ComputerSystem).Model).split(" ")[1]
[string]$BIOSVersion = (Get-ChildItem -Path $RelativePath | Where-Object { $_.Name -eq $Model } | Get-ChildItem -Filter *.exe)
$BIOSVersion = ($BIOSVersion.split("-")[1]).split(".")[0]
If ($BIOSVersion -eq $InstalledVersion) {
	Exit 0
} else {
	Exit 5
}
