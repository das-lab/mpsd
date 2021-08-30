













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


function Test-NetworkProfileCRUDMinimalParameters
{
    
    $rgname = Get-ResourceGroupName;
    $rglocation = Get-ProviderLocation ResourceManagement;
    $npName = Get-ResourceName;
    $location = Get-ProviderLocation "Microsoft.Network/NetworkProfiles";
    
    $containerNicConfigName = "cnic1";

    try
    {
        $resourceGroup = New-AzResourceGroup -Name $rgname -Location $rglocation;

        
        $containerNicConfig = New-AzContainerNicConfig -Name $containerNicConfigName;

        
        $vNetworkProfile = New-AzNetworkProfile -ResourceGroupName $rgname -Name $npName -Location $location -ContainerNetworkInterfaceConfiguration $containerNicConfig;
        Assert-NotNull $vNetworkProfile;
        Assert-True { Check-CmdletReturnType "New-AzNetworkProfile" $vNetworkProfile };
        Assert-Null $vNetworkProfile.ContainerNetworkInterfaces;
        Assert-NotNull $vNetworkProfile.ContainerNetworkInterfaceConfigurations;
        Assert-True { @($vNetworkProfile.ContainerNetworkInterfaceConfigurations).Count -gt 0 };
        Assert-AreEqual $npName $vNetworkProfile.Name;

        
        $vNetworkProfile = Get-AzNetworkProfile -ResourceGroupName $rgname -Name $npName;
        Assert-NotNull $vNetworkProfile;
        Assert-True { Check-CmdletReturnType "Get-AzNetworkProfile" $vNetworkProfile };
        Assert-AreEqual $npName $vNetworkProfile.Name;

        $vNetworkProfiles = Get-AzureRmNetworkProfile -ResourceGroupName $rgname;
        Assert-NotNull $vNetworkProfiles;

        $vNetworkProfilesAll = Get-AzureRmNetworkProfile;
        Assert-NotNull $vNetworkProfilesAll;

        $vNetworkProfilesAll = Get-AzureRmNetworkProfile -ResourceGroupName "*";
        Assert-NotNull $vNetworkProfilesAll;

        $vNetworkProfilesAll = Get-AzureRmNetworkProfile -Name "*"
        Assert-NotNull $vNetworkProfilesAll;

        $vNetworkProfilesAll = Get-AzureRmNetworkProfile -ResourceGroupName "*" -Name "*"
        Assert-NotNull $vNetworkProfilesAll;

        
        $removeNetworkProfile = Remove-AzNetworkProfile -ResourceGroupName $rgname -Name $npName -Force;

        
        Assert-ThrowsContains { Get-AzNetworkProfile -ResourceGroupName $rgname -Name $npName } "${npName} not found";
    }
    finally
    {
        
        Clean-ResourceGroup $rgname;
    }
}


function Test-NetworkProfileCRUDAllParameters
{
    
    $rgname = Get-ResourceGroupName;
    $rglocation = Get-ProviderLocation ResourceManagement;
    $npName = Get-ResourceName;
    $location = Get-ProviderLocation "Microsoft.Network/NetworkProfiles";
    
    $containerNicConfigName = "cnic1";

    try
    {
        $resourceGroup = New-AzResourceGroup -Name $rgname -Location $rglocation;
           
        
        $vNetworkProfile = New-AzNetworkProfile -ResourceGroupName $rgname -Name $npName -Location $location
        $vNetworkProfile.ContainerNetworkInterfaceConfigurations = New-AzContainerNicConfig -Name $containerNicConfigName

        Assert-NotNull $vNetworkProfile;
        Assert-True { Check-CmdletReturnType "New-AzNetworkProfile" $vNetworkProfile };
        Assert-Null $vNetworkProfile.ContainerNetworkInterfaces;
        Assert-NotNull $vNetworkProfile.ContainerNetworkInterfaceConfigurations;
        Assert-True { @($vNetworkProfile.ContainerNetworkInterfaceConfigurations).Count -gt 0 };
        Assert-AreEqual $npName $vNetworkProfile.Name;

        $vNetworkProfile | Set-AzNetworkProfile

        
        $vNetworkProfile = Get-AzNetworkProfile -ResourceGroupName $rgname -Name $npName;
        Assert-NotNull $vNetworkProfile;
        Assert-True { Check-CmdletReturnType "Get-AzNetworkProfile" $vNetworkProfile };
        Assert-AreEqual $npName $vNetworkProfile.Name;

        
        $containerNicConfig = @($vNetworkProfile.ContainerNetworkInterfaceConfigurations)[0]
        Assert-NotNull $containerNicConfig
        Assert-AreEqual $containerNicConfig.Name $containerNicConfigName
        
        
        $removeNetworkProfile = Remove-AzNetworkProfile -ResourceGroupName $rgname -Name $npName -Force;

        
        Assert-ThrowsContains { Get-AzNetworkProfile -ResourceGroupName $rgname -Name $npName } "${npName} not found";
    }
    finally
    {
        
        Clean-ResourceGroup $rgname;
    }
}


function Test-ContainerNetworkInterfaceConfigCRUDMinimalParameters
{
    
    $rgname = Get-ResourceGroupName;
    $rglocation = Get-ProviderLocation ResourceManagement;
    $networkProfileName = "np1"
    $containerNicConfigName = Get-ResourceName;
    $containerNicConfigNameAdd = "${containerNicConfigName}Add";
    $location = Get-ProviderLocation "Microsoft.Network/NetworkProfiles";

    try
    {
        $resourceGroup = New-AzResourceGroup -Name $rgname -Location $rglocation;

        
        $vContainerNetworkInterfaceConfig = New-AzContainerNicConfig -Name $containerNicConfigName;
        Assert-NotNull $vContainerNetworkInterfaceConfig;
        Assert-True { Check-CmdletReturnType "New-AzContainerNicConfig" $vContainerNetworkInterfaceConfig };
        $vNetworkProfile = New-AzNetworkProfile -ResourceGroupName $rgname -Name $networkProfileName -ContainerNetworkInterface $vContainerNetworkInterfaceConfig -Location $location;
        Assert-NotNull $vNetworkProfile;
        Assert-AreEqual $containerNicConfigName $vContainerNetworkInterfaceConfig.Name;

        
        $vContainerNetworkInterfaceConfig = @($vNetworkProfile.ContainerNetworkInterfaceConfigurations)[0]
        Assert-NotNull $vContainerNetworkInterfaceConfig;
        Assert-AreEqual $containerNicConfigName $vContainerNetworkInterfaceConfig.Name;

        
        $nicCfg = New-AzContainerNicConfig -Name $containerNicConfigNameAdd
        $vNetworkProfile.ContainerNetworkInterfaceConfigurations.Add($nicCfg)
        Assert-NotNull $vNetworkProfile;
        $vNetworkProfile = $vNetworkProfile | Set-AzNetworkProfile;

        
        $vContainerNetworkInterfaceConfig = $vNetworkProfile.ContainerNetworkInterfaceConfigurations | ? { $_.Name -eq $containerNicConfigNameAdd }
        Assert-NotNull $vContainerNetworkInterfaceConfig;
        Assert-AreEqual $containerNicConfigNameAdd $vContainerNetworkInterfaceConfig.Name;

        
        $vNetworkProfile.ContainerNetworkInterfaceConfigurations = $null
        $vNetworkProfile = $vNetworkProfile | Set-AzNetworkProfile;
    }
    finally
    {
        
        Clean-ResourceGroup $rgname;
    }
}

function Test-ContainerNetworkInterfaceConfigCRUD
{
    
    $rgname = Get-ResourceGroupName;
    $rglocation = Get-ProviderLocation ResourceManagement;
    $networkProfileName = "np1"
    $containerNicConfigName = Get-ResourceName;
    $ipConfigProfileName = "ipconfigprofile1"
    $ipConfigProfileNameAdd = "${ipConfigProfileName}Add"
    $location = Get-ProviderLocation "Microsoft.Network/NetworkProfiles";
    $vnetName = "vnet1"
    $subnetName = "subnet1"
    $subnetNameAdd = "${subnetName}Add"

    try
    {
        $resourceGroup = New-AzResourceGroup -Name $rgname -Location $rglocation;

        
        $subnet = New-AzVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix 10.0.1.0/24
        $subnetAdd = New-AzVirtualNetworkSubnetConfig -Name $subnetNameAdd -AddressPrefix 10.0.2.0/24
        $response = New-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgname -Location $location -AddressPrefix 10.0.0.0/16 -Subnet @($subnet, $subnetAdd)

        $subnet = $response.Subnets[0]
        $subnetAdd = $response.Subnets[1]

        Assert-AreEqual $subnet.Name $subnetName
        Assert-AreEqual $subnetAdd.Name $subnetNameAdd

        
        $ipConfigProfile = New-AzContainerNicConfigIpConfig -Name $ipConfigProfileName -Subnet $subnet
        Assert-NotNull $ipConfigProfile
        Assert-True { Check-CmdletReturnType "New-AzContainerNicConfigIpConfig" $ipConfigProfile };
        Assert-AreEqual $ipConfigProfile.Name $ipConfigProfileName

        
        $vContainerNetworkInterfaceConfig = New-AzContainerNicConfig -Name $containerNicConfigName -IPConfiguration $ipConfigProfile;
        Assert-NotNull $vContainerNetworkInterfaceConfig;
        Assert-True { Check-CmdletReturnType "New-AzContainerNicConfig" $vContainerNetworkInterfaceConfig };
        Assert-AreEqual $vContainerNetworkInterfaceConfig.Name $containerNicConfigName

        $vNetworkProfile = New-AzNetworkProfile -ResourceGroupName $rgname -Name $networkProfileName -ContainerNetworkInterfaceConfiguration $vContainerNetworkInterfaceConfig -Location $location;
        Assert-NotNull $vNetworkProfile;
        Assert-AreEqual $vNetworkProfile.Name $networkProfileName;

        
        $vContainerNetworkInterfaceConfig = @($vNetworkProfile.ContainerNetworkInterfaceConfigurations)[0]
        Assert-NotNull $vContainerNetworkInterfaceConfig;
        Assert-AreEqual $containerNicConfigName $vContainerNetworkInterfaceConfig.Name;

        
        $ipConfigProfile = @($vContainerNetworkInterfaceConfig.IpConfigurations)[0]
        Assert-NotNull $ipConfigProfile;
        Assert-AreEqual $ipConfigProfileName $ipConfigProfile.Name;

        
        $ipCfg = New-AzContainerNicConfigIpConfig -Name $ipConfigProfileNameAdd -Subnet $subnet
        $vContainerNetworkInterfaceConfig.IpConfigurations.Add($ipCfg);
        Assert-NotNull $vContainerNetworkInterfaceConfig
        Assert-True { @($vContainerNetworkInterfaceConfig.IpConfigurations).Count -gt 1 }
        Assert-AreEqual  $vContainerNetworkInterfaceConfig.IpConfigurations[0].Name $ipConfigProfileName
        Assert-AreEqual  $vContainerNetworkInterfaceConfig.IpConfigurations[1].Name $ipConfigProfileNameAdd
        $vNetworkProfile.ContainerNetworkInterfaceConfigurations[0] = $vContainerNetworkInterfaceConfig
        $vNetworkProfile = $vNetworkProfile | Set-AzNetworkProfile

        
        $vNetworkProfile.ContainerNetworkInterfaceConfigurations[0] = New-AzContainerNicConfig -Name $containerNicConfigName -IpConfiguration $vContainerNetworkInterfaceConfig.IpConfigurations[0]
        Assert-NotNull $vNetworkProfile;
        Assert-True { @($vNetworkProfile.ContainerNetworkInterfaceConfigurations).Count -eq 1 }
        Assert-AreEqual $vNetworkProfile.ContainerNetworkInterfaceConfigurations[0].Name $containerNicConfigName
        $vNetworkProfile = $vNetworkProfile | Set-AzNetworkProfile;

        
        $vContainerNetworkInterfaceConfig = @($vNetworkProfile.ContainerNetworkInterfaceConfigurations)[0];
        $ipConfigProfile = $vContainerNetworkInterfaceConfig.IpConfigurations | ? {$_.Name -eq $ipConfigProfileName}
        Assert-NotNull $ipConfigProfile;
        Assert-AreEqual $ipConfigProfileName $ipConfigProfileName;
        Assert-True { @($vContainerNetworkInterfaceConfig.IpConfigurations).Count -eq 1 }

        $vNetworkProfile.ContainerNetworkInterfaceConfigurations = $null

        $vNetworkProfile | Set-AzNetworkProfile;

        $vNetworkProfile | Remove-AzNetworkProfile -Force
    }
    finally
    {
        
        Clean-ResourceGroup $rgname;
    }
}
