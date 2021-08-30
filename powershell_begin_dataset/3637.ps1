














function Test-ThreatDetectionUpdatePolicyWithClassicStorage
{
	
	$testSuffix = getAssetName
	Create-ThreatDetectionClassicTestEnvironment $testSuffix
	$params = Get-SqlThreatDetectionTestEnvironmentParameters $testSuffix

	try 
	{
		
		Set-AzSqlDatabaseThreatDetectionSetting -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName -NotificationRecipientsEmails "koko1@mailTest.com" -EmailAdmins $false -ExcludedDetectionType "Sql_Injection_Vulnerability" -StorageAccountName $params.storageAccount
		$policy = Get-AzSqlDatabaseThreatDetectionSetting -ResourceGroupName $params.rgname -ServerName $params.serverName -DatabaseName $params.databaseName
	
		
		Assert-AreEqual $policy.ThreatDetectionState "Enabled"
		Assert-AreEqual $policy.NotificationRecipientsEmails "koko1@mailTest.com"
		Assert-AreEqual $policy.StorageAccountName $params.storageAccount
		Assert-False {$policy.EmailAdmins}
		Assert-AreEqual $policy.ExcludedDetectionTypes.Count 1
		Assert-True {$policy.ExcludedDetectionTypes.Contains([Microsoft.Azure.Commands.Sql.ThreatDetection.Model.DetectionType]::Sql_Injection_Vulnerability)}


		
		Set-AzSqlServerThreatDetectionSetting -ResourceGroupName $params.rgname -ServerName $params.serverName -NotificationRecipientsEmails "koko2@mailTest.com" -EmailAdmins $false -ExcludedDetectionType Sql_Injection_Vulnerability -StorageAccountName $params.storageAccount
		$policy = Get-AzSqlServerThreatDetectionSetting -ResourceGroupName $params.rgname -ServerName $params.serverName
	
		
		Assert-AreEqual $policy.ThreatDetectionState "Enabled"
		Assert-AreEqual $policy.NotificationRecipientsEmails "koko2@mailTest.com"
		Assert-False {$policy.EmailAdmins}
		Assert-AreEqual $policy.ExcludedDetectionTypes.Count 1
		Assert-True {$policy.ExcludedDetectionTypes.Contains([Microsoft.Azure.Commands.Sql.ThreatDetection.Model.DetectionType]::Sql_Injection_Vulnerability)}
	}
	finally
	{
		
		Remove-ThreatDetectionTestEnvironment $testSuffix
	}
}
