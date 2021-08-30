
param
(
	[switch]
	$FullScan,
	[switch]
	$QuickScan,
	[switch]
	$Email,
	[string]
	$EmailRecipient = '',
	[string]
	$EmailSender = '',
	[string]
	$SMTPServer = ''
)


Import-Module $env:ProgramFiles"\Microsoft Security Client\MpProvider\MpProvider.psd1"

$RelativePath = (split-path $SCRIPT:MyInvocation.MyCommand.Path -parent) + "\"

$LastInfection = get-winevent -filterhashtable @{ logname = 'system'; ID = 1116 } -maxevents 1 -ErrorAction SilentlyContinue

If ($FullScan.IsPresent) {
	
	Start-MProtScan -ScanType "FullScan"
	
	
	
	$LastScan = Get-WinEvent -FilterHashtable @{ logname = 'system'; ProviderName = 'Microsoft Antimalware'; ID = 1001 } -MaxEvents 1
	
	If ($LastScan.Message -like '*Microsoft Antimalware scan has finished*') {
		$EmailBody = "An Endpoint antimalware full system scan has been performed on" + [char]32 + $env:COMPUTERNAME + [char]32 + "due to the virus detection listed below." + [char]13 + [char]13 + $LastInfection.Message
	} else {
		$EmailBody = "An Endpoint antimalware full system scan did not complete on" + [char]32 + $env:COMPUTERNAME + [char]32 + "due to the virus detection listed below." + [char]13 + [char]13 + $LastInfection.Message
	}
}

If ($QuickScan.IsPresent) {
	
	Start-MProtScan -ScanType "QuickScan"
	
	
	
	$LastScan = Get-WinEvent -FilterHashtable @{ logname = 'system'; ProviderName = 'Microsoft Antimalware'; ID = 1001 } -MaxEvents 1
	
	If ($LastScan.Message -like '*Microsoft Antimalware scan has finished*') {
		$EmailBody = "An Endpoint antimalware quick system scan has been performed on" + [char]32 + $env:COMPUTERNAME + [char]32 + "due to the virus detection listed below." + [char]13 + [char]13 + $LastInfection.Message
	} else {
		$EmailBody = "An Endpoint antimalware quick system scan did not complete on" + [char]32 + $env:COMPUTERNAME + [char]32 + "due to the virus detection listed below." + [char]13 + [char]13 + $LastInfection.Message
	}
}

If ($Email.IsPresent) {
	$Subject = "Microsoft Endpoint Infection Report"
	$EmailSubject = "Virus Detection Report for" + [char]32 + $env:COMPUTERNAME
	Send-MailMessage -To $EmailRecipient -From $EmailSender -Subject $Subject -Body $EmailBody -SmtpServer $SMTPServer
}

$WMIPath = "\\" + $env:COMPUTERNAME + "\root\ccm:SMS_Client"
$SMSwmi = [wmiclass]$WMIPath
$strAction = "{00000000-0000-0000-0000-000000000121}"
[Void]$SMSwmi.TriggerSchedule($strAction)
