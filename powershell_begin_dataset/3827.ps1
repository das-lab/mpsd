














function TestAzureRmRelayNameTests 
{
	
	$location = "West US"
	$namespaceName = getAssetName "Relay-NS"
	$namespaceName2 = getAssetName "Relay-NS"
	$resourceGroupName = getAssetName
	$secondResourceGroup = getAssetName
	
	Write-Debug "Create resource group"
	Write-Debug "ResourceGroup name : $resourceGroupName"
	New-AzResourceGroup -Name $resourceGroupName -Location $location -Force 

	Write-Debug "Create resource group"
	Write-Debug "ResourceGroup name : $secondResourceGroup"
	New-AzResourceGroup -Name $secondResourceGroup -Location $location -Force 
	
	$ResultCheckNameAvailability = Test-AzRelayName -Namespace $namespaceName
	Assert-True {$ResultCheckNameAvailability.NameAvailable} "The Namespace Name not Available"
	
	Write-Debug " Create new Relay namespace"
	Write-Debug "NamespaceName : $namespaceName" 
	$result = New-AzRelayNamespace -ResourceGroupName $resourceGroupName -Name $namespaceName -Location $location
	Wait-Seconds 15

	
	Assert-True {$result.ProvisioningState -eq "Succeeded"}

	$ReCheckNameAvailability = Test-AzRelayName -Namespace $namespaceName
	Assert-False {$ReCheckNameAvailability.NameAvailable} "The Namespace Name Available failed"  
	
	Write-Debug " Delete namespaces"
	Remove-AzRelayNamespace -ResourceGroupName $resourceGroupName -Name $namespaceName

	Write-Debug " Delete resourcegroup"
	Remove-AzResourceGroup -Name $resourceGroupName -Force
}