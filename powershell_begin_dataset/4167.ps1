


Set-Variable -Name LocalAdmins -Force
Set-Variable -Name LogFile -Value $env:windir"\Logs\LocalAdministrators_Emailed.log" -Force
Set-Variable -Name Member -Force
Set-Variable -Name MemberExclusions -Force
Set-Variable -Name Members -Force
Set-Variable -Name SystemExclusions -Force

cls
$MemberExclusions = @("Domain Admins","Workstation Admins")
$SystemExclusions = @("SYSTEM01")
$LocalAdmins = @()
$Members = net localgroup administrators | where { $_ -AND $_ -notmatch "command completed successfully" } | select -skip 4
$Profiles = Get-ChildItem -Path $env:SystemDrive"\users" -Force
Foreach ($Member in $Members) {
	$Member = $Member.Split("\")
	If ($Member.Count -gt 1) {
		[string]$Member = $Member[1]
		If ($Member -notin $MemberExclusions) {
			$LocalAdmins += $Member
		}
	}
	Remove-Variable -Name Member
}
if (($LocalAdmins.Count -eq 0) -and ((Test-Path -Path $LogFile) -eq $true)) {
	Remove-Item -Path $LogFile -Force
}
if (($LocalAdmins.Count -gt 0) -and ($env:COMPUTERNAME -notin $SystemExclusions) -and ((Test-Path -Path $LogFile) -eq $false )) {
	Start-Sleep -Seconds 5
	exit 0
} else {
	Write-Host "No Local Administrators"
	Start-Sleep -Seconds 5
	exit 0
}
$LocalAdmins = $null


Remove-Variable -Name LocalAdmins -Force
Remove-Variable -Name LogFile -Force
Remove-Variable -Name Member -Force
Remove-Variable -Name MemberExclusions -Force
Remove-Variable -Name Members -Force
Remove-Variable -Name SystemExclusions -Force
