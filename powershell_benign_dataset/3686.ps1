














function Test-AccountCrud
{
    $resourceGroup = TestSetup-CreateResourceGroup
	
	try{
		$AccountName = getAssetName
		$tags = @{"tag1" = "value1"; "tag2" = "value2"}
		$AccountLocation = Get-Location "Microsoft.DataShare" "accounts" "WEST US"
		$createdAccount = New-AzDataShareAccount -Name $AccountName -ResourceGroupName $resourceGroup.ResourceGroupName -Location $AccountLocation -Tag $tags

		Assert-NotNull $createdAccount
		Assert-AreEqual $AccountName $createdAccount.Name
		Assert-AreEqual $AccountLocation $createdAccount.location
		Assert-Tags $tags $createdAccount.tags
		Assert-AreEqual "Succeeded" $createdAccount.ProvisioningState

		$retrievedAccount = Get-AzDataShareAccount -Name $AccountName -ResourceGroupName $resourceGroup.ResourceGroupName

		Assert-NotNull $retrievedAccount
		Assert-AreEqual $AccountName $retrievedAccount.Name
		Assert-AreEqual $AccountLocation $retrievedAccount.location
		Assert-AreEqual "Succeeded" $retrievedAccount.ProvisioningState

		$removed = Remove-AzDataShareAccount -Name $AccountName -ResourceGroupName $resourceGroup.ResourceGroupName -PassThru -Force

		Assert-True { $removed }
		Assert-ThrowsContains { Get-AzDataShareAccount -Name $AccountName -ResourceGroupName $resourceGroup.ResourceGroupName } "Resource 'sdktestingshareaccount9776' does not exist"
	}
	finally
	{
		Remove-AzResourceGroup -Name $resourceGroup.ResourceGroupName -Force
	}
}