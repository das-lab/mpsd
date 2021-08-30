
[CmdletBinding()]
param
(
		[Parameter(Mandatory = $false)][string]$ConsoleTitle = 'NIC Power Management',
		[bool]$TurnOffDevice = $true,
		[bool]$WakeComputer = $true,
		[bool]$AllowMagicPacketsOnly = $true
)

function Exit-PowerShell {

	
	[CmdletBinding()]
	param
	(
			[bool]$Errors
	)
	
	If ($Errors -eq $true) {
		Exit 1
	}
}

function Get-RelativePath {

	
	[CmdletBinding()][OutputType([string])]
	param ()
	
	$Path = (split-path $SCRIPT:MyInvocation.MyCommand.Path -parent) + "\"
	Return $Path
}

function Get-PhysicalNICs {

	
	[CmdletBinding()]
	param ()
	
	
	$NICs = Get-WmiObject Win32_NetworkAdapter -filter "AdapterTypeID = '0' `
	AND PhysicalAdapter = 'true' `
	AND NOT Description LIKE '%Centrino%' `
	AND NOT Description LIKE '%wireless%' `
	AND NOT Description LIKE '%virtual%' `
	AND NOT Description LIKE '%WiFi%' `
	AND NOT Description LIKE '%Bluetooth%'"
	Return $NICs
}

function Set-ConsoleTitle {

	
	[CmdletBinding()]
	param ()
	
	$host.ui.RawUI.WindowTitle = $ConsoleTitle
}

function Set-NICPowerManagement {

	
	[CmdletBinding()][OutputType([bool])]
	param
	(
			$NICs
	)
	
	foreach ($NIC in $NICs) {
		$Errors = $false
		Write-Host "NIC:"$NIC.Name
		
		Write-Host "Allow the computer to turn off this device....." -NoNewline
		$NICPowerManage = Get-WmiObject MSPower_DeviceEnable -Namespace root\wmi | Where-Object { $_.instancename -match [regex]::escape($nic.PNPDeviceID) }
		If ($NICPowerManage.Enable -ne $TurnOffDevice) {
			$NICPowerManage.Enable = $TurnOffDevice
			$HideOutput = $NICPowerManage.psbase.Put()
		}
		If ($NICPowerManage.Enable -eq $TurnOffDevice) {
			Write-Host "Success" -ForegroundColor Yellow
		} else {
			Write-Host "Failed" -ForegroundColor Red
			$Errors = $true
		}
		
		Write-Host "Allow this device to wake the computer....." -NoNewline
		$NICPowerManage = Get-WmiObject MSPower_DeviceWakeEnable -Namespace root\wmi | Where-Object { $_.instancename -match [regex]::escape($nic.PNPDeviceID) }
		If ($NICPowerManage.Enable -ne $WakeComputer) {
			$NICPowerManage.Enable = $WakeComputer
			$HideOutput = $NICPowerManage.psbase.Put()
		}
		If ($NICPowerManage.Enable -eq $WakeComputer) {
			Write-Host "Success" -ForegroundColor Yellow
		} else {
			Write-Host "Failed" -ForegroundColor Red
			$Errors = $true
		}
		
		Write-Host "Only allow a magic packet to wake the computer....." -NoNewline
		$NICPowerManage = Get-WmiObject MSNdis_DeviceWakeOnMagicPacketOnly -Namespace root\wmi | Where-Object { $_.instancename -match [regex]::escape($nic.PNPDeviceID) }
		If ($NICPowerManage.EnableWakeOnMagicPacketOnly -ne $AllowMagicPacketsOnly) {
			$NICPowerManage.EnableWakeOnMagicPacketOnly = $AllowMagicPacketsOnly
			$HideOutput = $NICPowerManage.psbase.Put()
		}
		If ($NICPowerManage.EnableWakeOnMagicPacketOnly -eq $AllowMagicPacketsOnly) {
			Write-Host "Success" -ForegroundColor Yellow
		} else {
			Write-Host "Failed" -ForegroundColor Red
			$Errors = $true
		}
	}
	Return $Errors
}

Clear-Host
Set-ConsoleTitle
$PhysicalNICs = Get-PhysicalNICs
$Errors = Set-NICPowerManagement -NICs $PhysicalNICs
Start-Sleep -Seconds 5
Exit-PowerShell -Errors $Errors
