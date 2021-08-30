













function Get-StorageAccountCredentialName
{
	return getAssetName
}


function Test-GetStorageAccountCredentialNonExistent
{	
	$rgname = Get-DeviceResourceGroupName
	$dfname = Get-DeviceName
	$staname = Get-StorageAccountCredentialName
	
	
	Assert-ThrowsContains { Get-AzDataBoxEdgeStorageAccountCredential $rgname $dfname $staname  } "not find"
}


function Test-CreateStorageAccountCredential
{	
	$rgname = Get-DeviceResourceGroupName
	$dfname = Get-DeviceName
	$staname = Get-StorageAccountCredentialName
	$encryptionKeyString = Get-EncryptionKey 
	$encryptionKey = ConvertTo-SecureString $encryptionKeyString -AsPlainText -Force

	$storageAccountType = 'GeneralPurposeStorage'
	$storageAccountSkuName = 'Standard_LRS'
	$storageAccountLocation = 'WestUS'
	$storageAccount = New-AzStorageAccount $rgname $staname $storageAccountSkuName -Location $storageAccountLocation

	$storageAccountKeys = Get-AzStorageAccountKey $rgname $staname
	$storageAccountKey = ConvertTo-SecureString $storageAccountKeys[0] -AsPlainText -Force
	
	try
	{
		$expected = New-AzDataBoxEdgeStorageAccountCredential $rgname $dfname $staname -StorageAccountType $storageAccountType -StorageAccountAccessKey $storageAccountKey -EncryptionKey $encryptionKey
		Assert-AreEqual $expected.Name $staname
		
	}
	finally
	{
		Remove-AzDataBoxEdgeStorageAccountCredential $rgname $dfname $staname
		Remove-AzStorageAccount $rgname $staname
	}  
}


function Test-RemoveStorageAccountCredential
{	
	 $rgname = Get-DeviceResourceGroupName
	$dfname = Get-DeviceName
	$staname = Get-StorageAccountCredentialName
	$encryptionKeyString = Get-EncryptionKey 
	$encryptionKey = ConvertTo-SecureString $encryptionKeyString -AsPlainText -Force

	$storageAccountType = 'GeneralPurposeStorage'
	$storageAccountSkuName = 'Standard_LRS'
	$storageAccountLocation = 'WestUS'
	$storageAccount = New-AzStorageAccount $rgname $staname $storageAccountSkuName -Location $storageAccountLocation

	$storageAccountKeys = Get-AzStorageAccountKey $rgname $staname
	$storageAccountKey = ConvertTo-SecureString $storageAccountKeys[0] -AsPlainText -Force
	
	try
	{
		New-AzDataBoxEdgeStorageAccountCredential $rgname $dfname $staname -StorageAccountType $storageAccountType -StorageAccountAccessKey $storageAccountKey -EncryptionKey $encryptionKey
		Remove-AzDataBoxEdgeStorageAccountCredential $rgname $dfname $staname
	}
	finally
	{
		Assert-ThrowsContains { Get-AzDataBoxEdgeStorageAccountCredential $rgname $dfname $staname  } "not find"	
		Remove-AzStorageAccount $rgname $staname 
	}  
}
