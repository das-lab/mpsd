














function Get-DataLakeStoreAccountName
{
    return getAssetName
}


function Get-DataLakeAnalyticsAccountName
{
    return getAssetName
}


function Get-ResourceGroupName
{
    return getAssetName
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