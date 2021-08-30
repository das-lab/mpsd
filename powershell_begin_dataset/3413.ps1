














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
