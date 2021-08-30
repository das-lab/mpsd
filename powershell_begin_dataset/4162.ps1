


$RebootThreshold = 14
$Today = Get-Date

$Architecture = Get-WmiObject -Class Win32_OperatingSystem | Select-Object OSArchitecture
$Architecture = $Architecture.OSArchitecture

$LastReboot = get-winevent -filterhashtable @{ logname = 'system'; ID = 1074 } -maxevents 1 -ErrorAction SilentlyContinue

if ($Architecture -eq "32-bit") {
	if ((Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Reboot") -eq $false) {
		New-Item "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Reboot" | New-ItemProperty -Name Rebooted -Value 0 -Force | Out-Null
	}
	$Rebooted = Get-ItemProperty -Name Rebooted -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Reboot"
} else {
	if ((Test-Path "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Reboot") -eq $false) {
		New-Item "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Reboot" | New-ItemProperty -Name Rebooted -Value 0 -Force | Out-Null
	}
	$Rebooted = Get-ItemProperty -Name Rebooted -Path "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Reboot"
}

$Rebooted = $Rebooted.Rebooted

if ($LastReboot -eq $null) {
	$Difference = $RebootThreshold
} else {
	$Difference = New-TimeSpan -Start $Today -End $LastReboot.TimeCreated
	$Difference = [math]::Abs($Difference.Days)
}

if (($Difference -lt $RebootThreshold) -and ($Rebooted -eq 0)) {
	Write-Host "Success"
	exit 0
}
if (($Difference -ge $RebootThreshold) -and ($Rebooted -eq 1)) {
	Write-Host "Success"
	exit 0
}
if (($Difference -ge $RebootThreshold) -and ($Rebooted -eq 0)) {
	exit 0
}
if (($Difference -lt $RebootThreshold) -and ($Rebooted -eq 1)) {
	exit 0
}
