














function Test-ManagedApplicationCRUD
{
	
	$rgname = Get-ResourceGroupName
	$managedrgname = Get-ResourceGroupName
	$appDefName = Get-ResourceName
	$appName = Get-ResourceName
	$rglocation = "EastUS2EUAP"
	$display = "myAppDefPoSH"

	
	New-AzResourceGroup -Name $rgname -Location $rglocation

	$appDef = New-AzManagedApplicationDefinition -Name $appDefName -ResourceGroupName $rgname -DisplayName $display -Description "Test" -Location $rglocation -LockLevel ReadOnly -PackageFileUri https://testclinew.blob.core.windows.net/files/vivekMAD.zip -Authorization 5e91139a-c94b-462e-a6ff-1ee95e8aac07:8e3af657-a8ff-443c-a75c-2fe8c4bcb635
	$actual = New-AzManagedApplication -Name $appName -ResourceGroupName $rgname -ManagedResourceGroupName $managedrgname -ManagedApplicationDefinitionId $appDef.ResourceId -Location $rglocation -Kind ServiceCatalog -Parameter "$TestOutputRoot\SampleManagedApplicationParameters.json"
	$expected = Get-AzManagedApplication -Name $appName -ResourceGroupName $rgname
	Assert-AreEqual $expected.Name $actual.Name
	Assert-AreEqual $expected.ManagedApplicationId $actual.ManagedApplicationId
	Assert-AreEqual $expected.Properties.applicationDefinitionId $appDef.ResourceId
	Assert-NotNull($actual.Properties.parameters)

	$actual = Set-AzManagedApplication -ResourceId $expected.ManagedApplicationId -Tags @{test="test"}
	$expected = Get-AzManagedApplication -Name $appName -ResourceGroupName $rgname
	Assert-AreEqual 1 @($actual.Tags).Count

	$list = Get-AzManagedApplication -ResourceGroupName $rgname
	Assert-AreEqual 1 @($list).Count
}