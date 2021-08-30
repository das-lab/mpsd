














function Get-ResourceGroupName
{
    return getAssetName
}


function Get-ResourceName
{
    return "AzTest" + (getAssetName)
}


function Get-StorageResourceId($rgname, $resourcename)
{
    $subscription = (Get-AzContext).Subscription.Id
    return "/subscriptions/$subscription/resourcegroups/$rgname/providers/microsoft.storage/storageaccounts/$resourcename"
}


function Get-ProviderLocation()
{
	if ([Microsoft.Azure.Test.HttpRecorder.HttpMockServer]::Mode -ne [Microsoft.Azure.Test.HttpRecorder.HttpRecorderMode]::Playback)
	{
		$namespace = "Microsoft.OperationalInsights"  
		$type = "workspaces"
		$location = Get-AzResourceProvider -ProviderNamespace $namespace | where {$_.ResourceTypes[0].ResourceTypeName -eq $type}  
  
		if ($location -eq $null) 
		{  
			return "East US"  
		} else 
		{  
			return $location.Locations[0]  
		}  
	}

	return "East US"
}
