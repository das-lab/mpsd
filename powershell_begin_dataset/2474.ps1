


function Save-AzrWebApp
{
	
	[OutputType([System.IO.FileInfo])]
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string]$Name,

		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string]$TargetPath,

		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[pscredential]$Credential
	)
	try
	{
		$syncParams = @{
			SourcePath = 'wwwroot'
			TargetPath = $TargetPath
			ComputerName = "https://$Name.scm.azurewebsites.net:443/msdeploy.axd?site=$Name"
			Credential = $Credential

		}
		Sync-Website @syncParams
		Get-Item -Path $TargetPath
	}
	catch
	{
		$PSCmdlet.ThrowTerminatingError($_)
	}
}