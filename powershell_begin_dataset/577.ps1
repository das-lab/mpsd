

function Uninstall-SPOSolution
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory=$true, Position=1)]
	    [string]$solutionName
	)
	
	Write-Host "Deactivate solution $path" -foregroundcolor black -backgroundcolor yellow
	
	Switch-SPOEnableDisableSolution -solutionName $solutionName -activate $false
	
	Write-Host "Solution succesfully deactivated" -foregroundcolor black -backgroundcolor green
}
