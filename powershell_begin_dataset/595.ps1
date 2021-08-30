

function Install-PowerShellPowerUp{



	param(
		[switch]
		$Force
	)
	
	
	
	
	Set-Location $PSprofile.Path
	Invoke-Expression "$($PSProfile.Install.FullName) -Force:`$Force"
	Set-Location $WorkingPath
}