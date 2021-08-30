














function Get-AnalysisServicesServerName
{
    return getAssetName
}


function Get-ResourceGroupName
{
    return getAssetName
}


function Get-AnalysisServicesLocation
{
    return Get-Location -providerNamespace "Microsoft.AnalysisServices" -resourceType "servers" -preferredLocation "West US"
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