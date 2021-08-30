
param
(
	[switch]$EventLogServiceStopped,
	[switch]$KernelBootType,
	[switch]$MultiprocessorFree,
	[switch]$EventLogServiceStarted
)
function Initialize-HardwareInventory {

	
	[CmdletBinding()]
	param ()
	
	$Output = "Initiate SCCM Hardware Inventory....."
	$SMSCli = [wmiclass] "\\localhost\root\ccm:SMS_Client"
	$ErrCode = ($SMSCli.TriggerSchedule("{00000000-0000-0000-0000-000000000001}")).ReturnValue
	If ($ErrCode -eq $null) {
		$Output += "Success"
	} else {
		$Output += "Failed"
	}
	Write-Output $Output
}

function New-WMIClass {

	
	[CmdletBinding()]
	param
	(
		[ValidateNotNullOrEmpty()][string]$Class
	)
	
	$WMITest = Get-WmiObject $Class -ErrorAction SilentlyContinue
	If (($WMITest -ne "") -and ($WMITest -ne $null)) {
		$Output = "Deleting " + $Class + " WMI class....."
		Remove-WmiObject $Class
		$WMITest = Get-WmiObject $Class -ErrorAction SilentlyContinue
		If ($WMITest -eq $null) {
			$Output += "Success"
		} else {
			$Output += "Failed"
			Exit 1
		}
		Write-Output $Output
	}
	$Output = "Creating " + $Class + " WMI class....."
	$newClass = New-Object System.Management.ManagementClass("root\cimv2", [string]::Empty, $null);
	$newClass["__CLASS"] = $Class;
	$newClass.Qualifiers.Add("Static", $true)
	$newClass.Properties.Add("LastRebootTime", [System.Management.CimType]::string, $false)
	$newClass.Properties["LastRebootTime"].Qualifiers.Add("key", $true)
	$newClass.Properties["LastRebootTime"].Qualifiers.Add("read", $true)
	$newClass.Put() | Out-Null
	$WMITest = Get-WmiObject $Class -ErrorAction SilentlyContinue
	If ($WMITest -eq $null) {
		$Output += "Success"
	} else {
		$Output += "Failed"
		Exit 1
	}
	Write-Output $Output
}

function New-WMIInstance {

	
	[CmdletBinding()]
	param
	(
		[ValidateNotNullOrEmpty()][string]$LastRebootTime,
		[ValidateNotNullOrEmpty()][string]$Class
	)
	
	$Output = "Writing Last Reboot information instance to" + [char]32 + $Class + [char]32 + "class....."
	$Return = Set-WmiInstance -Class $Class -Arguments @{ LastRebootTime = $LastRebootTime }
	If ($Return -like "*" + $LastRebootTime + "*") {
		$Output += "Success"
	} else {
		$Output += "Failed"
	}
	Write-Output $Output
}

Clear-Host

If ($KernelBootType.IsPresent) {
	[string]$LastReboot = (Get-WinEvent -FilterHashtable @{ logname = 'system'; ID = 27 } -MaxEvents 1 | Where-Object { $_.Message -like "*boot type was 0x0*" }).TimeCreated
}
If ($EventLogServiceStarted.IsPresent) {
	[string]$LastReboot = (Get-WinEvent -FilterHashtable @{ logname = 'system'; ID = 6005 } -MaxEvents 1 | Where-Object { $_.Message -like "*service was started*" }).TimeCreated
}
If ($EventLogServiceStopped.IsPresent) {
	[string]$LastReboot = (Get-WinEvent -FilterHashtable @{ logname = 'system'; ID = 6006 } -MaxEvents 1 | Where-Object { $_.Message -like "*service was stopped*" }).TimeCreated
}
If ($MultiprocessorFree.IsPresent) {
	[string]$LastReboot = (Get-WinEvent -FilterHashtable @{ logname = 'system'; ID = 6009 } -MaxEvents 1 | Where-Object { $_.Message -like "*Multiprocessor Free*" }).TimeCreated
}

$Output = "Last reboot/shutdown: " + $LastReboot
Write-Output $Output

New-WMIClass -Class "RebootInfo"

New-WMIInstance -LastRebootTime $LastReboot -Class "RebootInfo"

Initialize-HardwareInventory
