














function Test-ThreatDetectionGetDefaultPolicy
{
	
	$testSuffix = getAssetName
	Create-ThreatDetectionTestEnvironment $testSuffix
	$params = Get-SqlThreatDetectionTestEnvironmentParameters $testSuffix

	try 
	{
		
		$policy = Get-AzSqlDatabaseAdvancedThreatProtectionSetting -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName

		
		Assert-AreEqual $policy.ThreatDetectionState "Disabled"
		Assert-AreEqual $policy.NotificationRecipientsEmails ""
		Assert-False {$policy.EmailAdmins}
		Assert-AreEqual $policy.ExcludedDetectionTypes.Count 0

		
		$policy = Get-AzSqlServerAdvancedThreatProtectionSetting -ResourceGroupName $params.rgname -ServerName $params.serverName

		
		Assert-AreEqual $policy.ThreatDetectionState "Disabled"
		Assert-AreEqual $policy.NotificationRecipientsEmails ""
		Assert-False {$policy.EmailAdmins}
		Assert-AreEqual $policy.ExcludedDetectionTypes.Count 0
	}
	finally
	{
		
		Remove-ThreatDetectionTestEnvironment $testSuffix
	}
}


function Test-ThreatDetectionDatabaseUpdatePolicy
{
	
	$testSuffix = getAssetName
	Create-ThreatDetectionTestEnvironment $testSuffix
	$params = Get-SqlThreatDetectionTestEnvironmentParameters $testSuffix

	try
	{
		
		Update-AzSqlDatabaseAdvancedThreatProtectionSetting -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName -StorageAccountName $params.storageAccount
		$policy = Get-AzSqlDatabaseAdvancedThreatProtectionSetting -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName
	
		
		Assert-AreEqual $policy.ThreatDetectionState "Enabled"
		Assert-AreEqual $policy.NotificationRecipientsEmails ""
		Assert-False {$policy.EmailAdmins}
		Assert-AreEqual $policy.ExcludedDetectionTypes.Count 0
		Assert-AreEqual $policy.StorageAccountName $params.storageAccount

		
		Update-AzSqlDatabaseAdvancedThreatProtectionSetting -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName -NotificationRecipientsEmails "koko@mailTest.com;koko1@mailTest.com" -EmailAdmins $false -ExcludedDetectionType "Sql_Injection_Vulnerability" -StorageAccountName $params.storageAccount
		$policy = Get-AzSqlDatabaseAdvancedThreatProtectionSetting -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName
	
		
		Assert-AreEqual $policy.ThreatDetectionState "Enabled"
		Assert-AreEqual $policy.NotificationRecipientsEmails "koko@mailTest.com;koko1@mailTest.com"
		Assert-AreEqual $policy.StorageAccountName $params.storageAccount
		Assert-False {$policy.EmailAdmins}
		Assert-AreEqual $policy.ExcludedDetectionTypes.Count 1
		Assert-True {$policy.ExcludedDetectionTypes.Contains([Microsoft.Azure.Commands.Sql.ThreatDetection.Model.DetectionType]::Sql_Injection_Vulnerability)}

		
		Update-AzSqlDatabaseAdvancedThreatProtectionSetting -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName -ExcludedDetectionType "Sql_Injection", "Sql_Injection_Vulnerability", "Access_Anomaly", "Data_Exfiltration", "Unsafe_Action"
		$policy = Get-AzSqlDatabaseAdvancedThreatProtectionSetting -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName
	
		
		Assert-AreEqual $policy.ThreatDetectionState "Enabled"
		Assert-AreEqual $policy.NotificationRecipientsEmails "koko@mailTest.com;koko1@mailTest.com"
		Assert-False {$policy.EmailAdmins}
		Assert-AreEqual $policy.ExcludedDetectionTypes.Count 5
		Assert-AreEqual $policy.StorageAccountName $params.storageAccount
		Assert-True {$policy.ExcludedDetectionTypes.Contains([Microsoft.Azure.Commands.Sql.ThreatDetection.Model.DetectionType]::Sql_Injection)}
		Assert-True {$policy.ExcludedDetectionTypes.Contains([Microsoft.Azure.Commands.Sql.ThreatDetection.Model.DetectionType]::Sql_Injection_Vulnerability)}
		Assert-True {$policy.ExcludedDetectionTypes.Contains([Microsoft.Azure.Commands.Sql.ThreatDetection.Model.DetectionType]::Access_Anomaly)}
		Assert-True {$policy.ExcludedDetectionTypes.Contains([Microsoft.Azure.Commands.Sql.ThreatDetection.Model.DetectionType]::Data_Exfiltration)}
		Assert-True {$policy.ExcludedDetectionTypes.Contains([Microsoft.Azure.Commands.Sql.ThreatDetection.Model.DetectionType]::Unsafe_Action)}
        
		
		Clear-AzSqlDatabaseAdvancedThreatProtectionSetting -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName
		$policy = Get-AzSqlDatabaseAdvancedThreatProtectionSetting -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName
	
		
		Assert-AreEqual $policy.ThreatDetectionState "Disabled"
		Assert-AreEqual $policy.NotificationRecipientsEmails "koko@mailTest.com;koko1@mailTest.com"
		Assert-False {$policy.EmailAdmins}
		Assert-AreEqual $policy.ExcludedDetectionTypes.Count 5
		Assert-True {$policy.ExcludedDetectionTypes.Contains([Microsoft.Azure.Commands.Sql.ThreatDetection.Model.DetectionType]::Sql_Injection)}
		Assert-True {$policy.ExcludedDetectionTypes.Contains([Microsoft.Azure.Commands.Sql.ThreatDetection.Model.DetectionType]::Sql_Injection_Vulnerability)}
		Assert-True {$policy.ExcludedDetectionTypes.Contains([Microsoft.Azure.Commands.Sql.ThreatDetection.Model.DetectionType]::Access_Anomaly)}
		Assert-True {$policy.ExcludedDetectionTypes.Contains([Microsoft.Azure.Commands.Sql.ThreatDetection.Model.DetectionType]::Data_Exfiltration)}
		Assert-True {$policy.ExcludedDetectionTypes.Contains([Microsoft.Azure.Commands.Sql.ThreatDetection.Model.DetectionType]::Unsafe_Action)}
	
		
		Update-AzSqlDatabaseAdvancedThreatProtectionSetting -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName -ExcludedDetectionType "None"
		$policy = Get-AzSqlDatabaseAdvancedThreatProtectionSetting -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName
	
		
		Assert-AreEqual $policy.ThreatDetectionState "Enabled"
		Assert-AreEqual $policy.NotificationRecipientsEmails "koko@mailTest.com;koko1@mailTest.com"
		Assert-False {$policy.EmailAdmins}
		Assert-AreEqual $policy.ExcludedDetectionTypes.Count 0	
	}
	finally
	{
		
		Remove-ThreatDetectionTestEnvironment $testSuffix
	}
}


function Test-ThreatDetectionServerUpdatePolicy
{
	
	$testSuffix = getAssetName
	Create-ThreatDetectionTestEnvironment $testSuffix
	$params = Get-SqlThreatDetectionTestEnvironmentParameters $testSuffix

	try
	{
		
		Update-AzSqlServerAdvancedThreatProtectionSetting -ResourceGroupName $params.rgname -ServerName $params.serverName -EmailAdmins $false
		$policy = Get-AzSqlServerAdvancedThreatProtectionSetting -ResourceGroupName $params.rgname -ServerName $params.serverName
	
		
		Assert-AreEqual $policy.ThreatDetectionState "Enabled"
		Assert-AreEqual $policy.NotificationRecipientsEmails ""
		Assert-False {$policy.EmailAdmins}
		Assert-AreEqual $policy.ExcludedDetectionTypes.Count 0

		
		Update-AzSqlServerAdvancedThreatProtectionSetting -ResourceGroupName $params.rgname -ServerName $params.serverName -NotificationRecipientsEmails "koko@mailTest.com;koko1@mailTest.com" -EmailAdmins $false -ExcludedDetectionType Sql_Injection_Vulnerability -StorageAccountName $params.storageAccount
		$policy = Get-AzSqlServerAdvancedThreatProtectionSetting -ResourceGroupName $params.rgname -ServerName $params.serverName
	
		
		Assert-AreEqual $policy.ThreatDetectionState "Enabled"
		Assert-AreEqual $policy.NotificationRecipientsEmails "koko@mailTest.com;koko1@mailTest.com"
		Assert-False {$policy.EmailAdmins}
		Assert-AreEqual $policy.ExcludedDetectionTypes.Count 1
		Assert-True {$policy.ExcludedDetectionTypes.Contains([Microsoft.Azure.Commands.Sql.ThreatDetection.Model.DetectionType]::Sql_Injection_Vulnerability)}

		
		Update-AzSqlServerAdvancedThreatProtectionSetting -ResourceGroupName $params.rgname -ServerName $params.serverName -ExcludedDetectionType Sql_Injection, Sql_Injection_Vulnerability, Access_Anomaly, Data_Exfiltration, Unsafe_Action -StorageAccountName $params.storageAccount
		$policy = Get-AzSqlServerAdvancedThreatProtectionSetting -ResourceGroupName $params.rgname -ServerName $params.serverName
	
		
		Assert-AreEqual $policy.ThreatDetectionState "Enabled"
		Assert-AreEqual $policy.NotificationRecipientsEmails "koko@mailTest.com;koko1@mailTest.com"
		Assert-False {$policy.EmailAdmins}
		Assert-AreEqual $policy.ExcludedDetectionTypes.Count 5
		Assert-True {$policy.ExcludedDetectionTypes.Contains([Microsoft.Azure.Commands.Sql.ThreatDetection.Model.DetectionType]::Sql_Injection)}
		Assert-True {$policy.ExcludedDetectionTypes.Contains([Microsoft.Azure.Commands.Sql.ThreatDetection.Model.DetectionType]::Sql_Injection_Vulnerability)}
		Assert-True {$policy.ExcludedDetectionTypes.Contains([Microsoft.Azure.Commands.Sql.ThreatDetection.Model.DetectionType]::Access_Anomaly)}
		Assert-True {$policy.ExcludedDetectionTypes.Contains([Microsoft.Azure.Commands.Sql.ThreatDetection.Model.DetectionType]::Data_Exfiltration)}
		Assert-True {$policy.ExcludedDetectionTypes.Contains([Microsoft.Azure.Commands.Sql.ThreatDetection.Model.DetectionType]::Unsafe_Action)}
        
		
		Clear-AzSqlServerAdvancedThreatProtectionSetting -ResourceGroupName $params.rgname -ServerName $params.serverName
		$policy = Get-AzSqlServerAdvancedThreatProtectionSetting -ResourceGroupName $params.rgname -ServerName $params.serverName
	
		
		Assert-AreEqual $policy.ThreatDetectionState "Disabled"
		Assert-AreEqual $policy.NotificationRecipientsEmails "koko@mailTest.com;koko1@mailTest.com"
		Assert-False {$policy.EmailAdmins}
		Assert-AreEqual $policy.ExcludedDetectionTypes.Count 5
		Assert-True {$policy.ExcludedDetectionTypes.Contains([Microsoft.Azure.Commands.Sql.ThreatDetection.Model.DetectionType]::Sql_Injection)}
		Assert-True {$policy.ExcludedDetectionTypes.Contains([Microsoft.Azure.Commands.Sql.ThreatDetection.Model.DetectionType]::Sql_Injection_Vulnerability)}
		Assert-True {$policy.ExcludedDetectionTypes.Contains([Microsoft.Azure.Commands.Sql.ThreatDetection.Model.DetectionType]::Access_Anomaly)}
		Assert-True {$policy.ExcludedDetectionTypes.Contains([Microsoft.Azure.Commands.Sql.ThreatDetection.Model.DetectionType]::Data_Exfiltration)}
		Assert-True {$policy.ExcludedDetectionTypes.Contains([Microsoft.Azure.Commands.Sql.ThreatDetection.Model.DetectionType]::Unsafe_Action)}
	
		
		Update-AzSqlServerAdvancedThreatProtectionSetting -ResourceGroupName $params.rgname -ServerName $params.serverName  -ExcludedDetectionType None -StorageAccountName $params.storageAccount
		$policy = Get-AzSqlServerAdvancedThreatProtectionSetting -ResourceGroupName $params.rgname -ServerName $params.serverName
	
		
		Assert-AreEqual $policy.ThreatDetectionState "Enabled"
		Assert-AreEqual $policy.NotificationRecipientsEmails "koko@mailTest.com;koko1@mailTest.com"
		Assert-False {$policy.EmailAdmins}
		Assert-AreEqual $policy.ExcludedDetectionTypes.Count 0	
	}
	finally
	{
		
		Remove-ThreatDetectionTestEnvironment $testSuffix
	}
}


function Test-DisablingThreatDetection
{
	
	$testSuffix = getAssetName
	Create-ThreatDetectionTestEnvironment $testSuffix
	$params = Get-SqlThreatDetectionTestEnvironmentParameters $testSuffix

	try
	{
		
		Update-AzSqlDatabaseAdvancedThreatProtectionSetting -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName -StorageAccountName $params.storageAccount -EmailAdmins $true
		$policy = Get-AzSqlDatabaseAdvancedThreatProtectionSetting -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName
	
		
		Assert-AreEqual $policy.ThreatDetectionState "Enabled"

		
		Clear-AzSqlDatabaseAdvancedThreatProtectionSetting -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName 
		$policy = Get-AzSqlDatabaseAdvancedThreatProtectionSetting -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName

		
		Assert-AreEqual $policy.ThreatDetectionState "Disabled"

		
		Update-AzSqlDatabaseAdvancedThreatProtectionSetting -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName -StorageAccountName $params.storageAccount -EmailAdmins $true
		$policy = Get-AzSqlDatabaseAdvancedThreatProtectionSetting -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName
	}
	finally
	{
		
		Remove-ThreatDetectionTestEnvironment $testSuffix
	}
}


function Test-InvalidArgumentsThreatDetection
{
	
	$testSuffix = getAssetName
	Create-ThreatDetectionTestEnvironment $testSuffix
	$params = Get-SqlThreatDetectionTestEnvironmentParameters $testSuffix

	try
	{
		
		Assert-Throws {Update-AzSqlDatabaseAdvancedThreatProtectionSetting -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName} 

		
		Assert-Throws {Update-AzSqlDatabaseAdvancedThreatProtectionSetting -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName -NotificationRecipientsEmails "kokogmail.com"} 

		
		Assert-Throws {Update-AzSqlDatabaseAdvancedThreatProtectionSetting -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName -EmailAdmins $true -ExcludedDetectionType "None", "Sql_Injection_Vulnerability" -StorageAccountName $params.storageAccount} 
	}
	finally
	{
		
		Remove-ThreatDetectionTestEnvironment $testSuffix
	}
}
