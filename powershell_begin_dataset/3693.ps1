














function Test-ProviderShareSubscriptionGrantAndRevoke
{
    $resourceGroup = getAssetName
    $AccountName = getAssetName
    $ShareName = getAssetName
    $ShareSubId = getAssetName
	$resourceId = getAssetName

	$revoked = Revoke-AzDataShareSubscriptionAccess -ResourceGroupName $resourceGroup -AccountName $AccountName -ShareName $ShareName -ShareSubscriptionId $ShareSubId
	Assert-NotNull $revoked

	$revoked = Revoke-AzDataShareSubscriptionAccess -ResourceId $resourceId -ShareSubscriptionId $ShareSubId
	Assert-NotNull $revoked

	$reinstated = Grant-AzDataShareSubscriptionAccess -ResourceGroupName $resourceGroup -AccountName $AccountName -ShareName $ShareName -ShareSubscriptionId $ShareSubId
	Assert-NotNull $reinstated
	
	$reinstated = Grant-AzDataShareSubscriptionAccess -ResourceId $resourceId -ShareSubscriptionId $ShareSubId
	Assert-NotNull $reinstated
}

function Test-ProviderShareSubscriptionGet
{
    $resourceGroup = getAssetName
    $AccountName = getAssetName
    $ShareName = getAssetName
    $ShareSubscriptionId = getAssetName

    $retrievedProviderShareSubscription = Get-AzDataShareProviderShareSubscription -AccountName $AccountName -ResourceGroupName $resourceGroup -ShareName $ShareName -ShareSubscriptionId $ShareSubscriptionId
 	$shareSubscriptionName = "sdktestingprovidersharesubscription20"

    Assert-NotNull $retrievedProviderShareSubscription
    Assert-AreEqual $shareSubscriptionName $retrievedProviderShareSubscription.Name
    Assert-AreEqual $ShareSubscriptionId $retrievedProviderShareSubscription.ShareSubscriptionObjectId
    Assert-AreEqual "Active" $retrievedProviderShareSubscription.ShareSubscriptionStatus
    Assert-AreEqual "Microsoft" $retrievedProviderShareSubscription.Company
}