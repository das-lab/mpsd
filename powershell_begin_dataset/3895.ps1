














function Get-ResourceGroupName
{
    return getAssetName
}


function Get-ResourceName
{
    return getAssetName
}


function Get-ProviderLocation($provider)
{
    if ([Microsoft.Azure.Test.HttpRecorder.HttpMockServer]::Mode -ne [Microsoft.Azure.Test.HttpRecorder.HttpRecorderMode]::Playback)
    {
        $namespace = $provider.Split("/")[0]  
        if($provider.Contains("/"))  
        {  
            $type = $provider.Substring($namespace.Length + 1)  
            $location = Get-AzureRmResourceProvider -ProviderNamespace $namespace | where {$_.ResourceTypes[0].ResourceTypeName -eq $type}  
  
            if ($location -eq $null) 
            {  
                return "westcentralus"
            } else 
            {  
                return $location.Locations[0]  
            }  
        }
        
        return "westcentralus"
    }

    return "westcentralus"
}


function TestSetup-CreateResourceGroup
{
    $resourceGroupName = getAssetName
    $rglocation = Get-ProviderLocation "North Europe"
    $resourceGroup = New-AzureRmResourceGroup -Name $resourceGroupName -location $rglocation -Force
    return $resourceGroup
}


function Assert-Tags($tags1, $tags2)
{
    if($tags1.count -ne $tags2.count)
    {
        throw "Tag size not equal. Tag1: $tags1.count Tag2: $tags2.count"
    }

    foreach($key in $tags1.Keys)
    {
        if($tags1[$key] -ne $tags2[$key])
        {
            throw "Tag content not equal. Key:$key Tags1:" +  $tags1[$key] + "Tags2:" + $tags2[$key]
        }
    }
}


function Assert-CompressionTypes($types1, $types2)
{
    if($types1.Count -ne $types1.Count)
    {
        throw "Array size not equal. Types1: $types1.count Types2: $types2.count"
    }

    foreach($value1 in $types1)
    {
        $found = $false
        foreach($value2 in $types2)
        {
            if($value1.CompareTo($value2) -eq 0)
            {
                $found = $true
                break
            }
        }
        if(-Not($found))
        {
            throw "Compression content not equal. " + $value1 + " cannot be found in second array"
        }
    }
}



function Clean-ResourceGroup($rgname)
{
	Remove-AzureRmResourceGroup -Name $rgname -Force
}
