

















function Get-DeviceConnectionString 
{
	return "";
}


function Get-IotDeviceConnectionString 
{
	return "";
}


function Get-EncryptionKey
{
	return "";
}


function Get-Userpassword
{
	return "";
}




function Get-DeviceResourceGroupName
{
	return "psrgpfortest"
}


function Get-DeviceName
{
	return "psdataboxedgedevice"
}


function Get-StringHash([String] $String,$HashName = "MD5")
{
	$StringBuilder = New-Object System.Text.StringBuilder
	[System.Security.Cryptography.HashAlgorithm]::Create($HashName).ComputeHash([System.Text.Encoding]::UTF8.GetBytes($String))|%{[Void]$StringBuilder.Append($_.ToString("x2"))}
	$StringBuilder.ToString()
}



function Get-EncryptionKeyForDevice($resourceGroupName, $deviceName)
{

	$sp = Get-AzADServicePrincipal -ApplicationId "2368d027-f996-4edb-bf48-928f98f2ab8c"
	$e = Get-AzDataBoxEdgeDevice -ResourceGroupName $resourceGroupName -DeviceName $deviceName -ExtendedInfo
	$k = $sp.Id+$e.ResourceKey
	return Get-StringHash $k "SHA512"
}





function Get-StorageAccountName
{
	return getAssetName
}


function Assert-Tags($tags1, $tags2)
{
	if($tags1.count -ne $tags2.count)
	{
		throw "Tag size not equal. Tag1: $tags1.count Tag2: $tags2.count"
	}

	foreach($key in $tags1.Keys)
	{
		if($tags1[$key] -ne $tags2[$key])
		{
			throw "Tag content not equal. Key:$key Tags1:" +  $tags1[$key] + "Tags2:" + $tags2[$key]
		}
	}
}



function SleepInRecordMode ([int]$SleepIntervalInSec)
{
	$mode = $env:AZURE_TEST_MODE
	if ( $mode -ne $null -and $mode.ToUpperInvariant() -eq "RECORD")
	{
		Wait-Seconds $SleepIntervalInSec 
	}
}

