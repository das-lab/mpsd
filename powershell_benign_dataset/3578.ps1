














function Get-ResourceGroupName
{
    return getAssetName
}


function Get-ApiManagementServiceName
{
    return getAssetName
}


function Get-ProviderLocation($provider)
{
    $locations = Get-ProviderLocations $provider
    if ($locations -eq $null) {
        "West US"
    } else {
        $locations[0]
    }
}


function Get-ProviderLocations($provider)
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
                return @("West US", "East US") 
            } else 
            {  
                return $location.Locations[0]  
            }  
        }
        
        return @("West US", "East US")
    }

    return @("West US", "East US")
}