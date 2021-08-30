





function Test-InvitationCrud
{
    $resourceGroup = getAssetName

	try
	{
		$AccountName = getAssetName
		$ShareName = getAssetName
		$InvitationName = getAssetName
		$targetEmail = "test@microsoft.com"
		$createdInvitation = New-AzDataShareInvitation -AccountName $AccountName -ResourceGroupName $resourceGroup -ShareName $ShareName -Name $InvitationName -TargetEmail $targetEmail

		Assert-NotNull $createdInvitation
		Assert-AreEqual $InvitationName $createdInvitation.Name
		Assert-AreEqual "test@microsoft.com" $createdInvitation.TargetEmail
		Assert-AreEqual "Pending" $createdInvitation.InvitationStatus

		$retrievedInvitation = Get-AzDataShareInvitation -AccountName $AccountName -ResourceGroupName $resourceGroup -ShareName $ShareName -Name $InvitationName

		Assert-NotNull $retrievedInvitation
		Assert-AreEqual $InvitationName $retrievedInvitation.Name
		Assert-AreEqual "Pending" $retrievedInvitation.InvitationStatus

		$removed = Remove-AzDataShareInvitation -AccountName $AccountName -ResourceGroupName $resourceGroup -ShareName $ShareName -Name $InvitationName -PassThru

		Assert-True { $removed }
		Assert-ThrowsContains { Get-AzDataShareInvitation -AccountName $AccountName -ResourceGroupName $resourceGroup -ShareName $ShareName -Name $InvitationName} "Resource 'sdktestinginvitation' does not exist"
	}
    finally
	{
		Remove-AzResourceGroup -Name $resourceGroup -Force
	}
}