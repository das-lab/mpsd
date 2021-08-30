













function Get-PSResourceGroupName
{
	return Get-DeviceResourceGroupName
}

function Get-PSDeviceName
{
	return getAssetName
}


function Test-GetDeviceNonExistent
{	
	$rgname = Get-PSResourceGroupName
	$dfname = Get-PSDeviceName
	
	
	Assert-ThrowsContains { Get-AzDataBoxEdgeDevice $rgname $dfname } "not found"	
}


function Test-CreateDevice
{	
	$rgname = Get-PSResourceGroupName
	$dfname = Get-PSDeviceName
	$sku = 'Edge'
	$location = 'westus2'

	
	try
	{
		$expected = New-AzDataBoxEdgeDevice $rgname $dfname -Sku $sku -Location $location
		Assert-AreEqual $expected.Name $dfname
		
	}
	finally
	{
		Remove-AzDataBoxEdgeDevice $rgname $dfname
	}  
}


function Test-RemoveDevice
{	
	$rgname = Get-PSResourceGroupName
	$dfname = Get-PSDeviceName
	$sku = 'Edge'
	$location = 'westus2'

		
	
	$expected = New-AzDataBoxEdgeDevice $rgname $dfname -Sku $sku -Location $location
	Remove-AzDataBoxEdgeDevice $rgname $dfname
	Assert-ThrowsContains { Get-AzDataBoxEdgeDevice $rgname $dfname } "not found"
	
}
