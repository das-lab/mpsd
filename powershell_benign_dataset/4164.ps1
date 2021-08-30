


$Architecture = Get-WmiObject -Class Win32_OperatingSystem | Select-Object OSArchitecture
$Architecture = $Architecture.OSArchitecture

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

$RebootThreshold = 14
$Today = Get-Date

$LastReboot = get-winevent -filterhashtable @{ logname = 'system'; ID = 1074 } -maxevents 1 -ErrorAction SilentlyContinue

if ($LastReboot -eq $null) {
	$Difference = $RebootThreshold
} else {
	$Difference = New-TimeSpan -Start $Today -End $LastReboot.TimeCreated
	$Difference = [math]::Abs($Difference.Days)
}

if (($Difference -ge $RebootThreshold) -and ($Rebooted -eq 0)) {
	if ((Test-Path "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Reboot") -eq $true) {
		Set-ItemProperty -Path "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Reboot" -Name Rebooted -Value 1 -Type DWORD -Force
		$Rebooted = Get-ItemProperty -Name Rebooted -Path "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Reboot"
	} else {
		Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Reboot" -Name Rebooted -Value 1 -Type DWORD -Force
		$Rebooted = Get-ItemProperty -Name Rebooted -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Reboot"
	}
}
$Rebooted = $Rebooted.Rebooted

if (($Difference -lt $RebootThreshold) -and ($Rebooted -eq 1)) {
	if ((Test-Path "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Reboot") -eq $true) {
		Set-ItemProperty -Name Rebooted -Value 0 -Path "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Reboot" -Type DWORD -Force
		$Rebooted = Get-ItemProperty -Name Rebooted -Path "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Reboot"
	} else {
		Set-ItemProperty -Name Rebooted -Value 0 -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Reboot" -Type DWORD -Force
		$Rebooted = Get-ItemProperty -Name Rebooted -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Reboot"
	}
	$Rebooted = $Rebooted.Rebooted
	Write-Host "System is within"$RebootThreshold" Day Reboot Threshold"
}
Write-Host "Reboot Threshold:"$RebootThreshold
Write-Host "Difference:"$Difference
Write-Host "Rebooted:"$Rebooted
Exit 3010