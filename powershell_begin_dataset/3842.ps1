














function Get-RandomRegistryName
{
    return 'reg' + (getAssetName)
}


function Get-RandomResourceGroupName
{
    return 'rg' + (getAssetName)
}


function Get-RandomReplicationName
{
	return 'rep' + (getAssetName)
}


function Get-RandomWebhookName
{
	return 'wh' + (getAssetName)
}


function Get-ProviderLocation($provider)
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
				return "West US"
			} else
			{
				return $location.Locations[0].ToLower() -replace '\s',''
			}
		}

		return "West US"
	}

	return "West US"
}

function Assert-Error
{
	param([ScriptBlock] $script, [string] $message)

	$originalErrorCount = $error.Count
	$originalErrorActionPreference = $ErrorActionPreference
	$ErrorActionPreference = "SilentlyContinue"
	try
	{
		&$script
	}
	finally
	{
		$ErrorActionPreference = $originalErrorActionPreference
	}

	$result = $Error[0] -like "*$($message)*"

	If(!$result)
	{
		 Write-Output "expected error $($message), actual error $($Error[0])"
	}

	Assert-True {$result}

	$Error.Clear()
}