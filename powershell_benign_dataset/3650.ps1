














function Test-VulnerabilityAssessmentManagedInstanceSettingsTest
{
	
	$testSuffix = getAssetName
	Create-VulnerabilityAssessmentManagedInstanceTestEnvironment $testSuffix
	$params = Get-SqlVulnerabilityAssessmentManagedInstanceTestEnvironmentParameters $testSuffix
	$vnetName = "cl_initial"
	$subnetName = "Cool"
	$virtualNetwork1 = CreateAndGetVirtualNetworkForManagedInstance $vnetName $subnetName
	$subnetId = $virtualNetwork1.Subnets.where({ $_.Name -eq $subnetName })[0].Id
	$credentials = Get-ServerCredential
 	$licenseType = "BasePrice"
  	$storageSizeInGB = 32
 	$vCore = 16
 	$skuName = "GP_Gen4"
	$location = "West Central US"

	try
	{
		
		Enable-AzSqlInstanceAdvancedDataSecurity -ResourceGroupName $params.rgname -InstanceName $params.serverName -DoNotConfigureVulnerabilityAssessment

		Assert-ThrowsContains -script { Update-AzSqlInstanceVulnerabilityAssessmentSetting -ResourceGroupName $params.rgname -InstanceName $params.serverName `
		 -StorageAccountName $params.storageAccount -EmailAdmins $true -NotificationEmail @("invalidMail") -RecurringScansInterval Weekly } `
		 -message "One or more of the email addresses you entered are not valid.."

		Assert-ThrowsContains -script { Update-AzSqlInstanceVulnerabilityAssessmentSetting -ResourceGroupName $params.rgname -InstanceName $params.serverName `
		 -BlobStorageSasUri "https://invalid.blob.core.windows.netXXXXXXXXXXXXXXX"} `
		 -message "Invalid BlobStorageSasUri parameter value. The value should be in format of https://mystorage.blob.core.windows.net/vulnerability-assessment?st=XXXXXX."

		Update-AzSqlInstanceVulnerabilityAssessmentSetting -ResourceGroupName $params.rgname -InstanceName $params.serverName `
			 -StorageAccountName $params.storageAccount

		
		$settings = Get-AzSqlInstanceVulnerabilityAssessmentSetting -ResourceGroupName $params.rgname -InstanceName $params.serverName 
		
		
		Assert-AreEqual $params.rgname $settings.ResourceGroupName
		Assert-AreEqual $params.serverName $settings.InstanceName
		Assert-AreEqual "vulnerability-assessment" $settings.ScanResultsContainerName
		Assert-AreEqual $params.storageAccount $settings.StorageAccountName	
		Assert-AreEqual None $settings.RecurringScansInterval
		Assert-AreEqual $true $settings.EmailAdmins
		Assert-AreEqualArray @() $settings.NotificationEmail

		
		$testEmailAdmins = $true
		$testNotificationEmail = @("test1@mailTest.com", "test2@mailTest.com")
		$testRecurringScansInterval = [Microsoft.Azure.Commands.Sql.VulnerabilityAssessment.Model.RecurringScansInterval]::Weekly

		Update-AzSqlInstanceVulnerabilityAssessmentSetting -ResourceGroupName $params.rgname -InstanceName $params.serverName `
			  -RecurringScansInterval $testRecurringScansInterval -EmailAdmins $testEmailAdmins `
			  -NotificationEmail $testNotificationEmail

		
		$settings = Get-AzSqlInstanceVulnerabilityAssessmentSetting -ResourceGroupName $params.rgname -InstanceName $params.serverName 

		
		Assert-AreEqual $params.rgname $settings.ResourceGroupName
		Assert-AreEqual $params.serverName $settings.InstanceName
		Assert-AreEqual "vulnerability-assessment" $settings.ScanResultsContainerName
		Assert-AreEqual $params.storageAccount $settings.StorageAccountName	
		Assert-AreEqual $testRecurringScansInterval $settings.RecurringScansInterval
		Assert-AreEqual $testEmailAdmins $settings.EmailAdmins
		Assert-AreEqualArray $testNotificationEmail $settings.NotificationEmail

		
		Clear-AzSqlInstanceVulnerabilityAssessmentSetting -ResourceGroupName $params.rgname -InstanceName $params.serverName

		
		$settings = Get-AzSqlInstanceVulnerabilityAssessmentSetting -ResourceGroupName $params.rgname -InstanceName $params.serverName
		
		
		Assert-AreEqual $params.rgname $settings.ResourceGroupName
		Assert-AreEqual $params.serverName $settings.InstanceName
		Assert-AreEqual "" $settings.ScanResultsContainerName
		Assert-AreEqual "" $settings.StorageAccountName	
		Assert-AreEqual None $settings.RecurringScansInterval
		Assert-AreEqual $true $settings.EmailAdmins
		Assert-Null $settings.NotificationEmail

		
		$testScanResultsContainerName = "custom-container"
		$testStorageName = "storage1"
		$testBlobStorageSasUri = "https://" + $testStorageName +".blob.core.windows.net/" + $testScanResultsContainerName + "?st=XXXXXXXXXXXXXXX"
		$testRecurringScansInterval = [Microsoft.Azure.Commands.Sql.VulnerabilityAssessment.Model.RecurringScansInterval]::None

		Update-AzSqlInstanceVulnerabilityAssessmentSetting -ResourceGroupName $params.rgname -InstanceName $params.serverName `
		 -BlobStorageSasUri $testBlobStorageSasUri -RecurringScansInterval $testRecurringScansInterval -EmailAdmins $testEmailAdmins `
		 -NotificationEmail $testNotificationEmail
		
		
		$newManagedInstanceName = "newManagedInstanceName" +$testSuffix;
		$testNewNotificationEmail = @("test3@mailTest.com", "test4@mailTest.com")
		$testStorageName = $params.storageAccount
		$testBlobStorageSasUri = "https://" + $testStorageName +".blob.core.windows.net/" + $testScanResultsContainerName + "?st=XXXXXXXXXXXXXXX"
		$testRecurringScansInterval = [Microsoft.Azure.Commands.Sql.VulnerabilityAssessment.Model.RecurringScansInterval]::None

		New-AzSqlInstance -ResourceGroupName $params.rgname -Name $newManagedInstanceName `
 			-Location $location -AdministratorCredential $credentials -SubnetId $subnetId `
  			-LicenseType $licenseType -StorageSizeInGB $storageSizeInGB -Vcore $vCore -SkuName $skuName

		Enable-AzSqlInstanceAdvancedDataSecurity -ResourceGroupName $params.rgname -InstanceName $newManagedInstanceName -DoNotConfigureVulnerabilityAssessment

		Update-AzSqlInstanceVulnerabilityAssessmentSetting -ResourceGroupName $params.rgname -InstanceName $newManagedInstanceName `
		 -BlobStorageSasUri $testBlobStorageSasUri -RecurringScansInterval $testRecurringScansInterval -EmailAdmins $testEmailAdmins `
		 -NotificationEmail $testNewNotificationEmail

    	Get-AzSqlInstanceVulnerabilityAssessmentSetting -ResourceGroupName $params.rgname -InstanceName $newManagedInstanceName | Update-AzSqlInstanceVulnerabilityAssessmentSetting `
			 -ResourceGroupName $params.rgname -InstanceName $params.serverName
		$settings = Get-AzSqlInstanceVulnerabilityAssessmentSetting -ResourceGroupName $params.rgname -InstanceName $params.serverName 

		Assert-AreEqual $params.rgname $settings.ResourceGroupName
		Assert-AreEqual $params.serverName $settings.InstanceName
		Assert-AreEqual $testScanResultsContainerName $settings.ScanResultsContainerName
		Assert-AreEqual $testStorageName $settings.StorageAccountName	
		Assert-AreEqual $testRecurringScansInterval $settings.RecurringScansInterval
		Assert-AreEqual $testEmailAdmins $settings.EmailAdmins
		Assert-AreEqualArray $testNewNotificationEmail $settings.NotificationEmail

		
		$settings = Get-AzSqlInstance -ResourceGroupName $params.rgname -Name $params.serverName | Get-AzSqlInstanceVulnerabilityAssessmentSetting 
		 
		
		Assert-AreEqual $params.rgname $settings.ResourceGroupName
		Assert-AreEqual $params.serverName $settings.InstanceName
		Assert-AreEqual $testScanResultsContainerName $settings.ScanResultsContainerName
		Assert-AreEqual $testStorageName $settings.StorageAccountName	
		Assert-AreEqual $testRecurringScansInterval $settings.RecurringScansInterval
		Assert-AreEqual $testEmailAdmins $settings.EmailAdmins
		Assert-AreEqualArray $testNewNotificationEmail $settings.NotificationEmail

		
		$settings = Get-AzSqlInstance -ResourceGroupName $params.rgname -Name $params.serverName | Clear-AzSqlInstanceVulnerabilityAssessmentSetting 
		 
		
		Assert-Null $settings

		
		$testEmailAdmins = $false
		$testRecurringScansInterval = [Microsoft.Azure.Commands.Sql.VulnerabilityAssessment.Model.RecurringScansInterval]::Weekly
		Update-AzSqlInstanceVulnerabilityAssessmentSetting -ResourceGroupName $params.rgname -InstanceName $params.serverName `
			  -StorageAccountName $params.storageAccount -RecurringScansInterval $testRecurringScansInterval -EmailAdmins $testEmailAdmins

		
		$settings = Get-AzSqlInstanceVulnerabilityAssessmentSetting -ResourceGroupName $params.rgname -InstanceName $params.serverName 
		Assert-AreEqual $params.rgname $settings.ResourceGroupName
		Assert-AreEqual $params.serverName $settings.InstanceName
		Assert-AreEqual $params.storageAccount $settings.StorageAccountName	
		Assert-AreEqual $testRecurringScansInterval $settings.RecurringScansInterval
		Assert-AreEqual $testEmailAdmins $settings.EmailAdmins
		Assert-Null $settings.NotificationEmail

		
		Clear-AzSqlInstanceVulnerabilityAssessmentSetting -ResourceGroupName $params.rgname -InstanceName $params.serverName

		
		Update-AzSqlInstanceVulnerabilityAssessmentSetting -ResourceGroupName $params.rgname -InstanceName $params.serverName `
		  -StorageAccountName $params.storageAccount -WhatIf
		
		
		$settings = Get-AzSqlInstanceVulnerabilityAssessmentSetting -ResourceGroupName $params.rgname -InstanceName $params.serverName

		
		Assert-AreEqual $params.rgname $settings.ResourceGroupName
		Assert-AreEqual $params.serverName $settings.InstanceName
		Assert-AreEqual "" $settings.ScanResultsContainerName
		Assert-AreEqual "" $settings.StorageAccountName	
		Assert-AreEqual None $settings.RecurringScansInterval
		Assert-AreEqual $true $settings.EmailAdmins
		Assert-Null $settings.NotificationEmail

		
		Update-AzSqlInstanceVulnerabilityAssessmentSetting -ResourceGroupName $params.rgname -InstanceName $params.serverName `
		 -BlobStorageSasUri $testBlobStorageSasUri

		Clear-AzSqlInstanceVulnerabilityAssessmentSetting -ResourceGroupName $params.rgname -InstanceName $params.serverName `
		-WhatIf
		
		
		Get-AzSqlInstanceVulnerabilityAssessmentSetting -ResourceGroupName $params.rgname -InstanceName $params.serverName
	}
	finally
	{
		
		Remove-VulnerabilityAssessmentManagedInstanceTestEnvironment $testSuffix
	}
}


function Test-VulnerabilityAssessmentManagedDatabaseWithSettingsNotDefinedTest
{
	
	$testSuffix = getAssetName
	Create-VulnerabilityAssessmentManagedInstanceTestEnvironment $testSuffix
	$params = Get-SqlVulnerabilityAssessmentManagedInstanceTestEnvironmentParameters $testSuffix

	try
	{
		$ruleId = "VA2031"
		$scanId = "myCustomScanId"
		$baselineResults = @(@("userA", "SELECT"),@("userB", "SELECT"))
		
		
		Enable-AzSqlInstanceAdvancedDataSecurity -ResourceGroupName $params.rgname -InstanceName $params.serverName -DoNotConfigureVulnerabilityAssessment

		
		Assert-Throws { Set-AzSqlInstanceDatabaseVulnerabilityAssessmentRuleBaseline -ResourceGroupName $params.rgname -InstanceName $params.serverName `
		-DatabaseName $params.databaseName -RuleId $ruleId -BaselineResult $baselineResults }

		Assert-Throws { Get-AzSqlInstanceDatabaseVulnerabilityAssessmentRuleBaseline -ResourceGroupName $params.rgname -InstanceName $params.serverName `
		-DatabaseName $params.databaseName -RuleId $ruleId }

		Assert-Throws { Clear-AzSqlInstanceDatabaseVulnerabilityAssessmentRuleBaseline -ResourceGroupName $params.rgname -InstanceName $params.serverName `
		-DatabaseName $params.databaseName -RuleId $ruleId }

		
		Assert-Throws { Convert-AzSqlInstanceDatabaseVulnerabilityAssessmentScan -ResourceGroupName $params.rgname -InstanceName $params.serverName `
		-DatabaseName $params.databaseName -ScanId $scanId }

		Assert-Throws { Get-AzSqlInstanceDatabaseVulnerabilityAssessmentScanRecord -ResourceGroupName $params.rgname -InstanceName $params.serverName `
		-DatabaseName $params.databaseName -ScanId $scanId }

		Assert-Throws { Start-AzSqlInstanceDatabaseVulnerabilityAssessmentScan -ResourceGroupName $params.rgname -InstanceName $params.serverName `
		-DatabaseName $params.databaseName -ScanId $scanId }
	}
	finally
	{
		
		Remove-VulnerabilityAssessmentManagedInstanceTestEnvironment $testSuffix
	}
}


function Test-VulnerabilityAssessmentManagedDatabaseSettingsTest
{
	
	$testSuffix = getAssetName
	Create-VulnerabilityAssessmentManagedInstanceTestEnvironment $testSuffix
	$params = Get-SqlVulnerabilityAssessmentManagedInstanceTestEnvironmentParameters $testSuffix

	try
	{
		
		Enable-AzSqlInstanceAdvancedDataSecurity -ResourceGroupName $params.rgname -InstanceName $params.serverName -DoNotConfigureVulnerabilityAssessment

		Assert-ThrowsContains -script { Update-AzSqlInstanceDatabaseVulnerabilityAssessmentSetting -ResourceGroupName $params.rgname -InstanceName $params.serverName -DatabaseName $params.databaseName `
		 -StorageAccountName $params.storageAccount -EmailAdmins $true -NotificationEmail @("invalidMail") -RecurringScansInterval Weekly } `
		 -message "One or more of the email addresses you entered are not valid.."

		Assert-ThrowsContains -script { Update-AzSqlInstanceDatabaseVulnerabilityAssessmentSetting -ResourceGroupName $params.rgname -InstanceName $params.serverName -DatabaseName $params.databaseName `
		 -BlobStorageSasUri "https://invalid.blob.core.windows.netXXXXXXXXXXXXXXX"} `
		 -message "Invalid BlobStorageSasUri parameter value. The value should be in format of https://mystorage.blob.core.windows.net/vulnerability-assessment?st=XXXXXX."

		Update-AzSqlInstanceDatabaseVulnerabilityAssessmentSetting -ResourceGroupName $params.rgname -InstanceName $params.serverName -DatabaseName $params.databaseName `
			 -StorageAccountName $params.storageAccount

		
		$settings = Get-AzSqlInstanceDatabaseVulnerabilityAssessmentSetting -ResourceGroupName $params.rgname -InstanceName $params.serverName -DatabaseName $params.databaseName 
		
		
		Assert-AreEqual $params.rgname $settings.ResourceGroupName
		Assert-AreEqual $params.serverName $settings.InstanceName
		Assert-AreEqual $params.databaseName $settings.DatabaseName
		Assert-AreEqual "vulnerability-assessment" $settings.ScanResultsContainerName
		Assert-AreEqual $params.storageAccount $settings.StorageAccountName	
		Assert-AreEqual None $settings.RecurringScansInterval
		Assert-AreEqual $true $settings.EmailAdmins
		Assert-AreEqualArray @() $settings.NotificationEmail

		
		$testEmailAdmins = $true
		$testNotificationEmail = @("test1@mailTest.com", "test2@mailTest.com")
		$testRecurringScansInterval = [Microsoft.Azure.Commands.Sql.VulnerabilityAssessment.Model.RecurringScansInterval]::Weekly

		Update-AzSqlInstanceDatabaseVulnerabilityAssessmentSetting -ResourceGroupName $params.rgname -InstanceName $params.serverName -DatabaseName $params.databaseName `
			  -RecurringScansInterval $testRecurringScansInterval -EmailAdmins $testEmailAdmins `
			  -NotificationEmail $testNotificationEmail

		
		$settings = Get-AzSqlInstanceDatabaseVulnerabilityAssessmentSetting -ResourceGroupName $params.rgname -InstanceName $params.serverName -DatabaseName $params.databaseName 

		
		Assert-AreEqual $params.rgname $settings.ResourceGroupName
		Assert-AreEqual $params.serverName $settings.InstanceName
		Assert-AreEqual $params.databaseName $settings.DatabaseName
		Assert-AreEqual "vulnerability-assessment" $settings.ScanResultsContainerName
		Assert-AreEqual $params.storageAccount $settings.StorageAccountName	
		Assert-AreEqual $testRecurringScansInterval $settings.RecurringScansInterval
		Assert-AreEqual $testEmailAdmins $settings.EmailAdmins
		Assert-AreEqualArray $testNotificationEmail $settings.NotificationEmail

		
		Clear-AzSqlInstanceDatabaseVulnerabilityAssessmentSetting -ResourceGroupName $params.rgname -InstanceName $params.serverName -DatabaseName $params.databaseName

		
		$settings = Get-AzSqlInstanceDatabaseVulnerabilityAssessmentSetting -ResourceGroupName $params.rgname -InstanceName $params.serverName `
		-DatabaseName $params.databaseName

		
		Assert-AreEqual $params.rgname $settings.ResourceGroupName
		Assert-AreEqual $params.serverName $settings.InstanceName
		Assert-AreEqual "" $settings.ScanResultsContainerName
		Assert-AreEqual "" $settings.StorageAccountName	
		Assert-AreEqual None $settings.RecurringScansInterval
		Assert-AreEqual $true $settings.EmailAdmins
		Assert-Null $settings.NotificationEmail

		
		$testScanResultsContainerName = "custom-container"
		$testStorageName = "storage1"
		$testBlobStorageSasUri = "https://" + $testStorageName +".blob.core.windows.net/" + $testScanResultsContainerName + "?st=XXXXXXXXXXXXXXX"
		$testRecurringScansInterval = [Microsoft.Azure.Commands.Sql.VulnerabilityAssessment.Model.RecurringScansInterval]::None

		Update-AzSqlInstanceDatabaseVulnerabilityAssessmentSetting -ResourceGroupName $params.rgname -InstanceName $params.serverName -DatabaseName $params.databaseName `
		 -BlobStorageSasUri $testBlobStorageSasUri -RecurringScansInterval $testRecurringScansInterval -EmailAdmins $testEmailAdmins `
		 -NotificationEmail $testNotificationEmail
		
		
		$newDatabaseName = "newManagedDatabaseName";
		$testNewNotificationEmail = @("test3@mailTest.com", "test4@mailTest.com")
		$testStorageName = $params.storageAccount
		$testBlobStorageSasUri = "https://" + $testStorageName +".blob.core.windows.net/" + $testScanResultsContainerName + "?st=XXXXXXXXXXXXXXX"
		$testRecurringScansInterval = [Microsoft.Azure.Commands.Sql.VulnerabilityAssessment.Model.RecurringScansInterval]::None

		$collation = "SQL_Latin1_General_CP1_CI_AS"
		New-AzSqlInstanceDatabase -Name $newDatabaseName -ResourceGroupName $params.rgname -InstanceName $params.serverName -Collation $collation

		Update-AzSqlInstanceDatabaseVulnerabilityAssessmentSetting -ResourceGroupName $params.rgname -InstanceName $params.serverName -DatabaseName $newDatabaseName `
		 -BlobStorageSasUri $testBlobStorageSasUri -RecurringScansInterval $testRecurringScansInterval -EmailAdmins $testEmailAdmins `
		 -NotificationEmail $testNewNotificationEmail

    	Get-AzSqlInstanceDatabaseVulnerabilityAssessmentSetting -ResourceGroupName $params.rgname -InstanceName $params.serverName -DatabaseName $newDatabaseName | Update-AzSqlInstanceDatabaseVulnerabilityAssessmentSetting `
			 -ResourceGroupName $params.rgname -InstanceName $params.serverName -DatabaseName $params.databaseName
		$settings = Get-AzSqlInstanceDatabaseVulnerabilityAssessmentSetting -ResourceGroupName $params.rgname -InstanceName $params.serverName -DatabaseName $params.databaseName 

		Assert-AreEqual $params.rgname $settings.ResourceGroupName
		Assert-AreEqual $params.serverName $settings.InstanceName
		Assert-AreEqual $params.databaseName $settings.DatabaseName
		Assert-AreEqual $testScanResultsContainerName $settings.ScanResultsContainerName
		Assert-AreEqual $testStorageName $settings.StorageAccountName	
		Assert-AreEqual $testRecurringScansInterval $settings.RecurringScansInterval
		Assert-AreEqual $testEmailAdmins $settings.EmailAdmins
		Assert-AreEqualArray $testNewNotificationEmail $settings.NotificationEmail

		
		$settings = Get-AzSqlInstanceDatabase -ResourceGroupName $params.rgname -InstanceName $params.serverName -Name $params.databaseName | Get-AzSqlInstanceDatabaseVulnerabilityAssessmentSetting 
		 
		
		Assert-AreEqual $params.rgname $settings.ResourceGroupName
		Assert-AreEqual $params.serverName $settings.InstanceName
		Assert-AreEqual $params.databaseName $settings.DatabaseName
		Assert-AreEqual $testScanResultsContainerName $settings.ScanResultsContainerName
		Assert-AreEqual $testStorageName $settings.StorageAccountName	
		Assert-AreEqual $testRecurringScansInterval $settings.RecurringScansInterval
		Assert-AreEqual $testEmailAdmins $settings.EmailAdmins
		Assert-AreEqualArray $testNewNotificationEmail $settings.NotificationEmail

		
		$settings = Get-AzSqlInstanceDatabase -ResourceGroupName $params.rgname -InstanceName $params.serverName -Name $params.databaseName | Clear-AzSqlInstanceDatabaseVulnerabilityAssessmentSetting 
		 
		
		Assert-Null $settings

		
		$testEmailAdmins = $false
		$testRecurringScansInterval = [Microsoft.Azure.Commands.Sql.VulnerabilityAssessment.Model.RecurringScansInterval]::Weekly
		Update-AzSqlInstanceDatabaseVulnerabilityAssessmentSetting -ResourceGroupName $params.rgname -InstanceName $params.serverName -DatabaseName $params.databaseName `
			  -StorageAccountName $params.storageAccount -RecurringScansInterval $testRecurringScansInterval -EmailAdmins $testEmailAdmins

		
		$settings = Get-AzSqlInstanceDatabaseVulnerabilityAssessmentSetting -ResourceGroupName $params.rgname -InstanceName $params.serverName -DatabaseName $params.databaseName 
		Assert-AreEqual $params.rgname $settings.ResourceGroupName
		Assert-AreEqual $params.serverName $settings.InstanceName
		Assert-AreEqual $params.databaseName $settings.DatabaseName
		Assert-AreEqual $params.storageAccount $settings.StorageAccountName	
		Assert-AreEqual $testRecurringScansInterval $settings.RecurringScansInterval
		Assert-AreEqual $testEmailAdmins $settings.EmailAdmins
		Assert-Null $settings.NotificationEmail

		
		Clear-AzSqlInstanceDatabaseVulnerabilityAssessmentSetting -ResourceGroupName $params.rgname -InstanceName $params.serverName -DatabaseName $params.databaseName

		
		Update-AzSqlInstanceDatabaseVulnerabilityAssessmentSetting -ResourceGroupName $params.rgname -InstanceName $params.serverName -DatabaseName $params.databaseName `
		  -StorageAccountName $params.storageAccount -WhatIf

		
		$settings = Get-AzSqlInstanceDatabaseVulnerabilityAssessmentSetting -ResourceGroupName $params.rgname -InstanceName $params.serverName `
		-DatabaseName $params.databaseName

		
		Assert-AreEqual $params.rgname $settings.ResourceGroupName
		Assert-AreEqual $params.serverName $settings.InstanceName
		Assert-AreEqual "" $settings.ScanResultsContainerName
		Assert-AreEqual "" $settings.StorageAccountName	
		Assert-AreEqual None $settings.RecurringScansInterval
		Assert-AreEqual $true $settings.EmailAdmins
		Assert-Null $settings.NotificationEmail

		
		Update-AzSqlInstanceDatabaseVulnerabilityAssessmentSetting -ResourceGroupName $params.rgname -InstanceName $params.serverName -DatabaseName $params.databaseName `
		 -BlobStorageSasUri $testBlobStorageSasUri

		Clear-AzSqlInstanceDatabaseVulnerabilityAssessmentSetting -ResourceGroupName $params.rgname -InstanceName $params.serverName -DatabaseName $params.databaseName `
		-WhatIf
		
		
		Get-AzSqlInstanceDatabaseVulnerabilityAssessmentSetting -ResourceGroupName $params.rgname -InstanceName $params.serverName `
		-DatabaseName $params.databaseName
	}
	finally
	{
		
		Remove-VulnerabilityAssessmentManagedInstanceTestEnvironment $testSuffix
	}
}


function Test-VulnerabilityAssessmentManagedDatabaseBaselineTest
{
	
	$testSuffix = getAssetName
	Create-VulnerabilityAssessmentManagedInstanceTestEnvironment $testSuffix
	$params = Get-SqlVulnerabilityAssessmentManagedInstanceTestEnvironmentParameters $testSuffix

	try
	{
		
		Enable-AzSqlInstanceAdvancedDataSecurity -ResourceGroupName $params.rgname -InstanceName $params.serverName -DoNotConfigureVulnerabilityAssessment

		Update-AzSqlInstanceDatabaseVulnerabilityAssessmentSetting -ResourceGroupName $params.rgname -InstanceName $params.serverName -DatabaseName $params.databaseName `
			 -StorageAccountName $params.storageAccount

		$ruleId = "VA2108"

		
		$baselineDoesntExistsErrorMessage = "Baseline does not exist for rule 'VA2108'."
		Assert-ThrowsContains -script { Get-AzSqlInstanceDatabaseVulnerabilityAssessmentRuleBaseline -ResourceGroupName $params.rgname -InstanceName $params.serverName `
		-DatabaseName $params.databaseName -RuleId $ruleId } -message $baselineDoesntExistsErrorMessage

		Assert-ThrowsContains -script { Clear-AzSqlInstanceDatabaseVulnerabilityAssessmentRuleBaseline -ResourceGroupName $params.rgname -InstanceName $params.serverName `
		-DatabaseName $params.databaseName -RuleId $ruleId } -message $baselineDoesntExistsErrorMessage

		
		$baselineToSet = @( 'Principal1', 'db_ddladmin', 'SQL_USER', 'None'), @( 'Principal2', 'db_ddladmin', 'SQL_USER', 'None')
		Set-AzSqlInstanceDatabaseVulnerabilityAssessmentRuleBaseline -ResourceGroupName $params.rgname -InstanceName $params.serverName -DatabaseName $params.databaseName `
		-RuleId $ruleId -BaselineResult $baselineToSet
		
		
		$baseline = Get-AzSqlInstanceDatabaseVulnerabilityAssessmentRuleBaseline -ResourceGroupName $params.rgname -InstanceName $params.serverName -DatabaseName $params.databaseName `
		-RuleId $ruleId

		Assert-AreEqual $params.rgname $baseline.ResourceGroupName
		Assert-AreEqual $params.serverName $baseline.InstanceName
		Assert-AreEqual $params.databaseName $baseline.DatabaseName
		Assert-AreEqual $ruleId $baseline.RuleId
		Assert-AreEqual $false $baseline.RuleAppliesToMaster
		Assert-AreEqualArray $baselineToSet[0] $baseline.BaselineResult[0].Result
		Assert-AreEqualArray $baselineToSet[1] $baseline.BaselineResult[1].Result

		
		$baselineToSet = @( 'Principal3', 'db_ddladmin', 'SQL_USER', 'None'), @( 'Principal4', 'db_ddladmin', 'SQL_USER', 'None')
		Set-AzSqlInstanceDatabaseVulnerabilityAssessmentRuleBaseline -ResourceGroupName $params.rgname -InstanceName $params.serverName -DatabaseName $params.databaseName `
		-RuleId $ruleId -BaselineResult $baselineToSet
		
		
		$baseline = Get-AzSqlInstanceDatabaseVulnerabilityAssessmentRuleBaseline -ResourceGroupName $params.rgname -InstanceName $params.serverName -DatabaseName $params.databaseName `
		-RuleId $ruleId

		Assert-AreEqual $params.rgname $baseline.ResourceGroupName
		Assert-AreEqual $params.serverName $baseline.InstanceName
		Assert-AreEqual $params.databaseName $baseline.DatabaseName
		Assert-AreEqual $ruleId $baseline.RuleId
		Assert-AreEqual $false $baseline.RuleAppliesToMaster
		Assert-AreEqualArray $baselineToSet[0] $baseline.BaselineResult[0].Result
		Assert-AreEqualArray $baselineToSet[1] $baseline.BaselineResult[1].Result

		
		Clear-AzSqlInstanceDatabaseVulnerabilityAssessmentRuleBaseline -ResourceGroupName $params.rgname -InstanceName $params.serverName `
		-DatabaseName $params.databaseName -RuleId $ruleId

		
		Assert-ThrowsContains -script { Get-AzSqlInstanceDatabaseVulnerabilityAssessmentRuleBaseline -ResourceGroupName $params.rgname -InstanceName $params.serverName `
		-DatabaseName $params.databaseName -RuleId $ruleId } -message $baselineDoesntExistsErrorMessage

		Assert-ThrowsContains -script { Clear-AzSqlInstanceDatabaseVulnerabilityAssessmentRuleBaseline -ResourceGroupName $params.rgname -InstanceName $params.serverName `
		-DatabaseName $params.databaseName -RuleId $ruleId } -message $baselineDoesntExistsErrorMessage

		
		Set-AzSqlInstanceDatabaseVulnerabilityAssessmentRuleBaseline -ResourceGroupName $params.rgname -InstanceName $params.serverName -DatabaseName $params.databaseName `
		-RuleId $ruleId -BaselineResult $baselineToSet

		
		Assert-ThrowsContains -script { Get-AzSqlInstanceDatabaseVulnerabilityAssessmentRuleBaseline -ResourceGroupName $params.rgname -InstanceName $params.serverName `
		-DatabaseName $params.databaseName -RuleId $ruleId -RuleAppliesToMaster } -message $baselineDoesntExistsErrorMessage

		Assert-ThrowsContains -script { Clear-AzSqlInstanceDatabaseVulnerabilityAssessmentRuleBaseline -ResourceGroupName $params.rgname -InstanceName $params.serverName `
		-DatabaseName $params.databaseName -RuleId $ruleId -RuleAppliesToMaster} -message $baselineDoesntExistsErrorMessage

		Set-AzSqlInstanceDatabaseVulnerabilityAssessmentRuleBaseline -ResourceGroupName $params.rgname -InstanceName $params.serverName -DatabaseName $params.databaseName `
		-RuleId $ruleId -RuleAppliesToMaster -BaselineResult $baselineToSet

		$baseline = Get-AzSqlInstanceDatabase -ResourceGroupName $params.rgname -InstanceName $params.serverName -Name $params.databaseName`
		| Get-AzSqlInstanceDatabaseVulnerabilityAssessmentRuleBaseline -RuleId $ruleId -RuleAppliesToMaster
		Assert-AreEqual $params.rgname $baseline.ResourceGroupName
		Assert-AreEqual $params.serverName $baseline.InstanceName
		Assert-AreEqual $params.databaseName $baseline.DatabaseName
		Assert-AreEqual $ruleId $baseline.RuleId
		Assert-AreEqual $true $baseline.RuleAppliesToMaster
		Assert-AreEqualArray $baselineToSet[0] $baseline.BaselineResult[0].Result
		Assert-AreEqualArray $baselineToSet[1] $baseline.BaselineResult[1].Result

		Clear-AzSqlInstanceDatabaseVulnerabilityAssessmentRuleBaseline -ResourceGroupName $params.rgname -InstanceName $params.serverName -DatabaseName $params.databaseName `
		-RuleId $ruleId -RuleAppliesToMaster

		
		Set-AzSqlInstanceDatabaseVulnerabilityAssessmentRuleBaseline -ResourceGroupName $params.rgname -InstanceName $params.serverName -DatabaseName $params.databaseName `
		-RuleId $ruleId -BaselineResult $baselineToSet
		
		Get-AzSqlInstanceDatabaseVulnerabilityAssessmentRuleBaseline -ResourceGroupName $params.rgname -InstanceName $params.serverName -DatabaseName $params.databaseName `
		-RuleId $ruleId | Set-AzSqlInstanceDatabaseVulnerabilityAssessmentRuleBaseline

		$baseline = Get-AzSqlInstanceDatabase -ResourceGroupName $params.rgname -InstanceName $params.serverName -Name $params.databaseName | Get-AzSqlInstanceDatabaseVulnerabilityAssessmentRuleBaseline `
		-RuleId $ruleId
		Assert-AreEqual $params.rgname $baseline.ResourceGroupName
		Assert-AreEqual $params.serverName $baseline.InstanceName
		Assert-AreEqual $params.databaseName $baseline.DatabaseName
		Assert-AreEqual $ruleId $baseline.RuleId
		Assert-AreEqual $false $baseline.RuleAppliesToMaster
		Assert-AreEqualArray $baselineToSet[0] $baseline.BaselineResult[0].Result
		Assert-AreEqualArray $baselineToSet[1] $baseline.BaselineResult[1].Result

		Get-AzSqlInstanceDatabase -ResourceGroupName $params.rgname -InstanceName $params.serverName -Name $params.databaseName | Clear-AzSqlInstanceDatabaseVulnerabilityAssessmentRuleBaseline `
		-RuleId $ruleId
		Assert-ThrowsContains -script { Get-AzSqlInstanceDatabaseVulnerabilityAssessmentRuleBaseline -ResourceGroupName $params.rgname -InstanceName $params.serverName `
		-DatabaseName $params.databaseName -RuleId $ruleId } -message $baselineDoesntExistsErrorMessage

		
		Set-AzSqlInstanceDatabaseVulnerabilityAssessmentRuleBaseline -ResourceGroupName $params.rgname -InstanceName $params.serverName -DatabaseName $params.databaseName `
		-RuleId $ruleId -BaselineResult $baselineToSet -WhatIf
		
		
		Assert-ThrowsContains -script { Clear-AzSqlInstanceDatabaseVulnerabilityAssessmentRuleBaseline -ResourceGroupName $params.rgname -InstanceName $params.serverName -DatabaseName $params.databaseName `
		-RuleId $ruleId } -message $baselineDoesntExistsErrorMessage

		
		Set-AzSqlInstanceDatabaseVulnerabilityAssessmentRuleBaseline -ResourceGroupName $params.rgname -InstanceName $params.serverName -DatabaseName $params.databaseName `
		-RuleId $ruleId -BaselineResult $baselineToSet

		Clear-AzSqlInstanceDatabaseVulnerabilityAssessmentRuleBaseline -ResourceGroupName $params.rgname -InstanceName $params.serverName `
		-DatabaseName $params.databaseName -RuleId $ruleId -WhatIf
		
		
		Clear-AzSqlInstanceDatabaseVulnerabilityAssessmentRuleBaseline -ResourceGroupName $params.rgname -InstanceName $params.serverName -DatabaseName $params.databaseName `
		-RuleId $ruleId
	}
	finally
	{
		
		Remove-VulnerabilityAssessmentManagedInstanceTestEnvironment $testSuffix
	}
}


function Test-VulnerabilityAssessmentManagedDatabaseScanRecordGetListTest
{
	
	$testSuffix = getAssetName
	Create-VulnerabilityAssessmentManagedInstanceTestEnvironment $testSuffix
	$params = Get-SqlVulnerabilityAssessmentManagedInstanceTestEnvironmentParameters $testSuffix

	try
	{
		
		Enable-AzSqlInstanceAdvancedDataSecurity -ResourceGroupName $params.rgname -InstanceName $params.serverName -DoNotConfigureVulnerabilityAssessment

		Update-AzSqlInstanceDatabaseVulnerabilityAssessmentSetting -ResourceGroupName $params.rgname -InstanceName $params.serverName -DatabaseName $params.databaseName `
			 -StorageAccountName $params.storageAccount
	
		
		try
		{
			Start-AzSqlInstanceDatabaseVulnerabilityAssessmentScan -ResourceGroupName $params.rgname -InstanceName $params.serverName -DatabaseName $params.databaseName 
		}
		catch
		{
			if ((Get-SqlTestMode) -eq 'Playback')
			{
				
				
			}
			else
			{
				throw;
			}
		}

		
		$scanId1 = "cmdletGetListScan"
		$scanJob = Start-AzSqlInstanceDatabaseVulnerabilityAssessmentScan -ResourceGroupName $params.rgname -InstanceName $params.serverName -DatabaseName $params.databaseName -ScanId $scanId1 -AsJob
		$scanJob | Wait-Job
		$scanRecord1 = $scanJob | Receive-Job

		
		Assert-AreEqual $params.rgname $scanRecord1.ResourceGroupName
		Assert-AreEqual $params.serverName $scanRecord1.InstanceName 
		Assert-AreEqual $params.databaseName $scanRecord1.DatabaseName 
		Assert-AreEqual $scanId1 $scanRecord1.ScanId
		Assert-AreEqual "OnDemand" $scanRecord1.TriggerType

		
		$scanRecord1FromGet = Get-AzSqlInstanceDatabaseVulnerabilityAssessmentScanRecord -ResourceGroupName $params.rgname -InstanceName $params.serverName `
		-DatabaseName $params.databaseName -ScanId $scanId1

		Assert-AreEqual $scanRecord1FromGet.ResourceGroupName $scanRecord1.ResourceGroupName
		Assert-AreEqual $scanRecord1FromGet.InstanceName $scanRecord1.InstanceName
		Assert-AreEqual $scanRecord1FromGet.DatabaseName $scanRecord1.DatabaseName
		Assert-AreEqual $scanRecord1FromGet.ScanId $scanRecord1.ScanId
		Assert-AreEqual $scanRecord1FromGet.TriggerType $scanRecord1.TriggerType
		Assert-AreEqual $scanRecord1FromGet.State $scanRecord1.State
		Assert-AreEqual $scanRecord1FromGet.StartTime $scanRecord1.StartTime
		Assert-AreEqual $scanRecord1FromGet.EndTime $scanRecord1.EndTime
		Assert-AreEqual $scanRecord1FromGet.Errors $scanRecord1.Errors
		Assert-AreEqual $scanRecord1FromGet.ScanResultsLocationPath $scanRecord1.ScanResultsLocationPath
		Assert-AreEqual $scanRecord1FromGet.NumberOfFailedSecurityChecks $scanRecord1.NumberOfFailedSecurityChecks

		
		$scanRecord1FromGet = Get-AzSqlInstanceDatabase -ResourceGroupName $params.rgname -InstanceName $params.serverName -Name $params.databaseName | Get-AzSqlInstanceDatabaseVulnerabilityAssessmentScanRecord `
		-ScanId $scanId1

		Assert-AreEqual $scanRecord1FromGet.ResourceGroupName $scanRecord1.ResourceGroupName
		Assert-AreEqual $scanRecord1FromGet.InstanceName $scanRecord1.InstanceName
		Assert-AreEqual $scanRecord1FromGet.DatabaseName $scanRecord1.DatabaseName
		Assert-AreEqual $scanRecord1FromGet.ScanId $scanRecord1.ScanId
		Assert-AreEqual $scanRecord1FromGet.TriggerType $scanRecord1.TriggerType
		Assert-AreEqual $scanRecord1FromGet.State $scanRecord1.State
		Assert-AreEqual $scanRecord1FromGet.StartTime $scanRecord1.StartTime
		Assert-AreEqual $scanRecord1FromGet.EndTime $scanRecord1.EndTime
		Assert-AreEqual $scanRecord1FromGet.Errors $scanRecord1.Errors
		Assert-AreEqual $scanRecord1FromGet.ScanResultsLocationPath $scanRecord1.ScanResultsLocationPath
		Assert-AreEqual $scanRecord1FromGet.NumberOfFailedSecurityChecks $scanRecord1.NumberOfFailedSecurityChecks

		
		$excpectedScanCount = 2
		$scanRecordList = Get-AzSqlInstanceDatabaseVulnerabilityAssessmentScanRecord -ResourceGroupName $params.rgname -InstanceName $params.serverName -DatabaseName $params.databaseName 
		Assert-AreEqual $excpectedScanCount $scanRecordList.Count

		$scanRecord1FromListCmdlet = $scanRecordList[$excpectedScanCount-1]
		Assert-AreEqual $scanRecord1FromListCmdlet.ResourceGroupName $scanRecord1.ResourceGroupName
		Assert-AreEqual $scanRecord1FromListCmdlet.InstanceName $scanRecord1.InstanceName
		Assert-AreEqual $scanRecord1FromListCmdlet.DatabaseName $scanRecord1.DatabaseName
		Assert-AreEqual $scanRecord1FromListCmdlet.ScanId $scanRecord1.ScanId
		Assert-AreEqual $scanRecord1FromListCmdlet.TriggerType $scanRecord1.TriggerType
		Assert-AreEqual $scanRecord1FromListCmdlet.State $scanRecord1.State
		Assert-AreEqual $scanRecord1FromListCmdlet.StartTime $scanRecord1.StartTime
		Assert-AreEqual $scanRecord1FromListCmdlet.EndTime $scanRecord1.EndTime
		Assert-AreEqual $scanRecord1FromListCmdlet.Errors $scanRecord1.Errors
		Assert-AreEqual $scanRecord1FromListCmdlet.ScanResultsLocationPath $scanRecord1.ScanResultsLocationPath
		Assert-AreEqual $scanRecord1FromListCmdlet.NumberOfFailedSecurityChecks $scanRecord1.NumberOfFailedSecurityChecks

		
		$excpectedScanCount = $excpectedScanCount + 1
		Get-AzSqlInstanceDatabase -ResourceGroupName $params.rgname -InstanceName $params.serverName -Name $params.databaseName `
		| Start-AzSqlInstanceDatabaseVulnerabilityAssessmentScan -ScanId $scanId1

		
		$scanRecordList = Get-AzSqlInstanceDatabase -ResourceGroupName $params.rgname -InstanceName $params.serverName -Name $params.databaseName | Get-AzSqlInstanceDatabaseVulnerabilityAssessmentScanRecord 
		Assert-AreEqual $excpectedScanCount $scanRecordList.Count

		$scanRecord1FromListCmdlet = $scanRecordList[$excpectedScanCount-1]
		Assert-AreEqual $scanRecord1FromListCmdlet.ResourceGroupName $scanRecord1.ResourceGroupName
		Assert-AreEqual $scanRecord1FromListCmdlet.InstanceName $scanRecord1.InstanceName
		Assert-AreEqual $scanRecord1FromListCmdlet.DatabaseName $scanRecord1.DatabaseName
		Assert-AreEqual $scanRecord1FromListCmdlet.ScanId $scanRecord1.ScanId
		Assert-AreEqual $scanRecord1FromListCmdlet.TriggerType $scanRecord1.TriggerType
		Assert-AreEqual $scanRecord1FromListCmdlet.State $scanRecord1.State


		
		$scanRecordList = Get-AzSqlInstanceDatabaseVulnerabilityAssessmentScanRecord -ResourceGroupName $params.rgname -InstanceName $params.serverName -DatabaseName $params.databaseName
		$scansCount = $scanRecordList.Count

		Start-AzSqlInstanceDatabaseVulnerabilityAssessmentScan -ResourceGroupName $params.rgname -InstanceName $params.serverName -DatabaseName $params.databaseName `
		-WhatIf

		
		$scanRecordList = Get-AzSqlInstanceDatabaseVulnerabilityAssessmentScanRecord -ResourceGroupName $params.rgname -InstanceName $params.serverName -DatabaseName $params.databaseName
		Assert-AreEqual $scansCount $scanRecordList.Count
	}
	finally
	{
		
		Remove-VulnerabilityAssessmentManagedInstanceTestEnvironment $testSuffix
	}
}


function Test-VulnerabilityAssessmentManagedDatabaseScanConvertTest
{
	
	$testSuffix = getAssetName
	Create-VulnerabilityAssessmentManagedInstanceTestEnvironment $testSuffix
	$params = Get-SqlVulnerabilityAssessmentManagedInstanceTestEnvironmentParameters $testSuffix

	try
	{
		
		Enable-AzSqlInstanceAdvancedDataSecurity -ResourceGroupName $params.rgname -InstanceName $params.serverName -DoNotConfigureVulnerabilityAssessment

		Update-AzSqlInstanceDatabaseVulnerabilityAssessmentSetting -ResourceGroupName $params.rgname -InstanceName $params.serverName -DatabaseName $params.databaseName `
			 -StorageAccountName $params.storageAccount

		
		Assert-ThrowsContains -script { Convert-AzSqlInstanceDatabaseVulnerabilityAssessmentScan -ResourceGroupName $params.rgname -InstanceName $params.serverName `
		-DatabaseName $params.databaseName } -message "ScanId is a required parameter for this cmdlet. Please explicitly provide it or pass the Get-AzSqlInstanceDatabaseVulnerabilityAssessmentScanRecord output via pipe."

		
		$scanId = "cmdletConvertScan"
		Start-AzSqlInstanceDatabaseVulnerabilityAssessmentScan -ResourceGroupName $params.rgname -InstanceName $params.serverName -DatabaseName $params.databaseName -ScanId $scanId

		
		$convertScanObject = Convert-AzSqlInstanceDatabaseVulnerabilityAssessmentScan -ResourceGroupName $params.rgname -InstanceName $params.serverName -DatabaseName $params.databaseName `
		-ScanId $scanId
	
		Assert-AreEqual $params.rgname $convertScanObject.ResourceGroupName
		Assert-AreEqual $params.serverName $convertScanObject.InstanceName
		Assert-AreEqual $params.databaseName $convertScanObject.DatabaseName
		Assert-True -script  { $convertScanObject.ExportedReportLocation.Contains($scanId) }
		Assert-True -script  { $convertScanObject.ExportedReportLocation.Contains($params.storageAccount) }

		
		$scanId = "cmdletConvertScan1"
		Start-AzSqlInstanceDatabaseVulnerabilityAssessmentScan -ResourceGroupName $params.rgname -InstanceName $params.serverName -DatabaseName $params.databaseName -ScanId $scanId

		$convertScanObject =  Get-AzSqlInstanceDatabaseVulnerabilityAssessmentScanRecord -ResourceGroupName $params.rgname -InstanceName $params.serverName -DatabaseName $params.databaseName `
		-ScanId $scanId | Convert-AzSqlInstanceDatabaseVulnerabilityAssessmentScan
	
		Assert-AreEqual $params.rgname $convertScanObject.ResourceGroupName
		Assert-AreEqual $params.serverName $convertScanObject.InstanceName
		Assert-AreEqual $params.databaseName $convertScanObject.DatabaseName
		Assert-True -script  { $convertScanObject.ExportedReportLocation.Contains($scanId) }
		Assert-True -script  { $convertScanObject.ExportedReportLocation.Contains($params.storageAccount) }

		
		$convertScanObject = Convert-AzSqlInstanceDatabaseVulnerabilityAssessmentScan -ResourceGroupName $params.rgname -InstanceName $params.serverName -DatabaseName $params.databaseName `
		-ScanId $scanId -WhatIf
		Assert-Null $convertScanObject.ExportedReportLocation
		
		
		Clear-AzSqlInstanceDatabaseVulnerabilityAssessmentSetting -ResourceGroupName $params.rgname -InstanceName $params.serverName -DatabaseName $params.databaseName

		Update-AzSqlInstanceVulnerabilityAssessmentSetting -ResourceGroupName $params.rgname -InstanceName $params.serverName -StorageAccountName $params.storageAccount

		
		Start-AzSqlInstanceDatabaseVulnerabilityAssessmentScan -ResourceGroupName $params.rgname -InstanceName $params.serverName -DatabaseName $params.databaseName -ScanId $scanId
	}
	finally
	{
		
		Remove-VulnerabilityAssessmentManagedInstanceTestEnvironment $testSuffix
	}
}


function Create-VulnerabilityAssessmentManagedInstanceTestEnvironment ($testSuffix, $location = "West Central US")
{
	$params = Get-SqlVulnerabilityAssessmentManagedInstanceTestEnvironmentParameters $testSuffix
	Create-InstanceTestEnvironmentWithParams $params $location
}


function Get-SqlVulnerabilityAssessmentManagedInstanceTestEnvironmentParameters ($testSuffix)
{
	return @{ rgname = "sql-va-cmdlet-test-rg" +$testSuffix;
			  serverName = "sql-va-cmdlet-server" +$testSuffix;
			  databaseName = "sql-va-cmdlet-db" + $testSuffix;
			  storageAccount = "sqlvacmdlets" +$testSuffix
		}
}


function Remove-VulnerabilityAssessmentManagedInstanceTestEnvironment ($testSuffix)
{
	$params = Get-SqlVulnerabilityAssessmentManagedInstanceTestEnvironmentParameters $testSuffix
	Remove-AzureRmResourceGroup -Name $params.rgname -Force
}