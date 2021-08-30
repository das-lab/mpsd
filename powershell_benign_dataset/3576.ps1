














function Get-ResourceGroupName
{
    return "RG-" + (getAssetName)
}

function Get-AdmAssetName
{
	return "adm" + (getAssetName)
}


function Get-ProviderLocation($provider)
{
	if ([Microsoft.Azure.Test.HttpRecorder.HttpMockServer]::Mode -ne [Microsoft.Azure.Test.HttpRecorder.HttpRecorderMode]::Playback)
	{
		$namespace = $provider.Split("/")[0]  
		if($provider.Contains("/"))  
		{  
			$type = $provider.Substring($namespace.Length + 1)  
			$location = Get-AzResourceProvider -ProviderNamespace $namespace | where {$_.ResourceTypes[0].ResourceTypeName -eq $type}  
  
			if ($location -eq $null) 
			{  
				return "Central US"  
			} else 
			{  
				return $location.Locations[0]  
			}  
		}
		
		return "Central US"
	}

	return "Central US"
}


function TestSetup-CreateResourceGroup
{
    $resourceGroupName = getAssetName
	$rglocation = Get-ProviderLocation "Central US"
    $resourceGroup = New-AzResourceGroup -Name $resourceGroupName -location $rglocation -Force
	return $resourceGroup
}


function TestCleanup-RemoveResourceGroup($rgname)
{
    Remove-AzResourceGroup -Name $rgname -Force
}
