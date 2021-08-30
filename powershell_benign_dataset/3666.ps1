














function Test-DatabaseDataMaskingPrivilegedUsersChanges
{

	
	$testSuffix = getAssetName
	Create-DataMaskingTestEnvironment $testSuffix
	$params = Get-SqlDataMaskingTestEnvironmentParameters $testSuffix

	try
	{
		
		$policy = Get-AzSqlDatabaseDataMaskingPolicy -ResourceGroupName $params.rgname -ServerName $params.serverName  -DatabaseName $params.databaseName
	
		
		Assert-AreEqual "Disabled" $policy.DataMaskingState


		
		Set-AzSqlDatabaseDataMaskingPolicy -ResourceGroupName $params.rgname -ServerName $params.serverName  -DatabaseName $params.databaseName -PrivilegedUsers "public" -DataMaskingState "Enabled"
		$policy = Get-AzSqlDatabaseDataMaskingPolicy -ResourceGroupName $params.rgname -ServerName $params.serverName  -DatabaseName $params.databaseName
	
		
		Assert-AreEqual "public;" $policy.PrivilegedUsers
		Assert-AreEqual "Enabled" $policy.DataMaskingState

		
		Set-AzSqlDatabaseDataMaskingPolicy -ResourceGroupName $params.rgname -ServerName $params.serverName  -DatabaseName $params.databaseName -PrivilegedUsers "" 
		$policy = Get-AzSqlDatabaseDataMaskingPolicy -ResourceGroupName $params.rgname -ServerName $params.serverName  -DatabaseName $params.databaseName
	
		
	    Assert-AreEqual "" $policy.PrivilegedUsers

		
		Set-AzSqlDatabaseDataMaskingPolicy -ResourceGroupName $params.rgname -ServerName $params.serverName  -DatabaseName $params.databaseName -DataMaskingState "Disabled" 
		$policy = Get-AzSqlDatabaseDataMaskingPolicy -ResourceGroupName $params.rgname -ServerName $params.serverName  -DatabaseName $params.databaseName
	
		
	    Assert-AreEqual "" $policy.PrivilegedUsers

		
		Set-AzSqlDatabaseDataMaskingPolicy -ResourceGroupName $params.rgname -ServerName $params.serverName  -DatabaseName $params.databaseName -PrivilegedUsers "public" 
		$policy = Get-AzSqlDatabaseDataMaskingPolicy -ResourceGroupName $params.rgname -ServerName $params.serverName  -DatabaseName $params.databaseName
	
		
		Assert-AreEqual "" $policy.PrivilegedUsers

		
		Set-AzSqlDatabaseDataMaskingPolicy -ResourceGroupName $params.rgname -ServerName $params.serverName  -DatabaseName $params.databaseName -PrivilegedUsers ""  
		$policy = Get-AzSqlDatabaseDataMaskingPolicy -ResourceGroupName $params.rgname -ServerName $params.serverName  -DatabaseName $params.databaseName
	
		
		Assert-AreEqual "" $policy.PrivilegedUsers
	}
	finally
	{
		
		Remove-DataMaskingTestEnvironment $testSuffix
	}
}


function Test-DatabaseDataMaskingBasicRuleLifecycle
{

	
	$testSuffix = getAssetName
	Create-DataMaskingTestEnvironment $testSuffix
	$params = Get-SqlDataMaskingTestEnvironmentParameters $testSuffix

	try
	{
		
		Set-AzSqlDatabaseDataMaskingPolicy -ResourceGroupName $params.rgname -ServerName $params.serverName  -DatabaseName $params.databaseName

		$ruleCountBefore = (Get-AzSqlDatabaseDataMaskingRule -ResourceGroupName $params.rgname -ServerName $params.serverName  -DatabaseName $params.databaseName).Count
		$ruleCountBefore = if ( !$ruleCountBefore ) {0} else {$ruleCountBefore}
		New-AzSqlDatabaseDataMaskingRule -ResourceGroupName $params.rgname -ServerName $params.serverName  -DatabaseName $params.databaseName -MaskingFunction "Default" -SchemaName "dbo" -TableName  $params.table1 -ColumnName $params.column1
		$ruleCountAfter = (Get-AzSqlDatabaseDataMaskingRule -ResourceGroupName $params.rgname -ServerName $params.serverName  -DatabaseName $params.databaseName).Count
		$ruleCountAfter = if ( !$ruleCountAfter ) {0} else {$ruleCountAfter}

		
		Assert-AreEqual ($ruleCountBefore + 1) $ruleCountAfter
		$rule = Get-AzSqlDatabaseDataMaskingRule -ResourceGroupName $params.rgname -ServerName $params.serverName  -DatabaseName $params.databaseName -SchemaName "dbo" -TableName  $params.table1 -ColumnName $params.column1

		
		Assert-AreEqual $rule.ResourceGroupName $params.rgname
		Assert-AreEqual $rule.ServerName $params.serverName
		Assert-AreEqual $rule.DatabaseName $params.databaseName
		Assert-AreEqual $rule.MaskingFunction "Default"
		Assert-AreEqual $rule.SchemaName "dbo"
		Assert-AreEqual $rule.TableName $params.table1
		Assert-AreEqual $rule.ColumnName $params.column1

		Set-AzSqlDatabaseDataMaskingRule -ResourceGroupName $params.rgname -ServerName $params.serverName  -DatabaseName $params.databaseName  -MaskingFunction "Email" -SchemaName "dbo" -TableName  $params.table1 -ColumnName $params.column1
		$rule = Get-AzSqlDatabaseDataMaskingRule -ResourceGroupName $params.rgname -ServerName $params.serverName  -DatabaseName $params.databaseName -SchemaName "dbo" -TableName  $params.table1 -ColumnName $params.column1

		
		Assert-AreEqual $rule.ResourceGroupName $params.rgname
		Assert-AreEqual $rule.ServerName $params.serverName
		Assert-AreEqual $rule.DatabaseName $params.databaseName
		Assert-AreEqual $rule.MaskingFunction "Email"
		Assert-AreEqual $rule.SchemaName "dbo"
		Assert-AreEqual $rule.TableName $params.table1
		Assert-AreEqual $rule.ColumnName $params.column1

		Set-AzSqlDatabaseDataMaskingRule -ResourceGroupName $params.rgname -ServerName $params.serverName  -DatabaseName $params.databaseName -SchemaName "dbo" -TableName  $params.table1 -ColumnName $params.column1 -MaskingFunction "Default"
		$rule = Get-AzSqlDatabaseDataMaskingRule -ResourceGroupName $params.rgname -ServerName $params.serverName  -DatabaseName $params.databaseName

			
		Assert-AreEqual $rule.ResourceGroupName $params.rgname
		Assert-AreEqual $rule.ServerName $params.serverName
		Assert-AreEqual $rule.DatabaseName $params.databaseName
		Assert-AreEqual $rule.MaskingFunction "Default"
		Assert-AreEqual $rule.SchemaName "dbo"
		Assert-AreEqual $rule.TableName $params.table1
		Assert-AreEqual $rule.ColumnName $params.column1

		$ruleCountBefore = (Get-AzSqlDatabaseDataMaskingRule -ResourceGroupName $params.rgname -ServerName $params.serverName  -DatabaseName $params.databaseName).Count
		$ruleCountBefore = if ( !$ruleCountBefore ) {0} else {$ruleCountBefore}
		Remove-AzSqlDatabaseDataMaskingRule -ResourceGroupName $params.rgname -ServerName $params.serverName  -DatabaseName $params.databaseName -SchemaName "dbo" -TableName  $params.table1 -ColumnName $params.column1 -Force
		$ruleCountAfter = (Get-AzSqlDatabaseDataMaskingRule -ResourceGroupName $params.rgname -ServerName $params.serverName  -DatabaseName $params.databaseName).Count
		$ruleCountAfter = if ( !$ruleCountAfter ) {0} else {$ruleCountAfter}		
	}
	finally
	{
		
		Remove-DataMaskingTestEnvironment $testSuffix
	}
}


function Test-DatabaseDataMaskingNumberRuleLifecycle
{

	
	$testSuffix = getAssetName
	Create-DataMaskingTestEnvironment $testSuffix
	$params = Get-SqlDataMaskingTestEnvironmentParameters $testSuffix

	try
	{
		
		Set-AzSqlDatabaseDataMaskingPolicy -ResourceGroupName $params.rgname -ServerName $params.serverName  -DatabaseName $params.databaseName

		$ruleCountBefore = (Get-AzSqlDatabaseDataMaskingRule -ResourceGroupName $params.rgname -ServerName $params.serverName  -DatabaseName $params.databaseName).Count
		$ruleCountBefore = if ( !$ruleCountBefore ) {0} else {$ruleCountBefore}
		New-AzSqlDatabaseDataMaskingRule -ResourceGroupName $params.rgname -ServerName $params.serverName  -DatabaseName $params.databaseName -MaskingFunction "Number" -SchemaName "dbo" -TableName  $params.table1 -ColumnName $params.columnInt -NumberFrom 12 -NumberTo 56
		$ruleCountAfter = (Get-AzSqlDatabaseDataMaskingRule -ResourceGroupName $params.rgname -ServerName $params.serverName  -DatabaseName $params.databaseName).Count
		$ruleCountAfter = if ( !$ruleCountAfter ) {0} else {$ruleCountAfter}

		
		Assert-AreEqual ($ruleCountBefore + 1) $ruleCountAfter

		$rule = Get-AzSqlDatabaseDataMaskingRule -ResourceGroupName $params.rgname -ServerName $params.serverName  -DatabaseName $params.databaseName -SchemaName "dbo" -TableName  $params.table1 -ColumnName $params.columnInt

		
		Assert-AreEqual $rule.ResourceGroupName $params.rgname
		Assert-AreEqual $rule.ServerName $params.serverName
		Assert-AreEqual $rule.DatabaseName $params.databaseName
		Assert-AreEqual $rule.MaskingFunction "Number"
		Assert-AreEqual $rule.SchemaName "dbo"
		Assert-AreEqual $rule.TableName $params.table1
		Assert-AreEqual $rule.ColumnName $params.columnInt
		Assert-AreEqual $rule.NumberFrom 12
		Assert-AreEqual $rule.NumberTo 56
		

		Set-AzSqlDatabaseDataMaskingRule -ResourceGroupName $params.rgname -ServerName $params.serverName  -DatabaseName $params.databaseName -SchemaName "dbo" -TableName  $params.table1 -ColumnName $params.columnInt -NumberFrom 15 -NumberTo 34
		$rule = Get-AzSqlDatabaseDataMaskingRule -ResourceGroupName $params.rgname -ServerName $params.serverName  -DatabaseName $params.databaseName -SchemaName "dbo" -TableName  $params.table1 -ColumnName $params.columnInt

		
		Assert-AreEqual $rule.ResourceGroupName $params.rgname
		Assert-AreEqual $rule.ServerName $params.serverName
		Assert-AreEqual $rule.DatabaseName $params.databaseName
		Assert-AreEqual $rule.MaskingFunction "Number"
		Assert-AreEqual $rule.SchemaName "dbo"
		Assert-AreEqual $rule.TableName $params.table1
		Assert-AreEqual $rule.ColumnName $params.columnInt
		Assert-AreEqual $rule.NumberFrom 15
		Assert-AreEqual $rule.NumberTo 34


		$ruleCountBefore = (Get-AzSqlDatabaseDataMaskingRule -ResourceGroupName $params.rgname -ServerName $params.serverName  -DatabaseName $params.databaseName).Count
		$ruleCountBefore = if ( !$ruleCountBefore ) {0} else {$ruleCountBefore}
		Remove-AzSqlDatabaseDataMaskingRule -ResourceGroupName $params.rgname -ServerName $params.serverName  -DatabaseName $params.databaseName -SchemaName "dbo" -TableName  $params.table1 -ColumnName $params.column1 -Force
		$ruleCountAfter = (Get-AzSqlDatabaseDataMaskingRule -ResourceGroupName $params.rgname -ServerName $params.serverName  -DatabaseName $params.databaseName).Count
		$ruleCountAfter = if ( !$ruleCountAfter ) {0} else {$ruleCountAfter}

		
		Assert-AreEqual ($ruleCountBefore - 1) $ruleCountAfter

	}
	finally
	{
		
		Remove-DataMaskingTestEnvironment $testSuffix
	}
}


function Test-DatabaseDataMaskingTextRuleLifecycle
{

	
	$testSuffix = getAssetName
	Create-DataMaskingTestEnvironment $testSuffix
	$params = Get-SqlDataMaskingTestEnvironmentParameters $testSuffix

	try
	{
		
		Set-AzSqlDatabaseDataMaskingPolicy -ResourceGroupName $params.rgname -ServerName $params.serverName  -DatabaseName $params.databaseName

		$ruleCountBefore = (Get-AzSqlDatabaseDataMaskingRule -ResourceGroupName $params.rgname -ServerName $params.serverName  -DatabaseName $params.databaseName).Count
		$ruleCountBefore = if ( !$ruleCountBefore ) {0} else {$ruleCountBefore}
		New-AzSqlDatabaseDataMaskingRule -ResourceGroupName $params.rgname -ServerName $params.serverName  -DatabaseName $params.databaseName -MaskingFunction "Text" -SchemaName "dbo" -TableName  $params.table1 -ColumnName $params.column1 -PrefixSize 1 -ReplacementString "AAA" -SuffixSize 3
		$ruleCountAfter = (Get-AzSqlDatabaseDataMaskingRule -ResourceGroupName $params.rgname -ServerName $params.serverName  -DatabaseName $params.databaseName).Count
		$ruleCountAfter = if ( !$ruleCountAfter ) {0} else {$ruleCountAfter}

		
		Assert-AreEqual ($ruleCountBefore + 1) $ruleCountAfter

		$rule = Get-AzSqlDatabaseDataMaskingRule -ResourceGroupName $params.rgname -ServerName $params.serverName  -DatabaseName $params.databaseName -SchemaName "dbo" -TableName  $params.table1 -ColumnName $params.column1

		
		Assert-AreEqual $rule.ResourceGroupName $params.rgname
		Assert-AreEqual $rule.ServerName $params.serverName
		Assert-AreEqual $rule.DatabaseName $params.databaseName
		Assert-AreEqual $rule.MaskingFunction "Text"
		Assert-AreEqual $rule.SchemaName "dbo"
		Assert-AreEqual $rule.TableName $params.table1
		Assert-AreEqual $rule.ColumnName $params.column1
		Assert-AreEqual $rule.PrefixSize 1
		Assert-AreEqual $rule.ReplacementString "AAA"
		Assert-AreEqual $rule.SuffixSize 3
	
		Set-AzSqlDatabaseDataMaskingRule -ResourceGroupName $params.rgname -ServerName $params.serverName  -DatabaseName $params.databaseName -SchemaName "dbo" -TableName  $params.table1 -ColumnName $params.column1 -PrefixSize 4 -ReplacementString "BBB" -SuffixSize 2
		$rule = Get-AzSqlDatabaseDataMaskingRule -ResourceGroupName $params.rgname -ServerName $params.serverName  -DatabaseName $params.databaseName

		
		Assert-AreEqual $rule.ResourceGroupName $params.rgname
		Assert-AreEqual $rule.ServerName $params.serverName
		Assert-AreEqual $rule.DatabaseName $params.databaseName
		Assert-AreEqual $rule.MaskingFunction "Text"
		Assert-AreEqual $rule.SchemaName "dbo"
		Assert-AreEqual $rule.TableName $params.table1
		Assert-AreEqual $rule.ColumnName $params.column1
		Assert-AreEqual $rule.PrefixSize 4
		Assert-AreEqual $rule.ReplacementString "BBB"
		Assert-AreEqual $rule.SuffixSize 2


		$ruleCountBefore = (Get-AzSqlDatabaseDataMaskingRule -ResourceGroupName $params.rgname -ServerName $params.serverName  -DatabaseName $params.databaseName).Count
		$ruleCountBefore = if ( !$ruleCountBefore ) {0} else {$ruleCountBefore}
		Remove-AzSqlDatabaseDataMaskingRule -ResourceGroupName $params.rgname -ServerName $params.serverName  -DatabaseName $params.databaseName -SchemaName "dbo" -TableName  $params.table1 -ColumnName $params.column1 -Force
		$ruleCountAfter = (Get-AzSqlDatabaseDataMaskingRule -ResourceGroupName $params.rgname -ServerName $params.serverName  -DatabaseName $params.databaseName).Count
		$ruleCountAfter = if ( !$ruleCountAfter ) {0} else {$ruleCountAfter}

		
		Assert-AreEqual ($ruleCountBefore - 1) $ruleCountAfter
	}
	finally
	{
		
		Remove-DataMaskingTestEnvironment $testSuffix
	}
}


function Test-DatabaseDataMaskingRuleCreationFailures
{

	
	$testSuffix = getAssetName
	Create-DataMaskingTestEnvironment $testSuffix
	$params = Get-SqlDataMaskingTestEnvironmentParameters $testSuffix

	try
	{
		
		Set-AzSqlDatabaseDataMaskingPolicy -ResourceGroupName $params.rgname -ServerName $params.serverName  -DatabaseName $params.databaseName
		
		Assert-Throws { New-AzSqlDatabaseDataMaskingRule -ResourceGroupName "NONEXISTING" -ServerName $params.serverName  -DatabaseName $params.databaseName -MaskingFunction "Default" -SchemaName "dbo" -TableName  $params.table1 -ColumnName $params.column1} 
		Assert-Throws { New-AzSqlDatabaseDataMaskingRule -ResourceGroupName $params.rgname -ServerName "NONEXISTING"  -DatabaseName $params.databaseName -MaskingFunction "Default" -SchemaName "dbo" -TableName  $params.table1 -ColumnName $params.column1} 
		Assert-Throws { New-AzSqlDatabaseDataMaskingRule -ResourceGroupName $params.rgname -ServerName $params.serverName  -DatabaseName "NONEXISTING" -MaskingFunction "Default" -SchemaName "dbo" -TableName  $params.table1 -ColumnName $params.column1} 
		Assert-Throws { New-AzSqlDatabaseDataMaskingRule -ResourceGroupName $params.rgname -ServerName $params.serverName  -DatabaseName $params.databaseName -MaskingFunction "Default" -SchemaName "NONEXISTING" -TableName  $params.table1 -ColumnName $params.column1} 
		Assert-Throws { New-AzSqlDatabaseDataMaskingRule -ResourceGroupName $params.rgname -ServerName $params.serverName  -DatabaseName $params.databaseName -MaskingFunction "Default" -SchemaName "dbo" -TableName  "NONEXISTING" -ColumnName $params.column1} 
		Assert-Throws { New-AzSqlDatabaseDataMaskingRule -ResourceGroupName $params.rgname -ServerName $params.serverName  -DatabaseName $params.databaseName -MaskingFunction "Default" -SchemaName "dbo" -TableName  $params.table1 "NONEXISTING"} 
	}
	finally
	{
		
		Remove-DataMaskingTestEnvironment $testSuffix
	}
}


function Test-DatabaseDataMaskingRuleCreationWithoutPolicy
{

	
	$testSuffix = getAssetName
	Create-DataMaskingTestEnvironment $testSuffix
	$params = Get-SqlDataMaskingTestEnvironmentParameters $testSuffix

	try
	{
		
		$ruleCountBefore = (Get-AzSqlDatabaseDataMaskingRule -ResourceGroupName $params.rgname -ServerName $params.serverName  -DatabaseName $params.databaseName).Count
		$ruleCountBefore = if ( !$ruleCountBefore ) {0} else {$ruleCountBefore}
		New-AzSqlDatabaseDataMaskingRule -ResourceGroupName $params.rgname -ServerName $params.serverName  -DatabaseName $params.databaseName -MaskingFunction "Default" -SchemaName "dbo" -TableName  $params.table1 -ColumnName $params.column1
		$ruleCountAfter = (Get-AzSqlDatabaseDataMaskingRule -ResourceGroupName $params.rgname -ServerName $params.serverName  -DatabaseName $params.databaseName).Count
		$ruleCountAfter = if ( !$ruleCountAfter ) {0} else {$ruleCountAfter}

		
		Assert-AreEqual ($ruleCountBefore + 1) $ruleCountAfter
		$rule = Get-AzSqlDatabaseDataMaskingRule -ResourceGroupName $params.rgname -ServerName $params.serverName  -DatabaseName $params.databaseName -SchemaName "dbo" -TableName  $params.table1 -ColumnName $params.column1

		
		Assert-AreEqual $rule.ResourceGroupName $params.rgname
		Assert-AreEqual $rule.ServerName $params.serverName
		Assert-AreEqual $rule.DatabaseName $params.databaseName
		Assert-AreEqual $rule.MaskingFunction "Default"
		Assert-AreEqual $rule.SchemaName "dbo"
		Assert-AreEqual $rule.TableName $params.table1
		Assert-AreEqual $rule.ColumnName $params.column1

		$ruleCountBefore = $ruleCountAfter
		Remove-AzSqlDatabaseDataMaskingRule -ResourceGroupName $params.rgname -ServerName $params.serverName  -DatabaseName $params.databaseName -SchemaName "dbo" -TableName  $params.table1 -ColumnName $params.column1 -Force
		$ruleCountAfter = (Get-AzSqlDatabaseDataMaskingRule -ResourceGroupName $params.rgname -ServerName $params.serverName  -DatabaseName $params.databaseName).Count
		$ruleCountAfter = if ( !$ruleCountAfter ) {0} else {$ruleCountAfter}
		
		
		Assert-Throws {Get-AzSqlDatabaseDataMaskingRule -ResourceGroupName $params.rgname -ServerName $params.serverName  -DatabaseName $params.databaseName -RuleId $ruleId}
		Assert-AreEqual ($ruleCountBefore - 1) $ruleCountAfter
	}
	finally
	{
		
		Remove-DataMaskingTestEnvironment $testSuffix
	}
}

