













function Check-CmdletReturnType
{
    param($cmdletName, $cmdletReturn)

    $cmdletData = Get-Command $cmdletName;
    Assert-NotNull $cmdletData;
    [array]$cmdletReturnTypes = $cmdletData.OutputType.Name | Foreach-Object { return ($_ -replace "Microsoft.Azure.Commands.Network.Models.","") };
    [array]$cmdletReturnTypes = $cmdletReturnTypes | Foreach-Object { return ($_ -replace "System.","") };
    $realReturnType = $cmdletReturn.GetType().Name -replace "Microsoft.Azure.Commands.Network.Models.","";
    return $cmdletReturnTypes -contains $realReturnType;
}


function Test-PrivateLinkServiceCRUD
{
    
    $rgname = Get-ResourceGroupName;
    $rname = Get-ResourceName;
    $location = Get-ProviderLocation "Microsoft.Network/privateLinkServices" "westus";
    
    $IpConfigurationName = "IpConfigurationName";
    $vnetName = Get-ResourceName;
    $ilbFrontName = "LB-Frontend";
    $ilbBackendName = "LB-Backend";
    $ilbName = Get-ResourceName;

    try
    {
        $resourceGroup = New-AzResourceGroup -Name $rgname -Location $location;

        
        $frontendSubnet = New-AzVirtualNetworkSubnetConfig -Name "frontendSubnet" -AddressPrefix "10.0.1.0/24";
        $backendSubnet = New-AzVirtualNetworkSubnetConfig -Name "backendSubnet" -AddressPrefix "10.0.2.0/24";
        $otherSubnet = New-AzVirtualNetworkSubnetConfig -Name "otherSubnet" -AddressPrefix "10.0.3.0/24" -PrivateLinkServiceNetworkPoliciesFlag "Disabled"; 
        $vnet = New-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgname -Location $location -AddressPrefix "10.0.0.0/16" -Subnet $frontendSubnet,$backendSubnet,$otherSubnet;

        
        $frontendIP = New-AzLoadBalancerFrontendIpConfig -Name $ilbFrontName -PrivateIpAddress "10.0.1.5" -SubnetId $vnet.subnets[0].Id;
        $beaddresspool= New-AzLoadBalancerBackendAddressPoolConfig -Name $ilbBackendName;
        $job = New-AzLoadBalancer -ResourceGroupName $rgname -Name $ilbName -Location $location -FrontendIpConfiguration $frontendIP -BackendAddressPool $beaddresspool -Sku "Standard" -AsJob;
        $job | Wait-Job
        $ilbcreate = $job | Receive-Job

        
        Assert-NotNull $ilbcreate;
        Assert-AreEqual $ilbName $ilbcreate.Name;
        Assert-AreEqual (Normalize-Location $location) $ilbcreate.Location;
        Assert-AreEqual "Succeeded" $ilbcreate.ProvisioningState

        
        $IpConfiguration = New-AzPrivateLinkServiceIpConfig -Name $IpConfigurationName -PrivateIpAddress 10.0.3.5 -Subnet $vnet.subnets[2];
        $LoadBalancerFrontendIpConfiguration = Get-AzLoadBalancer -Name $ilbName | Get-AzLoadBalancerFrontendIpConfig
        
        
        $job = New-AzPrivateLinkService -ResourceGroupName $rgName -Name $rname -Location $location -IpConfiguration $IpConfiguration -LoadBalancerFrontendIpConfiguration $LoadBalancerFrontendIpConfiguration -AsJob;
        $job | Wait-Job
        $plscreate = $job | Receive-Job
        
        $vPrivateLinkService = Get-AzPrivateLinkService -Name $rname -ResourceGroupName $rgName
        
        
        Assert-NotNull $vPrivateLinkService;
        Assert-AreEqual $rname $vPrivateLinkService.Name;
        Assert-NotNull $vPrivateLinkService.IpConfigurations;
        Assert-True { $vPrivateLinkService.IpConfigurations.Length -gt 0 };
        Assert-AreEqual "Succeeded" $vPrivateLinkService.ProvisioningState

        
        $listPrivateLinkService = Get-AzPrivateLinkService -ResourceGroupName $rgname;
        Assert-NotNull ($listPrivateLinkService | Where-Object { $_.ResourceGroupName -eq $rgname -and $_.Name -eq $rname });

        
        $listPrivateLinkService = Get-AzPrivateLinkService;
        Assert-NotNull ($listPrivateLinkService | Where-Object { $_.ResourceGroupName -eq $rgname -and $_.Name -eq $rname });

        
        $listPrivateLinkService = Get-AzPrivateLinkService -ResourceGroupName "*";
        Assert-NotNull ($listPrivateLinkService | Where-Object { $_.ResourceGroupName -eq $rgname -and $_.Name -eq $rname });

        
        $listPrivateLinkService = Get-AzPrivateLinkService -Name "*";
        Assert-NotNull ($listPrivateLinkService | Where-Object { $_.ResourceGroupName -eq $rgname -and $_.Name -eq $rname });

        
        $listPrivateLinkService = Get-AzPrivateLinkService -ResourceGroupName "*" -Name "*";
        Assert-NotNull ($listPrivateLinkService | Where-Object { $_.ResourceGroupName -eq $rgname -and $_.Name -eq $rname });

        
        $job = Remove-AzPrivateLinkService -ResourceGroupName $rgname -Name $rname -PassThru -Force -AsJob;
        $job | Wait-Job;
        $removePrivateLinkService = $job | Receive-Job;
        Assert-AreEqual true $removePrivateLinkService;

        $list = Get-AzPrivateLinkService -ResourceGroupName $rgname
        Assert-AreEqual 0 @($list).Count
    }
    finally
    {
        
        Clean-ResourceGroup $rgname;
    }
} 


function Test-PrivateEndpointConnectionCRUD
{
    
    $rgname = Get-ResourceGroupName;
    $rname = Get-ResourceName;
    $location = Get-ProviderLocation "Microsoft.Network/privateLinkServices" "westus2";
    
    $IpConfigurationName = "IpConfigurationName";
    $vnetName = Get-ResourceName;
    $ilbFrontName = "LB-Frontend";
    $ilbBackendName = "LB-Backend";
    $ilbName = Get-ResourceName;

    $serverName = Get-ResourceName
    $serverLogin = "testusername"
    
    $serverPassword = "t357ingP@s5w0rd!Sec"
    $credentials = new-object System.Management.Automation.PSCredential($serverLogin, ($serverPassword | ConvertTo-SecureString -asPlainText -Force))
    $databaseName = "mySampleDatabase"
    $peName = "mype"
    $subId = getSubscription

    try
    {
        $resourceGroup = New-AzResourceGroup -Name $rgname -Location $location;

        if ((Get-NetworkTestMode) -ne 'Playback')
        {
            
            $server = New-AzSqlServer -ResourceGroupName $rgname `
                -ServerName $serverName `
                -Location $location `
                -SqlAdministratorCredentials $credentials

            $database = New-AzSqlDatabase  -ResourceGroupName $rgname `
                -ServerName $serverName `
                -DatabaseName $databaseName `
                -RequestedServiceObjectiveName "Basic" `
                -Edition "Basic"

            $sqlResourceId = $server.ResourceId
        }
        else
        {
            $sqlResourceId = "/subscriptions/$subId/resourceGroups/$rgname/providers/Microsoft.Sql/servers/$serverName"
        }

        
        $peSubnet = New-AzVirtualNetworkSubnetConfig -Name peSubnet -AddressPrefix "11.0.1.0/24" -PrivateEndpointNetworkPolicies "Disabled"
        $vnetPE = New-AzVirtualNetwork -Name "vnetPE" -ResourceGroupName $rgname -Location $location -AddressPrefix "11.0.0.0/16" -Subnet $peSubnet

        $plsConnection= New-AzPrivateLinkServiceConnection -Name plsConnection -PrivateLinkServiceId  $sqlResourceId -GroupId 'sqlServer'
        $privateEndpoint = New-AzPrivateEndpoint -ResourceGroupName $rgname -Name $peName -Location $location -Subnet $vnetPE.subnets[0] -PrivateLinkServiceConnection $plsConnection -ByManualRequest

        
        $pecGet = Get-AzPrivateEndpointConnection -PrivateLinkResourceId $sqlResourceId
        Assert-NotNull $pecGet;
        Assert-AreEqual "Pending" $pecGet.PrivateLinkServiceConnectionState.Status

        
        $pecApprove = Approve-AzPrivateEndpointConnection -ResourceId $pecGet.Id
        Assert-NotNull $pecApprove;
        Assert-AreEqual "Approved" $pecApprove.PrivateLinkServiceConnectionState.Status

        Start-TestSleep 30000

        
        $pecRemove = Remove-AzPrivateEndpointConnection -ResourceId $pecGet.Id -PassThru -Force
        Assert-AreEqual true $pecRemove

        
        $pecGet2 = Get-AzPrivateEndpointConnection -PrivateLinkResourceId $sqlResourceId
        Assert-Null($pecGet2)

    }
    finally
    {
        
        Clean-ResourceGroup $rgname;
    }
}
