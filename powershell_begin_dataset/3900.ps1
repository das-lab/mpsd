














function Test-GetNonExistingBatchAccount
{
    Assert-Throws { Get-AzBatchAccount -Name "accountthatdoesnotexist" }
}


function Test-BatchAccountEndToEnd
{
    
    $accountName = Get-BatchAccountName
    $resourceGroup = Get-ResourceGroupName

    try 
    {
        $location = Get-BatchAccountProviderLocation
        $tagName = "tag1"
        $tagValue = "tagValue1"

        
        New-AzResourceGroup -Name $resourceGroup -Location $location
        $createdAccount = New-AzBatchAccount -Name $accountName -ResourceGroupName $resourceGroup -Location $location -Tag @{$tagName = $tagValue}

        
        Assert-AreEqual $accountName $createdAccount.AccountName
        Assert-AreEqual $resourceGroup $createdAccount.ResourceGroupName	
        Assert-AreEqual $location $createdAccount.Location
        Assert-AreEqual 1 $createdAccount.Tags.Count
        Assert-AreEqual $tagValue $createdAccount.Tags[$tagName]
        Assert-True { $createdAccount.DedicatedCoreQuota -gt 0 }
        Assert-True { $createdAccount.LowPriorityCoreQuota -gt 0 }
        Assert-True { $createdAccount.PoolQuota -gt 0 }
        Assert-True { $createdAccount.ActiveJobAndJobScheduleQuota -gt 0 }

        
        $newTagName = "tag2"
        $newTagValue = "tagValue2"
        Set-AzBatchAccount -Name $accountName -ResourceGroupName $resourceGroup -Tag @{$newTagName = $newTagValue}

        
        $updatedAccount = Get-AzBatchAccount -Name $accountName -ResourceGroupName $resourceGroup

        Assert-AreEqual $accountName $updatedAccount.AccountName
        Assert-AreEqual 1 $updatedAccount.Tags.Count
        Assert-AreEqual $newTagValue $updatedAccount.Tags[$newTagName]

        
        $accountWithKeys = Get-AzBatchAccountKeys -Name $accountName
        Assert-NotNull $accountWithKeys.PrimaryAccountKey
        Assert-NotNull $accountWithKeys.SecondaryAccountKey

        
        $accountWithKeys = Get-AzBatchAccountKeys -Name $accountName -ResourceGroupName $resourceGroup
        Assert-NotNull $accountWithKeys.PrimaryAccountKey
        Assert-NotNull $accountWithKeys.SecondaryAccountKey

        
        $updatedKey = New-AzBatchAccountKey -Name $accountName -ResourceGroupName $resourceGroup -KeyType Primary
        Assert-NotNull $updatedKey.PrimaryAccountKey
        Assert-AreNotEqual $accountWithKeys.PrimaryAccountKey $updatedKey.PrimaryAccountKey
        Assert-AreEqual $accountWithKeys.SecondaryAccountKey $updatedKey.SecondaryAccountKey
    }
    finally
    {
        try
        {
            
            Remove-AzBatchAccount -Name $accountName -ResourceGroupName $resourceGroup -Force
            $errorMessage = "The specified account does not exist."
            Assert-ThrowsContains { Get-AzBatchAccount -Name $accountName -ResourceGroupName $resourceGroup } $errorMessage
        }
        finally
        {
            Remove-AzResourceGroup $resourceGroup
        }
    }
}


function Test-GetBatchSupportedImage
{
    $context = New-Object Microsoft.Azure.Commands.Batch.Test.ScenarioTests.ScenarioTestContext

    
    $supportedImages = Get-AzBatchSupportedImage -BatchContext $context

    foreach($supportedImage in $supportedImages)
    {
        Assert-True { $supportedImage.NodeAgentSkuId.StartsWith("batch.node") }
        Assert-True { $supportedImage.OSType -in "linux","windows" }
        Assert-AreNotEqual $null $supportedImage.VerificationType
    }
}