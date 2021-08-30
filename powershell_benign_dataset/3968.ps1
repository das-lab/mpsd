














function Test-EmptyRouteTable
{
    
    $rgname = Get-ResourceGroupName
    $routeTableName = Get-ResourceName
    $rglocation = Get-ProviderLocation ResourceManagement
    $resourceTypeParent = "Microsoft.Network/routeTables"
    $location = Get-ProviderLocation $resourceTypeParent
    
    try 
    {
        
        $resourceGroup = New-AzResourceGroup -Name $rgname -Location $rglocation -Tags @{ testtag = "testval" } 
        
        
        $job = New-AzRouteTable -name $routeTableName -ResourceGroupName $rgname -Location $location -AsJob
		$job | Wait-Job
		$rt = $job | Receive-Job

        
        $getRT = Get-AzRouteTable -name $routeTableName -ResourceGroupName $rgName
        
        
        Assert-AreEqual $rgName $getRT.ResourceGroupName
        Assert-AreEqual $routeTableName $getRT.Name
        Assert-NotNull $getRT.Etag
        Assert-AreEqual 0 @($getRT.Routes).Count        

        
        $list = Get-AzRouteTable -ResourceGroupName $rgname
        Assert-AreEqual 1 @($list).Count
        Assert-AreEqual $list[0].ResourceGroupName $getRT.ResourceGroupName
        Assert-AreEqual $list[0].Name $getRT.Name
        Assert-AreEqual $list[0].Etag $getRT.Etag
        Assert-AreEqual @($list[0].Routes).Count @($getRT.Routes).Count     
		
        $list = Get-AzRouteTable -ResourceGroupName "*"
        Assert-True { $list.Count -ge 0 }

        $list = Get-AzRouteTable -Name "*"
        Assert-True { $list.Count -ge 0 }

        $list = Get-AzRouteTable -ResourceGroupName "*" -Name "*"
        Assert-True { $list.Count -ge 0 }

        
        $job = Remove-AzRouteTable -ResourceGroupName $rgname -name $routeTableName -PassThru -Force -AsJob
		$job | Wait-Job
		$delete = $job | Receive-Job
        Assert-AreEqual true $delete
        
        $list = Get-AzRouteTable -ResourceGroupName $rgname
        Assert-AreEqual 0 @($list).Count
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-RouteTableCRUD
{
    
    $rgname = Get-ResourceGroupName
    $routeTableName = Get-ResourceName
    $domainNameLabel = Get-ResourceName
    $rglocation = Get-ProviderLocation ResourceManagement
    $resourceTypeParent = "Microsoft.Network/routeTables"
    $location = Get-ProviderLocation $resourceTypeParent
    
    try 
    {
        
        $resourceGroup = New-AzResourceGroup -Name $rgname -Location $rglocation -Tags @{ testtag = "testval" } 
        
		$route1 = New-AzRouteConfig -name "route1" -AddressPrefix "192.168.1.0/24" -NextHopIpAddress "23.108.1.1" -NextHopType "VirtualAppliance"
		        
        
        $rt = New-AzRouteTable -name $routeTableName -ResourceGroupName $rgname -Location $location -Route $route1

		
        $getRT = Get-AzRouteTable -name $routeTableName -ResourceGroupName $rgName

		
        Assert-AreEqual $rgName $getRT.ResourceGroupName
        Assert-AreEqual $routeTableName $getRT.Name
        Assert-NotNull $getRT.Etag
        Assert-AreEqual 1 @($getRT.Routes).Count       
		Assert-AreEqual $getRT.Routes[0].Name "route1"
		Assert-AreEqual $getRT.Routes[0].AddressPrefix "192.168.1.0/24"
		Assert-AreEqual $getRT.Routes[0].NextHopIpAddress "23.108.1.1"
		Assert-AreEqual $getRT.Routes[0].NextHopType "VirtualAppliance"
		Assert-NotNull $getRT.Routes[0].Etag

		
        $list = Get-AzRouteTable -ResourceGroupName $rgname
        Assert-AreEqual 1 @($list).Count
        Assert-AreEqual $list[0].ResourceGroupName $getRT.ResourceGroupName
        Assert-AreEqual $list[0].Name $getRT.Name
        Assert-AreEqual $list[0].Etag $getRT.Etag
        Assert-AreEqual @($list[0].Routes).Count @($getRT.Routes).Count
		Assert-AreEqual $list[0].Routes[0].Etag $getRT.Routes[0].Etag  

		$route2 = New-AzRouteConfig -name "route2" -AddressPrefix "192.168.2.0/24" -NextHopType "VnetLocal"

		
		$getRT = New-AzRouteTable -name $routeTableName -ResourceGroupName $rgname -Location $location -Route $route1,$route2 -Force

		
        Assert-AreEqual $rgName $getRT.ResourceGroupName
        Assert-AreEqual $routeTableName $getRT.Name
        Assert-NotNull $getRT.Etag
        Assert-AreEqual 2 @($getRT.Routes).Count       
		Assert-AreEqual $getRT.Routes[0].Name "route1"
		Assert-AreEqual $getRT.Routes[1].Name "route2"
		Assert-AreEqual $getRT.Routes[1].AddressPrefix "192.168.2.0/24"
		Assert-null $getRT.Routes[1].NextHopIpAddress
		Assert-AreEqual $getRT.Routes[1].NextHopType "VnetLocal"
		Assert-NotNull $getRT.Routes[1].Etag

		
		$getRT = New-AzRouteTable -name $routeTableName -ResourceGroupName $rgname -Location $location -Route $route2 -Force

		Assert-AreEqual $rgName $getRT.ResourceGroupName
        Assert-AreEqual $routeTableName $getRT.Name
        Assert-NotNull $getRT.Etag
        Assert-AreEqual 1 @($getRT.Routes).Count       
		Assert-AreEqual $getRT.Routes[0].Name "route2"		

		
        $delete = Remove-AzRouteTable -ResourceGroupName $rgname -name $routeTableName -PassThru -Force
        Assert-AreEqual true $delete
        
        $list = Get-AzRouteTable -ResourceGroupName $rgname
        Assert-AreEqual 0 @($list).Count
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-RouteTableSubnetRef
{
    
    $rgname = Get-ResourceGroupName
    $routeTableName = Get-ResourceName
	$vnetName = Get-ResourceName
    $subnetName = Get-ResourceName
    $domainNameLabel = Get-ResourceName
    $rglocation = Get-ProviderLocation ResourceManagement
    $resourceTypeParent = "Microsoft.Network/routeTables"
    $location = Get-ProviderLocation $resourceTypeParent
    
    try 
    {
        
        $resourceGroup = New-AzResourceGroup -Name $rgname -Location $rglocation -Tags @{ testtag = "testval" } 
        
		$route1 = New-AzRouteConfig -name "route1" -AddressPrefix "192.168.1.0/24" -NextHopIpAddress "23.108.1.1" -NextHopType "VirtualAppliance"
		        
        
        $rt = New-AzRouteTable -name $routeTableName -ResourceGroupName $rgname -Location $location -Route $route1

		
        $getRT = Get-AzRouteTable -name $routeTableName -ResourceGroupName $rgName

		
        Assert-AreEqual $rgName $getRT.ResourceGroupName
        Assert-AreEqual $routeTableName $getRT.Name
        Assert-NotNull $getRT.Etag
        Assert-AreEqual 1 @($getRT.Routes).Count       
		Assert-AreEqual $getRT.Routes[0].Name "route1"
	
		
		
        $subnet = New-AzVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix 10.0.1.0/24 -RouteTable $getRT
        $vnet = New-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgname -Location $location -AddressPrefix 10.0.0.0/16 -DnsServer 8.8.8.8 -Subnet $subnet
		
		
		Assert-AreEqual $vnet.Subnets[0].RouteTable.Id $getRT.Id

		
		$getRT = Get-AzRouteTable -name $routeTableName -ResourceGroupName $rgName
		Assert-AreEqual 1 @($getRT.Subnets).Count       
		Assert-AreEqual $vnet.Subnets[0].Id $getRT.Subnets[0].Id		
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-RouteTableRouteCRUD
{
    
    $rgname = Get-ResourceGroupName
    $routeTableName = Get-ResourceName
	$vnetName = Get-ResourceName
    $subnetName = Get-ResourceName
    $domainNameLabel = Get-ResourceName
    $rglocation = Get-ProviderLocation ResourceManagement
    $resourceTypeParent = "Microsoft.Network/routeTables"
    $location = Get-ProviderLocation $resourceTypeParent
    
    try 
    {
        
        $resourceGroup = New-AzResourceGroup -Name $rgname -Location $rglocation -Tags @{ testtag = "testval" } 
        
		$route1 = New-AzRouteConfig -name "route1" -AddressPrefix "192.168.1.0/24" -NextHopIpAddress "23.108.1.1" -NextHopType "VirtualAppliance"
		        
        
        $rt = New-AzRouteTable -name $routeTableName -ResourceGroupName $rgname -Location $location -Route $route1

		
        $getRT = Get-AzRouteTable -name $routeTableName -ResourceGroupName $rgName

		
        Assert-AreEqual $rgName $getRT.ResourceGroupName
        Assert-AreEqual $routeTableName $getRT.Name
        Assert-NotNull $getRT.Etag
        Assert-AreEqual 1 @($getRT.Routes).Count       
		Assert-AreEqual $getRT.Routes[0].Name "route1"
		
		
		$route = $getRT | Get-AzRouteConfig -name "route1"
		Assert-AreEqual $route.Name "route1"
		Assert-AreEqual $getRT.Routes[0].Name $route.Name
		Assert-AreEqual $getRT.Routes[0].AddressPrefix $route.AddressPrefix
		Assert-AreEqual $getRT.Routes[0].NextHopType $route.NextHopType
		Assert-AreEqual $getRT.Routes[0].NextHopIpAddress $route.NextHopIpAddress

		
		$job = Get-AzRouteTable -name $routeTableName -ResourceGroupName $rgName | Add-AzRouteConfig -name "route2" -AddressPrefix "192.168.2.0/24" -NextHopType "VnetLocal" | Set-AzRouteTable -AsJob
		$job | Wait-Job
		$getRT = $job | Receive-Job

		
		$route = $getRT | Get-AzRouteConfig -name "route2"

		
        Assert-AreEqual 2 @($getRT.Routes).Count       
		Assert-AreEqual $route.Name "route2"
		Assert-AreEqual $getRT.Routes[1].Name $route.Name
		Assert-AreEqual $getRT.Routes[1].AddressPrefix $route.AddressPrefix
		Assert-AreEqual $route.AddressPrefix "192.168.2.0/24"
		Assert-AreEqual $getRT.Routes[1].NextHopType $route.NextHopType
		Assert-AreEqual $route.NextHopType "VnetLocal"
		Assert-Null $route.NextHopIpAddress
		Assert-Null $getRT.Routes[1].NextHopIpAddress

		
		$list = $getRT | Get-AzRouteConfig
		Assert-AreEqual 2 @($list).Count       
		Assert-AreEqual $list[1].Name "route2"
		Assert-AreEqual $list[1].Name $route.Name
		Assert-AreEqual $list[1].AddressPrefix $route.AddressPrefix
		Assert-AreEqual $list[1].NextHopType $route.NextHopType
		Assert-Null $list[1].NextHopIpAddress

		
		$getRT = Get-AzRouteTable -name $routeTableName -ResourceGroupName $rgName | Set-AzRouteConfig -name "route2" -AddressPrefix "192.168.3.0/24" -NextHopType "VnetLocal" | Set-AzRouteTable

		
		$route = $getRT | Get-AzRouteConfig -name "route2"

		
        Assert-AreEqual 2 @($getRT.Routes).Count       
		Assert-AreEqual $route.Name "route2"
		Assert-AreEqual $getRT.Routes[1].Name $route.Name
		Assert-AreEqual $route.AddressPrefix "192.168.3.0/24"
		Assert-AreEqual $getRT.Routes[1].AddressPrefix $route.AddressPrefix
		Assert-AreEqual $getRT.Routes[1].NextHopType $route.NextHopType
		Assert-Null $route.NextHopIpAddress
		Assert-Null $getRT.Routes[1].NextHopIpAddress

		
		$getRT = Get-AzRouteTable -name $routeTableName -ResourceGroupName $rgName | Remove-AzRouteConfig -name "route1" | Set-AzRouteTable

		
		$list = $getRT | Get-AzRouteConfig
		Assert-AreEqual 1 @($list).Count       
		Assert-AreEqual $list[0].Name "route2"

		
        $delete = Remove-AzRouteTable -ResourceGroupName $rgname -name $routeTableName -PassThru -Force
        Assert-AreEqual true $delete
        
        $list = Get-AzRouteTable -ResourceGroupName $rgname
        Assert-AreEqual 0 @($list).Count
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-RouteHopTypeTest
{
    
    $rgname = Get-ResourceGroupName
    $routeTableName = Get-ResourceName
	$vnetName = Get-ResourceName
    $subnetName = Get-ResourceName
    $domainNameLabel = Get-ResourceName
    $rglocation = Get-ProviderLocation ResourceManagement
    $resourceTypeParent = "Microsoft.Network/routeTables"
    $location = Get-ProviderLocation $resourceTypeParent
    
    try 
    {
        
        $resourceGroup = New-AzResourceGroup -Name $rgname -Location $rglocation -Tags @{ testtag = "testval" } 
        
		$route1 = New-AzRouteConfig -name "route1" -AddressPrefix "192.168.1.0/24" -NextHopIpAddress "23.108.1.1" -NextHopType "VirtualAppliance"
		$route2 = New-AzRouteConfig -name "route2" -AddressPrefix "10.0.1.0/24" -NextHopType "VnetLocal"
		$route3 = New-AzRouteConfig -name "route3" -AddressPrefix "0.0.0.0/0" -NextHopType "Internet"
		$route4 = New-AzRouteConfig -name "route4" -AddressPrefix "10.0.2.0/24" -NextHopType "None"
		        
        
        $rt = New-AzRouteTable -name $routeTableName -ResourceGroupName $rgname -Location $location -Route $route1, $route2, $route3, $route4

		
        $getRT = Get-AzRouteTable -name $routeTableName -ResourceGroupName $rgName

		
        Assert-AreEqual $rgName $getRT.ResourceGroupName
        Assert-AreEqual $routeTableName $getRT.Name
        Assert-NotNull $getRT.Etag
        Assert-AreEqual 4 @($getRT.Routes).Count       
		Assert-AreEqual $getRT.Routes[0].Name "route1"
		Assert-AreEqual $getRT.Routes[0].NextHopType "VirtualAppliance"
		Assert-AreEqual $getRT.Routes[1].Name "route2"
		Assert-AreEqual $getRT.Routes[1].NextHopType "VnetLocal"
		Assert-AreEqual $getRT.Routes[2].Name "route3"
		Assert-AreEqual $getRT.Routes[2].NextHopType "Internet"
		Assert-AreEqual $getRT.Routes[3].Name "route4"
		Assert-AreEqual $getRT.Routes[3].NextHopType "None"
		
		
        $delete = Remove-AzRouteTable -ResourceGroupName $rgname -name $routeTableName -PassThru -Force
        Assert-AreEqual true $delete
        
        $list = Get-AzRouteTable -ResourceGroupName $rgname
        Assert-AreEqual 0 @($list).Count
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-RouteTableWithDisableBgpRoutePropagation
{
    
    $rgname = Get-ResourceGroupName
    $routeTableName = Get-ResourceName
    $rglocation = Get-ProviderLocation ResourceManagement
    $resourceTypeParent = "Microsoft.Network/routeTables"
    $location = Get-ProviderLocation $resourceTypeParent
    
    try 
    {
        
        $resourceGroup = New-AzResourceGroup -Name $rgname -Location $rglocation -Tags @{ testtag = "testval" } 
        
        
        $rt = New-AzRouteTable -name $routeTableName -DisableBgpRoutePropagation -ResourceGroupName $rgname -Location $location

        
        $getRT = Get-AzRouteTable -name $routeTableName -ResourceGroupName $rgName
        
        
        Assert-AreEqual $rgName $getRT.ResourceGroupName
        Assert-AreEqual $routeTableName $getRT.Name
		Assert-AreEqual true $getRt.DisableBGProutepropagation
        Assert-NotNull $getRT.Etag
        Assert-AreEqual 0 @($getRT.Routes).Count        

        
        $list = Get-AzRouteTable -ResourceGroupName $rgname
        Assert-AreEqual 1 @($list).Count
        Assert-AreEqual $list[0].ResourceGroupName $getRT.ResourceGroupName
        Assert-AreEqual $list[0].Name $getRT.Name
        Assert-AreEqual $list[0].DisableBGProutepropagation $getRT.DisableBGProutepropagation
        Assert-AreEqual $list[0].Etag $getRT.Etag
        Assert-AreEqual @($list[0].Routes).Count @($getRT.Routes).Count
		
        
        $delete = Remove-AzRouteTable -ResourceGroupName $rgname -name $routeTableName -PassThru -Force
        Assert-AreEqual true $delete
        
        $list = Get-AzRouteTable -ResourceGroupName $rgname
        Assert-AreEqual 0 @($list).Count
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}