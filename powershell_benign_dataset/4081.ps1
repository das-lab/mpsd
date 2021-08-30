
param
(
	[string]
	$OutputFile = 'InactiveSCCMSystemsReport.csv',
	[string]
	$Path = "\\drfs1\DesktopApplications\ProductionApplications\Waller\InactiveUserReport"
)
Import-Module ActiveDirectory


function ProcessTextFile {
	If ((Test-Path -Path $OutputFile) -eq $true) {
		Remove-Item -Path $OutputFile -Force
	}
}

function Get-SCCMInactiveSystems {
	
	Set-Variable -Name Systems -Scope Local -Force
	
	$Systems = get-cmdevice -collectionid "BNA00093" | select name | Sort-Object Name
	Return $Systems
	
	
	Remove-Variable -Name Systems -Scope Local -Force
}

function Find-SCCMInactiveSystemInAD {
	param ([string]
		$System)
	
	
	Set-Variable -Name AD -Scope Local -Force
	$ErrorActionPreference = 'SilentlyContinue'
	$AD = Get-ADComputer $System
	$ErrorActionPreference = 'Continue'
	if ($AD -ne $null) {
		Return "X"
	} else {
		Return " "	
	}
	
	
	Remove-Variable -Name AD -Scope Local -Force
}

function Get-LastLogonDate {
	param ([string]
		$System)
	
	
	Set-Variable -Name AD -Scope Local -Force
	
	$AD = Get-ADComputer $System -ErrorAction SilentlyContinue
	$AD = $AD.SamAccountName
	$AD = $AD.Substring(0, $AD.Length - 1)
	$AD = Get-ADComputer -Identity $AD -Properties *
	$AD = $AD.LastLogonDate
	Return $AD
		
	
	Remove-Variable -Name AD -Scope Local -Force
}


Set-Variable -Name ADEntry -Scope Local -Force
Set-Variable -Name Counter -Value 1 -Scope Local -Force
Set-Variable -Name LastLogon -Scope Local -Force
Set-Variable -Name Output -Scope Local -Force
Set-Variable -Name SCCMInactiveSystems -Scope Local -Force
Set-Variable -Name System -Scope Local -Force

cls
Import-Module -Name ActiveDirectory
Import-Module "D:\Program Files\Microsoft Configuration Manager\AdminConsole\bin\ConfigurationManager.psd1" -Force -Scope Global
Set-Location BNA:
$SCCMInactiveSystems = Get-SCCMInactiveSystems
Set-Location c:
$OutputFile = $Path + "\" + $OutputFile
ProcessTextFile
$Output = "Computer Name" + [char]44+"Active Directory"+[char]44+"Last Logon"
Out-File -FilePath $OutputFile -InputObject $Output -Force -Encoding UTF8
foreach ($System in $SCCMInactiveSystems) {
	cls
	$Output = "Processing "+$System.Name+" -- "+$Counter+" of "+$SCCMInactiveSystems.Count
	Write-Host $Output
	$Counter++
	$ADEntry = Find-SCCMInactiveSystemInAD -System $System.Name
	If ($ADEntry -ne " ") {
		$LastLogon = Get-LastLogonDate -System $System.Name
	}
	$Output = $System.Name+[char]44+$ADEntry+[char]44+$LastLogon
	Out-File -FilePath $Global:OutputFile -InputObject $Output -Append -Force -Encoding UTF8
	$ADEntry = $null
	$LastLogon = $null
	$Output = $null
}


Remove-Variable -Name ADEntry -Scope Local -Force
Remove-Variable -Name Counter -Scope Local -Force
Remove-Variable -Name LastLogon -Scope Local -Force
Remove-Variable -Name Output -Scope Local -Force
Remove-Variable -Name SCCMInactiveSystems -Scope Local -Force
Remove-Variable -Name System -Scope Local -Force
