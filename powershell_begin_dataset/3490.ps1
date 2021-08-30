














function Get-DevSpacesControllerName
{
    return 'devspaces' + (getAssetName)
}


function Get-DevSpacesControllerTagKey
{
     return 'tagKey' + (getAssetName)
}


function Get-DevSpacesControllerTagValue
{
    return 'tagValue' + (getAssetName)
}


function Assert-AreEqualPSController($controller1, $controller2)
{
    Assert-AreEqual $controller1.Name $controller2.Name
    Assert-AreEqual $controller1.ResourceGroupName $controller2.ResourceGroupName 
    Assert-AreEqual $controller1.ProvisioningState $controller2.ProvisioningState 
    Assert-AreEqual $controller1.Location $controller2.Location 
}