




















function Test-CreateInstancePool
{
    
    $props = Get-InstancePoolTestProperties
    $virtualNetwork = CreateAndGetVirtualNetworkForManagedInstance $props.vnetName $props.subnetName $props.location $props.resourceGroup
    $subnetId = $virtualNetwork.Subnets.where({ $_.Name -eq $props.subnetName })[0].Id

    $instancePool = New-AzSqlInstancePool -ResourceGroupName $props.resourceGroup -Name $props.name `
                    -Location $props.location -SubnetId $subnetId -VCore $props.vCores `
                    -Edition $props.edition -ComputeGeneration $props.computeGen `
                    -LicenseType $props.licenseType -Tag $props.tags

    Assert-InstancePoolProperties $instancePool

    
    Remove-ManagedInstancesInInstancePool($instancePool)
}


function Test-GetInstancePool
{
    
    $instancePool = Create-InstancePoolForTest
    Assert-InstancePoolProperties $instancePool

    try
    {
        
        $instancePool = Get-AzSqlInstancePool -ResourceGroupName $instancePool.ResourceGroupName -Name $instancePool.InstancePoolName
        Assert-InstancePoolProperties $instancePool

        
        $instancePool = Get-AzSqlInstancePool -ResourceId $instancePool.Id
        Assert-InstancePoolProperties $instancePool

        
        $instancePools = Get-AzSqlInstancePool -ResourceGroupName $instancePool.ResourceGroupName
        Assert-NotNull $instancePools

        
        $instancePools = Get-AzSqlInstancePool
        Assert-NotNull $instancePools
    }
    finally
    {
        
        Remove-ManagedInstancesInInstancePool($instancePool)
    }
}


function Test-UpdateInstancePool
{
    
    $instancePool = Create-InstancePoolForTest

    try
    {
        
        $newTags = @{ tag1="Test1" };
        $newLicenseType = "BasePrice";
        $instancePool = Set-AzSqlInstancePool -ResourceGroupName $instancePool.ResourceGroupName -Name $instancePool.InstancePoolName `
                                              -Tags $newTags -LicenseType $newLicenseType
        Assert-InstancePoolProperties $instancePool $newTags $newLicenseType

        
        $newTags = @{ tag2="Test2" };
        $newLicenseType = "LicenseIncluded";
        $instancePool = Set-AzSqlInstancePool -ResourceId $instancePool.Id -LicenseType $newLicenseType -Tags $newTags
        Assert-InstancePoolProperties $instancePool $newTags $newLicenseType

        
        $newTags = @{ tag3="Test3" };
        $newLicenseType = "BasePrice";
        $instancePool = Set-AzSqlInstancePool -InputObject $instancePool -LicenseType $newLicenseType -Tags $newTags
        Assert-InstancePoolProperties $instancePool $newTags $newLicenseType

        
        $newTags = @{ tag4="Test4" };
        $newLicenseType = "LicenseIncluded";
        $instancePool = $instancePool | Set-AzSqlInstancePool -LicenseType $newLicenseType -Tags $newTags
        Assert-InstancePoolProperties $instancePool $newTags $newLicenseType
    }
    finally
    {
        
        Remove-ManagedInstancesInInstancePool($instancePool)
    }
}


function Test-RemoveInstancePool
{
    
    $instancePool = Create-InstancePoolForTest
    Assert-InstancePoolProperties $instancePool

    try
    {
        
        $instancePool = Remove-AzSqlInstancePool -ResourceGroupName $instancePool.ResourceGroupName -Name $instancePool.InstancePoolName
        Assert-InstancePoolProperties $instancePool

        
        $instancePool = Create-InstancePoolForTest
        Assert-InstancePoolProperties $instancePool

        
        $instancePool = Remove-AzSqlInstancePool -InputObject $instancePool
        Assert-InstancePoolProperties $instancePool

        
        $instancePool = Create-InstancePoolForTest
        Assert-InstancePoolProperties $instancePool

        
        $instancePool = Remove-AzSqlInstancePool -ResourceId $instancePool.Id
        Assert-InstancePoolProperties $instancePool

        
        $instancePool = Create-InstancePoolForTest
        Assert-InstancePoolProperties $instancePool

        
        $instancePool = $instancePool | Remove-AzSqlInstancePool
        Assert-InstancePoolProperties $instancePool
    }
    finally
    {
        
        Remove-ManagedInstancesInInstancePool($instancePool)
    }
}







function Test-CreateManagedInstanceInInstancePool
{
    
    $instancePool = Create-InstancePoolForTest
    Assert-InstancePoolProperties $instancePool

    
    $managedInstanceName = Get-ManagedInstanceName
    $credential = Get-ServerCredential
    $vCores = 2
    $collation = "Serbian_Cyrillic_100_CS_AS"
    $proxyOverride = "Proxy"
    $timezoneId = "Central Europe Standard Time"

    try
    {
        
        $managedInstance1 = New-AzSqlInstance -ResourceGroupName $instancePool.ResourceGroupName -Name $managedInstanceName `
                                             -AdministratorCredential $credential -Location $instancePool.Location -SubnetId $instancePool.SubnetId `
                                             -VCore 2 -SkuName "GP_Gen5" -LicenseType LicenseIncluded -StorageSizeInGb 32 -Collation $collation `
                                             -PublicDataEndpointEnabled -TimezoneId $timezoneId -Tag $instancePool.Tags -InstancePoolName $instancePool.InstancePoolName
        Assert-ManagedInstanceInInstancePoolProperties $managedInstance1 $instancePool

        
        $managedInstanceName = Get-ManagedInstanceName
        $managedInstance2 = New-AzSqlInstance -ResourceGroupName $instancePool.ResourceGroupName -Name $managedInstanceName `
                                             -AdministratorCredential $credential -Location $instancePool.Location -SubnetId $instancePool.SubnetId `
                                             -VCore 2 -ComputeGeneration "Gen5" -Edition "GeneralPurpose" -LicenseType LicenseIncluded `
                                             -StorageSizeInGb 32 -Collation $collation `
                                             -PublicDataEndpointEnabled -TimezoneId $timezoneId -Tag $instancePool.Tags `
                                             -InstancePoolName $instancePool.InstancePoolName
        Assert-ManagedInstanceInInstancePoolProperties $managedInstance2 $instancePool

        
        $managedInstanceName = Get-ManagedInstanceName
        $managedInstance3 = New-AzSqlInstance -InstancePoolResourceId $instancePool.Id -Name $managedInstanceName `
                                             -VCore 2 -AdministratorCredential $credential -StorageSizeInGb 32 -PublicDataEndpointEnabled
        Assert-ManagedInstanceInInstancePoolProperties $managedInstance3 $instancePool

        
        $managedInstanceName = Get-ManagedInstanceName
        $managedInstance4 = New-AzSqlInstance -InstancePool $instancePool -Name $managedInstanceName -VCore 2 -AdministratorCredential $credential `
                                              -StorageSizeInGb 32 -PublicDataEndpointEnabled
        Assert-ManagedInstanceInInstancePoolProperties $managedInstance4 $instancePool

        
        $managedInstanceName = Get-ManagedInstanceName
        $managedInstance5 = $instancePool | New-AzSqlInstance -Name $managedInstanceName -VCore 2 -AdministratorCredential $credential `
                                                               -StorageSizeInGb 32 -PublicDataEndpointEnabled
        Assert-ManagedInstanceInInstancePoolProperties $managedInstance5 $instancePool
    }
    finally
    {
        
        Remove-ManagedInstancesInInstancePool($instancePool)
    }
}


function Test-GetManagedInstanceInInstancePool
{
    
    $instancePool = Create-InstancePoolForTest
    Assert-InstancePoolProperties $instancePool

    
    $instance1 = Create-ManagedInstanceInInstancePoolForTest $instancePool
    $instance2 = Create-ManagedInstanceInInstancePoolForTest $instancePool

    try
    {
        
        $instance1 = Get-AzSqlInstance -ResourceGroupName $instance1.ResourceGroupName -Name $instance1.ManagedInstanceName
        Assert-ManagedInstanceInInstancePoolProperties $instance1 $instancePool

        
        $instances = Get-AzSqlInstance -ResourceGroupName $instance1.ResourceGroupName -InstancePoolName $instancePool.InstancePoolName
        Assert-NotNull $instances

        
        $instances = Get-AzSqlInstance -ResourceGroupname $instance1.ResourceGroupName
        Assert-NotNull $instances

        
        $instance2 = Get-AzSqlInstance -ResourceId $instance2.Id
        Assert-ManagedInstanceInInstancePoolProperties $instance2 $instancePool

        
        $instances = Get-AzSqlInstance -InstancePoolResourceId $instancePool.Id
        Assert-NotNull $instances

        
        $instances = Get-AzSqlInstance -InstancePool $instancePool
        Assert-NotNull $instances

        
        $instances = Get-AzSqlInstance
        Assert-NotNull $instances
    }
    finally
    {
        
        Remove-ManagedInstancesInInstancePool($instancePool)
    }
}


function Test-UpdateManagedInstanceInInstancePool
{
    
    $instancePool = Create-InstancePoolForTest
    Assert-InstancePoolProperties $instancePool

    
    $securePassword = (Get-ServerCredential).Password
    $edition = "GeneralPurpose"
    $instance = Create-ManagedInstanceInInstancePoolForTest $instancePool
    Assert-ManagedInstanceInInstancePoolProperties $instance $instancePool

    try
    {
        
        $instance = Set-AzSqlInstance -ResourceGroupName $instance.ResourceGroupName -Name $instance.ManagedInstanceName `
                                      -AdministratorPassword $securePassword -Edition $edition -LicenseType LicenseIncluded `
                                      -StorageSizeInGb 32 -VCore 2 -PublicDataEndpointEnabled $true `
                                      -InstancePoolName $instancePool.InstancePoolName -Force

        
        $instance = Set-AzSqlInstance -ResourceId $instance.Id -AdministratorPassword $securePassword -Edition $edition `
                                      -LicenseType LicenseIncluded -StorageSizeInGb 32 -VCore 2 -PublicDataEndpointEnabled $true `
                                      -InstancePoolName $instancePool.InstancePoolName -Force

        
        $instance = Set-AzSqlInstance -InputObject $instance -VCore 2 -InstancePoolName $instancePool.InstancePoolName -PublicDataEndpointEnabled $true -Force

        
        $instance = $instance | Set-AzSqlInstance -VCore 2 -InstancePoolName $instancePool.InstancePoolName -PublicDataEndpointEnabled $true -Force
    }
    finally
    {
        
        Remove-ManagedInstancesInInstancePool($instancePool)
    }
}


function Test-DeleteManagedInstanceInInstancePool
{
    
    $instancePool = Create-InstancePoolForTest
    Assert-InstancePoolProperties $instancePool

    
    $managedInstance1 = Create-ManagedInstanceInInstancePoolForTest $instancePool
    $managedInstance2 = Create-ManagedInstanceInInstancePoolForTest $instancePool
    $managedInstance3 = Create-ManagedInstanceInInstancePoolForTest $instancePool
    $managedInstance4 = Create-ManagedInstanceInInstancePoolForTest $instancePool

    try
    {
        
        $managedInstance1 = Remove-AzSqlInstance -ResourceGroupName $managedInstance1.ResourceGroupName -Name $managedInstance1.ManagedInstanceName -Force
        Assert-ManagedInstanceInInstancePoolProperties $managedInstance1 $instancePool

        
        $managedInstance2 = Remove-AzSqlInstance -InputObject $managedInstance2 -Force
        Assert-ManagedInstanceInInstancePoolProperties $managedInstance2 $instancePool

        
        $managedInstance3 = Remove-AzSqlInstance -ResourceId $managedInstance3.Id -Force
        Assert-ManagedInstanceInInstancePoolProperties $managedInstance3 $instancePool

        
        $managedInstance4 = $managedInstance4 | Remove-AzSqlInstance -Force
        Assert-ManagedInstanceInInstancePoolProperties $managedInstance4 $instancePool
    }
    finally
    {
        
        Remove-ManagedInstancesInInstancePool($instancePool)
    }
}






function Test-GetInstancePoolUsage
{
    $instancePool = Create-InstancePoolForTest
    $managedInstance1 = Create-ManagedInstanceInInstancePoolForTest $instancePool

    try
    {
        
        $usages = Get-AzSqlInstancePoolUsage -ResourceGroupName $instancePool.ResourceGroupname -Name $instancePool.InstancePoolName
        Assert-InstancePoolUsages $usages

        
        $usages = Get-AzSqlInstancePoolUsage -ResourceGroupName $instancePool.ResourceGroupName -Name $instancePool.InstancePoolName -ExpandChildren
        Assert-InstancePoolUsages $usages

        
        $usages = Get-AzSqlInstancePoolUsage -ResourceId $instancePool.Id
        Assert-InstancePoolUsages $usages

        
        $usages = Get-AzSqlInstancePoolUsage -ResourceId $instancePool.Id -ExpandChildren
        Assert-InstancePoolUsages $usages

        
        $usages = $instancePool | Get-AzSqlInstancePoolUsage
        Assert-InstancePoolUsages $usages

        
        $usages = $instancePool | Get-AzSqlInstancePoolUsage -ExpandChildren
        Assert-InstancePoolUsages $usages
    }
    finally
    {
        
        Remove-ManagedInstancesInInstancePool($instancePool)
    }
}






function Assert-InstancePoolProperties($instancePool, $newTags = $null, $newLicenseType = $null)
{
    $props = Get-InstancePoolTestProperties
    Assert-AreEqual $instancePool.ResourceGroupName $props.resourceGroup
    Assert-AreEqual $instancePool.InstancePoolName $props.Name
    Assert-AreEqual $instancePool.VCores $props.vCores

    $subnetFormat = -join("*virtualNetworks/", $props.vnetName, "/subnets/", $props.subnetName,"*")
    $subnetMatch = $instancePool.SubnetId -like $subnetFormat
    Assert-AreEqual True $subnetMatch
    Assert-AreEqual $instancePool.ComputeGeneration $props.computeGen
    Assert-AreEqual $instancePool.Edition $props.Edition
    Assert-AreEqual $instancePool.Location $props.Location
    Assert-NotNull $instancePool.Tags

    if ($newTags -ne $null)
    {
        $newTagsKey = $newTags.Keys[0]
        $newTagsValue = $newTags[$newTagsKey]
        Assert-AreEqual True $instancePool.Tags.ContainsKey($newTagsKey)
        Assert-AreEqual $newTagsValue $instancePool.Tags[$newTagsKey]
    }
    else
    {
        Assert-AreEqual True $instancePool.Tags.ContainsKey($props.tags.Keys[0])
        Assert-AreEqual $props.tags[$props.tags.Keys[0]] $instancePool.Tags[$props.tags.Keys[0]]
    }

    if ($newLicenseType -ne $null)
    {
        Assert-AreEqual $newLicenseType $instancePool.LicenseType
    }
    else
    {
        Assert-AreEqual $props.LicenseType $instancePool.LicenseType
    }
}


function Assert-ManagedInstanceInInstancePoolProperties($managedInstance, $instancePool)
{
    Assert-AreEqual $instancePool.Sku.Name $managedInstance.Sku.Name
    Assert-AreEqual $instancePool.Sku.Tier $managedInstance.Sku.Tier
    Assert-AreEqual $instancePool.LicenseType $managedInstance.LicenseType
    Assert-AreEqual $instancePool.SubnetId $managedInstance.SubnetId
    Assert-AreEqual $instancePool.ResourceGroupName $managedInstance.ResourceGroupName
    Assert-AreEqual $instancePool.Location $managedInstance.Location
}


function Assert-InstancePoolUsages($usages)
{
    Assert-AreEqual True ($usages.Count -ge 3)

    Assert-AreEqual "VCores" $usages[0].Unit
    Assert-AreEqual "VCore utilization" $usages[0].name
    Assert-NotNull $usages[0].CurrentValue
    Assert-NotNull $usages[0].Limit

    Assert-AreEqual "Gigabytes" $usages[1].Unit
    Assert-AreEqual "Storage utilization" $usages[1].name
    Assert-NotNull $usages[1].CurrentValue
    Assert-NotNull $usages[1].Limit

    Assert-AreEqual "Number of Databases" $usages[2].Unit
    Assert-AreEqual "Database utilization" $usages[2].name
    Assert-NotNull $usages[2].CurrentValue
    Assert-NotNull $usages[2].Limit
}