














function Test-TriggerCrud
{
    $ResourceGroupName = getAssetName

	try{
		$AccountName = getAssetName
		$SubName = getAssetName
		$TriggerName = getAssetName

		$RecurrenceInterval = "hour"
		$SynchronizationTime = "06/19/2019 22:53:33"

		$newTrigger = New-AzDataShareTrigger -ResourceGroupName $ResourceGroupName -AccountName $AccountName -ShareSubscriptionName $SubName -RecurrenceInterval $RecurrenceInterval -SynchronizationTime $SynchronizationTime -Name $TriggerName

		Assert-NotNull $newTrigger
		Assert-AreEqual $newTrigger.Name $TriggerName
		Assert-AreEqual $newTrigger.ProvisioningState "Succeeded"

		$gottenTrigger = Get-AzDataShareTrigger -ResourceGroupName $ResourceGroupName -AccountName $AccountName -ShareSubscriptionName $SubName

		Assert-NotNull $newTrigger
		Assert-AreEqual $newTrigger.Name $TriggerName
		Assert-AreEqual $newTrigger.ProvisioningState "Succeeded"

		$gottenTrigger = Get-AzDataShareTrigger -ResourceGroupName $ResourceGroupName -AccountName $AccountName -ShareSubscriptionName $SubName -Name $TriggerName

		Assert-NotNull $newTrigger
		Assert-AreEqual $newTrigger.Name $TriggerName
		Assert-AreEqual $newTrigger.ProvisioningState "Succeeded"

		$gottenTrigger = Get-AzDataShareTrigger -ResourceId $gottenTrigger.Id
	
		Assert-NotNull $newTrigger
		Assert-AreEqual $newTrigger.Name $TriggerName
		Assert-AreEqual $newTrigger.ProvisioningState "Succeeded"

		$removedTrigger = Remove-AzDataShareTrigger -InputObject $gottenTrigger
	}
	finally
	{
		Remove-AzResourceGroup -Name $resourceGroup -Force
	}
}