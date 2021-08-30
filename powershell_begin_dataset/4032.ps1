














function Test-ResourceLockCRUD
{
	
	$rgname = Get-ResourceGroupName
	$rname = Get-ResourceName
	$rglocation = Get-Location "Microsoft.Resources" "resourceGroups" "West US"
	$apiversion = "2014-04-01"

	$rg = New-AzResourceGroup -Name $rgname -Location $rglocation
	$actual = New-AzResourceLock -LockName $rname -LockLevel CanNotDelete -Force -Scope $rg.ResourceId
	$expected = Get-AzResourceLock -LockName $rname -Scope $rg.ResourceId

	
	Assert-AreEqual $expected.Name $actual.Name
	Assert-AreEqual $expected.ResourceId $actual.ResourceId
	Assert-AreEqual $expected.ResourceName $actual.ResourceName
	Assert-AreEqual $expected.ResourceType $actual.ResourceType
	Assert-AreEqual $expected.LockId $actual.LockId

	$expectedSet = Set-AzResourceLock -LockId $expected.LockId -LockLevel CanNotDelete -LockNotes test -Force
	Assert-AreEqual $expectedSet.Properties.Notes "test"

	$removed = Remove-AzResourceLock -LockId $expectedSet.LockId -Force
	Assert-AreEqual True $removed

	$actual = New-AzResourceLock -LockName $rname -LockLevel CanNotDelete -Force -Scope $rg.ResourceId
	$removed = Remove-AzResourceLock -ResourceId $actual.ResourceId -Force
	Assert-AreEqual True $removed

	
	$actual = New-AzResourceLock -LockName $rname -LockLevel ReadOnly -Force -Scope $rg.ResourceId
	Assert-AreEqual $expected.Name $actual.Name

	$expected = Get-AzResourceLock -LockName $rname -Scope $rg.ResourceId
	Assert-AreEqual $expected.Properties.Level "ReadOnly"

	$removed = Remove-AzResourceLock -ResourceId $actual.ResourceId -Force
	Assert-AreEqual True $removed
}


function Test-ResourceLockNonExisting
{
	
	$rgname = Get-ResourceGroupName
	$rglocation = Get-Location "Microsoft.Resources" "resourceGroups" "West US"

	$rg = New-AzResourceGroup -Name $rgname -Location $rglocation
	Assert-AreEqual $rgname $rg.ResourceGroupName
	
	$lock = Get-AzResourceLock -LockName "NonExisting" -Scope $rg.ResourceId -ErrorAction SilentlyContinue

	Assert-True { $Error[0] -like "*LockNotFound : The lock 'NonExisting' could not be found." }
	Assert-Null $lock

	$Error.Clear()
}