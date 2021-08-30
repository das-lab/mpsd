













function Get-RandomLetters
{
	return -join ((97..122) | Get-Random -Count 5 | % {[char]$_})
}


function Get-WebsiteName
{
    return "someuniqueWebsite$(Get-RandomLetters)"
}


function Get-TrafficManagerProfileName
{
    return "someuniqueTrafficManager"
}


function Get-WebHostPlanName
{
    return "hostplan231" 
}


function Get-ResourceGroupName
{
    return "rg$(Get-RandomLetters)"
}


function Get-BackupName
{
    return "someuniqueBackupName"
}


function Get-AseName
{
    return "someuniqueAseName"
}


function Get-Location
{
	$namespace = "Microsoft.Web"
	$type = "sites"
	$location = Get-AzureRmResourceProvider -ProviderNamespace $namespace | where {$_.ResourceTypes[0].ResourceTypeName -eq $type}

	if ($location -eq $null) 
	{  
		return "West US"  
	} else 
	{  
		return $location.Locations[0]  
	}
}


function Get-SecondaryLocation
{
	$namespace = "Microsoft.Web"
	$type = "sites"
	$location = Get-AzureRmResourceProvider -ProviderNamespace $namespace | where {$_.ResourceTypes[0].ResourceTypeName -eq $type}

	if ($location -eq $null) 
	{  
		return "East US"  
	} else 
	{  
		return $location.Locations[1]  
	}

	return "EastUS"
}


function Clean-Website($resourceGroup, $websiteName)
{
	$result = Remove-AzureRmWebsite -ResourceGroupName $resourceGroup.ToString() -WebsiteName $websiteName.ToString() -Force
}

function PingWebApp($webApp)
{
	try 
	{
		$result = Invoke-WebRequest $webApp.HostNames[0] 
		$statusCode = $result.StatusCode
	} 
	catch [System.Net.WebException ] 
	{ 
		$statusCode = $_.Exception.Response.StatusCode
	}

		return $statusCode
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
