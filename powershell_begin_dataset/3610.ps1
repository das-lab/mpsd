













function Get-StorageAccountCredentialName
{
	return getAssetName
}

function Get-ShareName
{
	return getAssetName
}




function Test-GetShareNonExistent
{	
	$rgname = Get-DeviceResourceGroupName
	$dfname = Get-DeviceName
	$sharename = Get-ShareName
	
	
	Assert-ThrowsContains { Get-AzDataBoxEdgeShare $rgname $dfname $sharename  } "not find"	
}


function Test-CreateShare
{	
	$rgname = Get-DeviceResourceGroupName
	$dfname = Get-DeviceName
	$sharename = Get-ShareName
	$dataFormat = 'BlockBlob'


	$staname = Get-StorageAccountCredentialName
	$encryptionKeyString = Get-EncryptionKey 
	$encryptionKey = ConvertTo-SecureString $encryptionKeyString -AsPlainText -Force
	$storageAccountType = 'GeneralPurposeStorage'
	$storageAccountSkuName = 'Standard_LRS'
	$storageAccountLocation = 'WestUS'
	$storageAccount = New-AzStorageAccount $rgname $staname $storageAccountSkuName -Location $storageAccountLocation

	$storageAccountKeys = Get-AzStorageAccountKey $rgname $staname
	$storageAccountKey = ConvertTo-SecureString $storageAccountKeys[0] -AsPlainText -Force
	$storageAccountCredential = New-AzDataBoxEdgeStorageAccountCredential $rgname $dfname $staname -StorageAccountType $storageAccountType -StorageAccountAccessKey $storageAccountKey -EncryptionKey $encryptionKey
		
	
	try
	{
		$expected = New-AzDataBoxEdgeShare $rgname $dfname $sharename $storageAccountCredential.Name -Smb -DataFormat $dataFormat
		Assert-AreEqual $expected.Name $sharename
		
	}
	finally
	{
		Remove-AzDataBoxEdgeShare $rgname $dfname $sharename
		Remove-AzDataBoxEdgeStorageAccountCredential $rgname $dfname $staname
		Remove-AzStorageAccount $rgname $staname
	}  
}


function Test-RemoveShare
{	
	$rgname = Get-DeviceResourceGroupName
	$dfname = Get-DeviceName
	$sharename = Get-ShareName
	$dataFormat = 'BlockBlob'


	$staname = Get-StorageAccountCredentialName
	$encryptionKeyString = Get-EncryptionKey 
	$encryptionKey = ConvertTo-SecureString $encryptionKeyString -AsPlainText -Force

	$storageAccountType = 'GeneralPurposeStorage'
	$storageAccountSkuName = 'Standard_LRS'
	$storageAccountLocation = 'WestUS'
	$storageAccount = New-AzStorageAccount $rgname $staname $storageAccountSkuName -Location $storageAccountLocation

	$storageAccountKeys = Get-AzStorageAccountKey $rgname $staname
	$storageAccountKey = ConvertTo-SecureString $storageAccountKeys[0] -AsPlainText -Force
	$storageAccountCredential = New-AzDataBoxEdgeStorageAccountCredential $rgname $dfname $staname -StorageAccountType $storageAccountType -StorageAccountAccessKey $storageAccountKey -EncryptionKey $encryptionKey
		
	
	try
	{
		$expected = New-AzDataBoxEdgeShare $rgname $dfname $sharename $storageAccountCredential.Name -Smb -DataFormat $dataFormat
		Remove-AzDataBoxEdgeShare $rgname $dfname $sharename
		Assert-ThrowsContains { Get-AzDataBoxEdgeShare $rgname $dfname $sharename  } "not find"	

		
	}
	finally
	{
		Remove-AzDataBoxEdgeStorageAccountCredential $rgname $dfname $staname
		Remove-AzStorageAccount $rgname $staname
	}  
}
