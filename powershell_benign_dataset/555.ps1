

function Add-SPOSubsite
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory=$true, Position=1)]
	    [string]$title,
		
		[Parameter(Mandatory=$false, Position=2)]
	    [string]$webTemplate = "STS
		
		[Parameter(Mandatory=$false, Position=3)]
	    [string]$description = "",
		
		[Parameter(Mandatory=$false, Position=4)]
	    [string]$url = "",
		
		[Parameter(Mandatory=$false, Position=5)]
	    [int]$language = 1033,
		
		[Parameter(Mandatory=$false, Position=6)]
	    [bool]$useSamePermissionsAsParentSite = $true
	)
	Write-Host "Creating subsite $title" -foregroundcolor black -backgroundcolor yellow
	
	
	if ($url -eq "")
	{
		$url = $title
	}
	
	$webCreationInfo = new-object Microsoft.SharePoint.Client.WebCreationInformation
	$webCreationInfo.Title = $title
	$webCreationInfo.Description = $description
	$webCreationInfo.Language = $language
	$webCreationInfo.Url = $url
	$webCreationInfo.UseSamePermissionsAsParentSite = $useSamePermissionsAsParentSite
	$webCreationInfo.WebTemplate = $webTemplate
	
	$newSite = $clientContext.Web.Webs.Add($webCreationInfo)
		
    try {
	    
        $clientContext.ExecuteQuery()
        Write-Host "Subsite $title succesfully created" -foregroundcolor black -backgroundcolor green

    }	
    catch
    {
        
        Write-Host "Subsite $title already exists" -foregroundcolor black -backgroundcolor yellow

    }
}
