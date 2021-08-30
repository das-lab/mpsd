














function Test-ResourceLockCRUD
{
	
	$rgname = Get-ResourceGroupName
	$rname = Get-ResourceName
	$rglocation = Get-ProviderLocation ResourceManagement
	$apiversion = "2014-04-01"

	$rg = New-AzureRMResourceGroup -Name $rgname -Location $rglocation
	$actual = New-AzureRMResourceLock -LockName $rname -LockLevel CanNotDelete -Force -Scope $rg.ResourceId
	$expected = Get-AzureRMResourceLock -LockName $rname -Scope $rg.ResourceId

	
	Assert-AreEqual $expected.Name $actual.Name
	Assert-AreEqual $expected.ResourceId $actual.ResourceId
	Assert-AreEqual $expected.ResourceName $actual.ResourceName
	Assert-AreEqual $expected.ResourceType $actual.ResourceType
	Assert-AreEqual $expected.LockId $actual.LockId

	$expectedSet = Set-AzureRMResourceLock -LockId $expected.LockId -LockLevel CanNotDelete -LockNotes test -Force
	Assert-AreEqual $expectedSet.Properties.Notes "test"

	$removed = Remove-AzureRMResourceLock -LockId $expectedSet.LockId -Force
	Assert-AreEqual True $removed

	$actual = New-AzureRMResourceLock -LockName $rname -LockLevel CanNotDelete -Force -Scope $rg.ResourceId
	$removed = Remove-AzureRMResourceLock -ResourceId $actual.ResourceId -Force
	Assert-AreEqual True $removed

	
	$actual = New-AzureRMResourceLock -LockName $rname -LockLevel ReadOnly -Force -Scope $rg.ResourceId
	Assert-AreEqual $expected.Name $actual.Name

	$expected = Get-AzureRMResourceLock -LockName $rname -Scope $rg.ResourceId
	Assert-AreEqual $expected.Properties.Level "ReadOnly"

	$removed = Remove-AzureRMResourceLock -ResourceId $actual.ResourceId -Force
	Assert-AreEqual True $removed
}


function Test-ResourceLockNonExisting
{
	
	$rgname = Get-ResourceGroupName
	$rglocation = Get-ProviderLocation ResourceManagement

	$rg = New-AzureRMResourceGroup -Name $rgname -Location $rglocation
	Assert-AreEqual $rgname $rg.ResourceGroupName
	
	$lock = Get-AzureRMResourceLock -LockName "NonExisting" -Scope $rg.ResourceId -ErrorAction SilentlyContinue

	Assert-True { $Error[0] -like "*LockNotFound : The lock 'NonExisting' could not be found." }
	Assert-Null $lock

	$Error.Clear()
}