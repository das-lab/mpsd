















function Get-TestResourcesDeployment([string]$rgn)
{
    $virtualMachineName = Get-NrpResourceName
    $storageAccountName = Get-NrpResourceName
    $routeTableName = Get-NrpResourceName
    $virtualNetworkName = Get-NrpResourceName
    $networkInterfaceName = Get-NrpResourceName
    $networkSecurityGroupName = Get-NrpResourceName
    $diagnosticsStorageAccountName = Get-NrpResourceName
    
        $paramFile = (Resolve-Path ".\TestData\DeploymentParameters.json").Path
        $paramContent =
@"
{
            "rgName": {
            "value": "$rgn"
            },
            "location": {
            "value": "$location"
            },
            "virtualMachineName": {
            "value": "$virtualMachineName"
            },
            "virtualMachineSize": {
            "value": "Standard_A4"
            },
            "adminUsername": {
            "value": "netanaytics12"
            },
            "storageAccountName": {
            "value": "$storageAccountName"
            },
            "routeTableName": {
            "value": "$routeTableName"
            },
            "virtualNetworkName": {
            "value": "$virtualNetworkName"
            },
            "networkInterfaceName": {
            "value": "$networkInterfaceName"
            },
            "networkSecurityGroupName": {
            "value": "$networkSecurityGroupName"
            },
            "adminPassword": {
            "value": "netanalytics-32${resourceGroupName}"
            },
            "storageAccountType": {
            "value": "Standard_LRS"
            },
            "diagnosticsStorageAccountName": {
            "value": "$diagnosticsStorageAccountName"
            },
            "diagnosticsStorageAccountId": {
            "value": "Microsoft.Storage/storageAccounts/${diagnosticsStorageAccountName}"
            },
            "diagnosticsStorageAccountType": {
            "value": "Standard_LRS"
            },
            "addressPrefix": {
            "value": "10.17.3.0/24"
            },
            "subnetName": {
            "value": "default"
            },
            "subnetPrefix": {
            "value": "10.17.3.0/24"
            },
            "publicIpAddressName": {
            "value": "${virtualMachineName}-ip"
            },
            "publicIpAddressType": {
            "value": "Dynamic"
            }
}
"@;

        $st = Set-Content -Path $paramFile -Value $paramContent -Force;
        New-AzResourceGroupDeployment  -Name "${rgn}" -ResourceGroupName "$rgn" -TemplateFile "$templateFile" -TemplateParameterFile $paramFile
}

function Get-NrpResourceName
{
	Get-ResourceName "psnrp";
}

function Get-NrpResourceGroupName
{
	Get-ResourceGroupName "psnrp";
}

function Wait-Vm($vm)
{
    
    $minutes = 30;
    while((Get-AzVM -ResourceGroupName $vm.ResourceGroupName -Name $vm.Name).ProvisioningState -ne "Succeeded")
    {
        Start-TestSleep 60;
        if(--$minutes -eq 0)
        {
            break;
        }
    }
}


function Get-CreateTestNetworkWatcher($location, $nwName, $nwRgName)
{
    $nw = $null
    $canonicalLocation = Normalize-Location $location

    
    $nwlist = Get-AzNetworkWatcher
    foreach ($i in $nwlist)
    {
        if($i.Location -eq $canonicalLocation)
        {
            $nw = $i
            break
        }
    }

    
    if(!$nw)
    {
        $nw = New-AzNetworkWatcher -Name $nwName -ResourceGroupName $nwRgName -Location $location
    }

    return $nw
}

function Get-CanaryLocation
{
    Get-ProviderLocation "Microsoft.Network/networkWatchers" "Central US EUAP";
}

function Get-PilotLocation
{
    Get-ProviderLocation "Microsoft.Network/networkWatchers" "West Central US";
}


function Test-GetTopology
{
    
    $resourceGroupName = Get-NrpResourceGroupName
    $nwName = Get-NrpResourceName
    $nwRgName = Get-NrpResourceGroupName
    $templateFile = (Resolve-Path ".\TestData\Deployment.json").Path
    $location = Get-ProviderLocation "Microsoft.Network/networkWatchers" "East US"

    try 
    {
        . ".\AzureRM.Resources.ps1"

        
        New-AzResourceGroup -Name $resourceGroupName -Location "$location"
        
        
        Get-TestResourcesDeployment -rgn "$resourceGroupName"
        
		
        New-AzResourceGroup -Name $nwRgName -Location "$location"
        
        
		$nw = Get-CreateTestNetworkWatcher -location $location -nwName $nwName -nwRgName $nwRgName

        
        $topology = Get-AzNetworkWatcherTopology -NetworkWatcher $nw -TargetResourceGroupName $resourceGroupName

        
        $vm = Get-AzVM -ResourceGroupName $resourceGroupName

        
        $nic = Get-AzNetworkInterface -ResourceGroupName $resourceGroupName
    }
    finally
    {
        
        Clean-ResourceGroup $resourceGroupName
        Clean-ResourceGroup $nwRgName
    }
}


function Test-GetSecurityGroupView
{ 
    
    $resourceGroupName = Get-NrpResourceGroupName
    $nwName = Get-NrpResourceName
    $location = Get-PilotLocation
    $resourceTypeParent = "Microsoft.Network/networkWatchers"
    $nwLocation = Get-ProviderLocation $resourceTypeParent
    $nwRgName = Get-NrpResourceGroupName
    $securityRuleName = Get-NrpResourceName
    $templateFile = (Resolve-Path ".\TestData\Deployment.json").Path
    
    try 
    {
        . ".\AzureRM.Resources.ps1"

        
        New-AzResourceGroup -Name $resourceGroupName -Location "$location"

        
        Get-TestResourcesDeployment -rgn "$resourceGroupName"
        
        
        New-AzResourceGroup -Name $nwRgName -Location "$location"
        
        
		$nw = Get-CreateTestNetworkWatcher -location $location -nwName $nwName -nwRgName $nwRgName
        
        
        $vm = Get-AzVM -ResourceGroupName $resourceGroupName
        
        
        $nsg = Get-AzNetworkSecurityGroup -ResourceGroupName $resourceGroupName
        
        
        $nsg[0] | Add-AzNetworkSecurityRuleConfig -Name scr1 -Description "test" -Protocol Tcp -SourcePortRange * -DestinationPortRange 80 -SourceAddressPrefix * -DestinationAddressPrefix * -Access Deny -Priority 122 -Direction Outbound
        $nsg[0] | Set-AzNetworkSecurityGroup

        Wait-Seconds 300

        
        $job = Get-AzNetworkWatcherSecurityGroupView -NetworkWatcher $nw -Target $vm.Id -AsJob
        $job | Wait-Job
        $nsgView = $job | Receive-Job

        
        Assert-AreEqual $nsgView.NetworkInterfaces[0].EffectiveSecurityRules[4].Access Deny 
        Assert-AreEqual $nsgView.NetworkInterfaces[0].EffectiveSecurityRules[4].DestinationPortRange 80-80 
        Assert-AreEqual $nsgView.NetworkInterfaces[0].EffectiveSecurityRules[4].Direction Outbound 
        Assert-AreEqual $nsgView.NetworkInterfaces[0].EffectiveSecurityRules[4].Name UserRule_scr1 
        Assert-AreEqual $nsgView.NetworkInterfaces[0].EffectiveSecurityRules[4].Protocol TCP 
        Assert-AreEqual $nsgView.NetworkInterfaces[0].EffectiveSecurityRules[4].Priority 122 
    }
    finally
    {
        
        Clean-ResourceGroup $resourceGroupName
        Clean-ResourceGroup $nwRgName
    }
}


function Test-GetNextHop
{
    
    $resourceGroupName = Get-NrpResourceGroupName
    $nwName = Get-NrpResourceName
    $nwRgName = Get-NrpResourceGroupName
    $securityRuleName = Get-NrpResourceName
    $templateFile = (Resolve-Path ".\TestData\Deployment.json").Path
    $location = Get-ProviderLocation "Microsoft.Network/networkWatchers" "East US"
    
    try 
    {
        . ".\AzureRM.Resources.ps1"

        
        New-AzResourceGroup -Name $resourceGroupName -Location "$location"

        
        Get-TestResourcesDeployment -rgn "$resourceGroupName"
        
        
        New-AzResourceGroup -Name $nwRgName -Location "$location"
        
        
		$nw = Get-CreateTestNetworkWatcher -location $location -nwName $nwName -nwRgName $nwRgName
        
        
        $vm = Get-AzVM -ResourceGroupName $resourceGroupName
        
        
        $address = Get-AzPublicIpAddress -ResourceGroupName $resourceGroupName

        
        $job = Get-AzNetworkWatcherNextHop -NetworkWatcher $nw -TargetVirtualMachineId $vm.Id -DestinationIPAddress 10.1.3.6 -SourceIPAddress $address.IpAddress -AsJob
        $job | Wait-Job
        $nextHop1 = $job | Receive-Job
        $nextHop2 = Get-AzNetworkWatcherNextHop -NetworkWatcher $nw -TargetVirtualMachineId $vm.Id -DestinationIPAddress 12.11.12.14 -SourceIPAddress $address.IpAddress
    
        
        Assert-AreEqual $nextHop1.NextHopType None
        Assert-AreEqual $nextHop1.NextHopIpAddress 10.0.1.2
        Assert-AreEqual $nextHop2.NextHopType Internet
        Assert-AreEqual $nextHop2.RouteTableId "System Route"
    }
    finally
    {
        
        Clean-ResourceGroup $resourceGroupName
        Clean-ResourceGroup $nwRgName
    }
}


function Test-VerifyIPFlow
{
    
    $resourceGroupName = Get-NrpResourceGroupName
    $nwName = Get-NrpResourceName
    $nwRgName = Get-NrpResourceGroupName
    $securityGroupName = Get-NrpResourceName
    $templateFile = (Resolve-Path ".\TestData\Deployment.json").Path
    $location = Get-ProviderLocation "Microsoft.Network/networkWatchers" "East US"
    
    try 
    {
        . ".\AzureRM.Resources.ps1"

        
        New-AzResourceGroup -Name $resourceGroupName -Location "$location"

        
        Get-TestResourcesDeployment -rgn "$resourceGroupName"
        
        
        New-AzResourceGroup -Name $nwRgName -Location "$location"
        
        
		$nw = Get-CreateTestNetworkWatcher -location $location -nwName $nwName -nwRgName $nwRgName
        
        
        $nsg = Get-AzNetworkSecurityGroup -ResourceGroupName $resourceGroupName

        
        $nsg[0] | Add-AzNetworkSecurityRuleConfig -Name scr1 -Description "test1" -Protocol Tcp -SourcePortRange * -DestinationPortRange 80 -SourceAddressPrefix * -DestinationAddressPrefix * -Access Deny -Priority 122 -Direction Outbound
        $nsg[0] | Set-AzNetworkSecurityGroup

        $nsg[0] | Add-AzNetworkSecurityRuleConfig -Name sr2 -Description "test2" -Protocol Tcp -SourcePortRange "23-45" -DestinationPortRange "46-56" -SourceAddressPrefix * -DestinationAddressPrefix * -Access Allow -Priority 123 -Direction Inbound
        $nsg[0] | Set-AzNetworkSecurityGroup

        Wait-Seconds 300

        
        $vm = Get-AzVM -ResourceGroupName $resourceGroupName
        
        
        $nic = Get-AzNetworkInterface -ResourceGroupName $resourceGroupName
        $address = $nic[0].IpConfigurations[0].PrivateIpAddress

        
        $job = Test-AzNetworkWatcherIPFlow -NetworkWatcher $nw -TargetVirtualMachineId $vm.Id -Direction Inbound -Protocol Tcp -RemoteIPAddress 121.11.12.14 -LocalIPAddress $address -LocalPort 50 -RemotePort 40 -AsJob
        $job | Wait-Job
        $verification1 = $job | Receive-Job
        $verification2 = Test-AzNetworkWatcherIPFlow -NetworkWatcher $nw -TargetVirtualMachineId $vm.Id -Direction Outbound -Protocol Tcp -RemoteIPAddress 12.11.12.14 -LocalIPAddress $address -LocalPort 80 -RemotePort 80

        
        Assert-AreEqual $verification2.Access Deny
        Assert-AreEqual $verification2.RuleName securityRules/scr1
    }
    finally
    {
        
        Clean-ResourceGroup $resourceGroupName
        Clean-ResourceGroup $nwRgName
    }
}


function Test-NetworkConfigurationDiagnostic
{
    
    $resourceGroupName = Get-NrpResourceGroupName
    $nwName = Get-NrpResourceName
    $nwRgName = Get-NrpResourceGroupName
    $securityGroupName = Get-NrpResourceName
    $templateFile = (Resolve-Path ".\TestData\Deployment.json").Path
    $location = Get-ProviderLocation "Microsoft.Network/networkWatchers" "East US"
    
    try 
    {
        . ".\AzureRM.Resources.ps1"

        
        New-AzResourceGroup -Name $resourceGroupName -Location "$location"

        
        Get-TestResourcesDeployment -rgn "$resourceGroupName"
        
        
        New-AzResourceGroup -Name $nwRgName -Location "$location"
        
        
        $nw = Get-CreateTestNetworkWatcher -location $location -nwName $nwName -nwRgName $nwRgName
        
        
        $nsg = Get-AzNetworkSecurityGroup -ResourceGroupName $resourceGroupName

        
        $vm = Get-AzVM -ResourceGroupName $resourceGroupName

        
        $profile = New-AzNetworkWatcherNetworkConfigurationDiagnosticProfile -Direction Inbound -Protocol Tcp -Source 10.1.1.4 -Destination * -DestinationPort 50 
        $result1 = Invoke-AzNetworkWatcherNetworkConfigurationDiagnostic -NetworkWatcher $nw -TargetResourceId $vm.Id -Profile $profile
        $result2 = Invoke-AzNetworkWatcherNetworkConfigurationDiagnostic -NetworkWatcher $nw -TargetResourceId $vm.Id -Profile $profile -VerbosityLevel Full

        
        Assert-AreEqual $result1.results[0].profile.direction Inbound
        Assert-AreEqual $result1.results[0].profile.protocol Tcp
        Assert-AreEqual $result1.results[0].profile.source 10.1.1.4
        Assert-AreEqual $result1.results[0].profile.destinationPort 50
        Assert-AreEqual $result1.results[0].networkSecurityGroupResult.securityRuleAccessResult Deny
    }
    finally
    {
        
        Clean-ResourceGroup $resourceGroupName
        Clean-ResourceGroup $nwRgName
    }
}


function Test-PacketCapture
{
    
    $resourceGroupName = Get-NrpResourceGroupName
    $nwName = Get-NrpResourceName
    $location = Get-PilotLocation
    $resourceTypeParent = "Microsoft.Network/networkWatchers"
    $nwLocation = Get-ProviderLocation $resourceTypeParent
    $nwRgName = Get-NrpResourceGroupName
    $securityGroupName = Get-NrpResourceName
    $templateFile = (Resolve-Path ".\TestData\Deployment.json").Path
    $pcName1 = Get-NrpResourceName
    $pcName2 = Get-NrpResourceName
    
    try 
    {
        . ".\AzureRM.Resources.ps1"

        
        New-AzResourceGroup -Name $resourceGroupName -Location "$location"

        
        Get-TestResourcesDeployment -rgn "$resourceGroupName"
        
        
        New-AzResourceGroup -Name $nwRgName -Location "$location"
        
        
		$nw = Get-CreateTestNetworkWatcher -location $location -nwName $nwName -nwRgName $nwRgName

        
        $vm = Get-AzVM -ResourceGroupName $resourceGroupName
        
        
        Set-AzVMExtension -ResourceGroupName "$resourceGroupName" -Location "$location" -VMName $vm.Name -Name "MyNetworkWatcherAgent" -Type "NetworkWatcherAgentWindows" -TypeHandlerVersion "1.4" -Publisher "Microsoft.Azure.NetworkWatcher" 

        
        $f1 = New-AzPacketCaptureFilterConfig -Protocol Tcp -RemoteIPAddress 127.0.0.1-127.0.0.255 -LocalPort 80 -RemotePort 80-120
        $f2 = New-AzPacketCaptureFilterConfig -LocalIPAddress 127.0.0.1;127.0.0.5

        
        $job = New-AzNetworkWatcherPacketCapture -NetworkWatcher $nw -PacketCaptureName $pcName1 -TargetVirtualMachineId $vm.Id -LocalFilePath C:\tmp\Capture.cap -Filter $f1, $f2 -AsJob
        $job | Wait-Job
        New-AzNetworkWatcherPacketCapture -NetworkWatcher $nw -PacketCaptureName $pcName2 -TargetVirtualMachineId $vm.Id -LocalFilePath C:\tmp\Capture.cap -TimeLimitInSeconds 1
        Start-Sleep -s 2

        
        $job = Get-AzNetworkWatcherPacketCapture -NetworkWatcher $nw -PacketCaptureName $pcName1 -AsJob
        $job | Wait-Job
        $pc1 = $job | Receive-Job
        $pc2 = Get-AzNetworkWatcherPacketCapture -NetworkWatcher $nw -PacketCaptureName $pcName2
        $pcList = Get-AzNetworkWatcherPacketCapture -NetworkWatcher $nw -PacketCaptureName "*"

        
        Assert-AreEqual $pc1.Name $pcName1
        Assert-AreEqual "Succeeded" $pc1.ProvisioningState
        Assert-AreEqual $pc1.TotalBytesPerSession 1073741824
        Assert-AreEqual $pc1.BytesToCapturePerPacket 0
        Assert-AreEqual $pc1.TimeLimitInSeconds 18000
        Assert-AreEqual $pc1.Filters[0].LocalPort 80
        Assert-AreEqual $pc1.Filters[0].Protocol TCP
        Assert-AreEqual $pc1.Filters[0].RemoteIPAddress 127.0.0.1-127.0.0.255
        Assert-AreEqual $pc1.Filters[1].LocalIPAddress 127.0.0.1;127.0.0.5
        Assert-AreEqual $pc1.StorageLocation.FilePath C:\tmp\Capture.cap

        $currentCount = $pcList.Count;

        
        $job = Stop-AzNetworkWatcherPacketCapture -NetworkWatcher $nw -PacketCaptureName $pcName1 -AsJob
        $job | Wait-Job

        
        $pc1 = Get-AzNetworkWatcherPacketCapture -NetworkWatcher $nw -PacketCaptureName $pcName1

        
        $job = Remove-AzNetworkWatcherPacketCapture -NetworkWatcher $nw -PacketCaptureName $pcName1 -AsJob
        $job | Wait-Job

        
        $pcList = Get-AzNetworkWatcherPacketCapture -NetworkWatcher $nw
        Assert-AreEqual $pcList.Count ($currentCount - 1)

        
        Remove-AzNetworkWatcherPacketCapture -NetworkWatcher $nw -PacketCaptureName $pcName2

    }
    finally
    {
        
        Clean-ResourceGroup $resourceGroupName
        Clean-ResourceGroup $nwRgName
    }
}


function Test-Troubleshoot
{
    
    $resourceGroupName = Get-NrpResourceGroupName
    $nwName = Get-NrpResourceName
    $location = Get-PilotLocation
    $resourceTypeParent = "Microsoft.Network/networkWatchers"
    $nwLocation = Get-ProviderLocation $resourceTypeParent
    $nwRgName = Get-NrpResourceGroupName
    $domainNameLabel = Get-NrpResourceName
    $vnetName = Get-NrpResourceName
    $publicIpName = Get-NrpResourceName
    $vnetGatewayConfigName = Get-NrpResourceName
    $gwName = Get-NrpResourceName
    
    try 
    {
        
        New-AzResourceGroup -Name $resourceGroupName -Location "$location"

        
        $subnet = New-AzVirtualNetworkSubnetConfig -Name "GatewaySubnet" -AddressPrefix 10.0.0.0/24
        $vnet = New-AzVirtualNetwork -Name $vnetName -ResourceGroupName $resourceGroupName -Location $location -AddressPrefix 10.0.0.0/16 -Subnet $subnet
        $vnet = Get-AzVirtualNetwork -Name $vnetName -ResourceGroupName $resourceGroupName
        $subnet = Get-AzVirtualNetworkSubnetConfig -Name "GatewaySubnet" -VirtualNetwork $vnet
 
        
        $publicip = New-AzPublicIpAddress -ResourceGroupName $resourceGroupName -name $publicIpName -location $location -AllocationMethod Dynamic -DomainNameLabel $domainNameLabel    
 
        
        $vnetIpConfig = New-AzVirtualNetworkGatewayIpConfig -Name $vnetGatewayConfigName -PublicIpAddress $publicip -Subnet $subnet
        $gw = New-AzVirtualNetworkGateway -ResourceGroupName $resourceGroupName -Name $gwName -location $location -IpConfigurations $vnetIpConfig -GatewayType Vpn -VpnType RouteBased -EnableBgp $false
        
        
        New-AzResourceGroup -Name $nwRgName -Location "$location"

		
		$nw = Get-CreateTestNetworkWatcher -location $location -nwName $nwName -nwRgName $nwRgName

        
        $stoname = 'sto' + $resourceGroupName
        $stotype = 'Standard_GRS'
        $containerName = 'cont' + $resourceGroupName

        New-AzStorageAccount -ResourceGroupName $resourceGroupName -Name $stoname -Location $location -Type $stotype;
        $key = Get-AzStorageAccountKey -ResourceGroupName $resourceGroupName -Name $stoname
        $context = New-AzStorageContext -StorageAccountName $stoname -StorageAccountKey $key[0].Value
        New-AzStorageContainer -Name $containerName -Context $context
        $container = Get-AzStorageContainer -Name $containerName -Context $context

        $sto = Get-AzStorageAccount -ResourceGroupName $resourceGroupName -Name $stoname;

        Start-AzNetworkWatcherResourceTroubleshooting -NetworkWatcher $nw -TargetResourceId $gw.Id -StorageId $sto.Id -StoragePath $container.CloudBlobContainer.StorageUri.PrimaryUri.AbsoluteUri;
		$result = Get-AzNetworkWatcherTroubleshootingResult -NetworkWatcher $nw -TargetResourceId $gw.Id

		
        Assert-AreEqual $result.code "UnHealthy"
		Assert-AreEqual $result.results[0].id "NoConnectionsFoundForGateway"
    }
    finally
    {
        
        Clean-ResourceGroup $resourceGroupName
        Clean-ResourceGroup $nwRgName
    }
}


function Test-FlowLog
{
    
    $resourceGroupName = Get-NrpResourceGroupName
    $nwName = Get-NrpResourceName
    $nwRgName = Get-NrpResourceGroupName
    $domainNameLabel = Get-NrpResourceName
    $nsgName = Get-NrpResourceName
	$stoname =  Get-NrpResourceName
	$workspaceName = Get-NrpResourceName
    $location = Get-ProviderLocation "Microsoft.Network/networkWatchers" "West Central US"
    $workspaceLocation = Get-ProviderLocation ResourceManagement "East US"
	$flowlogFormatType = "Json"
	$flowlogFormatVersion = "1"	
	$trafficAnalyticsInterval = 10;
	
    try 
    {
        
        New-AzResourceGroup -Name $resourceGroupName -Location "$location"

        
        $nsg = New-AzNetworkSecurityGroup -name $nsgName -ResourceGroupName $resourceGroupName -Location $location

        
        $getNsg = Get-AzNetworkSecurityGroup -name $nsgName -ResourceGroupName $resourceGroupName
        
        
        New-AzResourceGroup -Name $nwRgName -Location "$location"
        
        
		$nw = Get-CreateTestNetworkWatcher -location $location -nwName $nwName -nwRgName $nwRgName
 
        
		$stoname = 'sto' + $stoname
        $stotype = 'Standard_GRS'

        New-AzStorageAccount -ResourceGroupName $resourceGroupName -Name $stoname -Location $location -Type $stotype;
        $sto = Get-AzStorageAccount -ResourceGroupName $resourceGroupName -Name $stoname;

		
		$workspaceName = 'tawspace' + $workspaceName
		$workspaceSku = 'free'

		New-AzOperationalInsightsWorkspace -ResourceGroupName $resourceGroupName -Name $workspaceName -Location $workspaceLocation -Sku $workspaceSku;
		$workspace = Get-AzOperationalInsightsWorkspace -Name $workspaceName -ResourceGroupName $resourceGroupName
		
		
        $job = Set-AzNetworkWatcherConfigFlowLog -NetworkWatcher $nw -TargetResourceId $getNsg.Id -EnableFlowLog $true -StorageAccountId $sto.Id -EnableTrafficAnalytics:$true -Workspace $workspace -AsJob -FormatType $flowlogFormatType -FormatVersion $flowlogFormatVersion -TrafficAnalyticsInterval $trafficAnalyticsInterval
        $job | Wait-Job
        $config = $job | Receive-Job
		
        $job = Get-AzNetworkWatcherFlowLogStatus -NetworkWatcher $nw -TargetResourceId $getNsg.Id -AsJob
        $job | Wait-Job
        $status = $job | Receive-Job

        
        Assert-AreEqual $config.TargetResourceId $getNsg.Id
        Assert-AreEqual $config.StorageId $sto.Id
        Assert-AreEqual $config.Enabled $true
        Assert-AreEqual $config.RetentionPolicy.Days 0
        Assert-AreEqual $config.RetentionPolicy.Enabled $false
		Assert-AreEqual $config.Format.Type $flowlogFormatType
		Assert-AreEqual $config.Format.Version $flowlogFormatVersion
		Assert-AreEqual $config.FlowAnalyticsConfiguration.NetworkWatcherFlowAnalyticsConfiguration.Enabled $true
		Assert-AreEqual $config.FlowAnalyticsConfiguration.NetworkWatcherFlowAnalyticsConfiguration.WorkspaceResourceId $workspace.ResourceId
		Assert-AreEqual $config.FlowAnalyticsConfiguration.NetworkWatcherFlowAnalyticsConfiguration.WorkspaceId $workspace.CustomerId.ToString()
		Assert-AreEqual $config.FlowAnalyticsConfiguration.NetworkWatcherFlowAnalyticsConfiguration.WorkspaceRegion $workspace.Location
		Assert-AreEqual $config.FlowAnalyticsConfiguration.NetworkWatcherFlowAnalyticsConfiguration.TrafficAnalyticsInterval $trafficAnalyticsInterval
		
		
        Assert-AreEqual $status.TargetResourceId $getNsg.Id
        Assert-AreEqual $status.StorageId $sto.Id
        Assert-AreEqual $status.Enabled $true
        Assert-AreEqual $status.RetentionPolicy.Days 0
        Assert-AreEqual $status.RetentionPolicy.Enabled $false
		Assert-AreEqual $status.Format.Type  $flowlogFormatType
		Assert-AreEqual $status.Format.Version $flowlogFormatVersion
		Assert-AreEqual $status.FlowAnalyticsConfiguration.NetworkWatcherFlowAnalyticsConfiguration.Enabled $true
		Assert-AreEqual $status.FlowAnalyticsConfiguration.NetworkWatcherFlowAnalyticsConfiguration.WorkspaceResourceId $workspace.ResourceId
		Assert-AreEqual $status.FlowAnalyticsConfiguration.NetworkWatcherFlowAnalyticsConfiguration.WorkspaceId $workspace.CustomerId.ToString()
		Assert-AreEqual $status.FlowAnalyticsConfiguration.NetworkWatcherFlowAnalyticsConfiguration.WorkspaceRegion $workspace.Location
		Assert-AreEqual $status.FlowAnalyticsConfiguration.NetworkWatcherFlowAnalyticsConfiguration.TrafficAnalyticsInterval $trafficAnalyticsInterval
    }
    finally
    {
        
        Clean-ResourceGroup $resourceGroupName
        Clean-ResourceGroup $nwRgName
    }
}


function Test-ConnectivityCheck
{
    . ".\AzureRM.Resources.ps1"

    
    $resourceGroupName = Get-NrpResourceGroupName
    $nwName = Get-NrpResourceName
    $nwRgName = Get-NrpResourceGroupName
    $securityGroupName = Get-NrpResourceName
    $templateFile = (Resolve-Path ".\TestData\Deployment.json").Path
    $pcName1 = Get-NrpResourceName
    $pcName2 = Get-NrpResourceName
    $location = Get-ProviderLocation "Microsoft.Network/networkWatchers" "West Central US"
    
    try 
    {
        . ".\AzureRM.Resources.ps1"

        
        New-AzResourceGroup -Name $resourceGroupName -Location "$location"

        
        Get-TestResourcesDeployment -rgn "$resourceGroupName"
        
        
        New-AzResourceGroup -Name $nwRgName -Location "$location"
        
        
		$nw = Get-CreateTestNetworkWatcher -location $location -nwName $nwName -nwRgName $nwRgName

        
        $vm = Get-AzVM -ResourceGroupName $resourceGroupName
        
        
        Set-AzVMExtension -ResourceGroupName "$resourceGroupName" -Location "$location" -VMName $vm.Name -Name "MyNetworkWatcherAgent" -Type "NetworkWatcherAgentWindows" -TypeHandlerVersion "1.4" -Publisher "Microsoft.Azure.NetworkWatcher"

		
		$config = New-AzNetworkWatcherProtocolConfiguration -Protocol "Http" -Method "Get" -Header @{"accept"="application/json"} -ValidStatusCode @(200,202,204)

        
        $job = Test-AzNetworkWatcherConnectivity -NetworkWatcher $nw -SourceId $vm.Id -DestinationAddress "bing.com" -DestinationPort 80 -ProtocolConfiguration $config -AsJob
        $job | Wait-Job
        $check = $job | Receive-Job

        
        Assert-AreEqual $check.ConnectionStatus "Reachable"
        Assert-AreEqual $check.ProbesFailed 0
        Assert-AreEqual $check.Hops.Count 2
        Assert-True { $check.Hops[0].Type -eq "19" -or $check.Hops[0].Type -eq "VirtualMachine"}
        Assert-AreEqual $check.Hops[1].Type "Internet"
        Assert-AreEqual $check.Hops[0].Address "10.17.3.4"
    }
    finally
    {
		Assert-ThrowsContains { Test-AzNetworkWatcherConnectivity -NetworkWatcher $nw -SourceId $vm.Id -DestinationId $vm.Id -DestinationPort 80 } "Connectivity check destination resource id must not be the same as source";
		Assert-ThrowsContains { Test-AzNetworkWatcherConnectivity -NetworkWatcher $nw -SourceId $vm.Id -DestinationPort 80 } "Connectivity check missing destination resource id or address";
		Assert-ThrowsContains { Test-AzNetworkWatcherConnectivity -NetworkWatcher $nw -SourceId $vm.Id -DestinationAddress "bing.com" } "Connectivity check missing destination port";

        
        Clean-ResourceGroup $resourceGroupName
        Clean-ResourceGroup $nwRgName
    }
}


function Test-ReachabilityReport
{
    
    $rgname = Get-NrpResourceGroupName
    $nwName = Get-NrpResourceName
    $resourceTypeParent = "Microsoft.Network/networkWatchers"
    $location = Get-ProviderLocation $resourceTypeParent "West Central US"
    
    try 
    {
        
        $resourceGroup = New-AzResourceGroup -Name $rgname -Location $location -Tags @{ testtag = "testval" }

        
        $nw = Get-CreateTestNetworkWatcher -location $location -nwName $nwName -nwRgName $rgName

        $job = Get-AzNetworkWatcherReachabilityReport -NetworkWatcher $nw -Location "West US" -Country "United States" -StartTime "2017-10-05" -EndTime "2017-10-10" -AsJob
        $job | Wait-Job
        $report1 = $job | Receive-Job
        $report2 = Get-AzNetworkWatcherReachabilityReport -NetworkWatcher $nw -Location "West US" -Country "United States" -State "washington" -StartTime "2017-10-05" -EndTime "2017-10-10"
        $report3 = Get-AzNetworkWatcherReachabilityReport -NetworkWatcher $nw -Location "West US" -Country "United States" -State "washington" -City "seattle" -StartTime "2017-10-05" -EndTime "2017-10-10"

        Assert-AreEqual $report1.AggregationLevel "Country"
        Assert-AreEqual $report1.ProviderLocation.Country "United States"
        Assert-AreEqual $report2.AggregationLevel "State"
        Assert-AreEqual $report2.ProviderLocation.Country "United States"
        Assert-AreEqual $report2.ProviderLocation.State "washington"
        Assert-AreEqual $report3.AggregationLevel "City"
        Assert-AreEqual $report3.ProviderLocation.Country "United States"
        Assert-AreEqual $report3.ProviderLocation.State "washington"
        Assert-AreEqual $report3.ProviderLocation.City "seattle"
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-ProvidersList
{
    
    $rgname = Get-NrpResourceGroupName
    $nwName = Get-NrpResourceName
    $resourceTypeParent = "Microsoft.Network/networkWatchers"
    $location = Get-ProviderLocation $resourceTypeParent "West Central US"
    
    try 
    {
        
        $resourceGroup = New-AzResourceGroup -Name $rgname -Location $location -Tags @{ testtag = "testval" }

        
        $nw = Get-CreateTestNetworkWatcher -location $location -nwName $nwName -nwRgName $rgname

        $job = Get-AzNetworkWatcherReachabilityProvidersList -NetworkWatcher $nw -Location "West US" -Country "United States" -AsJob
        $job | Wait-Job
        $list1 = $job | Receive-Job
        $list2 = Get-AzNetworkWatcherReachabilityProvidersList -NetworkWatcher $nw -Location "West US" -Country "United States" -State "washington"
        $list3 = Get-AzNetworkWatcherReachabilityProvidersList -NetworkWatcher $nw -Location "West US" -Country "United States" -State "washington" -City "seattle"

        Assert-AreEqual $list1.Countries.CountryName "United States"
        Assert-AreEqual $list2.Countries.CountryName "United States"
        Assert-AreEqual $list2.Countries.States.StateName "washington"
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-ConnectionMonitor
{
    
    $resourceGroupName = Get-NrpResourceGroupName
    $nwName = Get-NrpResourceName
    $location = Get-PilotLocation
    $resourceTypeParent = "Microsoft.Network/networkWatchers"
    $nwLocation = Get-ProviderLocation $resourceTypeParent
    $nwRgName = Get-NrpResourceGroupName
    $securityGroupName = Get-NrpResourceName
    $templateFile = (Resolve-Path ".\TestData\Deployment.json").Path
    $cmName1 = Get-NrpResourceName
    $cmName2 = Get-NrpResourceName
    
    $locationMod = ($location -replace " ","").ToLower()

    try 
    {
        . ".\AzureRM.Resources.ps1"

        
        New-AzResourceGroup -Name $resourceGroupName -Location "$location"

        
        Get-TestResourcesDeployment -rgn "$resourceGroupName"

        
        New-AzResourceGroup -Name $nwRgName -Location "$location"
        
        
        $nw = Get-CreateTestNetworkWatcher -location $location -nwName $nwName -nwRgName $nwRgName

        
        $vm = Get-AzVM -ResourceGroupName $resourceGroupName
        
        
        Set-AzVMExtension -ResourceGroupName "$resourceGroupName" -Location "$location" -VMName $vm.Name -Name "MyNetworkWatcherAgent" -Type "NetworkWatcherAgentWindows" -TypeHandlerVersion "1.4" -Publisher "Microsoft.Azure.NetworkWatcher" 

        
        $job1 = New-AzNetworkWatcherConnectionMonitor -NetworkWatcher $nw -Name $cmName1 -SourceResourceId $vm.Id -DestinationAddress bing.com -DestinationPort 80 -AsJob
        $job1 | Wait-Job
        $cm1 = $job1 | Receive-Job

        
        Assert-AreEqual $cm1.Name $cmName1
        Assert-AreEqual $cm1.Source.ResourceId $vm.Id
        Assert-AreEqual $cm1.Destination.Address bing.com
        Assert-AreEqual $cm1.Destination.Port 80

        $job2 = New-AzNetworkWatcherConnectionMonitor -NetworkWatcher $nw -Name $cmName2 -SourceResourceId $vm.Id -DestinationAddress google.com -DestinationPort 80 -AsJob
        $job2 | Wait-Job
        $cm2 = $job2 | Receive-Job

        
        Assert-AreEqual $cm2.Name $cmName2
        Assert-AreEqual $cm2.Source.ResourceId $vm.Id
        Assert-AreEqual $cm2.Destination.Address google.com
        Assert-AreEqual $cm2.Destination.Port 80
        Assert-AreEqual $cm2.MonitoringStatus Running

        

        Stop-AzNetworkWatcherConnectionMonitor -ResourceGroup $nw.ResourceGroupName -NetworkWatcherName $nw.Name -Name $cmName1
        $cm1 = Set-AzNetworkWatcherConnectionMonitor -ResourceGroup $nw.ResourceGroupName -NetworkWatcherName $nw.Name -Name $cmName1 -SourceResourceId $vm.Id -DestinationAddress bing.com -DestinationPort 81 -ConfigureOnly -MonitoringIntervalInSeconds 50
        Assert-AreEqual $cm1.Destination.Port 81
        Assert-AreEqual $cm1.MonitoringIntervalInSeconds 50

        Stop-AzNetworkWatcherConnectionMonitor -ResourceGroup $nw.ResourceGroupName -NetworkWatcherName $nw.Name -Name $cmName1
        $cm1 = Set-AzNetworkWatcherConnectionMonitor -Location $locationMod -Name $cmName1 -SourceResourceId $vm.Id -DestinationAddress test.com -DestinationPort 81 -MonitoringIntervalInSeconds 50
        Assert-AreEqual $cm1.Destination.Address test.com

        Stop-AzNetworkWatcherConnectionMonitor -ResourceGroup $nw.ResourceGroupName -NetworkWatcherName $nw.Name -Name $cmName1
        $cm1 = Set-AzNetworkWatcherConnectionMonitor -ResourceId $cm1.Id -SourceResourceId $vm.Id -DestinationAddress test.com -DestinationPort 80 -MonitoringIntervalInSeconds 50
        Assert-AreEqual $cm1.Destination.Port 80

        Stop-AzNetworkWatcherConnectionMonitor -ResourceGroup $nw.ResourceGroupName -NetworkWatcherName $nw.Name -Name $cmName1
        $cm1Job = Set-AzNetworkWatcherConnectionMonitor -InputObject $cm1 -SourceResourceId $vm.Id -DestinationAddress test.com -DestinationPort 81 -MonitoringIntervalInSeconds 42 -AsJob
        $cm1Job | Wait-Job
        $cm1 = $cm1Job | Receive-Job
        Assert-AreEqual $cm1.MonitoringIntervalInSeconds 42

        Stop-AzNetworkWatcherConnectionMonitor -ResourceGroup $nw.ResourceGroupName -NetworkWatcherName $nw.Name -Name $cmName1
        $cm1 = Set-AzNetworkWatcherConnectionMonitor -NetworkWatcher $nw -Name $cmName1 -SourceResourceId $vm.Id -DestinationAddress test.com -DestinationPort 80 -MonitoringIntervalInSeconds 42
        Assert-AreEqual $cm1.Destination.Port 80

        
        $stopJob = Stop-AzNetworkWatcherConnectionMonitor -NetworkWatcher $nw -Name $cmName2 -AsJob -PassThru
        $stopJob | Wait-Job
        $stopResult = $stopJob | Receive-Job
        Assert-AreEqual true $stopResult
        $cm2 = Get-AzNetworkWatcherConnectionMonitor -NetworkWatcher $nw -Name $cmName2
        Assert-AreEqual $cm2.MonitoringStatus Stopped

        
        $startJob = Start-AzNetworkWatcherConnectionMonitor -NetworkWatcher $nw -Name $cmName2 -AsJob -PassThru
        $startJob | Wait-Job
        $startResult = $startJob | Receive-Job
        Assert-AreEqual true $startResult
        $cm2 = Get-AzNetworkWatcherConnectionMonitor -NetworkWatcher $nw -Name $cmName2
        Assert-AreEqual $cm2.MonitoringStatus Running

        
        Stop-AzNetworkWatcherConnectionMonitor -Location $locationMod -Name $cm2.Name
        $cm2 = Get-AzNetworkWatcherConnectionMonitor -Location $locationMod -Name $cm2.Name
        Assert-AreEqual $cm2.MonitoringStatus Stopped
        
        
        Start-AzNetworkWatcherConnectionMonitor -Location $locationMod -Name $cm2.Name
        $cm2 = Get-AzNetworkWatcherConnectionMonitor -Location $locationMod -Name $cm2.Name
        Assert-AreEqual $cm2.MonitoringStatus Running

        
        Stop-AzNetworkWatcherConnectionMonitor -ResourceId $cm2.Id
        $cm2 = Get-AzNetworkWatcherConnectionMonitor -ResourceId $cm2.Id
        Assert-AreEqual $cm2.MonitoringStatus Stopped

        
        Start-AzNetworkWatcherConnectionMonitor -ResourceId $cm2.Id
        $cm2 = Get-AzNetworkWatcherConnectionMonitor -ResourceId $cm2.Id
        Assert-AreEqual $cm2.MonitoringStatus Running

        
        Stop-AzNetworkWatcherConnectionMonitor -InputObject $cm2
        $cm2 = Get-AzNetworkWatcherConnectionMonitor -NetworkWatcher $nw -Name $cmName2
        Assert-AreEqual $cm2.MonitoringStatus Stopped

        
        Start-AzNetworkWatcherConnectionMonitor -InputObject $cm2
        $cm2 = Get-AzNetworkWatcherConnectionMonitor -NetworkWatcher $nw -Name $cmName2
        Assert-AreEqual $cm2.MonitoringStatus Running

        
        $cms = Get-AzNetworkWatcherConnectionMonitor -NetworkWatcher $nw -Name "*"
        Assert-NotNull $cms

        
        $report = Get-AzNetworkWatcherConnectionMonitorReport -NetworkWatcher $nw -Name $cmName1
        Assert-NotNull $report

        $report = Get-AzNetworkWatcherConnectionMonitorReport -Location $locationMod -Name $cmName1
        Assert-NotNull $report

        $report = Get-AzNetworkWatcherConnectionMonitorReport -ResourceId $cm1.Id
        Assert-NotNull $report

        $reportJob = Get-AzNetworkWatcherConnectionMonitorReport -InputObject $cm1 -AsJob
        $reportJob | Wait-Job
        $report = $reportJob | Receive-Job
        Assert-NotNull $report

        
        Remove-AzNetworkWatcherConnectionMonitor -NetworkWatcher $nw -Name $cmName1
        Wait-Vm $vm

        
        $job1 = New-AzNetworkWatcherConnectionMonitor -Location $locationMod -Name $cmName1 -SourceResourceId $vm.Id -DestinationAddress bing.com -DestinationPort 80 -ConfigureOnly -MonitoringIntervalInSeconds 30 -AsJob
        $job1 | Wait-Job
        $cm1 = $job1 | Receive-Job

        Remove-AzNetworkWatcherConnectionMonitor -Location $locationMod -Name $cmName1
        Wait-Vm $vm

        
        $job1 = New-AzNetworkWatcherConnectionMonitor -ResourceGroup $nw.ResourceGroupName -NetworkWatcherName $nw.Name -Name $cmName1 -SourceResourceId $vm.Id -DestinationAddress bing.com -DestinationPort 80 -ConfigureOnly -MonitoringIntervalInSeconds 30 -AsJob
        $job1 | Wait-Job
        $cm1 = $job1 | Receive-Job

        Remove-AzNetworkWatcherConnectionMonitor -ResourceId $cm1.Id
        Wait-Vm $vm

        
        $job1 = New-AzNetworkWatcherConnectionMonitor -ResourceGroup $nw.ResourceGroupName -NetworkWatcherName $nw.Name -Name $cmName1 -SourceResourceId $vm.Id -DestinationAddress bing.com -DestinationPort 80 -ConfigureOnly -MonitoringIntervalInSeconds 30 -AsJob
        $job1 | Wait-Job
        $cm1 = $job1 | Receive-Job

        $rmJob = Remove-AzNetworkWatcherConnectionMonitor -InputObject $cm1 -AsJob -PassThru
        $rmJob | Wait-Job
        $result = $rmJob | Receive-Job
        Wait-Vm $vm

        Assert-ThrowsLike { Set-AzNetworkWatcherConnectionMonitor -NetworkWatcher $nw -Name "fakeName" -SourceResourceId $vm.Id -DestinationAddress test.com -DestinationPort 80 -MonitoringIntervalInSeconds 42 } "*not*found*"

        
        Remove-AzNetworkWatcher -ResourceGroupName $nw.ResourceGroupName -Name $nw.Name

        Assert-ThrowsLike { New-AzNetworkWatcherConnectionMonitor -Location $locationMod -Name $cmName1 -SourceResourceId $vm.Id -DestinationAddress bing.com -DestinationPort 80 } "*There is no*"
        Assert-ThrowsLike { Remove-AzNetworkWatcherConnectionMonitor -Location $locationMod -Name $cmName1 } "*There is no*"
        Assert-ThrowsLike { Get-AzNetworkWatcherConnectionMonitor -Location $locationMod -Name $cmName1 } "*There is no*"
        Assert-ThrowsLike { Set-AzNetworkWatcherConnectionMonitor -Location $locationMod -Name $cmName1 -SourceResourceId $vm.Id -DestinationAddress test.com -DestinationPort 80 -MonitoringIntervalInSeconds 42 } "*There is no*"
        Assert-ThrowsLike { Get-AzNetworkWatcherConnectionMonitorReport -Location $locationMod -Name $cmName1 } "*There is no*"
        Assert-ThrowsLike { Stop-AzNetworkWatcherConnectionMonitor -Location $locationMod -Name $cmName1 } "*There is no*"
        Assert-ThrowsLike { Start-AzNetworkWatcherConnectionMonitor -Location $locationMod -Name $cmName1 } "*There is no*"
    }
    finally
    {
        
        Clean-ResourceGroup $resourceGroupName
        Clean-ResourceGroup $nwRgName
    }
}
