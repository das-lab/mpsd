














function Get-ResourceGroupName
{
    return getAssetName
}


function Get-VaultName
{
    return getAssetName
}


function Get-KeyVaultTestMode {
    try {
        $testMode = [Microsoft.Azure.Test.HttpRecorder.HttpMockServer]::Mode;
        $testMode = $testMode.ToString();
    } catch {
        if ($PSItem.Exception.Message -like '*Unable to find type*') {
            $testMode = 'Record';
        } else {
            throw;
        }
    }

    return $testMode
}


function Get-ProviderLocation($provider)
{
	if ((Get-KeyVaultTestMode) -ne 'Playback')
	{
		$namespace = $provider.Split("/")[0]  
		if($provider.Contains("/"))  
		{  
			$type = $provider.Substring($namespace.Length + 1)  
			$location = Get-AzResourceProvider -ProviderNamespace $namespace | where {$_.ResourceTypes[0].ResourceTypeName -eq $type}  
  
			if ($location -eq $null) 
			{  
				return "East US"  
			} 
            else 
			{  
				return $location.Locations[0]  
			}  
		}
		
		return "East US"
	}

	return "East US"
}


function Clean-ResourceGroup($rgname)
{
    if ((Get-KeyVaultTestMode) -ne 'Playback') {
        Remove-AzResourceGroup -Name $rgname -Force
    }
}