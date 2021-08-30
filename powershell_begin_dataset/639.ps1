
$PromptSettings = (Get-Host).UI.RawUI
$PromptSettings.BufferSize.Width = 120
$PromptSettings.BufferSize.Height = 999
$PromptSettings.WindowSize.Width = 120
$PromptSettings.WindowSize.Height = 50
$PromptSettings.MaxWindowSize.Width = 120
$PromptSettings.MaxWindowSize.Height = 50
$PromptSettings.MaxPhysicalWindowSize.Width = 120
$PromptSettings.MaxPhysicalWindowSize.Height = 50



nal -Name gpc -Value "Get-PPConfiguration" -ErrorAction SilentlyContinue

nal -Name grc -Value "Get-RemoteConnection" -ErrorAction SilentlyContinue
nal -Name crdp -Value "Connect-RDP" -ErrorAction SilentlyContinue
nal -Name crps -Value "Connect-PSS" -ErrorAction SilentlyContinue
nal -Name chttp -Value "Connect-Http" -ErrorAction SilentlyContinue
nal -Name cssh -Value "Connect-SSH" -ErrorAction SilentlyContinue
nal -Name cscp -Value "Connect-SCP" -ErrorAction SilentlyContinue
nal -Name cftp -Value "Connect-FTP" -ErrorAction SilentlyContinue
nal -Name cvs -Value "Connect-VSphere" -ErrorAction SilentlyContinue
nal -Name cvm -Value "Connect-VM" -ErrorAction SilentlyContinue

nal -Name sps -Value "Start-PPScript" -ErrorAction SilentlyContinue
nal -Name gpps -value "Get-PPScript" -ErrorAction SilentlyContinue


Write-Host "    _/_/_/    _/_/_/        _/"
Write-Host "   _/    _/  _/    _/      _/"
Write-Host "  _/_/_/    _/_/_/    _/_/_/_/_/"
Write-Host " _/        _/            _/"
Write-Host "_/        _/            _/        This is a PowerShell PowerUp configured session`n"