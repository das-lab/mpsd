














function Test-AzSecurityAdvancedThreatProtection-ResourceId
{
	
	$testPrefix = "psstorage"
	$testParams = Get-AdvancedThreatProtectionTestEnvironmentParameters $testPrefix
	$resourceId = "/subscriptions/" + $testParams.subscriptionId + "/resourceGroups/" + $testParams.rgName + "/providers/Microsoft.Storage/storageAccounts/" + $testParams.accountName
	Create-TestEnvironmentWithParams $testParams

	
	$policy = Enable-AzSecurityAdvancedThreatProtection -ResourceId $resourceId 
    $fetchedPolicy = Get-AzSecurityAdvancedThreatProtection -ResourceId $resourceId
	Assert-AreEqual $True $policy.IsEnabled 
	Assert-AreEqual $True $fetchedPolicy.IsEnabled

	
	$policy = Disable-AzSecurityAdvancedThreatProtection -ResourceId $resourceId 
    $fetchedPolicy = Get-AzSecurityAdvancedThreatProtection -ResourceId $resourceId
	Assert-AreEqual $False $policy.IsEnabled 
	Assert-AreEqual $False $fetchedPolicy.IsEnabled
}


function Get-AdvancedThreatProtectionTestEnvironmentParameters ($testPrefix)
{
	return @{ subscriptionId =  (Get-AzContext).Subscription.Id;
			rgName = getAssetName ($testPrefix);
			accountName = getAssetName ($testPrefix);
			storageSku = "Standard_GRS";
			location = Get-Location "Microsoft.Resources" "resourceGroups" "West US"
			}
}

	
function Create-TestEnvironmentWithParams ($testParams)
{
	
	New-AzResourceGroup -Name $testParams.rgName -Location $testParams.location

	
	$storageAccount = New-AzStorageAccount -ResourceGroupName $testParams.rgName -Name $testParams.accountName -Location $testParams.location -Type $testParams.storageSku
}