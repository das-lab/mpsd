














function HybridConnectionsTests
{
	
	$location = "West US"
	$resourceGroupName = getAssetName
	$namespaceName = getAssetName "Relay-NS"
	$HybridConnectionsName = getAssetName "Relay-NS"

	
	Write-Debug "Create resource group"    
	Write-Debug " Resource Group Name : $resourceGroupName"
	New-AzResourceGroup -Name $resourceGroupName -Location $location -Force
	
		
	
	Write-Debug "  Create new Relay namespace"
	Write-Debug " Namespace name : $namespaceName"
	$result = New-AzRelayNamespace -ResourceGroupName $resourceGroupName -Name $namespaceName -Location $location
	Wait-Seconds 15

	Try
	{
		
		Assert-True {$result.ProvisioningState -eq "Succeeded"}

		
		Write-Debug " Get the created namespace within the resource group"
		$returnedNamespace = Get-AzRelayNamespace -ResourceGroupName $resourceGroupName -Name $namespaceName    
		
		Assert-AreEqual $location $returnedNamespace.Location "NameSpace Location Not matched."        
		Assert-True {$returnedNamespace.Name -eq $namespaceName} "Namespace created earlier is not found."
	
		
		Write-Debug "Create new HybridConnections"
		$userMetadata = "User Meta data"
		$result = New-AzRelayHybridConnection -ResourceGroupName $resourceGroupName -Namespace $namespaceName -Name $HybridConnectionsName -RequiresClientAuthorization $True -UserMetadata $userMetadata
	
		
		Write-Debug " Get the created HybridConnections "
		$createdHybridConnections = Get-AzRelayHybridConnection -ResourceGroupName $resourceGroupName -Namespace $namespaceName -Name $HybridConnectionsName
	
		$result2 = Set-AzRelayHybridConnection -ResourceGroupName $resourceGroupName -Namespace $namespaceName -Name $HybridConnectionsName -UserMetadata "Test UserMetdata"

		
		Assert-True {$result2.Name -eq $HybridConnectionsName} "HybridConnections created earlier is not found."

		
		Write-Debug " Get all the created HybridConnections "
		$createdHybridConnectionsList = Get-AzRelayHybridConnection -ResourceGroupName $resourceGroupName -Namespace $namespaceName
		
		
		Assert-True {$createdHybridConnectionsList[0].Name -eq $HybridConnectionsName }"HybridConnections created earlier is not found."
	
		
		Write-Debug " Update HybridConnections "
		$createdHybridConnections.UserMetadata = "usermetadata is a placeholder to store user-defined string data for the HybridConnection endpoint.e.g. it can be used to store  descriptive data, such as list of teams and their contact information also user-defined configuration settings can be stored."	   
		$result1 = Set-AzRelayHybridConnection -ResourceGroupName $resourceGroupName -Namespace $namespaceName -Name $HybridConnectionsName -InputObject $createdHybridConnections
		Wait-Seconds 15
	
		
		Assert-True { $result1.UserMetadata -eq $createdHybridConnections.UserMetadata } "Updated HybridConnections 'RequiresClientAuthorization' not Matched "	
	}
	Finally
	{
		
		
		Write-Debug " Delete the HybridConnections"
		for ($i = 0; $i -lt $createdHybridConnectionsList.Count; $i++)
		{
			$delete1 = Remove-AzRelayHybridConnection -ResourceGroupName $resourceGroupName -Namespace $namespaceName -Name $HybridConnectionsName		
		}
		Write-Debug " Delete namespaces"
		Remove-AzRelayNamespace -ResourceGroupName $resourceGroupName -Name $namespaceName

		Write-Debug " Delete resourcegroup"
		Remove-AzResourceGroup -Name $resourceGroupName -Force
	}
}