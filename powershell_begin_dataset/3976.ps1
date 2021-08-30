














function Test-VirtualHubRouteTableCRUD
{
    
    $rgName = Get-ResourceGroupName
    $rglocation = Get-ProviderLocation "ResourceManagement" "westcentralus"

    $virtualWanName = Get-ResourceName
    $virtualHubName = Get-ResourceName
    $expressRouteGatewayName = Get-ResourceName
	$routeTable1Name = Get-ResourceName
	$remoteVirtualNetworkName = Get-ResourceName

    try
    {
        
        $resourceGroup = New-AzureRmResourceGroup -Name $rgName -Location $rglocation

        
        $createdVirtualWan = New-AzureRmVirtualWan -ResourceGroupName $rgName -Name $virtualWanName -Location $rglocation -AllowVnetToVnetTraffic -AllowBranchToBranchTraffic
        $virtualWan = Get-AzureRmVirtualWan -ResourceGroupName $rgName -Name $virtualWanName
        Write-Debug "Created Virtual WAN $virtualWan.Name successfully"

		
        $createdVirtualHub = New-AzureRmVirtualHub -ResourceGroupName $rgName -Name $virtualHubName -Location $rglocation -AddressPrefix "10.8.0.0/24" -VirtualWan $virtualWan
        $virtualHub = Get-AzureRmVirtualHub -ResourceGroupName $rgName -Name $virtualHubName
        Write-Debug "Created Virtual Hub virtualHub.Name successfully"

        
        $createdExpressRouteGateway = New-AzureRmExpressRouteGateway -ResourceGroupName $rgName -Name $expressRouteGatewayName -VirtualHub $virtualHub -MinScaleUnits 2
        Write-Debug "Created ExpressRoute Gateway $expressRouteGatewayName successfully"
        $expressRouteGateway = Get-AzureRmExpressRouteGateway -ResourceGroupName $rgName -Name $expressRouteGatewayName
        Assert-NotNull $expressRouteGateway
        Write-Debug "Retrieved ExpressRoute Gateway $expressRouteGatewayName successfully"

		
		$route1 = Add-AzVirtualHubRoute -DestinationType "CIDR" -Destination @("10.4.0.0/16", "10.5.0.0/16") -NextHopType "IPAddress" -NextHop @("10.0.0.68")
		$route2 = Add-AzVirtualHubRoute -DestinationType "CIDR" -Destination @("0.0.0.0/0") -NextHopType "IPAddress" -NextHop @("10.0.0.68")
    	$routeTable1 = Add-AzVirtualHubRouteTable -Route @($route1, $route2) -Connection @("All_Vnets") -Name $routeTable1Name
		Set-AzVirtualHub -ResourceGroupName $rgName -Name $virtualHubName -RouteTable @($routeTable1)
		$virtualHub = Get-AzVirtualHub -ResourceGroupName $rgName -Name $virtualHubName
		Assert-AreEqual $virtualHubName $virtualHub.Name
		$routeTables = $virtualHub.RouteTables
		Assert-AreEqual 1 @($routeTables).Count
		$routes1 = $routeTables[0].Routes
		Assert-AreEqual 2 @($routes1).Count

		
		$routeTable1 = Get-AzVirtualHubRouteTable -ResourceGroupName $rgName -HubName $virtualHubName -Name $routeTable1Name
		$routeTable1.Routes.RemoveAt(1)
		$routeTable1.Routes[0].NextHops = @("10.0.0.67")
		$routeTable1.Connections = @("All_Branches")
		Set-AzVirtualHub -ResourceGroupName $rgName -Name $virtualHubName -RouteTable @($routeTable1)
		$virtualHub = Get-AzVirtualHub -ResourceGroupName $rgName -Name $virtualHubName
		Assert-AreEqual $virtualHubName $virtualHub.Name
		$routeTables = $virtualHub.RouteTables
		Assert-AreEqual 1 @($routeTables).Count
		$routes1 = $routeTables[0].Routes
		Assert-AreEqual 1 @($routes1).Count

		
		Remove-AzVirtualHubRouteTable -ResourceGroupName $rgName -HubName $virtualHubName -Name $routeTable1Name -Force
		$virtualHub = Get-AzVirtualHub -ResourceGroupName $rgName -Name $virtualHubName
		Assert-AreEqual $virtualHubName $virtualHub.Name
		$routeTables = $virtualHub.RouteTables
		Assert-AreEqual 0 @($routeTables).Count
		
        
        Remove-AzureRmExpressRouteGateway -ResourceGroupName $rgName -Name $expressRouteGatewayName -Force
        Assert-ThrowsLike { Get-AzureRmExpressRouteGateway -ResourceGroupName $rgName -Name $expressRouteGatewayName } "*Not*Found*"

        Remove-AzureRmVirtualHub -ResourceGroupName $rgName -Name $virtualHubName -Force

        Remove-AzureRmVirtualWan -ResourceGroupName $rgName -Name $virtualWanName -Force
        Assert-ThrowsLike { Get-AzureRmVirtualWan -ResourceGroupName $rgName -Name $virtualWanName } "*Not*Found*"
    }
    finally
    {
        Clean-ResourceGroup $rgname
    }
}