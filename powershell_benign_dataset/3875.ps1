














function Test-GetWebAppSlot
{
	
	$rgname = Get-ResourceGroupName
	$appname = Get-WebsiteName
	$slotname1 = "staging"
	$slotname2 = "testing"
	$location = Get-Location
	$planName = Get-WebHostPlanName
	$tier = "Standard"
	$resourceType = "Microsoft.Web/sites"

	try
	{
		
		New-AzResourceGroup -Name $rgname -Location $location
		$serverFarm = New-AzAppServicePlan -ResourceGroupName $rgname -Name  $planName -Location  $location -Tier $tier
		
		
		$webapp = New-AzWebApp -ResourceGroupName $rgname -Name $appname -Location $location -AppServicePlan $planName 
		
		
		Assert-AreEqual $appname $webapp.Name
		Assert-AreEqual $serverFarm.Id $webapp.ServerFarmId
		
		
		$slot1 = New-AzWebAppSlot -ResourceGroupName $rgname -Name $appname -Slot $slotname1 -AppServicePlan $planName
		$appWithSlotName1 = "$appname/$slotname1"

		
		Assert-AreEqual $appWithSlotName1 $slot1.Name
		Assert-AreEqual $serverFarm.Id $slot1.ServerFarmId

		
		$slot1 = Get-AzWebAppSlot -ResourceGroupName $rgname -Name $appname -Slot $slotname1

		
		Assert-AreEqual $appWithSlotName1 $slot1.Name
		Assert-AreEqual $serverFarm.Id $slot1.ServerFarmId

		
		$slot1 = $webapp | Get-AzWebAppSlot -Slot $slotname1

		
		Assert-AreEqual $appWithSlotName1 $slot1.Name
		Assert-AreEqual $serverFarm.Id $slot1.ServerFarmId

		
		$slot2 = New-AzWebAppSlot -ResourceGroupName $rgname -Name $appname -Slot $slotname2 -AppServicePlan $planName 
		$appWithSlotName2 = "$appname/$slotname2"

		
		Assert-AreEqual $appWithSlotName2 $slot2.Name
		Assert-AreEqual $serverFarm.Id $slot2.ServerFarmId

		
		$slots = Get-AzWebAppSlot -ResourceGroupName $rgname -Name $appname 
		$slotNames = $slots | Select -expand Name

		
		Assert-AreEqual 2 $slots.Count
		Assert-True { $slotNames -contains $appWithSlotName1 }
		Assert-True { $slotNames -contains $appWithSlotName2 }
	}
	finally
	{
		
		Remove-AzWebAppSlot -ResourceGroupName $rgname -Name $appname -Slot $slotname1 -Force
		Remove-AzWebAppSlot -ResourceGroupName $rgname -Name $appname -Slot $slotname2 -Force
		Remove-AzWebApp -ResourceGroupName $rgname -Name $appname -Force
		Remove-AzAppServicePlan -ResourceGroupName $rgname -Name  $planName -Force
		Remove-AzResourceGroup -Name $rgname -Force
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
	$resourceType = "Microsoft.Web/sites"

	try
	{
		
		New-AzResourceGroup -Name $rgname -Location $location
		$serverFarm = New-AzAppServicePlan -ResourceGroupName $rgname -Name  $planName -Location  $location -Tier $tier
		
		
		$webapp = New-AzWebApp -ResourceGroupName $rgname -Name $appname -Location $location -AppServicePlan $planName 
		
		
		Assert-AreEqual $appname $webApp.Name
		Assert-AreEqual $serverFarm.Id $webApp.ServerFarmId
		
		
		$slot = New-AzWebAppSlot -ResourceGroupName $rgname -Name $appname -Slot $slotname -AppServicePlan $planName 
		$appWithSlotName = "$appname/$slotname"

		
		Assert-AreEqual $appWithSlotName $slot.Name
		Assert-AreEqual $serverFarm.Id $slot.ServerFarmId

		
		$slot = $slot | Stop-AzWebAppSlot

		Assert-AreEqual "Stopped" $slot.State

		
		$slot = $slot | Start-AzWebAppSlot

		Assert-AreEqual "Running" $slot.State

		
		$slot = Stop-AzWebAppSlot -ResourceGroupName $rgname -Name $appname -Slot $slotname

		Assert-AreEqual "Stopped" $slot.State

		
		$slot = Start-AzWebAppSlot -ResourceGroupName $rgname -Name $appname -Slot $slotname

		Assert-AreEqual "Running" $slot.State

		
		$slot = Restart-AzWebAppSlot -ResourceGroupName $rgname -Name $appname -Slot $slotname

		Assert-AreEqual "Running" $slot.State

		
		$slot = $slot | Restart-AzWebAppSlot

		Assert-AreEqual "Running" $slot.State
	}
	finally
	{
		
		Remove-AzWebAppSlot -ResourceGroupName $rgname -Name $appname -Slot $slotname -Force
		Remove-AzWebApp -ResourceGroupName $rgname -Name $appname -Force
		Remove-AzAppServicePlan -ResourceGroupName $rgname -Name  $planName -Force
		Remove-AzResourceGroup -Name $rgname -Force
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
	$resourceType = "Microsoft.Web/sites"

	try
	{
		
		New-AzResourceGroup -Name $rgname -Location $location
		$serverFarm = New-AzAppServicePlan -ResourceGroupName $rgname -Name  $planName -Location  $location -Tier $tier
		
		
		$webapp = New-AzWebApp -ResourceGroupName $rgname -Name $appname -Location $location -AppServicePlan $planName 
		
		
		Assert-AreEqual $appname $webapp.Name
		Assert-AreEqual $serverFarm.Id $webapp.ServerFarmId

		
		$slot = New-AzWebAppSlot -ResourceGroupName $rgname -Name $appname -Slot $slotname -AppServicePlan $planName -SourceWebApp $webapp
		$appWithSlotName = "$appname/$slotname"

		
		Assert-AreEqual $appWithSlotName $slot.Name

		
		$slot = Get-AzWebAppSlot -ResourceGroupName $rgname -Name $appname -Slot $slotname
		
		
		Assert-AreEqual $appWithSlotName $slot.Name
	}
	finally
	{
		
		Remove-AzWebAppSlot -ResourceGroupName $rgname -Name $appname -Slot $slotname -Force
		Remove-AzWebApp -ResourceGroupName $rgname -Name $appname -Force
		Remove-AzAppServicePlan -ResourceGroupName $rgname -Name  $planName -Force
		Remove-AzResourceGroup -Name $rgname -Force
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

		
		$slot1 = New-AzWebAppSlot -ResourceGroupName $rgname -Name $appname -Slot $slotname -AppServicePlan $planName
		$appWithSlotName = "$appname/$slotname"

		
		Assert-AreEqual $appWithSlotName $slot1.Name
		Assert-AreEqual $serverFarm.Id $slot1.ServerFarmId

		
		$serverFarm2 = New-AzAppServicePlan -ResourceGroupName $rgname -Name  $destPlanName -Location  $destLocation -Tier $tier

		
		$webapp2 = New-AzWebApp -ResourceGroupName $rgname -Name $destAppName -Location $destLocation -AppServicePlan $destPlanName
		
		
		Assert-AreEqual $destAppName $webapp2.Name
		Assert-AreEqual $serverFarm2.Id $webapp2.ServerFarmId

		
		$slot2 = New-AzWebAppSlot -ResourceGroupName $rgname -Name $destAppName -Slot $slotname -AppServicePlan $planName -SourceWebApp $slot1
		$appWithSlotName2 = "$destAppName/$slotname"

		
		Assert-AreEqual $appWithSlotName2 $slot2.Name
	}
	finally
	{
		
		Remove-AzResourceGroup -Name $rgname -Force
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
	$resourceType = "Microsoft.Web/sites"
	try
	{
		
		New-AzResourceGroup -Name $rgname -Location $location
		$serverFarm = New-AzAppServicePlan -ResourceGroupName $rgname -Name  $planName -Location  $location -Tier $tier
		
		
		$actual =  New-AzWebApp -ResourceGroupName $rgname -Name $appname -Location $location -AppServicePlan $planName
		
		
		Assert-AreEqual $appname $actual.Name
		Assert-AreEqual $serverFarm.Id $actual.ServerFarmId

		
		$result = Get-AzWebApp -ResourceGroupName $rgname -Name $appname
		
		
		Assert-AreEqual $appname $result.Name
		Assert-AreEqual $serverFarm.Id $result.ServerFarmId

		
		$job = New-AzWebAppSlot -ResourceGroupName $rgname -Name $appname -Slot $slotname -AsJob
		$job | Wait-Job
		$slot1 = $job | Receive-Job

		$appWithSlotName = "$appname/$slotname"

		
		Assert-AreEqual $appWithSlotName $slot1.Name
		Assert-AreEqual $serverFarm.Id $slot1.ServerFarmId
	}
	finally
	{
		
		Remove-AzWebAppSlot -ResourceGroupName $rgname -Name $appname -Slot $slotname -Force
		Remove-AzWebApp -ResourceGroupName $rgname -Name $appname -Force
		Remove-AzAppServicePlan -ResourceGroupName $rgname -Name  $planName -Force
		Remove-AzResourceGroup -Name $rgname -Force
	}
}


function Test-CreateNewWebAppSlotOnAse
{
	
	$rgname = "appdemorg"
	$appname = Get-WebsiteName
	$slotname = "staging"
	$location = "West US"
	$planName = "travelproductionplan"
	$aseName = "asedemops"

	$apiversion = "2015-08-01"
	$resourceType = "Microsoft.Web/sites"
	try
	{
		
		$serverFarm = Get-AzAppServicePlan -ResourceGroupName $rgname -Name  $planName
		
		
		$actual = New-AzWebApp -ResourceGroupName $rgname -Name $appname -Location $location -AppServicePlan $planName -AseName $aseName
		
		
		Assert-AreEqual $appname $actual.Name
		Assert-AreEqual $serverFarm.Id $actual.ServerFarmId

		
		$result = Get-AzWebApp -ResourceGroupName $rgname -Name $appname
		
		
		Assert-AreEqual $appname $result.Name
		Assert-AreEqual $serverFarm.Id $result.ServerFarmId

		
		$slot1 = New-AzWebAppSlot -ResourceGroupName $rgname -Name $appname -Slot $slotname -AppServicePlan $planName -AseName $aseName
		$appWithSlotName = "$appname/$slotname"

		
		Assert-AreEqual $appWithSlotName $slot1.Name
		Assert-AreEqual $serverFarm.Id $slot1.ServerFarmId

		
		$slot1 = Get-AzWebAppSlot -ResourceGroupName $rgname -Name $appname -Slot $slotname

		
		Assert-AreEqual $appWithSlotName $slot1.Name
		Assert-AreEqual $serverFarm.Id $slot1.ServerFarmId

	}
	finally
	{
		
		Remove-AzWebAppSlot -ResourceGroupName $rgname -Name $appname -Slot $slotname -Force
		Remove-AzWebApp -ResourceGroupName $rgname -Name $appname -Force
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
		
		New-AzResourceGroup -Name $rgname -Location $location
		$serverFarm1 = New-AzAppServicePlan -ResourceGroupName $rgname -Name  $planName1 -Location  $location -Tier $tier1
		$serverFarm2 = New-AzAppServicePlan -ResourceGroupName $rgname -Name  $planName2 -Location  $location -Tier $tier2
		
		
		$webApp = New-AzWebApp -ResourceGroupName $rgname -Name $appname -Location $location -AppServicePlan $planName1 
		
		
		Assert-AreEqual $appname $webApp.Name
		Assert-AreEqual $serverFarm1.Id $webApp.ServerFarmId

		
		$slot = New-AzWebAppSlot -ResourceGroupName $rgname -Name $appname -Slot $slotname -AppServicePlan $planName1
		$appWithSlotName = "$appname/$slotname"

		
		Assert-AreEqual $appWithSlotName $slot.Name
		Assert-AreEqual $serverFarm1.Id $slot.ServerFarmId
        Assert-Null $webApp.Identity
		
		
		$job = Set-AzWebAppSlot -ResourceGroupName $rgname -Name $appname -Slot $slotname -AppServicePlan $planName2 -HttpsOnly $true -AsJob
		$job | Wait-Job
		$slot = $job | Receive-Job

		
		Assert-AreEqual $appWithSlotName $slot.Name
		Assert-AreEqual $serverFarm2.Id $slot.ServerFarmId
        Assert-AreEqual $true $slot.HttpsOnly

		
		$slot.SiteConfig.HttpLoggingEnabled = $true
		$slot.SiteConfig.RequestTracingEnabled = $true

		$slot = $slot | Set-AzWebAppSlot

		
		Assert-AreEqual $appWithSlotName $slot.Name
		Assert-AreEqual $serverFarm2.Id $slot.ServerFarmId
		Assert-AreEqual $true $slot.SiteConfig.HttpLoggingEnabled
		Assert-AreEqual $true $slot.SiteConfig.RequestTracingEnabled

		
		$appSettings = @{ "setting1" = "valueA"; "setting2" = "valueB"}
		$connectionStrings = @{ connstring1 = @{ Type="MySql"; Value="string value 1"}; connstring2 = @{ Type = "SQLAzure"; Value="string value 2"}}

		$slot = Set-AzWebAppSlot -ResourceGroupName $rgname -Name $appname -Slot $slotname -AppSettings $appSettings -AssignIdentity $true

        
        Assert-NotNull  $slot.Identity
        Assert-AreEqual ($appSettings.Keys.Count) $slot.SiteConfig.AppSettings.Count

        $slot = Set-AzWebAppSlot -ResourceGroupName $rgname -Name $appname -Slot $slotname -AppSettings $appSettings -ConnectionStrings $connectionStrings -numberofworkers $numberOfWorkers

		
		Assert-AreEqual $appWithSlotName $slot.Name
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
		
		Remove-AzWebAppSlot -ResourceGroupName $rgname -Name $appname -Slot $slotname -Force
		Remove-AzWebApp -ResourceGroupName $rgname -Name $appname -Force
		Remove-AzAppServicePlan -ResourceGroupName $rgname -Name  $planName1 -Force
		Remove-AzAppServicePlan -ResourceGroupName $rgname -Name  $planName2 -Force
		Remove-AzResourceGroup -Name $rgname -Force
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
		
		New-AzResourceGroup -Name $rgname -Location $location
		$serverFarm = New-AzAppServicePlan -ResourceGroupName $rgname -Name  $planName -Location  $location -Tier $tier
		
		
		$webapp = New-AzWebApp -ResourceGroupName $rgname -Name $appname -Location $location -AppServicePlan $planName 
		
		
		Assert-AreEqual $appname $webapp.Name
		Assert-AreEqual $serverFarm.Id $webapp.ServerFarmId

		
		$slot = New-AzWebAppSlot -ResourceGroupName $rgname -Name $appname -Slot $slotname -AppServicePlan $planName
		$appWithSlotName = "$appname/$slotname"

		
		Assert-AreEqual $appWithSlotName $slot.Name
		Assert-AreEqual $serverFarm.Id $slot.ServerFarmId

		
		$slot | Remove-AzWebAppSlot -Force -AsJob | Wait-Job

		
		$slotNames = Get-AzWebAppSlot -ResourceGroupName $rgname -Name $appname | Select -expand Name

		Assert-False { $slotNames -contains $appname }
	}
	finally
	{
		
		Remove-AzWebApp -ResourceGroupName $rgname -Name $appname -Force
		Remove-AzAppServicePlan -ResourceGroupName $rgname -Name  $planName -Force
		Remove-AzResourceGroup -Name $rgname -Force
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
		
		New-AzResourceGroup -Name $rgname -Location $location
		$serverFarm = New-AzAppServicePlan -ResourceGroupName $rgname -Name  $planName -Location  $location -Tier $tier
		
		
		$webapp = New-AzWebApp -ResourceGroupName $rgname -Name $appname -Location $location -AppServicePlan $planName 
		
		
		Assert-AreEqual $appname $webapp.Name
		Assert-AreEqual $serverFarm.Id $webapp.ServerFarmId

		
		$slot = New-AzWebAppSlot -ResourceGroupName $rgname -Name $appname -Slot $slotname -AppServicePlan $planName
		$appWithSlotName = "$appname/$slotname"
		$appWithSlotName2 = "{0}__{1}" -f $appname, $slotname
		$appWithSlotName3 = "{0}-{1}" -f $appname, $slotname

		
		Assert-AreEqual $appWithSlotName $slot.Name
		Assert-AreEqual $serverFarm.Id $slot.ServerFarmId

		
		[xml]$profile = Get-AzWebAppSlotPublishingProfile -ResourceGroupName $rgname -Name $appname -Slot $slotname -OutputFile $profileFileName
		$msDeployProfile = $profile.publishData.publishProfile | ? { $_.publishMethod -eq 'MSDeploy' } | Select -First 1
		$pass = $msDeployProfile.userPWD

		
		Assert-True { $msDeployProfile.msdeploySite -eq $appWithSlotName2 }

		
		$newPass = $slot | Reset-AzWebAppSlotPublishingProfile 

		
		Assert-False { $pass -eq $newPass }

		
		[xml]$profile = $slot | Get-AzWebAppSlotPublishingProfile -OutputFile $profileFileName -Format FileZilla3
		$fileZillaProfile = $profile.FileZilla3.Servers.Server

		
		Assert-True { $fileZillaProfile.Name -eq $appWithSlotName3 }

		
		[xml]$profile = Get-AzWebAppSlotPublishingProfile -ResourceGroupName $rgname -Name $appname -Slot $slotname

		
		Assert-NotNull $profile

	}
	finally
	{
		
		Remove-AzWebAppSlot -ResourceGroupName $rgname -Name $appname  -Slot $slotname -Force
		Remove-AzWebApp -ResourceGroupName $rgname -Name $appname -Force
		Remove-AzAppServicePlan -ResourceGroupName $rgname -Name  $planName -Force
		Remove-AzResourceGroup -Name $rgname -Force
	}
}


function Test-ManageSlotSlotConfigName
{
	
	$rgname = Get-ResourceGroupName
	$appname = Get-WebsiteName
	$location = Get-Location
	$planName = Get-WebHostPlanName
	$tier = "Standard"

	try
	{
		
		New-AzResourceGroup -Name $rgname -Location $location
		$serverFarm = New-AzAppServicePlan -ResourceGroupName $rgname -Name  $planName -Location  $location -Tier $tier
		
		
		$webapp = New-AzWebApp -ResourceGroupName $rgname -Name $appname -Location $location -AppServicePlan $planName 
		
		
		Assert-AreEqual $appname $webapp.Name
		Assert-AreEqual $serverFarm.Id $webapp.ServerFarmId

		$slotConfigNames = $webApp | Get-AzWebAppSlotConfigName

		
		Assert-AreEqual 0 $slotConfigNames.AppSettingNames.Count
		Assert-AreEqual 0 $slotConfigNames.ConnectionStringNames.Count

		
		$appSettingNames = $webApp.SiteConfig.AppSettings | Select-Object -ExpandProperty Name

		Assert-NotNull $appSettingNames
		
		$webApp | Set-AzWebAppSlotConfigName -AppSettingNames $appSettingNames 
		$slotConfigNames = $webApp | Get-AzWebAppSlotConfigName
		Assert-AreEqual $webApp.SiteConfig.AppSettings.Count $slotConfigNames.AppSettingNames.Count
		Assert-AreEqual 0 $slotConfigNames.ConnectionStringNames.Count

		
		$webApp | Set-AzWebAppSlotConfigName -RemoveAllAppSettingNames
		$slotConfigNames = $webApp | Get-AzWebAppSlotConfigName
		Assert-AreEqual 0 $slotConfigNames.AppSettingNames.Count
		Assert-AreEqual $webApp.SiteConfig.ConnectionStrings.Count $slotConfigNames.ConnectionStringNames.Count

		
		Set-AzWebAppSlotConfigName -ResourceGroupName $rgname -Name $appname -RemoveAllConnectionStringNames
		$slotConfigNames = Get-AzWebAppSlotConfigName -ResourceGroupName $rgname -Name $appname
		Assert-AreEqual 0 $slotConfigNames.AppSettingNames.Count
		Assert-AreEqual 0 $slotConfigNames.ConnectionStringNames.Count
	}
	finally
	{
		
		Remove-AzResourceGroup -Name $rgname -Force
	}
}



function Test-WebAppRegularSlotSwap
{
	$rgname = Get-ResourceGroupName
	$appname = Get-WebsiteName
	$location = Get-Location
	$planName = Get-WebHostPlanName
	$tier = "Standard"
	$sourceSlotName = "staging"
	$destinationSlotName = "production"

	
	try
	{
		
		New-AzResourceGroup -Name $rgname -Location $location
		$serverFarm = New-AzAppServicePlan -ResourceGroupName $rgname -Name  $planName -Location  $location -Tier $tier
		
		
		$webapp = New-AzWebApp -ResourceGroupName $rgname -Name $appname -Location $location -AppServicePlan $planName 
		
		
		Assert-AreEqual $appname $webapp.Name
		Assert-AreEqual $serverFarm.Id $webapp.ServerFarmId

		
		$slot = New-AzWebAppSlot -ResourceGroupName $rgname -Name $appname -Slot $sourceSlotName -AppServicePlan $planName
		$webApp = Switch-AzWebAppSlot -ResourceGroupName $rgname -Name $appname -SourceSlotName $sourceSlotName -DestinationSlotName $destinationSlotName
	}
	finally
	{
		
		Remove-AzWebAppSlot -ResourceGroupName $rgname -Name $appname  -Slot $sourceSlotName -Force
		Remove-AzWebApp -ResourceGroupName $rgname -Name $appname -Force
		Remove-AzAppServicePlan -ResourceGroupName $rgname -Name  $planName -Force
		Remove-AzResourceGroup -Name $rgname -Force
	}
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
	$rgname = Get-ResourceGroupName
	$appname = Get-WebsiteName
	$location = Get-Location
	$planName = Get-WebHostPlanName
	$tier = "Standard"
	$sourceSlotName = "staging"
	$destinationSlotName = "production"
	$appSettingName = 'testappsetting'
	$originalSourceAppSettingValue = "staging"
	$originalDestinationAppSettingValue = "production"

	try
	{
		
		New-AzResourceGroup -Name $rgname -Location $location
		$serverFarm = New-AzAppServicePlan -ResourceGroupName $rgname -Name  $planName -Location  $location -Tier $tier
		
		
		$webapp = New-AzWebApp -ResourceGroupName $rgname -Name $appname -Location $location -AppServicePlan $planName 
		
		
		Assert-AreEqual $appname $webapp.Name
		Assert-AreEqual $serverFarm.Id $webapp.ServerFarmId

		
		$slot = New-AzWebAppSlot -ResourceGroupName $rgname -Name $appname -Slot $sourceSlotName -AppServicePlan $planName

		
		$appSettings = @{ $appSettingName = $originalDestinationAppSettingValue }
		Set-AzWebApp -ResourceGroupName $rgname -Name $appname -AppSettings $appSettings

		$appSettings = @{ $appSettingName = $originalSourceAppSettingValue }
		Set-AzWebAppSlot -ResourceGroupName $rgname -Name $appname -Slot $sourceSlotName -AppSettings $appSettings

		
		$destinationWebApp = Get-AzWebApp -ResourceGroupName $rgname -Name  $appname
		Validate-SlotSwapAppSetting $destinationWebApp $appSettingName $originalDestinationAppSettingValue
		
		$sourceWebApp = Get-AzWebAppSlot -ResourceGroupName $rgname -Name $appname -Slot $sourceSlotName
		Validate-SlotSwapAppSetting $sourceWebApp $appSettingName $originalSourceAppSettingValue

		
		Switch-AzWebAppSlot -ResourceGroupName $rgname -Name $appname -SourceSlotName $sourceSlotName -DestinationSlotName $destinationSlotName -SwapWithPreviewAction 'ApplySlotConfig'
		Wait-Seconds 30
		$sourceWebApp = Get-AzWebAppSlot -ResourceGroupName $rgname -Name  $appname -Slot $sourceSlotName
		Validate-SlotSwapAppSetting $sourceWebApp $appSettingName $originalSourceAppSettingValue

		
		Switch-AzWebAppSlot -ResourceGroupName $rgname -Name $appname -SourceSlotName $sourceSlotName -DestinationSlotName $destinationSlotName -SwapWithPreviewAction $swapWithPreviewAction
		Wait-Seconds 30
		$sourceWebApp = Get-AzWebAppSlot -ResourceGroupName $rgname -Name  $appname -Slot $sourceSlotName
		If ($swapWithPreviewAction -eq 'ResetSlotSwap') {
			Validate-SlotSwapAppSetting $sourceWebApp $appSettingName $originalSourceAppSettingValue
		} Else {
			Validate-SlotSwapAppSetting $sourceWebApp $appSettingName $originalDestinationAppSettingValue
		}
	}
	finally
	{
		
		Remove-AzResourceGroup -Name $rgname -Force
	}

}


function Test-SetAzureStorageWebAppHyperVSlot
{
	
	$rgname = Get-ResourceGroupName
	$wname = Get-WebsiteName
	$slotname = "staging"
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
		
		Write-Debug "Created the web app"

		
		Assert-AreEqual $wname $result.Name
		Assert-AreEqual $serverFarm.Id $result.ServerFarmId
        Assert-AreEqual $true $result.IsXenon
        Assert-AreEqual ($dockerPrefix + $containerImageName)  $result.SiteConfig.WindowsFxVersion

		
		$job = New-AzWebAppSlot -ResourceGroupName $rgname -Name $wname -Slot $slotname -AsJob
		$job | Wait-Job
		$slot1 = $job | Receive-Job

		Write-Debug "Created the slot"

		$appWithSlotName = "$wname/$slotname"

		Write-Debug $appWithSlotName

		
		Assert-AreEqual $appWithSlotName $slot1.Name
		Assert-AreEqual $serverFarm.Id $slot1.ServerFarmId

		$testStorageAccount1 = New-AzWebAppAzureStoragePath -Name $azureStorageAccountCustomId1 -Type $azureStorageAccountType1 -AccountName $azureStorageAccountName1 -ShareName $azureStorageAccountShareName1 -AccessKey $azureStorageAccountAccessKey1 -MountPath $azureStorageAccountMountPath1
		$testStorageAccount2 = New-AzWebAppAzureStoragePath -Name $azureStorageAccountCustomId2 -Type $azureStorageAccountType2 -AccountName $azureStorageAccountName2 -ShareName $azureStorageAccountShareName2 -AccessKey $azureStorageAccountAccessKey2 -MountPath $azureStorageAccountMountPath2

		Write-Debug "Created the new storage account paths"

		Write-Debug $testStorageAccount1.Name
		Write-Debug $testStorageAccount2.Name


		
        $webApp = Set-AzWebAppSlot -ResourceGroupName $rgname -Name $wname -Slot $slotname -AzureStoragePath $testStorageAccount1, $testStorageAccount2

		Write-Debug "Set the new storage account paths"


		
		$result = Get-AzWebAppSlot -ResourceGroupName $rgname -Name $wname -Slot $slotname
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


function Validate-SlotSwapAppSetting($webApp, $appSettingName, $expectedValue)
{
	Assert-AreEqual $appSettingName $webApp.SiteConfig.AppSettings[0].Name
	Assert-AreEqual $expectedValue $webApp.SiteConfig.AppSettings[0].Value
}
