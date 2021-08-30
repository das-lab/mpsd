














function Get-ResourceGroupName
{
    return getAssetName
}


function Get-ResourceName
{
    return getAssetName
}


function TestSetup-CreateResourceGroup
{
    $resourceGroupName = getAssetName
    $rglocation = Get-Location "Microsoft.Resources" "resourceGroups" "West US"
    $resourceGroup = New-AzResourceGroup -Name $resourceGroupName -location $rglocation -Force
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