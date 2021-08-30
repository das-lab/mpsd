
[CmdletBinding()]
param
(
	[ValidateNotNullOrEmpty()][string]$SCCMServer='BNASCCM',
	[ValidateNotNullOrEmpty()][string]$SCCMDrive='BNA',
	[ValidateNotNullOrEmpty()][string]$SCCMCollection = 'All Systems',
	[switch]$ReportOnly
)

function Get-RelativePath {

	
	[CmdletBinding()][OutputType([string])]
	param ()
	
	$Path = (split-path $SCRIPT:MyInvocation.MyCommand.Path -parent) + "\"
	Return $Path
}

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

function Get-SCCMCollectionList {

	
	[CmdletBinding()]
	param
	(
		[ValidateNotNullOrEmpty()][string]$CollectionName
	)
	
	
	$FQDN = ([System.Net.Dns]::GetHostByName($SCCMServer)).HostName
	
	New-PSDrive -Name $SCCMDrive -PSProvider "AdminUI.PS.Provider\CMSite" -Root $FQDN -Description $SCCMDrive"Primary Site" | Out-Null
	
	If ($SCCMDrive[$SCCMDrive.Length - 1] -ne ":") {
		$SCCMDrive = $SCCMDrive + ":"
	}
	
	Set-Location $SCCMDrive
	
	$CollectionID = (Get-CMDeviceCollection | Where-Object { $_.Name -eq $SCCMCollection }).CollectionID
	
	$CollectionSystems = (Get-CMDevice -CollectionId $CollectionID).Name | Where-Object { $_ -notlike "*Unknown Computer*" } | Sort-Object
	
	Set-Location $env:HOMEDRIVE
	
	$Collection = @()
	foreach ($System in $CollectionSystems) {
		try {
			$ADSystem = (Get-ADComputer $System).Enabled
		} catch {
			$ADSystem = $false
		}
		$objSystem = New-Object System.Object
		$objSystem | Add-Member -MemberType NoteProperty -Name Name -Value $System
		$objSystem | Add-Member -MemberType NoteProperty -Name Enabled -Value $ADSystem
		$Collection += $objSystem
}
	Return $Collection
}

function Remove-Systems {

	
	[CmdletBinding()]
	param
	(
		[ValidateNotNullOrEmpty()]$Collection
	)
	
	
	$FQDN = ([System.Net.Dns]::GetHostByName($SCCMServer)).HostName
	
	New-PSDrive -Name $SCCMDrive -PSProvider "AdminUI.PS.Provider\CMSite" -Root $FQDN -Description $SCCMDrive"Primary Site" | Out-Null
	
	If ($SCCMDrive[$SCCMDrive.Length - 1] -ne ":") {
		$SCCMDrive = $SCCMDrive + ":"
	}
	
	Set-Location $SCCMDrive
	
	foreach ($System in $Collection) {
		If ($System.Enabled -eq $False) {
			Remove-CMDevice -Name $System.Name -Force
		}
	}
	
	Set-Location $env:HOMEDRIVE
}

Clear-Host
Import-Module ActiveDirectory
Import-SCCMModule -SCCMServer $SCCMServer

$RelativePath = Get-RelativePath
$Collection = Get-SCCMCollectionList -CollectionName "All Systems"
If (!($ReportOnly.IsPresent)) {
	Remove-Systems -Collection $Collection
	$Collection
	$File = $RelativePath + "DeletedSystems.csv"
	$Collection | Out-File -FilePath $File -Encoding UTF8 -NoClobber -force
} else {
	
	$File = $RelativePath + "DisabledSystems.csv"
	
	If ((Test-Path $File) -eq $true) {
		Remove-Item -Path $File -Force
	}
	$Collection
	$Collection | Out-File -FilePath $File -Encoding UTF8 -NoClobber -force
}
