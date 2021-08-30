

function Install-SPOSolution
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory=$true, Position=1)]
	    [string]$solutionName
	)
	
	Write-Host "Activate solution $path" -foregroundcolor black -backgroundcolor yellow
	
	Switch-SPOEnableDisableSolution -solutionName $solutionName -activate $true
	
	Write-Host "Solution succesfully activated" -foregroundcolor black -backgroundcolor green
}
