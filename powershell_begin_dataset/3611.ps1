













function Get-BandwidthScheduleName
{
	return getAssetName
}


function Test-GetNonExistingBandwidthSchedule
{	
	$rgname = Get-DeviceResourceGroupName
	$dfname = Get-DeviceName
	$bwname = Get-BandwidthScheduleName
	
	
	
	Assert-ThrowsContains { Get-AzDataBoxEdgeBandwidthSchedule -ResourceGroupName $rgname -DeviceName $dfname -Name $bwname } "not find"	
}


function Test-CreateBandwidthSchedule
{	
	$rgname = Get-DeviceResourceGroupName
	$dfname = Get-DeviceName
	$bwname = Get-BandwidthScheduleName
	$bwRateInMbps = 45
	$bwStartTime = "11:00:00"
	$bwStopTime = "13:00:00"
	$bwDaysOfWeek = "Sunday,Saturday"

	
	try
	{
		$expected = New-AzDataBoxEdgeBandwidthSchedule $rgname $dfname $bwname -DaysOfWeek $bwDaysOfWeek -StartTime $bwStartTime -StopTime $bwStopTime -Bandwidth $bwRateInMbps
		Assert-AreEqual $expected.Name $bwname
	}
	finally
	{
		Remove-AzDataBoxEdgeBandwidthSchedule $rgname $dfname $bwname
	}  
}


function Test-UpdateBandwidthSchedule
{	
	$rgname = Get-DeviceResourceGroupName
	$dfname = Get-DeviceName
	$bwname = Get-BandwidthScheduleName
	$bwRateInMbps = 45
	$bwStartTime = "14:00:00"
	$bwStopTime = "15:00:00"
	$bwDaysOfWeek = "Sunday,Saturday"
	$bwNewRateInMbps = 95
	
	
	try
	{
		New-AzDataBoxEdgeBandwidthSchedule $rgname $dfname $bwname -DaysOfWeek $bwDaysOfWeek -StartTime $bwStartTime -StopTime $bwStopTime -Bandwidth $bwRateInMbps
		$expected = Set-AzDataBoxEdgeBandwidthSchedule $rgname $dfname $bwname -Bandwidth $bwNewRateInMbps
		Assert-AreEqual $expected.BandwidthSchedule.RateInMbps $bwNewRateInMbps
	}
	finally
	{
		Remove-AzDataBoxEdgeBandwidthSchedule $rgname $dfname $bwname
	}  
}



function Test-CreateUnlimitedBandwidthSchedule
{	
	$rgname = Get-DeviceResourceGroupName
	$dfname = Get-DeviceName
	$bwname = Get-BandwidthScheduleName
	$bwStartTime = "17:00:00"
	$bwStopTime = "19:00:00"
	$bwDaysOfWeek = "Sunday,Saturday"
	$bwUnlimitedRateInMbps = 0
	
	
	try
	{
		$expected  = New-AzDataBoxEdgeBandwidthSchedule $rgname $dfname $bwname -DaysOfWeek $bwDaysOfWeek -StartTime $bwStartTime -StopTime $bwStopTime -UnlimitedBandwidth $true
		Assert-AreEqual $expected.BandwidthSchedule.RateInMbps $bwUnlimitedRateInMbps
	}
	finally
	{
		Remove-AzDataBoxEdgeBandwidthSchedule $rgname $dfname $bwname
	}  
}



function Test-RemoveBandwidthSchedule
{	
	$rgname = Get-DeviceResourceGroupName
	$dfname = Get-DeviceName
	$bwname = Get-BandwidthScheduleName
	$bwRateInMbps = 45
	$bwStartTime = "11:00:00"
	$bwStopTime = "13:00:00"
	$bwDaysOfWeek = "Sunday,Saturday"

	
	try
	{
		$expected = New-AzDataBoxEdgeBandwidthSchedule $rgname $dfname $bwname -DaysOfWeek $bwDaysOfWeek -StartTime $bwStartTime -StopTime $bwStopTime -Bandwidth $bwRateInMbps
		Assert-AreEqual $expected.Name $bwname
		Remove-AzDataBoxEdgeBandwidthSchedule $rgname $dfname $bwname
	}
	finally
	{
		Assert-ThrowsContains { Get-AzDataBoxEdgeBandwidthSchedule -ResourceGroupName $rgname -DeviceName $dfname -Name $bwname } "not find"	
	}  
}
