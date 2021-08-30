
$global:BannedCommands = @(
	'Write-Host',
	'Write-Verbose',
	'Write-Warning',
	'Write-Error',
	'Write-Output',
	'Write-Information',
	'Write-Debug'
)


$global:MayContainCommand = @{
	"Write-Host"  = @('Write-PSFHostColor.ps1')
	"Write-Verbose" = @()
	"Write-Warning" = @()
	"Write-Error"  = @('Invoke-PSFCommand.ps1','Stop-PSFFunction.ps1')
	"Write-Output" = @('filesystem.provider.ps1', 'gelf.provider.ps1', 'logfile.provider.ps1', 'input.ps1')
	"Write-Information" = @()
	"Write-Debug" = @()
}