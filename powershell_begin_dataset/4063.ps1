


$LastInfection = get-winevent -filterhashtable @{ logname = 'system'; ID = 1116 } -maxevents 1 -ErrorAction SilentlyContinue
$LastScan = Get-WinEvent -FilterHashtable @{ logname = 'system'; ProviderName = 'Microsoft Antimalware'; ID = 1001 } -MaxEvents 1
If ($LastScan.TimeCreated -lt $LastInfection.TimeCreated) {
	
	Start-Sleep -Seconds 5
	exit 0
} else {
	
	Write-Host "No Infection"
	Start-Sleep -Seconds 5
	exit 0
}
