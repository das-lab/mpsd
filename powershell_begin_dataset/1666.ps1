
$TargetApplication = "C:\Program Files\Pulseway\pcmontask.exe"
$TargetArguments = " support"
$ShortcutFile = "$env:Public\Desktop\Get Support.lnk"
$WScriptShell = New-Object -ComObject WScript.Shell
$Shortcut = $WScriptShell.CreateShortcut($ShortcutFile)
$Shortcut.TargetPath = $TargetApplication
$Shortcut.Arguments = $TargetArguments
$Shortcut.Save()