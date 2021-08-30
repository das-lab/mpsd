
[CmdletBinding()]
param
(
	[ValidateNotNullOrEmpty()][string]$CollectionName = 'TSTBLD Systems',
	[ValidateNotNullOrEmpty()][string]$SCCMServer = 'BNASCCM',
	[ValidateNotNullOrEmpty()][string]$SCCMDrive = 'BNA',
	[ValidateNotNullOrEmpty()][string]$ReportFile = 'PendingRebootReport.csv'
)

function Import-SCCMModule {

	
	[CmdletBinding()]
	param
	(
		[ValidateNotNullOrEmpty()][string]$SCCMServer
	)
	
	
	$Architecture = (get-wmiobject win32_operatingsystem -computername $SCCMServer).OSArchitecture
	
	$Uninstall = Invoke-Command -ComputerName $SCCMServer -ScriptBlock { Get-ChildItem -Path REGISTRY::"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" -Force -ErrorAction SilentlyContinue }
	If ($Architecture -eq "64-bit") {
		$Uninstall += Invoke-Command -ComputerName $SCCMServer -ScriptBlock { Get-ChildItem -Path REGISTRY::"HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall" -Force -ErrorAction SilentlyContinue }
	}
	
	$RegKey = ($Uninstall | Where-Object { $_ -like "*SMS Primary Site*" }) -replace 'HKEY_LOCAL_MACHINE', 'HKLM:'
	$Reg = Invoke-Command -ComputerName $SCCMServer -ScriptBlock { Get-ItemProperty -Path $args[0] } -ArgumentList $RegKey
	
	$Directory = (($Reg.UninstallString).Split("\", 4) | Select-Object -Index 0, 1, 2) -join "\"
	
	$Module = Invoke-Command -ComputerName $SCCMServer -ScriptBlock { Get-ChildItem -Path $args[0] -Filter "ConfigurationManager.psd1" -Recurse } -ArgumentList $Directory
	
	If ($Module.Length -gt 1) {
		foreach ($Item in $Module) {
			If (($NewModule -eq $null) -or ($Item.CreationTime -gt $NewModule.CreationTime)) {
				$NewModule = $Item
			}
		}
		$Module = $NewModule
	}
	
	[string]$Module = "\\" + $SCCMServer + "\" + ($Module.Fullname -replace ":", "$")
	
	Import-Module -Name $Module
}

function Get-RebootPendingSystems {

	
	[CmdletBinding()]
	param ()
	
	
	$Report = @()
	
	If ($SCCMDrive[$SCCMDrive.Length - 1] -ne ":") {
		$SCCMDrive = $SCCMDrive + ":"
	}
	
	Set-Location $SCCMDrive
	
	$Systems = (Get-CMDevice -collectionname $CollectionName).Name | Sort-object
	foreach ($System in $Systems) {
		$Object = New-Object -TypeName System.Management.Automation.PSObject
		$Object | Add-Member -MemberType NoteProperty -Name ComputerName -Value $System.ToUpper()
		$Report += $Object
	}
	
	Set-Location $env:HOMEDRIVE
	
	Return $Report
}

function Get-RelativePath {

	
	[CmdletBinding()][OutputType([string])]
	param ()
	
	$Path = (split-path $SCRIPT:MyInvocation.MyCommand.Path -parent) + "\"
	Return $Path
}

Clear-Host

Import-SCCMModule -SCCMServer $SCCMServer

$Report = Get-RebootPendingSystems

$RelativePath = Get-RelativePath

$ReportFile = $RelativePath + $ReportFile

If ((Test-Path $ReportFile) -eq $true) {
	Remove-Item -Path $ReportFile -Force
}

$Report

$Report | Export-Csv -Path $ReportFile -Encoding UTF8 -Force -NoTypeInformation
