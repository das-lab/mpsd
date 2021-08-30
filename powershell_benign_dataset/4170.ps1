
param
(
	[switch]$ListQueries,
	[string]$Query,
	[string]$SCCMServer,
	[string]$SCCMServerDrive
)

function Get-ListOfQueries {

	
	[CmdletBinding()]
	param ()
	
	Set-Location $SCCMServerDrive
	$Queries = Get-CMQuery
	Set-Location $env:SystemDrive
	$QueryArray = @()
	foreach ($Query in $Queries) {
		$QueryArray += $Query.Name
	}
	$QueryArray = $QueryArray | Sort-Object
	$QueryArray
}

function Get-RelativePath {

	
	[CmdletBinding()][OutputType([string])]
	param ()
	
	$Path = (split-path $SCRIPT:MyInvocation.MyCommand.Path -parent) + "\"
	Return $Path
}

function Get-SCCMQueryData {
	[CmdletBinding()]
	param ()
	
	$Report = @()
	
	Set-Location $SCCMServerDrive
	
	$Output = Get-CMQuery -Name $Query | Invoke-CMQuery
	
	Set-Location $env:SystemDrive
	
	foreach ($Item in $Output) {
		$Item1 = [string]$Item
		$Domain = (($Item1.split(';'))[0]).Split('"')[1]
		$User = ((($Item1.split(";"))[1]).Split('"'))[1]
		$ComputerName = ((($Item1.split(";"))[3]).Split('"'))[1]
		$Object = New-Object -TypeName System.Management.Automation.PSObject
		$Object | Add-Member -MemberType NoteProperty -Name ComputerName -Value $ComputerName.ToUpper()
		$Object | Add-Member -MemberType NoteProperty -Name Domain -Value $Domain.ToUpper()
		$Object | Add-Member -MemberType NoteProperty -Name UserName -Value $User.ToUpper()
		$Report += $Object
	}
	$Report = $Report | Sort-Object -Property UserName
	Return $Report
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

function Send-Report {

	
	[CmdletBinding()]
	param ()
	
	
}

Clear-Host

If ($SCCMServerDrive[$SCCMServerDrive.Length - 1] -ne ":") {
	$SCCMServerDrive += ":"
}

Import-SCCMModule -SCCMServer $SCCMServer

If ($ListQueries.IsPresent) {
	Get-ListOfQueries
}

If (($Query -ne $null) -and ($Query -ne "")) {
	
	$Report = Get-SCCMQueryData | Sort-Object -Property ComputerName
	
	$Report
	
	$RelativePath = Get-RelativePath
	
	$File = $RelativePath + "LocalAdministrators.csv"
	
	If ((Test-Path $File) -eq $true) {
		Remove-Item -Path $File -Force
	}
	
	$Report | Export-Csv -Path $File -Encoding UTF8 -Force
}
