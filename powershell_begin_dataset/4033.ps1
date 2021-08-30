














function Test-ManagedApplicationDefinitionCRUD
{
	
	$rgname = Get-ResourceGroupName
	$appDefName = Get-ResourceName
	$rglocation = "EastUS2EUAP"
	$display = "myAppDefPoSH"

	
	New-AzResourceGroup -Name $rgname -Location $rglocation

	$actual = New-AzManagedApplicationDefinition -Name $appDefName -ResourceGroupName $rgname -DisplayName $display -Description "Test" -Location $rglocation -LockLevel ReadOnly -PackageFileUri https://testclinew.blob.core.windows.net/files/vivekMAD.zip -Authorization 5e91139a-c94b-462e-a6ff-1ee95e8aac07:8e3af657-a8ff-443c-a75c-2fe8c4bcb635
	$expected = Get-AzManagedApplicationDefinition -Name $appDefName -ResourceGroupName $rgname
	Assert-AreEqual $expected.Name $actual.Name
	Assert-AreEqual $expected.ManagedApplicationDefinitionId $actual.ManagedApplicationDefinitionId
	Assert-AreEqual $expected.Properties.DisplayName $actual.Properties.DisplayName
	Assert-NotNull($actual.Properties.Authorizations)

	$actual = Set-AzManagedApplicationDefinition -ResourceId $expected.ManagedApplicationDefinitionId -PackageFileUri https://testclinew.blob.core.windows.net/files/vivekMAD.zip -Description "updated"
	$expected = Get-AzManagedApplicationDefinition -Name $appDefName -ResourceGroupName $rgname
	Assert-AreEqual $expected.Properties.description $actual.Properties.Description

	$list = Get-AzManagedApplicationDefinition -ResourceGroupName $rgname
	Assert-AreEqual 1 @($list).Count

	$remove = Remove-AzManagedApplicationDefinition -Name $appDefName -ResourceGroupName $rgname -Force
	Assert-AreEqual True $remove

}