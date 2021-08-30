














function Test-AdvancedDataSecurityPolicyTest
{
	
	$testSuffix = getAssetName
	Create-AdvancedDataSecurityTestEnvironment $testSuffix
	$params = Get-SqlAdvancedDataSecurityTestEnvironmentParameters $testSuffix

	try
	{
		
		$policy = Get-AzSqlServerAdvancedDataSecurityPolicy -ResourceGroupName $params.rgname -ServerName $params.serverName 
				
		
		Assert-AreEqual $params.rgname $policy.ResourceGroupName
		Assert-AreEqual $params.serverName $policy.ServerName
		Assert-False { $policy.IsEnabled }

		
		Enable-AzSqlServerAdvancedDataSecurity -ResourceGroupName $params.rgname -ServerName $params.serverName -DoNotConfigureVulnerabilityAssessment
		$policy = Get-AzSqlServerAdvancedDataSecurityPolicy -ResourceGroupName $params.rgname -ServerName $params.serverName 
				
		
		Assert-AreEqual $params.rgname $policy.ResourceGroupName
		Assert-AreEqual $params.serverName $policy.ServerName
		Assert-True { $policy.IsEnabled }

		
		Disable-AzSqlServerAdvancedDataSecurity -ResourceGroupName $params.rgname -ServerName $params.serverName 
		$policy = Get-AzSqlServerAdvancedDataSecurityPolicy -ResourceGroupName $params.rgname -ServerName $params.serverName 
				
		
		Assert-AreEqual $params.rgname $policy.ResourceGroupName
		Assert-AreEqual $params.serverName $policy.ServerName
		Assert-False { $policy.IsEnabled }

		
		Update-AzSqlServerAdvancedThreatProtectionSetting -ResourceGroupName $params.rgname -ServerName $params.serverName -NotificationRecipientsEmails "koko@mailTest.com;koko1@mailTest.com" -EmailAdmins $false -ExcludedDetectionType Sql_Injection_Vulnerability

		Disable-AzSqlServerAdvancedDataSecurity -ResourceGroupName $params.rgname -ServerName $params.serverName 

		
		$policy = Get-AzSqlServerAdvancedThreatProtectionSetting -ResourceGroupName $params.rgname -ServerName $params.serverName
		Assert-AreEqual $policy.ThreatDetectionState "Disabled"
		Assert-AreEqual $policy.NotificationRecipientsEmails "koko@mailTest.com;koko1@mailTest.com"
		Assert-False {$policy.EmailAdmins}
		Assert-AreEqual $policy.ExcludedDetectionTypes.Count 1
		Assert-True {$policy.ExcludedDetectionTypes.Contains([Microsoft.Azure.Commands.Sql.ThreatDetection.Model.DetectionType]::Sql_Injection_Vulnerability)}

		Enable-AzSqlServerAdvancedDataSecurity -ResourceGroupName $params.rgname -ServerName $params.serverName -DoNotConfigureVulnerabilityAssessment

		
		$policy = Get-AzSqlServerAdvancedThreatProtectionSetting -ResourceGroupName $params.rgname -ServerName $params.serverName
		Assert-AreEqual $policy.ThreatDetectionState "Enabled"
		Assert-AreEqual $policy.NotificationRecipientsEmails "koko@mailTest.com;koko1@mailTest.com"
		Assert-False {$policy.EmailAdmins}
		Assert-AreEqual $policy.ExcludedDetectionTypes.Count 1
		Assert-True {$policy.ExcludedDetectionTypes.Contains([Microsoft.Azure.Commands.Sql.ThreatDetection.Model.DetectionType]::Sql_Injection_Vulnerability)}

		
		Disable-AzSqlServerAdvancedDataSecurity -ResourceGroupName $params.rgname -ServerName $params.serverName 
		Enable-AzSqlServerAdvancedDataSecurity -ResourceGroupName $params.rgname -ServerName $params.serverName -DeploymentName "EnableVA_sql-ads-cmdlet-test-srv1"

		
		$policy = Get-AzSqlServerAdvancedDataSecurityPolicy -ResourceGroupName $params.rgname -ServerName $params.serverName 
		Assert-AreEqual $params.rgname $policy.ResourceGroupName
		Assert-AreEqual $params.serverName $policy.ServerName
		Assert-True { $policy.IsEnabled }

		
		$settings = Get-AzSqlServerVulnerabilityAssessmentSetting -ResourceGroupName $params.rgname -ServerName $params.serverName 
		Assert-AreEqual $params.rgname $settings.ResourceGroupName
		Assert-AreEqual $params.serverName $settings.ServerName
		Assert-AreEqual "vulnerability-assessment" $settings.ScanResultsContainerName
		Assert-AreNotEqual "" $settings.StorageAccountName	
		Assert-AreEqual Weekly $settings.RecurringScansInterval
		Assert-AreEqual $true $settings.EmailAdmins
		Assert-AreEqualArray @() $settings.NotificationEmail

		
		Update-AzSqlServerAdvancedThreatProtectionSetting -ResourceGroupName $params.rgname -ServerName $params.serverName -NotificationRecipientsEmails "koko@mailTest.com;koko1@mailTest.com" -EmailAdmins $false -ExcludedDetectionType Sql_Injection_Vulnerability

		Disable-AzSqlServerAdvancedDataSecurity -ResourceGroupName $params.rgname -ServerName $params.serverName 

		
		$policy = Get-AzSqlServerAdvancedThreatProtectionSetting -ResourceGroupName $params.rgname -ServerName $params.serverName
		Assert-AreEqual $policy.ThreatDetectionState "Disabled"
		Assert-AreEqual $policy.NotificationRecipientsEmails "koko@mailTest.com;koko1@mailTest.com"
		Assert-False {$policy.EmailAdmins}
		Assert-AreEqual $policy.ExcludedDetectionTypes.Count 1
		Assert-True {$policy.ExcludedDetectionTypes.Contains([Microsoft.Azure.Commands.Sql.ThreatDetection.Model.DetectionType]::Sql_Injection_Vulnerability)}

		Enable-AzSqlServerAdvancedDataSecurity -ResourceGroupName $params.rgname -ServerName $params.serverName -DeploymentName "EnableVA_sql-ads-cmdlet-test-srv2"

		
		$policy = Get-AzSqlServerAdvancedThreatProtectionSetting -ResourceGroupName $params.rgname -ServerName $params.serverName
		Assert-AreEqual $policy.ThreatDetectionState "Enabled"
		Assert-AreEqual $policy.NotificationRecipientsEmails "koko@mailTest.com;koko1@mailTest.com"
		Assert-False {$policy.EmailAdmins}
		Assert-AreEqual $policy.ExcludedDetectionTypes.Count 1
		Assert-True {$policy.ExcludedDetectionTypes.Contains([Microsoft.Azure.Commands.Sql.ThreatDetection.Model.DetectionType]::Sql_Injection_Vulnerability)}
	}
	finally
	{
		
		Remove-AdvancedDataSecurityTestEnvironment $testSuffix
	}
}


function Create-AdvancedDataSecurityTestEnvironment ($testSuffix, $location = "West Central US", $serverVersion = "12.0")
{
	$params = Get-SqlAdvancedDataSecurityTestEnvironmentParameters $testSuffix
	Create-BasicTestEnvironmentWithParams $params $location $serverVersion
}


function Get-SqlAdvancedDataSecurityTestEnvironmentParameters ($testSuffix)
{
	return @{ rgname = "sql-ads-cmdlet-test-rg" +$testSuffix;
			  serverName = "sql-ads-cmdlet-server" +$testSuffix;
			  databaseName = "sql-ads-cmdlet-db" + $testSuffix;
			  }
}


function Remove-AdvancedDataSecurityTestEnvironment ($testSuffix)
{
	$params = Get-SqlAdvancedDataSecurityTestEnvironmentParameters $testSuffix
	Remove-AzResourceGroup -Name $params.rgname -Force
}
