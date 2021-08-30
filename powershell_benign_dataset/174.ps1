






Start-Job -Name "UpdateHelp" -ScriptBlock { Update-Help -Force } | Out-null
Write-Host "Updating Help in background (Get-Help to check)" -ForegroundColor Yellow


Write-host "PowerShell Version: $($psversiontable.psversion) - ExecutionPolicy: $(Get-ExecutionPolicy)" -ForegroundColor yellow


Set-Location $home\onedrive\scripts\github
















Import-Module -Name PSReadline

if(Get-Module -name PSReadline)
{
	
	
	
	Set-PSReadlineKeyHandler -Key UpArrow -Function HistorySearchBackward
	Set-PSReadlineKeyHandler -Key DownArrow -Function HistorySearchForward
}





Set-Alias -Name npp -Value notepad++.exe
Set-Alias -Name np -Value notepad.exe
if (Test-Path $env:USERPROFILE\OneDrive){$OneDriveRoot = "$env:USERPROFILE\OneDrive"}








function prompt
{
	
	Write-output "PS [LazyWinAdmin.com]> "
}


function Get-ScriptDirectory
{
	if ($hostinvocation -ne $null)
	{
		Split-Path $hostinvocation.MyCommand.path
	}
	else
	{
		Split-Path $script:MyInvocation.MyCommand.Path
	}
}

$MyInvocation.MyCommand


$currentpath = Get-ScriptDirectory
. (Join-Path -Path $currentpath -ChildPath "\functions\Show-Object.ps1")
. (Join-Path -Path $currentpath -ChildPath "\functions\Connect-Office365.ps1")
. (Join-Path -Path $currentpath -ChildPath "\functions\Test-Port.ps1")
. (Join-Path -Path $currentpath -ChildPath "\functions\Get-NetAccelerator.ps1")
. (Join-Path -Path $currentpath -ChildPath "\functions\Clx.ps1")
. (Join-Path -Path $currentpath -ChildPath "\functions\Test-DatePattern.ps1")
. (Join-Path -Path $currentpath -ChildPath "\functions\View-Cats.ps1")
. (Join-Path -Path $currentpath -ChildPath "\functions\Find-Apartment.ps1")
. (Join-Path -Path $currentpath -ChildPath "\functions\Launch-AzurePortal.ps1")
. (Join-Path -Path $currentpath -ChildPath "\functions\Launch-ExchangeOnline.ps1")
. (Join-Path -Path $currentpath -ChildPath "\functions\Launch-InternetExplorer.ps1")
. (Join-Path -Path $currentpath -ChildPath "\functions\Launch-Office365Admin.ps1")







Get-Command -Module Microsoft*,Cim*,PS*,ISE | Get-Random | Get-Help -ShowWindow
Get-Random -input (Get-Help about*) | Get-Help -ShowWindow



