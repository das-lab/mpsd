
[CmdletBinding()]
param
(
	[switch]$FileOutput,
	[ValidateNotNullOrEmpty()][string]$FileName = 'TrustedSitesReport.txt'
)

function Get-RelativePath {

	
	[CmdletBinding()][OutputType([string])]
	param ()
	
	$Path = (split-path $SCRIPT:MyInvocation.MyCommand.Path -parent) + "\"
	Return $Path
}


$HKCU = $(get-item "HKCU:\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMapKey" -ErrorAction SilentlyContinue).property | Sort-Object

$HKLM = $(get-item "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMapKey" -ErrorAction SilentlyContinue).property | Sort-Object

$RelativePath = Get-RelativePath

$File = $RelativePath + "TrustedSitesReport.txt"

If ((Test-Path $File) -eq $true) {
	Remove-Item -Path $File -Force
}

New-Item -Path $File -ItemType File -Force

If ($HKCU -ne $null) {
	
	"HKEY_CURRENT_USERS" | Out-File -FilePath $File -Append
	
	$HKCU
	If ($FileOutput.IsPresent) {
		$HKCU | Out-File -FilePath $File -Append
	}
	
	" "| Out-File -FilePath $File -Append
}

If ($HKLM -ne $null) {
	
	"HKEY_LOCAL_MACHINE" | Out-File -FilePath $File -Append
	
	$HKLM
	If ($FileOutput.IsPresent) {
		$HKLM | Out-File -FilePath $File -Append
	}
}
