

function Add-SPOGroup
{
	[CmdletBinding()]
	param
	(	

		[Parameter(Mandatory=$true, Position=1)]
		[string]$name
	)

	process
	{
		Write-Host "Create SharePoint group $name" -foregroundcolor black -backgroundcolor yellow

        $groupCreation = new-object Microsoft.SharePoint.Client.GroupCreationInformation
        $groupCreation.Title = $name

        try {
            
			$group = $clientContext.Web.SiteGroups.Add($groupCreation)
			$clientContext.ExecuteQuery()
			Write-Host "SharePoint group succesfully created" -foregroundcolor black -backgroundcolor green
			
		} catch {

			Write-Host "Group already exists" -foregroundcolor black -backgroundcolor yellow
			
        }
	}
}
