
function Test-AzureRmDevSpacesController
{
    
    $resourceGroupName = "rgps4504"
    $kubeClusterName = "kubeps5496"

    
    $devSpacesName = Get-DevSpacesControllerName
    $tagKey =  Get-DevSpacesControllerTagKey
    $tagValue =  Get-DevSpacesControllerTagValue

    $referenceObject = @{}
    $referenceObject.Name = $devSpacesName
    $referenceObject.ResourceGroupName = $resourceGroupName
    $referenceObject.ProvisioningState = "Succeeded"
    $referenceObject.Location = "eastus"

    
    $devSpaceController = New-AzDevSpacesController -ResourceGroupName $resourceGroupName -Name $devSpacesName -TargetClusterName $kubeClusterName -TargetResourceGroupName $resourceGroupName
    Assert-AreEqualPSController $referenceObject $devSpaceController

    
    $devSpaceController = Get-AzDevSpacesController -ResourceGroupName $resourceGroupName -Name $devSpacesName
    Assert-AreEqualPSController $referenceObject $devSpaceController

    
    $devSpaceControllerUpdated = $devSpaceController | Update-AzDevSpacesController -Tag @{ $tagKey=$tagValue}
    Assert-AreEqualPSController $referenceObject $devSpaceControllerUpdated
    $tag = Get-AzTag -Name $tagKey
    $tagValueExist = $tag.Values.Name -Contains $tagValue
    Assert-AreEqual "True" $tagValueExist

    
    $deletedAzureRmDevSpace = $devSpaceController | Remove-AzDevSpacesController -PassThru
    Assert-AreEqual "True" $deletedAzureRmDevSpace

    
    $azureRmDevSpaces = Get-AzDevSpacesController -ResourceGroupName $resourceGroupName
    Assert-Null $azureRmDevSpaces    
}


function Test-TestAzureDevSpacesAsJobParameter
{
    
    $resourceGroupName = "rgps4505"
    $kubeClusterName = "kubeps5497"

    
    $devSpacesName = Get-DevSpacesControllerName
    $tagKey =  Get-DevSpacesControllerTagKey
    $tagValue =  Get-DevSpacesControllerTagValue

    $referenceObject = @{}
    $referenceObject.Name = $devSpacesName
    $referenceObject.ResourceGroupName = $resourceGroupName
    $referenceObject.ProvisioningState = "Succeeded"
    $referenceObject.Location = "eastus"

	$job = New-AzDevSpacesController -ResourceGroupName $resourceGroupName -Name $devSpacesName -TargetClusterName $kubeClusterName -TargetResourceGroupName $resourceGroupName -AsJob
	$job | Wait-Job
	$devSpaceController = $job | Receive-Job
	Assert-AreEqualPSController $referenceObject $devSpaceController

	$deletedJob = $devSpaceController | Remove-AzDevSpacesController -PassThru -AsJob
	$deletedJob | Wait-Job
	$deletedAzureRmDevSpace = $deletedJob | Receive-Job
	Assert-AreEqual "True" $deletedAzureRmDevSpace

    
    $azureRmDevSpaces = Get-AzDevSpacesController -ResourceGroupName $resourceGroupName
    Assert-Null $azureRmDevSpaces
}
