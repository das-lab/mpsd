














function Get-Cluster-Location
{
	return Get-Location "Microsoft.Kusto" "operations" "Central US"
}

function Get-RG-Location
{
	Get-Location "Microsoft.Resources" "resourceGroups" "Central US"
}


function Get-RG-Name
{
	return getAssetname
}


function Get-Cluster-Default-Capacity
{
	return 2
}


function Get-Cluster-Capacity
{
	return 5
}


function Get-Cluster-Updated-Capacity
{
	return 10
}


function Get-Cluster-Name
{
	return getAssetName
	
}


function Get-Sku
{
	return "D13_v2"
}


function Get-Updated-Sku
{
	return "D14_v2"
}


function Get-Cluster-Resource-Type
{
	return "Microsoft.Kusto/Clusters"
}


function Get-Cluster-Resource-Id
{
	Param([string]$Subscription,
		[string]$ResourceGroupName,
		[string]$ClusterName)
	return "/subscriptions/$Subscription/resourceGroups/$ResourceGroupName/providers/Microsoft.Kusto/clusters/$ClusterName"
}


function Get-Database-Resource-Id
{
	Param([string]$Subscription,
		[string]$ResourceGroupName,
		[string]$ClusterName,
		[string]$DatabaseName)
	$clusterResourceId = Get-Cluster-Resource-Id -Subscription $Subscription -ResourceGroupName $ResourceGroupName -ClusterName $ClusterName
	return "$clusterResourceId/databases/$DatabaseName"
}



function Get-Database-Name
{
	return getAssetName
}


function Get-Database-Type
{
	return "Microsoft.Kusto/Clusters/Databases"
}


function Get-Soft-Delete-Period-In-Days
{
	return 4
}


function Get-Hot-Cache-Period-In-Days
{
	return 2
}


function Get-Updated-Soft-Delete-Period-In-Days
{
	return 6
}


function Get-Updated-Hot-Cache-Period-In-Days
{
	return 3
}


function Get-Database-Not-Exist-Message
{
	Param([string]$DatabaseName)
	return "$DatabaseName' is not found"
}


function Get-Cluster-Not-Exist-Message
{
	Param([string]$ResourceGroupName,
		[string]$ClusterName)
	return "'Microsoft.Kusto/clusters/$ClusterName' under resource group '$ResourceGroupName' was not found"
}



function Get-Cluster-Name-Exists-Message
{
	Param([string]$ClusterName)
	return "Name '$ClusterName' with type Engine is already taken. Please specify a different name"
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