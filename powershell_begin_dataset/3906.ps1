














function Test-UploadApplicationPackage
{
    param([string] $applicationName, [string] $applicationVersion, [string]$filePath)

    
    $context = New-Object Microsoft.Azure.Commands.Batch.Test.ScenarioTests.ScenarioTestContext

    $addAppPack = New-AzBatchApplicationPackage -ResourceGroupName $context.ResourceGroupName -AccountName $context.AccountName -ApplicationName $applicationName -ApplicationVersion $applicationVersion -format "zip" -ActivateOnly
    $subId = $context.Subscription
    $resourceGroup = $context.ResourceGroupName
    $batchAccountName = $context.AccountName

    Assert-AreEqual "/subscriptions/$subId/resourceGroups/$resourceGroup/providers/Microsoft.Batch/batchAccounts/$batchAccountName/applications/$applicationName/versions/$applicationVersion" $addAppPack.Id
    Assert-AreEqual $applicationVersion $addAppPack.Name
}


function Test-UpdateApplicationPackage
{
    param([string] $applicationName, [string] $applicationVersion, [string]$filePath)

    
    $newDisplayName = "application-display-name"
    $context = New-Object Microsoft.Azure.Commands.Batch.Test.ScenarioTests.ScenarioTestContext

    $beforeUpdateApp = Get-AzBatchApplication -ResourceGroupName $context.ResourceGroupName -AccountName $context.AccountName -ApplicationName $applicationName

    $addAppPack = New-AzBatchApplicationPackage -ResourceGroupName $context.ResourceGroupName -AccountName $context.AccountName -ApplicationName $applicationName -ApplicationVersion $applicationVersion -format "zip" -ActivateOnly
    Set-AzBatchApplication -ResourceGroupName $context.ResourceGroupName -AccountName $context.AccountName -ApplicationName $applicationName -displayName $newDisplayName -defaultVersion $applicationVersion

    $afterUpdateApp = Get-AzBatchApplication -ResourceGroupName $context.ResourceGroupName -AccountName $context.AccountName -ApplicationName $applicationName

    Assert-AreEqual $afterUpdateApp.DefaultVersion $applicationVersion
    Assert-AreNotEqual $afterUpdateApp.DefaultVersion $beforeUpdateApp.DefaultVersion
    Assert-AreEqual $afterUpdateApp.AllowUpdates $true
}


function Test-CreatePoolWithApplicationPackage
{
    param([string] $applicationName, [string] $applicationVersion, [string] $poolId, [string]$filePath)

    
    $context = New-Object Microsoft.Azure.Commands.Batch.Test.ScenarioTests.ScenarioTestContext

    try
    {
        $addAppPack = New-AzBatchApplicationPackage -ResourceGroupName $context.ResourceGroupName -AccountName $context.AccountName -ApplicationName $applicationName -ApplicationVersion $applicationVersion -format "zip" -ActivateOnly

        Assert-AreEqual $applicationVersion $addAppPack.Name

        $apr1 = New-Object Microsoft.Azure.Commands.Batch.Models.PSApplicationPackageReference
        $apr1.ApplicationId = $applicationName
        $apr1.Version = $applicationVersion
        $apr = [Microsoft.Azure.Commands.Batch.Models.PSApplicationPackageReference[]]$apr1

        
        $osFamily = "4"
        $targetOSVersion = "*"
        $paasConfiguration = New-Object Microsoft.Azure.Commands.Batch.Models.PSCloudServiceConfiguration -ArgumentList @($osFamily, $targetOSVersion)

        New-AzBatchPool -Id $poolId -CloudServiceConfiguration $paasConfiguration -TargetDedicated 3 -VirtualMachineSize "small" -BatchContext $context -ApplicationPackageReferences $apr
    }
    finally
    {
        Remove-AzBatchApplicationPackage -AccountName $context.AccountName -ApplicationName $applicationName -ResourceGroupName $context.ResourceGroupName -ApplicationVersion $applicationVersion
        Remove-AzBatchApplication  -AccountName $context.AccountName -ApplicationName $applicationName -ResourceGroupName $context.ResourceGroupName
        Remove-AzBatchPool -Id $poolId -Force -BatchContext $context
    }
}


function Test-UpdatePoolWithApplicationPackage
{
    param([string] $applicationName, [string] $applicationVersion, [string] $poolId, [string]$filePath)

    $context = New-Object Microsoft.Azure.Commands.Batch.Test.ScenarioTests.ScenarioTestContext

    $addAppPack = New-AzBatchApplicationPackage -ResourceGroupName $context.ResourceGroupName -AccountName $context.AccountName -ApplicationName $applicationName -ApplicationVersion $applicationVersion -format "zip" -ActivateOnly

    Assert-AreEqual $applicationVersion $addAppPack.Name

    $getPool = Get-AzBatchPool -Id $poolId -BatchContext $context

    
    $apr1 = New-Object Microsoft.Azure.Commands.Batch.Models.PSApplicationPackageReference
    $apr1.ApplicationId = $applicationName
    $apr1.Version = $applicationVersion
    $apr = [Microsoft.Azure.Commands.Batch.Models.PSApplicationPackageReference[]]$apr1

    $getPool.ApplicationPackageReferences = $apr
    $getPool | Set-AzBatchPool -BatchContext $context

    $getPoolWithAPR = get-AzBatchPool -Id $poolId -BatchContext $context
    
    Assert-AreNotEqual $getPoolWithAPR.ApplicationPackageReferences $null
}
