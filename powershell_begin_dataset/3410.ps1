














function Test-GetWebApp
{
	
	$rgname = Get-ResourceGroupName
	$wname = Get-WebsiteName
	$wname2 = "$(Get-WebsiteName)Second"
	$location = Get-Location
	$whpName = Get-WebHostPlanName
	$tier = "Shared"
	$apiversion = "2015-08-01"
	$resourceType = "Microsoft.Web/sites"

	try
	{
		try 
		{
			Remove-AzureRmResourceGroup -Name $rgname -Force
		}
		catch [Exception]
		{
		}

		
		New-AzureRmResourceGroup -Name $rgname -Location $location -Force
		$serverFarm = New-AzureRmAppServicePlan -ResourceGroupName $rgname -Name  $whpName -Location  $location -Tier $tier
		
		
		$actual = New-AzureRmWebApp -ResourceGroupName $rgname -Name $wname -Location $location -AppServicePlan $whpName 
		
		
		Assert-AreEqual $wname $actual.Name
		Assert-AreEqual $serverFarm.Id $actual.ServerFarmId
		
		
		$result = Get-AzureRmWebApp -Name $wname

		
		Assert-AreEqual $wname $actual.Name
		Assert-AreEqual $serverFarm.Id $actual.ServerFarmId

		
		$actual = New-AzureRmWebApp -ResourceGroupName $rgname -Name $wname2 -Location $location -AppServicePlan $whpName

		
		Assert-AreEqual $wname2 $actual.Name
		Assert-AreEqual $serverFarm.Id $actual.ServerFarmId

		
		$result = Get-AzureRmWebApp

		
		Assert-True { $result.Count -ge 2 }

		
		$result = Get-AzureRmWebApp -Location $location
		
		
		Assert-True { $result.Count -ge 2 }
		
		
		$result = Get-AzureRmWebApp -ResourceGroupName $rgname
		
		
		Assert-AreEqual 2 $result.Count

		
		$result = Get-AzureRmWebApp -AppServicePlan $serverFarm
		
		
		Assert-True { $result.Count -ge 2 }

	}
	finally
	{
		Remove-AzureRmResourceGroup -Name $rgname -Force
	}
}


function Test-GetWebAppMetrics
{
	
	$rgname = Get-ResourceGroupName
	$wname = Get-WebsiteName
	$location = Get-Location
	$whpName = Get-WebHostPlanName
	$tier = "Shared"
	$apiversion = "2015-08-01"
	$resourceType = "Microsoft.Web/sites"

	try
	{
		
		New-AzureRmResourceGroup -Name $rgname -Location $location
		$serverFarm = New-AzureRmAppServicePlan -ResourceGroupName $rgname -Name  $whpName -Location  $location -Tier $tier
		
		
		$webapp = New-AzureRmWebApp -ResourceGroupName $rgname -Name $wname -Location $location -AppServicePlan $whpName 
		
		
		Assert-AreEqual $wname $webapp.Name
		Assert-AreEqual $serverFarm.Id $webapp.ServerFarmId
		
		for($i = 0; $i -lt 10; $i++)
		{
			PingWebApp $webapp
		}

		$endTime = Get-Date
		$startTime = $endTime.AddHours(-3)

		$metricnames = @('CPU', 'Requests')
		
		
		$metrics = Get-AzureRmWebAppMetrics -ResourceGroupName $rgname -Name $wname -Metrics $metricnames -StartTime $startTime -EndTime $endTime -Granularity PT1M

		$actualMetricNames = $metrics | Select -Expand Name | Select -Expand Value 

		foreach ($i in $metricnames)
		{
			Assert-True { $actualMetricNames -contains $i}
		}

		
		$metrics = $webapp | Get-AzureRmWebAppMetrics -Metrics $metricnames -StartTime $startTime -EndTime $endTime -Granularity PT1M

		$actualMetricNames = $metrics | Select -Expand Name | Select -Expand Value 

		foreach ($i in $metricnames)
		{
			Assert-True { $actualMetricNames -contains $i}
		}
	}
	finally
	{
		
		Remove-AzureRmResourceGroup -Name $rgname -Force
	}
}


function Test-StartStopRestartWebApp
{
	
	$rgname = Get-ResourceGroupName
	$wname = Get-WebsiteName
	$location = Get-Location
	$whpName = Get-WebHostPlanName
	$tier = "Shared"
	$apiversion = "2015-08-01"
	$resourceType = "Microsoft.Web/sites"

	try
	{
		
		New-AzureRmResourceGroup -Name $rgname -Location $location -Force
		$serverFarm = New-AzureRmAppServicePlan -ResourceGroupName $rgname -Name  $whpName -Location  $location -Tier $tier
		
		
		$webApp = New-AzureRmWebApp -ResourceGroupName $rgname -Name $wname -Location $location -AppServicePlan $whpName 
		
		
		Assert-AreEqual $wname $webApp.Name
		Assert-AreEqual $serverFarm.Id $webApp.ServerFarmId
		
		
		$webApp = $webApp | Stop-AzureRmWebApp

		Assert-AreEqual "Stopped" $webApp.State

		
		$webApp = $webApp | Start-AzureRmWebApp

		Assert-AreEqual "Running" $webApp.State

		
		$webApp = Stop-AzureRmWebApp -ResourceGroupName $rgname -Name $wname

		Assert-AreEqual "Stopped" $webApp.State

		
		$webApp = Start-AzureRmWebApp -ResourceGroupName $rgname -Name $wname

		Assert-AreEqual "Running" $webApp.State

		
		$webApp = Restart-AzureRmWebApp -ResourceGroupName $rgname -Name $wname

		Assert-AreEqual "Running" $webApp.State

		
		$webApp = $webApp | Restart-AzureRmWebApp

		Assert-AreEqual "Running" $webApp.State
	}
	finally
	{
		Remove-AzureRmResourceGroup -Name $rgname -Force
	}
}


function Test-CloneNewWebApp
{
	
	$rgname = Get-ResourceGroupName
	$appname = Get-WebsiteName
	$location = Get-Location
	$planName = Get-WebHostPlanName
	$tier = "Premium"
	$apiversion = "2015-08-01"
	$resourceType = "Microsoft.Web/sites"

	
	$destPlanName = Get-WebHostPlanName
	$destLocation = Get-SecondaryLocation
	$destAppName = Get-WebsiteName

	try
	{
		
		New-AzureRmResourceGroup -Name $rgname -Location $location
		$serverFarm = New-AzureRmAppServicePlan -ResourceGroupName $rgname -Name  $planName -Location  $location -Tier $tier
		
		
		$webapp = New-AzureRmWebApp -ResourceGroupName $rgname -Name $appname -Location $location -AppServicePlan $planName 
		
		
		Assert-AreEqual $appname $webapp.Name
		Assert-AreEqual $serverFarm.Id $webapp.ServerFarmId

		
		$webapp = Get-AzureRmWebApp -ResourceGroupName $rgname -Name $appname
		
		
		Assert-AreEqual $appname $webapp.Name
		Assert-AreEqual $serverFarm.Id $webapp.ServerFarmId

		
		$serverFarm2 = New-AzureRmAppServicePlan -ResourceGroupName $rgname -Name  $destPlanName -Location  $destLocation -Tier $tier

		
		$webapp2 = New-AzureRmWebApp -ResourceGroupName $rgname -Name $destAppName -Location $destLocation -AppServicePlan $destPlanName -SourceWebApp $webapp
		
		
		Assert-AreEqual $destAppName $webapp2.Name

		
		$webapp2 = Get-AzureRmWebApp -ResourceGroupName $rgname -Name $destAppName
		
		
		Assert-AreEqual $destAppName $webapp2.Name
	}
	finally
	{
		
		Remove-AzureRmWebApp -ResourceGroupName $rgname -Name $appname -Force
		Remove-AzureRmAppServicePlan -ResourceGroupName $rgname -Name  $planName -Force

		Remove-AzureRmWebApp -ResourceGroupName $rgname -Name $destAppName -Force
		Remove-AzureRmAppServicePlan -ResourceGroupName $rgname -Name  $destPlanName -Force
		Remove-AzureRmResourceGroup -Name $rgname -Force
	}
}


function Test-CloneNewWebAppAndDeploymentSlots
{
	
	$rgname = Get-ResourceGroupName
	$appname = Get-WebsiteName
	$slot1name = "staging"
	$slot2name = "testing"
	$location = Get-Location
	$planName = Get-WebHostPlanName
	$tier = "Premium"
	$apiversion = "2015-08-01"
	$resourceType = "Microsoft.Web/sites"

	
	$destPlanName = "$($planName)Destination"
	$destLocation = Get-SecondaryLocation
	$destAppName = "$($appname)Destination"

	try
	{
		
		New-AzureRmResourceGroup -Name $rgname -Location $location -Force
		$serverFarm = New-AzureRmAppServicePlan -ResourceGroupName $rgname -Name  $planName -Location  $location -Tier $tier
		
		
		$webapp = New-AzureRmWebApp -ResourceGroupName $rgname -Name $appname -Location $location -AppServicePlan $planName 
		
		
		Assert-AreEqual $appname $webapp.Name
		Assert-AreEqual $serverFarm.Id $webapp.ServerFarmId

		
		$webapp = Get-AzureRmWebApp -ResourceGroupName $rgname -Name $appname
		
		
		Assert-AreEqual $appname $webapp.Name
		Assert-AreEqual $serverFarm.Id $webapp.ServerFarmId

		
		$slot1 = New-AzureRmWebAppSlot -ResourceGroupName $rgname -Name $appname -Slot $slot1name -AppServicePlan $planName
		$appWithSlotName = "$appname/$slot1name"

		
		Assert-AreEqual $appWithSlotName $slot1.Name
		Assert-AreEqual $serverFarm.Id $slot1.ServerFarmId

		
		$slot2 = New-AzureRmWebAppSlot -ResourceGroupName $rgname -Name $appname -Slot $slot2name -AppServicePlan $planName
		$appWithSlotName = "$appname/$slot2name"

		
		Assert-AreEqual $appWithSlotName $slot2.Name
		Assert-AreEqual $serverFarm.Id $slot2.ServerFarmId

		
		$serverFarm2 = New-AzureRmAppServicePlan -ResourceGroupName $rgname -Name  $destPlanName -Location  $destLocation -Tier $tier

		
		$webapp2 = New-AzureRmWebApp -ResourceGroupName $rgname -Name $destAppName -Location $destLocation -AppServicePlan $destPlanName -SourceWebApp $webapp -IncludeSourceWebAppSlots
		
		
		Assert-AreEqual $destAppName $webapp2.Name

		
		$webapp2 = Get-AzureRmWebApp -ResourceGroupName $rgname -Name $destAppName
		
		
		Assert-AreEqual $destAppName $webapp2.Name

		
		$slot1 = Get-AzureRmWebAppSlot -ResourceGroupName $rgname -Name $destAppName -Slot $slot1name

		$appWithSlotName = "$destAppName/$slot1name"

		
		Assert-AreEqual $appWithSlotName $slot1.Name
		Assert-AreEqual $serverFarm2.Id $slot1.ServerFarmId

		
		$slot2 = Get-AzureRmWebAppSlot -ResourceGroupName $rgname -Name $destAppName -Slot $slot2name
		$appWithSlotName = "$destAppName/$slot2name"

		
		Assert-AreEqual $appWithSlotName $slot2.Name
		Assert-AreEqual $serverFarm2.Id $slot2.ServerFarmId
	}
	finally
	{
		
		Remove-AzureRmResourceGroup -Name $rgname -Force
	}
}


function Test-CloneNewWebAppWithTrafficManager
{
	
	$rgname = Get-ResourceGroupName
	$wname = Get-WebsiteName
	$location = Get-Location
	$whpName = Get-WebHostPlanName
	$tier = "Premium"
	$apiversion = "2015-08-01"
	$resourceType = "Microsoft.Web/sites"

	
	$destAppServicePlanName = "$(Get-WebHostPlanName)Destination"
	$destLocation = Get-SecondaryLocation
	$destWebAppName = "$(Get-WebsiteName)Destination"
	$profileName = Get-TrafficManagerProfileName

	try
	{
		
		New-AzureRmResourceGroup -Name $rgname -Location $location -Force
		$serverFarm = New-AzureRmAppServicePlan -ResourceGroupName $rgname -Name  $whpName -Location  $location -Tier $tier
		
		
		$actual = New-AzureRmWebApp -ResourceGroupName $rgname -Name $wname -Location $location -AppServicePlan $whpName 
		
		
		Assert-AreEqual $wname $actual.Name
		Assert-AreEqual $serverFarm.Id $actual.ServerFarmId

		
		$result = Get-AzureRmWebApp -ResourceGroupName $rgname -Name $wname
		
		
		Assert-AreEqual $wname $result.Name
		Assert-AreEqual $serverFarm.Id $result.ServerFarmId

		
		$serverFarm = New-AzureRmAppServicePlan -ResourceGroupName $rgname -Name  $destAppServicePlanName -Location  $destLocation -Tier $tier

		
		$actual = New-AzureRmWebApp -ResourceGroupName $rgname -Name $destWebAppName -Location $destLocation -AppServicePlan $destAppServicePlanName -SourceWebApp $result -TrafficManagerProfileName $profileName
		
		
		Assert-AreEqual $destWebAppName $actual.Name

		
		$result = Get-AzureRmWebApp -ResourceGroupName $rgname -Name $destWebAppName
		
		
		Assert-AreEqual $destWebAppName $result.Name
	}
	finally
	{
		Remove-AzureRmResourceGroup -Name $rgname -Force
	}
}


function Test-CreateNewWebApp
{
	
	$rgname = Get-ResourceGroupName
	$wname = Get-WebsiteName
	$location = Get-Location
	$whpName = Get-WebHostPlanName
	$tier = "Shared"
	$apiversion = "2015-08-01"
	$resourceType = "Microsoft.Web/sites"
	try
	{
		
		New-AzureRmResourceGroup -Name $rgname -Location $location -Force
		$serverFarm = New-AzureRmAppServicePlan -ResourceGroupName $rgname -Name  $whpName -Location  $location -Tier $tier
		
		
		$actual = New-AzureRmWebApp -ResourceGroupName $rgname -Name $wname -Location $location -AppServicePlan $whpName 
		
		
		Assert-AreEqual $wname $actual.Name
		Assert-AreEqual $serverFarm.Id $actual.ServerFarmId

		
		$result = Get-AzureRmWebApp -ResourceGroupName $rgname -Name $wname
		
		
		Assert-AreEqual $wname $result.Name
		Assert-AreEqual $serverFarm.Id $result.ServerFarmId
	}
	finally
	{
		
		Remove-AzureRmWebApp -ResourceGroupName $rgname -Name $wname -Force
		Remove-AzureRmAppServicePlan -ResourceGroupName $rgname -Name  $whpName -Force
		Remove-AzureRmResourceGroup -Name $rgname -Force
	}
}


function Test-CreateNewWebAppOnAse
{
	
	$rgname = "appdemorg"
	$wname = Get-WebsiteName
	$location = "West US"
	$whpName = "travel_production_plan"
	$aseName = "asedemo"
	$apiversion = "2015-08-01"
	$resourceType = "Microsoft.Web/sites"
	try
	{
		
		$serverFarm = Get-AzureRmAppServicePlan -ResourceGroupName $rgname -Name  $whpName

		
		$actual = New-AzureRmWebApp -ResourceGroupName $rgname -Name $wname -Location $location -AppServicePlan $whpName -AseName $aseName
		
		
		Assert-AreEqual $wname $actual.Name
		Assert-AreEqual $serverFarm.Id $actual.ServerFarmId

		
		$result = Get-AzureRmWebApp -ResourceGroupName $rgname -Name $wname
		
		
		Assert-AreEqual $wname $result.Name
		Assert-AreEqual $serverFarm.Id $result.ServerFarmId
	}
	finally
	{
		
		Remove-AzureRmWebApp -ResourceGroupName $rgname -Name $wname -Force
	}
}


function Test-SetWebApp
{
	
	$rgname = Get-ResourceGroupName
	$webAppName = Get-WebsiteName
	$location = Get-Location
	$appServicePlanName1 = (Get-WebHostPlanName) + "One"
	$appServicePlanName2 = (Get-WebHostPlanName) + "Two"
	$tier1 = "Shared"
	$tier2 = "Standard"
	$apiversion = "2015-08-01"
	$resourceType = "Microsoft.Web/sites"
	$capacity = 2

	try
	{
		
		New-AzureRmResourceGroup -Name $rgname -Location $location -Force
		$serverFarm1 = New-AzureRmAppServicePlan -ResourceGroupName $rgname -Name  $appServicePlanName1 -Location  $location -Tier $tier1
		$serverFarm2 = New-AzureRmAppServicePlan -ResourceGroupName $rgname -Name  $appServicePlanName2 -Location  $location -Tier $tier2
		
		
		$webApp = New-AzureRmWebApp -ResourceGroupName $rgname -Name $webAppName -Location $location -AppServicePlan $appServicePlanName1 
		
		
		Assert-AreEqual $webAppName $webApp.Name
		Assert-AreEqual $serverFarm1.Id $webApp.ServerFarmId
		
		
		$webApp = Set-AzureRmWebApp -ResourceGroupName $rgname -Name $webAppName -AppServicePlan $appServicePlanName2

		
		Assert-AreEqual $webAppName $webApp.Name
		Assert-AreEqual $serverFarm2.Id $webApp.ServerFarmId

		
		$webapp.SiteConfig.HttpLoggingEnabled = $true
		$webapp.SiteConfig.RequestTracingEnabled = $true

		$webApp = $webApp | Set-AzureRmWebApp

		
		Assert-AreEqual $webAppName $webApp.Name
		Assert-AreEqual $serverFarm2.Id $webApp.ServerFarmId
		Assert-AreEqual $true $webApp.SiteConfig.HttpLoggingEnabled
		Assert-AreEqual $true $webApp.SiteConfig.RequestTracingEnabled

		
		$appSettings = @{ "setting1" = "valueA"; "setting2" = "valueB"}
		$connectionStrings = @{ connstring1 = @{ Type="MySql"; Value="string value 1"}; connstring2 = @{ Type = "SQLAzure"; Value="string value 2"}}
		$webApp = Set-AzureRmWebApp -ResourceGroupName $rgname -Name $webAppName -AppSettings $appSettings -ConnectionStrings $connectionStrings -NumberofWorkers $capacity
		
		
		Assert-AreEqual $webAppName $webApp.Name
		Assert-AreEqual $appSettings.Keys.Count $webApp.SiteConfig.AppSettings.Count
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

	}
	finally
	{
		Remove-AzureRmResourceGroup -Name $rgname -Force
	}
}


function Test-RemoveWebApp
{
	
	$rgname = Get-ResourceGroupName
	$appName = Get-WebsiteName
	$location = Get-Location
	$planName = Get-WebHostPlanName
	$tier = "Shared"
	$apiversion = "2015-08-01"
	$resourceType = "Microsoft.Web/sites"

	try
	{
		
		New-AzureRmResourceGroup -Name $rgname -Location $location -Force
		$serverFarm = New-AzureRmAppServicePlan -ResourceGroupName $rgname -Name  $planName -Location  $location -Tier $tier
		
		
		$webapp = New-AzureRmWebApp -ResourceGroupName $rgname -Name $appName -Location $location -AppServicePlan $planName 
		
		
		Assert-AreEqual $appName $webapp.Name
		Assert-AreEqual $serverFarm.Id $webapp.ServerFarmId

		
		$webapp | Remove-AzureRmWebApp -Force

		
		$webappNames = Get-AzureRmWebApp -ResourceGroupName $rgname

		Assert-False { $webappNames -contains $appName }
	}
	finally
	{
		Remove-AzureRmResourceGroup -Name $rgname -Force
	}
}


function Test-WebAppPublishingProfile
{
	
	$rgname = Get-ResourceGroupName
	$appName = Get-WebsiteName
	$location = Get-Location
	$planName = Get-WebHostPlanName
	$tier = "Shared"
	$apiversion = "2015-08-01"
	$resourceType = "Microsoft.Web/sites"
	$profileFileName = "profile.xml"

	try
	{
		
		New-AzureRmResourceGroup -Name $rgname -Location $location -Force
		$serverFarm = New-AzureRmAppServicePlan -ResourceGroupName $rgname -Name  $planName -Location  $location -Tier $tier
		
		
		$webapp = New-AzureRmWebApp -ResourceGroupName $rgname -Name $appName -Location $location -AppServicePlan $planName 
		
		
		Assert-AreEqual $appName $webapp.Name
		Assert-AreEqual $serverFarm.Id $webapp.ServerFarmId

		
		[xml]$profile = Get-AzureRmWebAppPublishingProfile -ResourceGroupName $rgname -Name $appName -OutputFile $profileFileName
		$msDeployProfile = $profile.publishData.publishProfile | ? { $_.publishMethod -eq 'MSDeploy' } | Select -First 1
		$pass = $msDeployProfile.userPWD

		
		Assert-True { $msDeployProfile.msdeploySite -eq $appName }

		
		$newPass = $webapp | Reset-AzureRmWebAppPublishingProfile 

		
		Assert-False { $pass -eq $newPass }

		
		[xml]$profile = $webapp | Get-AzureRmWebAppPublishingProfile -OutputFile $profileFileName -Format FileZilla3
		$fileZillaProfile = $profile.FileZilla3.Servers.Server

		
		Assert-True { $fileZillaProfile.Name -eq $appName }
	}
	finally
	{
		Remove-AzureRmResourceGroup -Name $rgname -Force
	}
}