













function Get-RoleName
{
	return getAssetName
}



function Test-GetRoleNonExistent
{	
	$rgname = Get-DeviceResourceGroupName
	$dfname = Get-DeviceName
	$name = Get-RoleName
	
	
	Assert-ThrowsContains { Get-AzDataBoxEdgeRole $rgname $dfname $name  } "not find"	
}


function Test-CreateRole
{	
	$rgname = Get-DeviceResourceGroupName
	$dfname = Get-DeviceName
	$name = Get-RoleName

	$deviceConnectionString = Get-DeviceConnectionString
	$deviceConnSec = ConvertTo-SecureString $deviceConnectionString -AsPlainText -Force

	$iotDeviceConnectionString = Get-IotDeviceConnectionString
	$iotDeviceConnSec = ConvertTo-SecureString $iotDeviceConnectionString -AsPlainText -Force

	$encryptionKeyString = Get-EncryptionKey 
	$encryptionKey = ConvertTo-SecureString $encryptionKeyString -AsPlainText -Force

	$enabled = "Enabled"
	$platform = "Windows"
	
	try
	{
		$expected  = New-AzDataBoxEdgeRole -ResourceGroupName $rgname -DeviceName $dfname -Name $name -ConnectionString -IotEdgeDeviceConnectionString $iotDeviceConnSec -IotDeviceConnectionString $deviceConnSec -Platform $platform -RoleStatus $enabled -EncryptionKey $encryptionKey
		Assert-AreEqual $expected.Name $name	
	}
	finally
	{
		Remove-AzDataBoxEdgeRole $rgname $dfname $name
	}  
}


function Test-RemoveRole
{	
	$rgname = Get-DeviceResourceGroupName
	$dfname = Get-DeviceName
	$name = Get-RoleName

	
	$deviceConnectionString = Get-DeviceConnectionString
	$deviceConnSec = ConvertTo-SecureString $deviceConnectionString -AsPlainText -Force

	$iotDeviceConnectionString = Get-IotDeviceConnectionString
	$iotDeviceConnSec = ConvertTo-SecureString $iotDeviceConnectionString -AsPlainText -Force

	$encryptionKeyString = Get-EncryptionKey 
	$encryptionKey = ConvertTo-SecureString $encryptionKeyString -AsPlainText -Force

	$enabled = "Enabled"
	$platform = "Windows"
	
	try
	{
		$expected  = New-AzDataBoxEdgeRole -ResourceGroupName $rgname -DeviceName $dfname -Name $name -ConnectionString -IotEdgeDeviceConnectionString $iotDeviceConnSec -IotDeviceConnectionString $deviceConnSec -Platform $platform -RoleStatus $enabled -EncryptionKey $encryptionKey
		Remove-AzDataBoxEdgeRole $rgname $dfname $name
	}
	finally
	{
		Assert-ThrowsContains { Get-AzDataBoxEdgeRole $rgname $dfname $name  } "not find"	
	}  
}