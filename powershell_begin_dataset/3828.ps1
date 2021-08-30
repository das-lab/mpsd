














function WcfRelayTests
{
	
	$location = "West US"
	$resourceGroupName = getAssetName
	$namespaceName = getAssetName "Relay-NS"
	$wcfRelayName = getAssetName "Relay-WcfR"

	
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
	
		
		Write-Debug "Create new WcfRelay"    
		$wcfRelayType = "NetTcp"
		$userMetadata = "User Meta data"
		$result = New-AzWcfRelay -ResourceGroupName $resourceGroupName -Namespace $namespaceName -Name $wcfRelayName -WcfRelayType $wcfRelayType  -RequiresClientAuthorization $True -RequiresTransportSecurity $True -UserMetadata $userMetadata
	
		
		Write-Debug " Get the created WcfRelay "
		$createdWcfRelay = Get-AzWcfRelay -ResourceGroupName $resourceGroupName -Namespace $namespaceName -Name $wcfRelayName

		
		Assert-True {$createdWcfRelay.Name -eq $wcfRelayName} "WcfRelay created earlier is not found."

		
		Write-Debug " Get all the created WcfRelay "
		$createdWcfRelayList = Get-AzWcfRelay -ResourceGroupName $resourceGroupName -Namespace $namespaceName
		
		
		Assert-True {$createdWcfRelayList[0].Name -eq $wcfRelayName }"WcfRelay created earlier is not found."

		
		$result2 = Set-AzWcfRelay -ResourceGroupName $resourceGroupName -Namespace $namespaceName -Name $wcfRelayName -UserMetadata "usermetadata is a placeholder to store user-defined string data for the HybridConnection endpoint.e.g. it can be used to store  descriptive data, such as list of teams and their contact information also user-defined configuration settings can be stored."

		
		Write-Debug " Update the first WcfRelay "
		$createdWcfRelay.UserMetadata = "usermetadata is a placeholder to store user-defined string data for the HybridConnection endpoint.e.g. it can be used to store  descriptive data, such as list of teams and their contact information also user-defined configuration settings can be stored."	   
		$result1 = Set-AzWcfRelay -ResourceGroupName $resourceGroupName -Namespace $namespaceName -Name $wcfRelayName -InputObject $createdWcfRelay
		Wait-Seconds 15
	
		
		Assert-True { $result1.RequiresClientAuthorization -eq $createdWcfRelay.RequiresClientAuthorization } "Updated WCFRelay 'RequiresClientAuthorization' not Matched "
	
		
		
		Write-Debug " Delete the WcfRelay"
		for ($i = 0; $i -lt $createdWcfRelayList.Count; $i++)
		{
			$delete1 = Remove-AzWcfRelay -ResourceGroupName $resourceGroupName -Namespace $namespaceName -Name $wcfRelayName		
		}
	}
	Finally
	{
		Write-Debug " Delete namespaces"
		Remove-AzRelayNamespace -ResourceGroupName $resourceGroupName -Name $namespaceName

		Write-Debug " Delete resourcegroup"
		Remove-AzResourceGroup -Name $resourceGroupName -Force
	}	
}