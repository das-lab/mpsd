














function Test-NewAzureRmSearchService
{
	
	$rgname = getAssetName
	$loc = Get-Location -providerNamespace "Microsoft.Search" -resourceType "searchServices" -preferredLocation "West US"
	$svcName = $rgname + "-service"
	$sku = "Standard"
	$partitionCount = 1
	$replicaCount = 1
	$hostingMode = "Default"

	try
    {
		New-AzResourceGroup -Name $rgname -Location $loc
		
		
		$newSearchService = New-AzSearchService -ResourceGroupName $rgname -Name $svcName -Sku $sku -Location $loc -PartitionCount $partitionCount -ReplicaCount $replicaCount -HostingMode $hostingMode
		
		
		Assert-NotNull $newSearchService
		Assert-AreEqual $svcName $newSearchService.Name 
		Assert-AreEqual $sku $newSearchService.Sku
		Assert-AreEqual $loc $newSearchService.Location
		Assert-AreEqual $partitionCount $newSearchService.PartitionCount
		Assert-AreEqual $replicaCount $newSearchService.ReplicaCount
		Assert-AreEqual $hostingMode $newSearchService.HostingMode
	}
	finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-NewAzureRmSearchServiceBasic
{
	
	$rgname = getAssetName
	$rgname = $rgname
	$loc = Get-Location -providerNamespace "Microsoft.Search" -resourceType "searchServices" -preferredLocation "West US"
	$svcName = $rgname + "-service"
	$sku = "Basic"
	$partitionCount = 1
	$replicaCount = 1
	$hostingMode = "Default"

	try
    {
		New-AzResourceGroup -Name $rgname -Location $loc
		
		
		$newSearchService = New-AzSearchService -ResourceGroupName $rgname -Name $svcName -Sku $sku -Location $loc -PartitionCount $partitionCount -ReplicaCount $replicaCount -HostingMode $hostingMode
		
		
		Assert-NotNull $newSearchService
		Assert-AreEqual $svcName $newSearchService.Name 
		Assert-AreEqual $sku $newSearchService.Sku
		Assert-AreEqual $loc $newSearchService.Location
		Assert-AreEqual $partitionCount $newSearchService.PartitionCount
		Assert-AreEqual $replicaCount $newSearchService.ReplicaCount
		Assert-AreEqual $hostingMode $newSearchService.HostingMode
	}
	finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-NewAzureRmSearchServiceL1
{
	
	$rgname = getAssetName
	$rgname = $rgname
	$loc = Get-Location -providerNamespace "Microsoft.Search" -resourceType "searchServices" -preferredLocation "West US"
	$svcName = $rgname + "-service"
	$sku = "Storage_Optimized_L1"
	$partitionCount = 1
	$replicaCount = 1
	$hostingMode = "Default"

	try
    {
		New-AzResourceGroup -Name $rgname -Location $loc
		
		
		$newSearchService = New-AzSearchService -ResourceGroupName $rgname -Name $svcName -Sku $sku -Location $loc -PartitionCount $partitionCount -ReplicaCount $replicaCount -HostingMode $hostingMode
		
		
		Assert-NotNull $newSearchService
		Assert-AreEqual $svcName $newSearchService.Name 
		Assert-AreEqual $sku $newSearchService.Sku
		Assert-AreEqual $loc $newSearchService.Location
		Assert-AreEqual $partitionCount $newSearchService.PartitionCount
		Assert-AreEqual $replicaCount $newSearchService.ReplicaCount
		Assert-AreEqual $hostingMode $newSearchService.HostingMode
	}
	finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-GetAzureRmSearchService
{
    
	$rgname = getAssetName
	$loc = Get-Location -providerNamespace "Microsoft.Search" -resourceType "searchServices" -preferredLocation "West US"
	$svcName = $rgname + "-service"
	$sku = "Standard"

	try
    {
		New-AzResourceGroup -Name $rgname -Location $loc
		
		
		$newSearchService = New-AzSearchService -ResourceGroupName $rgname -Name $svcName -Sku $sku -Location $loc

		
		$retrievedSearchService1 = Get-AzSearchService -ResourceGroupName $rgname -Name $svcName

		
		$retrievedSearchService2 = Get-AzSearchService -ResourceId $newSearchService.Id
		
		
		Assert-NotNull $retrievedSearchService1
		Assert-NotNull $retrievedSearchService2

		Assert-AreEqual $newSearchService.Name $retrievedSearchService1.Name
		Assert-AreEqual $newSearchService.Name $retrievedSearchService2.Name

		Assert-AreEqual $newSearchService.Location $retrievedSearchService1.Location
		Assert-AreEqual $newSearchService.Location $retrievedSearchService2.Location

		Assert-AreEqual $sku $newSearchService.Sku
		Assert-AreEqual $newSearchService.Sku $retrievedSearchService1.Sku
		Assert-AreEqual $newSearchService.Sku $retrievedSearchService2.Sku

		
		$svcName2 = $rgname + "-service2"
		$newSearchService2 = New-AzSearchService -ResourceGroupName $rgname -Name $svcName2 -Sku $sku -Location $loc

		
		$allSearchServices = Get-AzSearchService -ResourceGroupName $rgname

		Assert-AreEqual 2 $allSearchServices.Count
	}
	finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-RemoveAzureRmSearchService
{
    
	$rgname = getAssetName
	$loc = Get-Location -providerNamespace "Microsoft.Search" -resourceType "searchServices" -preferredLocation "West US"
	$sku = "Standard"

	try
    {
		New-AzResourceGroup -Name $rgname -Location $loc
		
		
		
		$newSearchService = New-AzSearchService -ResourceGroupName $rgname -Name $($rgname + "-service1") -Sku $sku -Location $loc

		
		$retrievedSvc = Get-AzSearchService -ResourceId $newSearchService.Id
		Assert-NotNull $retrievedSvc

		
		$retrievedSvc | Remove-AzSearchService -Force

		
		$retrievedSvc = Get-AzSearchService -ResourceId $newSearchService.Id
		Assert-Null $retrievedSvc
		
		
		
		$newSearchService = New-AzSearchService -ResourceGroupName $rgname -Name $($rgname + "-service2") -Sku $sku -Location $loc
		
		
		$retrievedSvc = Get-AzSearchService -ResourceId $newSearchService.Id
		Assert-NotNull $retrievedSvc
		
		
		Remove-AzSearchService -ResourceId $retrievedSvc.Id -Force

		
		$retrievedSvc = Get-AzSearchService -ResourceId $newSearchService.Id
		Assert-Null $retrievedSvc

		
		
		$newSearchService = New-AzSearchService -ResourceGroupName $rgname -Name $($rgname + "-service3") -Sku $sku -Location $loc
		
		
		$retrievedSvc = Get-AzSearchService -ResourceId $newSearchService.Id
		Assert-NotNull $retrievedSvc
		
		
		Remove-AzSearchService -ResourceGroupName $rgname -Name $retrievedSvc.Name -Force

		
		$retrievedSvc = Get-AzSearchService -ResourceId $newSearchService.Id
		Assert-Null $retrievedSvc
	}
	finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-SetAzureRmSearchService
{
    
	$rgname = getAssetName
	$loc = Get-Location -providerNamespace "Microsoft.Search" -resourceType "searchServices" -preferredLocation "West US"
	$sku = "Standard"
	$partitionCount = 1
	$replicaCount = 1
	$hostingMode = "Default"

	try
    {
		New-AzResourceGroup -Name $rgname -Location $loc
		
		
		$newSearchService = New-AzSearchService -ResourceGroupName $rgname -Name $($rgname + "-service1") -Sku $sku -Location $loc -PartitionCount $partitionCount -ReplicaCount $replicaCount -HostingMode $hostingMode

		
		$newSearchService | Set-AzSearchService -PartitionCount 2 -ReplicaCount 2

		
		$retrievedSvc = Get-AzSearchService -ResourceId $newSearchService.Id
		Assert-AreEqual 2 $retrievedSvc.PartitionCount
		Assert-AreEqual 2 $retrievedSvc.ReplicaCount

		
		$newSearchService = New-AzSearchService -ResourceGroupName $rgname -Name $($rgname + "-service2") -Sku $sku -Location $loc -PartitionCount $partitionCount -ReplicaCount $replicaCount -HostingMode $hostingMode
		
		
		Set-AzSearchService -ResourceId $newSearchService.Id -PartitionCount 3 -ReplicaCount 3

		
		$retrievedSvc = Get-AzSearchService -ResourceId $newSearchService.Id
		Assert-AreEqual 3 $retrievedSvc.PartitionCount
		Assert-AreEqual 3 $retrievedSvc.ReplicaCount

		
		$newSearchService = New-AzSearchService -ResourceGroupName $rgname -Name $($rgname + "-service3") -Sku $sku -Location $loc -PartitionCount $partitionCount -ReplicaCount $replicaCount -HostingMode $hostingMode

		
		Set-AzSearchService -ResourceGroupName $rgname -Name $newSearchService.Name -PartitionCount 2 -ReplicaCount 2

		
		$retrievedSvc = Get-AzSearchService -ResourceId $newSearchService.Id
		Assert-AreEqual 2 $retrievedSvc.PartitionCount
		Assert-AreEqual 2 $retrievedSvc.ReplicaCount
	}
	finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-ManageAzureRmSearchServiceAdminKey
{
    
	$rgname = getAssetName
	$svcName = $rgname + "-service"
	$loc = Get-Location -providerNamespace "Microsoft.Search" -resourceType "searchServices" -preferredLocation "West US"
	$sku = "Standard"
	$partitionCount = 1
	$replicaCount = 1
	$hostingMode = "Default"

	try
    {
		New-AzResourceGroup -Name $rgname -Location $loc
		
		
		$newSearchService = New-AzSearchService -ResourceGroupName $rgname -Name $svcName -Sku $sku -Location $loc -PartitionCount $partitionCount -ReplicaCount $replicaCount -HostingMode $hostingMode

		
		$adminKeyPair1 = $newSearchService | Get-AzSearchAdminKeyPair
		$adminKeyPair2 = Get-AzSearchAdminKeyPair -ParentResourceId $newSearchService.Id
		$adminKeyPair3 = Get-AzSearchAdminKeyPair -ResourceGroupName $rgname -ServiceName $svcName

		
		Assert-NotNull $adminKeyPair1
		Assert-NotNull $adminKeyPair2
		Assert-NotNull $adminKeyPair3

		Assert-AreEqual $adminKeyPair1.Primary $adminKeyPair2.Primary
		Assert-AreEqual $adminKeyPair2.Primary $adminKeyPair3.Primary

		Assert-AreEqual $adminKeyPair1.Secondary $adminKeyPair2.Secondary
		Assert-AreEqual $adminKeyPair2.Secondary $adminKeyPair3.Secondary

		
		$newKeyPair1 = $newSearchService | New-AzSearchAdminKey -KeyKind Primary -Force
		$newKeyPair2 = New-AzSearchAdminKey -ParentResourceId $newSearchService.Id -KeyKind Secondary -Force
		$newKeyPair3 = New-AzSearchAdminKey -ResourceGroupName $rgname -ServiceName $svcName -KeyKind Primary -Force

		
		Assert-NotNull $newKeyPair1
		Assert-AreNotEqual $newKeyPair1.Primary $adminKeyPair1.Primary
		Assert-AreEqual $newKeyPair1.Secondary $adminKeyPair1.Secondary

		
		Assert-NotNull $newKeyPair2
		Assert-AreEqual $newKeyPair2.Primary $newKeyPair1.Primary
		
		Assert-AreNotEqual $newKeyPair2.Secondary $adminKeyPair1.Secondary
		Assert-AreNotEqual $newKeyPair2.Primary $adminKeyPair1.Primary

		
		Assert-NotNull $newKeyPair3
		Assert-AreEqual $newKeyPair3.Secondary $newKeyPair2.Secondary

		Assert-AreNotEqual $newKeyPair3.Secondary $adminKeyPair3.Secondary
		Assert-AreNotEqual $newKeyPair3.Primary $adminKeyPair3.Primary
	}
	finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-ManageAzureRmSearchServiceQueryKey
{
    
	$rgname = getAssetName
	$svcName = $rgname + "-service"
	$loc = Get-Location -providerNamespace "Microsoft.Search" -resourceType "searchServices" -preferredLocation "West US"
	$sku = "Standard"
	$partitionCount = 1
	$replicaCount = 1
	$hostingMode = "Default"

	try
    {
		New-AzResourceGroup -Name $rgname -Location $loc
		
		
		$newSearchService = New-AzSearchService -ResourceGroupName $rgname -Name $svcName -Sku $sku -Location $loc -PartitionCount $partitionCount -ReplicaCount $replicaCount -HostingMode $hostingMode

		
		$queryKey1 = $newSearchService | Get-AzSearchQueryKey
		$queryKey2 = Get-AzSearchQueryKey -ParentResourceId $newSearchService.Id
		$queryKey3 = Get-AzSearchQueryKey -ResourceGroupName $rgname -ServiceName $svcName

		
		Assert-NotNull $queryKey1
		Assert-NotNull $queryKey2
		Assert-NotNull $queryKey3

		
		Assert-AreEqual 1 $queryKey1.Count
		Assert-AreEqual $queryKey1.Count $queryKey2.Count
		Assert-AreEqual $queryKey2.Count $queryKey3.Count

		Assert-AreEqual $queryKey1[0].Name $queryKey2[0].Name
		Assert-AreEqual $queryKey2[0].Name $queryKey3[0].Name

		Assert-AreEqual $queryKey1[0].Key $queryKey2[0].Key
		Assert-AreEqual $queryKey2[0].Key $queryKey3[0].Key

		
		$newQueryKey1 = $newSearchService | New-AzSearchQueryKey -Name "newquerykey1"
		$newQueryKey2 = New-AzSearchQueryKey -ParentResourceId $newSearchService.Id -Name "newquerykey2"
		$newQueryKey3 = New-AzSearchQueryKey -ResourceGroupName $rgname -ServiceName $svcName -Name "newquerykey3"

		$allKeys = Get-AzSearchQueryKey -ParentResourceId $newSearchService.Id
		
		Assert-AreEqual 4 $allKeys.Count

		
		$newSearchService | Remove-AzSearchQueryKey -KeyValue $newQueryKey1.Key -Force
		Remove-AzSearchQueryKey -ParentResourceId $newSearchService.Id -KeyValue $newQueryKey2.Key -Force
		Remove-AzSearchQueryKey -ResourceGroupName $rgname -ServiceName $svcName -KeyValue $newQueryKey3.Key -Force

		$allKeys = Get-AzSearchQueryKey -ParentResourceId $newSearchService.Id

		Assert-AreEqual 1 $allKeys.Count
	}
	finally
    {
        
        Clean-ResourceGroup $rgname
    }
}