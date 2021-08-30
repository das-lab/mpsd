













$TestOutputRoot = [System.AppDomain]::CurrentDomain.BaseDirectory;
$ResourcesPath = Join-Path (Join-Path $TestOutputRoot "ScenarioTests") "Resources"


function Get-WebsiteName
{
    return getAssetName
}


function Get-TrafficManagerProfileName
{
    return getAssetName
}


function Get-WebHostPlanName
{
    return getAssetName 
}


function Get-ResourceGroupName
{
    return getAssetName
}


function Get-BackupName
{
    return getAssetName
}


function Get-AseName
{
    return getAssetName
}


function Get-WebsitesTestMode {
    try {
        $testMode = [Microsoft.Azure.Test.HttpRecorder.HttpMockServer]::Mode;
        $testMode = $testMode.ToString();
    } catch {
        if ($PSItem.Exception.Message -like '*Unable to find type*') {
            $testMode = 'Record';
        } else {
            throw;
        }
    }

    return $testMode
}


function Get-WebLocation
{
	if ((Get-WebsitesTestMode) -ne 'Playback')
	{
		$namespace = "Microsoft.Web"
		$type = "sites"
		$location = Get-AzResourceProvider -ProviderNamespace $namespace | where {$_.ResourceTypes[0].ResourceTypeName -eq $type}
  
		if ($location -eq $null) 
		{  
			return "West US"  
		} else 
		{  
			return $location.Locations[0]  
		}
	}

	return "West US"
}


function Get-SecondaryLocation
{
	if ((Get-WebsitesTestMode) -ne 'Playback')
	{
		$namespace = "Microsoft.Web"
		$type = "sites"
		$location = Get-AzResourceProvider -ProviderNamespace $namespace | where {$_.ResourceTypes[0].ResourceTypeName -eq $type}
  
		if ($location -eq $null) 
		{  
			return "West US"  
		} else 
		{  
			return $location.Locations[1]  
		}
	}

	return "West US"
}


function Clean-Website($resourceGroup, $websiteName)
{
    if ((Get-WebsitesTestMode) -ne 'Playback') 
	{
		$result = Remove-AzWebsite -ResourceGroupName $resourceGroup.ToString() -WebsiteName $websiteName.ToString() -Force
    }
}

function PingWebApp($webApp)
{
	if ((Get-WebsitesTestMode) -ne 'Playback') 
	{
		
		Start-Sleep -Seconds 30

		try 
		{
			$result = Invoke-WebRequest $webApp.HostNames[0] -UseBasicParsing
			$statusCode = $result.StatusCode
		} 
		catch [System.Net.WebException ] 
		{ 
			$statusCode = $_.Exception.Response.StatusCode
		}

		return $statusCode
    }
}


function Get-SasUri
{
    param ([string] $storageAccount, [string] $storageKey, [string] $container, [TimeSpan] $duration, [Microsoft.WindowsAzure.Storage.Blob.SharedAccessBlobPermissions] $type)

	$uri = "https://$storageAccount.blob.core.windows.net/$container"

	$destUri = New-Object -TypeName System.Uri($uri);
	$cred = New-Object -TypeName Microsoft.WindowsAzure.Storage.Auth.StorageCredentials($storageAccount, $storageKey);
	$destBlob = New-Object -TypeName Microsoft.WindowsAzure.Storage.Blob.CloudPageBlob($destUri, $cred);
	$policy = New-Object Microsoft.WindowsAzure.Storage.Blob.SharedAccessBlobPolicy;
	$policy.Permissions = $type;
	$policy.SharedAccessExpiryTime = (Get-Date).Add($duration);
	$uri += $destBlob.GetSharedAccessSignature($policy);

	return $uri;
}
