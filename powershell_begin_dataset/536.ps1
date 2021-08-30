

function Enable-SPOFeature
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory=$true, Position=1)]
	    [string]$featureId,
		
		[Parameter(Mandatory=$true, Position=2)]
	    [bool]$force,
		
		[Parameter(Mandatory=$true, Position=3)]
	    [Microsoft.SharePoint.Client.FeatureDefinitionScope]$featureDefinitionScope
	)
	Write-Host "Enabling feature $featureId on $featureDefinitionScope" -foregroundcolor black -backgroundcolor yellow
		
	$featureGuid = new-object System.Guid $featureId
		
	$features = $null	
	
	if ($featureDefinitionScope -eq [Microsoft.SharePoint.Client.FeatureDefinitionScope]::Site)
	{
	
		$features = $clientContext.Site.Features
		
	} else {
	
		$features = $clientContext.Web.Features
		
	}
	$clientContext.Load($features)
	$clientContext.ExecuteQuery()
	
	$feature = $features.Add($featureGuid, $force, [Microsoft.SharePoint.Client.FeatureDefinitionScope]::None)
	
	
	$clientContext.ExecuteQuery()
	
	Write-Host "Feature succesfully enabled" -foregroundcolor black -backgroundcolor green
}
