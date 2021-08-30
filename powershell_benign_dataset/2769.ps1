

Get-ItemProperty -Path 'HKLM:SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\*' | Where-Object { $_.Debugger }
Get-ItemProperty -Path 'HKLM:SOFTWARE\Wow6432Node\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\*' | Where-Object { $_.Debugger }