
[CmdletBinding()]
param
(
	[ValidateNotNullOrEmpty()][string]$ReferenceTS = '\\DeploymentShare\Control\WIN10REF\ts.xml',
	[ValidateNotNullOrEmpty()][string]$ProductionTS = '\\DeploymentShareTST\Control\WINDOWS10PROD\ts.xml',
	[string]$ARPExclusionsFile = "\\InstalledApplications\ARPExclusions.txt",
	[string]$TSExclusionsFile = "\\InstalledApplications\TSExclusions.txt",
	[string]$OutputDIR = '\\NAS\ApplicationLists\'
)

$Applications = @()
$TSExclusions = Get-Content -Path $TSExclusionsFile
$ARPExclusions = Get-Content -Path $ARPExclusionsFile
$Installed = (Get-ItemProperty -Path REGISTRY::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*, REGISTRY::HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*).DisplayName | Where-Object { ($_ -notlike '*Update for*') -and ($_ -notlike '*MUI*') -and ($_ -notlike '*Intel(R)*') } | ForEach-Object { If ($_ -notin $ARPExclusions) { $_ } } | Sort-Object -Unique
$TS = Get-Content -Path $ReferenceTS, $ProductionTS | Where-Object { $_ -like '*BDD_InstallApplication*' } | ForEach-Object { $_.split('=')[2].Replace('description', '').Replace('"', '').Trim() } | ForEach-Object { If ($_ -notin $TSExclusions) { $_ } } | Sort-Object
foreach ($App in $Installed) {
	If ($App -notin $TS) {
		$Applications += $App
	}
}
$Applications | Sort-Object -Unique | Out-file -FilePath ($OutputDIR + $env:COMPUTERNAME + '.txt')
