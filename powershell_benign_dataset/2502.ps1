

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