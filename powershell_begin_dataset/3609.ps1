













function Get-User
{
	return getAssetName
}


function Test-GetNonExistingUser
{	
	$rgname = Get-DeviceResourceGroupName
	$dfname = Get-DeviceName
	$name = Get-User
	
	
	Assert-ThrowsContains { Get-AzDataBoxEdgeUser -ResourceGroupName $rgname -DeviceName $dfname -Name $name  } "not find"	
}



function Test-CreateNewUser
{	
	$rgname = Get-DeviceResourceGroupName
	$dfname = Get-DeviceName
	$name = Get-User
	
	$passwordString = Get-Userpassword
	$password = ConvertTo-SecureString $passwordString -AsPlainText -Force
	$encryptionKeyString = Get-EncryptionKey 
	$encryptionKey = ConvertTo-SecureString $encryptionKeyString -AsPlainText -Force

	
	
	try
	{
		$expected = New-AzDataBoxEdgeUser $rgname $dfname $name -Password $password -EncryptionKey $encryptionKey
		Assert-AreEqual $expected.Name $name
	}
	finally
	{
		Remove-AzDataBoxEdgeUser $rgname $dfname $name
	}  
}



function Test-RemoveUser
{	
	$rgname = Get-DeviceResourceGroupName
	$dfname = Get-DeviceName
	$name = Get-User

	$passwordString = Get-Userpassword
	$password = ConvertTo-SecureString $passwordString -AsPlainText -Force
	$encryptionKeyString = Get-EncryptionKey 
	$encryptionKey = ConvertTo-SecureString $encryptionKeyString -AsPlainText -Force

	
	try
	{
		$expected = New-AzDataBoxEdgeUser $rgname $dfname $name -Password $password -EncryptionKey $encryptionKey
		Assert-AreEqual $expected.Name $name
		Remove-AzDataBoxEdgeUser $rgname $dfname $name
	}
	finally
	{
		Assert-ThrowsContains { Get-AzDataBoxEdgeUser -ResourceGroupName $rgname -DeviceName $dfname -Name $name  } "not find"	
	}  
}