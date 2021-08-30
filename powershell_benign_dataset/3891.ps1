














function Get-RandomSignalRName
{
	param([string]$prefix = "signalr-test-")
	return $prefix + (getAssetName)
}


function Get-RandomResourceGroupName
{
	param([string]$prefix = "signalr-test-rg-")
	return $prefix + (getAssetName)
}


function Assert-LocationEqual
{
	param([string]$loc1, [string]$loc2)

	$loc1 = $loc1.ToLower().Replace(" ", "")
	$loc2 = $loc2.ToLower().Replace(" ", "")
	Assert-AreEqual $loc1 $loc2
}


function Get-ProviderLocation([string]$provider)
{
	if ([Microsoft.Azure.Test.HttpRecorder.HttpMockServer]::Mode -ne [Microsoft.Azure.Test.HttpRecorder.HttpRecorderMode]::Playback)
	{
		$namespace = $provider.Split("/")[0]
		if($provider.Contains("/"))
		{
			$type = $provider.Substring($namespace.Length + 1)
			$location = Get-AzResourceProvider -ProviderNamespace $namespace | where {$_.ResourceTypes[0].ResourceTypeName -eq $type}

			if ($location -eq $null)
			{
				return "East US"
			}
			else
			{
				return $location.Locations[0].ToLower() -replace '\s',''
			}
		}

		return "East US"
	}

	return "East US"
}
