





function Test-SourceDataSetsCrud
{
    $resourceGroup = getAssetName
    $AccountName = getAssetName
    $ShareSubscriptionName = getAssetName
	$SourceDataSets = Get-AzDataShareSourceDataSet -ResourceGroupName $resourceGroup -AccountName $AccountName -ShareSubscriptionName $ShareSubscriptionName

	Assert-NotNull $SourceDataSets
}
