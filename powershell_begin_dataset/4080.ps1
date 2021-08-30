

Import-Module $env:ProgramFiles"\Microsoft Security Client\MpProvider"

Start-MProtScan -ScanType "FullScan"
New-EventLog –LogName System –Source "Antimalware Full Scan"
Write-EventLog -LogName System -Source "Antimalware Full Scan" -EntryType Information -EventId 1118 -Message "Antimalware full system scan was performed" -Category ""



$WMIPath = "\\" + $env:COMPUTERNAME + "\root\ccm:SMS_Client"
$SMSwmi = [wmiclass]$WMIPath
$strAction = "{00000000-0000-0000-0000-000000000021}"
[Void]$SMSwmi.TriggerSchedule($strAction)
Exit 0
