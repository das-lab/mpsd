














function Test-AdvancedDataSecurityPolicyManagedInstanceTest
{
	
	$testSuffix = getAssetName
	Create-AdvancedDataSecurityManagedInstanceTestEnvironment $testSuffix
	$params = Get-SqlAdvancedDataSecurityManagedInstanceTestEnvironmentParameters $testSuffix

	try
	{
		
		$policy = Get-AzSqlInstanceAdvancedDataSecurityPolicy -ResourceGroupName $params.rgname -InstanceName $params.serverName 
				
		
		Assert-AreEqual $params.rgname $policy.ResourceGroupName
		Assert-AreEqual $params.serverName $policy.ManagedInstanceName
		Assert-False { $policy.IsEnabled }

		
		Enable-AzSqlInstanceAdvancedDataSecurity -ResourceGroupName $params.rgname -InstanceName $params.serverName -DoNotConfigureVulnerabilityAssessment
		$policy = Get-AzSqlInstanceAdvancedDataSecurityPolicy -ResourceGroupName $params.rgname -InstanceName $params.serverName 
				
		
		Assert-AreEqual $params.rgname $policy.ResourceGroupName
		Assert-AreEqual $params.serverName $policy.ManagedInstanceName
		Assert-True { $policy.IsEnabled }

		
		Disable-AzSqlInstanceAdvancedDataSecurity -ResourceGroupName $params.rgname -InstanceName $params.serverName 
		$policy = Get-AzSqlInstanceAdvancedDataSecurityPolicy -ResourceGroupName $params.rgname -InstanceName $params.serverName 
				
		
		Assert-AreEqual $params.rgname $policy.ResourceGroupName
		Assert-AreEqual $params.serverName $policy.ManagedInstanceName
		Assert-False { $policy.IsEnabled }

		
		Disable-AzSqlInstanceAdvancedDataSecurity -ResourceGroupName $params.rgname -InstanceName $params.serverName 
		Enable-AzSqlInstanceAdvancedDataSecurity -ResourceGroupName $params.rgname -InstanceName $params.serverName -DeploymentName "EnableVA_sql-ads-cmdlet-test-srv1"

		
		$policy = Get-AzSqlInstanceAdvancedDataSecurityPolicy -ResourceGroupName $params.rgname -InstanceName $params.serverName 
		Assert-AreEqual $params.rgname $policy.ResourceGroupName
		Assert-AreEqual $params.serverName $policy.ManagedInstanceName
		Assert-True { $policy.IsEnabled }

		
		$settings = Get-AzSqlInstanceVulnerabilityAssessmentSetting -ResourceGroupName $params.rgname -InstanceName $params.serverName 
		Assert-AreEqual $params.rgname $settings.ResourceGroupName
		Assert-AreEqual $params.serverName $settings.InstanceName
		Assert-AreEqual "vulnerability-assessment" $settings.ScanResultsContainerName
		Assert-AreNotEqual "" $settings.StorageAccountName	
		Assert-AreEqual Weekly $settings.RecurringScansInterval
		Assert-AreEqual $true $settings.EmailAdmins
		Assert-AreEqualArray @() $settings.NotificationEmail
	}
	finally
	{
		
		Remove-AdvancedDataSecurityManagedInstanceTestEnvironment $testSuffix
	}
}


function Create-AdvancedDataSecurityManagedInstanceTestEnvironment ($testSuffix, $location = "West Central US")
{
	$params = Get-SqlAdvancedDataSecurityManagedInstanceTestEnvironmentParameters $testSuffix
	Create-BasicManagedTestEnvironmentWithParams $params $location
}


function Get-SqlAdvancedDataSecurityManagedInstanceTestEnvironmentParameters ($testSuffix)
{
	return @{ rgname = "sql-atp-cmdlet-test-rg" +$testSuffix;
			  serverName = "sql-atp-cmdlet-server" +$testSuffix;
			  databaseName = "sql-atp-cmdlet-db" + $testSuffix;
			  }
}


function Remove-AdvancedDataSecurityManagedInstanceTestEnvironment ($testSuffix)
{
	$params = Get-SqlAdvancedDataSecurityManagedInstanceTestEnvironmentParameters $testSuffix
	Remove-AzureRmResourceGroup -Name $params.rgname -Force
}
