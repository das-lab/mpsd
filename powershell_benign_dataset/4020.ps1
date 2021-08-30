














function Test-AzureProvider
{
    $defaultProviders = Get-AzResourceProvider
    Assert-True { $defaultProviders.Length -gt 0 }

    $allProviders = Get-AzResourceProvider -ListAvailable
    Assert-True { $allProviders.Length -gt $defaultProviders.Length }

	$ErrorActionPreference = "SilentlyContinue"
	$Error.Clear()

	$nonProviders = Get-AzResourceProvider -Location "abc"
	Assert-True { $Error[0].Contains("Provided location is not supported") }
	Assert-True { $nonProviders.Length -eq 0 }

	$ErrorActionPreference = "Stop"

	$globalProviders = Get-AzResourceProvider -Location "global"
	Assert-True { $globalProviders.Length -gt 0 }

    Register-AzResourceProvider -ProviderNamespace "Microsoft.ApiManagement"

    $endTime = [DateTime]::UtcNow.AddMinutes(5)

    while ([DateTime]::UtcNow -lt $endTime -and @(Get-AzResourceProvider -ProviderNamespace "Microsoft.ApiManagement")[0].RegistrationState -ne "Registered")
    {
        [Microsoft.WindowsAzure.Commands.Utilities.Common.TestMockSupport]::Delay(1000)
    }
	$provider = Get-AzResourceProvider -ProviderNamespace "Microsoft.ApiManagement"
    Assert-True { $provider[0].RegistrationState -eq "Registered" } 

    Unregister-AzResourceProvider -ProviderNamespace "Microsoft.ApiManagement"

    while ([DateTime]::UtcNow -lt $endTime -and @(Get-AzResourceProvider -ProviderNamespace "Microsoft.ApiManagement")[0].RegistrationState -ne "Unregistered")
    {
        [Microsoft.WindowsAzure.Commands.Utilities.Common.TestMockSupport]::Delay(1000)
    }
	$provider = Get-AzResourceProvider -ProviderNamespace "Microsoft.ApiManagement"
    Assert-True { $provider[0].RegistrationState -eq "Unregistered" }
 }

 
function Test-AzureProvider-WithZoneMappings
{
    $testProvider = Get-AzResourceProvider -ProviderNamespace "Providers.Test"
	Assert-True { $testProvider.Count -gt 0 }

	$statefulResources = $testProvider | where-object {$_.ResourceTypes.ResourceTypeName -contains "statefulResources"}

	Assert-NotNull { $statefulResources }
	Assert-NotNull { $statefulResources.ZoneMappings }

	Assert-True { $statefulResources.ZoneMappings.Count -eq 2 }
	Assert-True { $statefulResources.ZoneMappings["West Europe"] -contains "3"}
}


function Test-AzureProviderOperation
{
    
    $allActions = Get-AzProviderOperation
	Assert-True { $allActions.Length -gt 0 }

	
	$insightsActions = Get-AzProviderOperation Microsoft.Insights/*
	$insightsActions
	Assert-True { $insightsActions.Length -gt 0 }
	Assert-True { $allActions.Length -gt $insightsActions.Length }

	
	$eventgridActions = Get-AzProviderOperation Microsoft.EventGrid/*
	$eventgridActions
	Assert-True { $eventgridActions.Length -gt 0 }
	Assert-True { $allActions.Length -gt $eventgridActions.Length }

	
	$nonInsightsActions = $allActions | Where-Object { $_.Operation.ToLower().StartsWith("microsoft.insights/") -eq $false }
	$actualLength = $allActions.Length - $nonInsightsActions.Length;
	$expectedLength = $insightsActions.Length;
	Assert-True { $actualLength -eq  $expectedLength }

	foreach ($action in $insightsActions)
	{
	    Assert-True { $action.Operation.ToLower().StartsWith("microsoft.insights/"); }
	    Assert-NotNull $action.isDataAction
	}

	
	$insightsCaseActions = Get-AzProviderOperation MicROsoFt.InSIghTs/*
	Assert-True { $insightsCaseActions.Length -gt 0 }
	Assert-True { $insightsCaseActions.Length -eq $insightsActions.Length }
	foreach ($action in $insightsCaseActions)
	{
		Assert-True { $action.Operation.ToLower().Startswith("microsoft.insights/"); }
	    Assert-NotNull $action.isDataAction
	}

	
	$insightsReadActions = Get-AzProviderOperation Microsoft.Insights/*/read
	Assert-True { $insightsReadActions.Length -gt 0 }
	Assert-True { $insightsActions.Length -gt $insightsReadActions.Length }
	foreach ($action in $insightsReadActions)
	{
	    Assert-True { $action.Operation.ToLower().EndsWith("/read"); }
		Assert-True { $action.Operation.ToLower().StartsWith("microsoft.insights/");}
	    Assert-NotNull $action.isDataAction
	}

	
	$readActions = Get-AzProviderOperation */read
	Assert-True { $readActions.Length -gt 0 }
	Assert-True { $readActions.Length -lt $allActions.Length }
	Assert-True { $readActions.Length -gt $insightsReadActions.Length }

	foreach ($action in $readActions)
	{
	    Assert-True { $action.Operation.ToLower().EndsWith("/read"); }
	    Assert-NotNull $action.isDataAction
	}

	
	$action = Get-AzProviderOperation Microsoft.OperationalInsights/workspaces/usages/read
	Assert-AreEqual $action.Operation.ToLower() "Microsoft.OperationalInsights/workspaces/usages/read".ToLower();

	
	$action = Get-AzProviderOperation Microsoft.OperationalInsights/workspaces/usages/read/123
	Assert-True { $action.Length -eq 0 }

	
	$exceptionMessage = "Provider 'NonExistentProvider' not found.";
	Assert-Throws { Get-AzProviderOperation NonExistentProvider/* } $exceptionMessage

	
	Assert-Throws { Get-AzProviderOperation NonExistentProvider/servers/read } $exceptionMessage

	
	$exceptionMessage = "Individual parts in the search string should either equal * or not contain *.";
	Assert-Throws {Get-AzProviderOperation Microsoft.ClassicCompute/virtual*/read } $exceptionMessage

	
	$exceptionMessage = "To get all operations under Microsoft.Sql, please specify the search string as Microsoft.Sql/*.";
	Assert-Throws {Get-AzProviderOperation Microsoft.Sql } $exceptionMessage

	
	$exceptionMessage = "Wildcard character ? is not supported.";
	Assert-Throws {Get-AzProviderOperation Microsoft.Sql/servers/*/rea? } $exceptionMessage
 }

 
function Test-AzureProviderOperationDataActions
{

	
	$storageDataActions = Get-AzProviderOperation Microsoft.Storage/storageAccounts/blobServices/containers/blobs/*

	foreach ($action in $storageDataActions)
	{
	    Assert-NotNull $action
	    Assert-AreEqual $action.isDataAction $true
	}

 }